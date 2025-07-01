#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== TroupeX DigitalOcean Droplet Setup ===${NC}"
echo -e "${YELLOW}This script will set up a new Ubuntu droplet for TroupeX deployment${NC}"
echo ""

# Configuration
DEPLOY_USER="deploy"
APP_DIR="/home/${DEPLOY_USER}/troupex"
RUBY_VERSION="3.4.4"
NODE_VERSION="22"

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu 22.04" /etc/os-release && ! grep -q "Ubuntu 20.04" /etc/os-release; then
        echo -e "${YELLOW}Warning: This script is tested on Ubuntu 20.04/22.04${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

echo -e "${GREEN}Step 1: System Updates${NC}"
apt-get update
apt-get upgrade -y

echo -e "${GREEN}Step 2: Installing Essential Packages${NC}"
apt-get install -y \
    curl wget git vim htop \
    build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release \
    ufw fail2ban \
    postgresql-client redis-tools \
    imagemagick ffmpeg libvips-tools \
    nginx certbot python3-certbot-nginx \
    unzip

echo -e "${GREEN}Step 3: Setting up Firewall${NC}"
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'Rails'
ufw allow 4000/tcp comment 'Streaming'
ufw --force enable

echo -e "${GREEN}Step 4: Creating Deploy User${NC}"
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash $DEPLOY_USER
    usermod -aG sudo $DEPLOY_USER
    echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$DEPLOY_USER
    
    # Create SSH directory
    mkdir -p /home/$DEPLOY_USER/.ssh
    chmod 700 /home/$DEPLOY_USER/.ssh
    
    # Copy authorized_keys if exists
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/
        chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
        chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh
    fi
fi

echo -e "${GREEN}Step 5: Installing Docker${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | bash
    usermod -aG docker $DEPLOY_USER
    systemctl enable docker
    systemctl start docker
fi

echo -e "${GREEN}Step 6: Installing Docker Compose${NC}"
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

echo -e "${GREEN}Step 7: Installing Cloudflared${NC}"
if ! command -v cloudflared &> /dev/null; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
fi

echo -e "${GREEN}Step 8: Setting up Application Directory${NC}"
sudo -u $DEPLOY_USER bash << EOF
    mkdir -p ${APP_DIR}/{mastodon,scripts,backups,logs}
    mkdir -p ${APP_DIR}/mastodon/public/{system,assets,packs}
    mkdir -p ~/.cloudflared
    
    # Create Docker networks
    docker network create troupex_external 2>/dev/null || true
    docker network create troupex_internal 2>/dev/null || true
EOF

echo -e "${GREEN}Step 9: Setting up Swap (if needed)${NC}"
if ! swapon --show | grep -q swap; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    # Optimize swappiness for server use
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl -p
fi

echo -e "${GREEN}Step 10: Setting up Fail2ban${NC}"
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

systemctl restart fail2ban

echo -e "${GREEN}Step 11: Optimizing System Settings${NC}"
# Increase file limits
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
EOF

# Optimize kernel parameters
cat >> /etc/sysctl.conf << EOF
# Network optimizations
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Memory optimizations
vm.overcommit_memory = 1
EOF

sysctl -p

echo -e "${GREEN}Step 12: Setting up Log Rotation${NC}"
cat > /etc/logrotate.d/troupex << EOF
${APP_DIR}/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $DEPLOY_USER $DEPLOY_USER
    sharedscripts
    postrotate
        docker exec troupex-web-1 kill -USR1 1
    endscript
}
EOF

echo -e "${GREEN}Step 13: Creating Helper Scripts${NC}"
# Create deployment helper script
cat > ${APP_DIR}/deploy.sh << 'EOF'
#!/bin/bash
cd /home/deploy/troupex
./scripts/deploy.sh
EOF
chmod +x ${APP_DIR}/deploy.sh
chown $DEPLOY_USER:$DEPLOY_USER ${APP_DIR}/deploy.sh

# Create backup script
cat > ${APP_DIR}/backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/home/deploy/troupex/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

mkdir -p ${BACKUP_PATH}

# Backup database
docker compose exec -T db pg_dump -U mastodon mastodon_production | gzip > ${BACKUP_PATH}/database.sql.gz

# Backup media files
tar -czf ${BACKUP_PATH}/media.tar.gz -C /home/deploy/troupex/mastodon/public/system .

# Backup environment
cp /home/deploy/troupex/mastodon/.env.production ${BACKUP_PATH}/

# Keep only last 7 days of backups
find ${BACKUP_DIR} -name "backup_*" -mtime +7 -exec rm -rf {} \;

echo "Backup completed: ${BACKUP_PATH}"
EOF
chmod +x ${APP_DIR}/backup.sh
chown $DEPLOY_USER:$DEPLOY_USER ${APP_DIR}/backup.sh

# Create monitoring script
cat > ${APP_DIR}/monitor.sh << 'EOF'
#!/bin/bash
echo "=== TroupeX Service Status ==="
docker compose ps
echo ""
echo "=== Resource Usage ==="
docker stats --no-stream
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== Memory Usage ==="
free -h
EOF
chmod +x ${APP_DIR}/monitor.sh
chown $DEPLOY_USER:$DEPLOY_USER ${APP_DIR}/monitor.sh

echo -e "${GREEN}Step 14: Setting up Cron Jobs${NC}"
sudo -u $DEPLOY_USER crontab -l 2>/dev/null | { cat; echo "0 3 * * * ${APP_DIR}/backup.sh >> ${APP_DIR}/logs/backup.log 2>&1"; } | sudo -u $DEPLOY_USER crontab -

echo -e "${GREEN}Step 15: Setting up MOTD${NC}"
cat > /etc/motd << EOF

╔══════════════════════════════════════════════════════════════╗
║                     TroupeX Production Server                 ║
╠══════════════════════════════════════════════════════════════╣
║  Quick Commands:                                              ║
║  - cd ~/troupex              : Go to application directory   ║
║  - ./deploy.sh               : Deploy latest changes         ║
║  - ./monitor.sh              : Check service status          ║
║  - ./backup.sh               : Create backup                 ║
║  - docker compose logs -f    : View application logs         ║
║  - sudo journalctl -f -u cloudflared : View tunnel logs      ║
╚══════════════════════════════════════════════════════════════╝

EOF

echo ""
echo -e "${GREEN}✅ DigitalOcean droplet setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. SSH as deploy user: ssh ${DEPLOY_USER}@<droplet-ip>"
echo "2. Clone your repository: git clone https://github.com/material-lab-io/TroupeX.git ${APP_DIR}"
echo "3. Set up environment variables in ${APP_DIR}/mastodon/.env.production"
echo "4. Configure Cloudflare tunnel"
echo "5. Run the deployment"
echo ""
echo -e "${YELLOW}Security Notes:${NC}"
echo "- Change deploy user password: sudo passwd ${DEPLOY_USER}"
echo "- Review firewall rules: sudo ufw status"
echo "- Check fail2ban status: sudo fail2ban-client status"
echo ""
echo -e "${BLUE}System Information:${NC}"
echo "- Ubuntu Version: $(lsb_release -d | cut -f2)"
echo "- Docker Version: $(docker --version)"
echo "- Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "- CPU: $(nproc) cores"
echo "- Disk: $(df -h / | tail -1 | awk '{print $2}')"