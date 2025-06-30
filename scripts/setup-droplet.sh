#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== TroupeX DigitalOcean Droplet Setup ===${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Variables
DEPLOY_USER="deploy"
APP_DIR="/home/${DEPLOY_USER}/troupex"

echo -e "${YELLOW}Step 1: System Update${NC}"
apt-get update && apt-get upgrade -y

echo -e "${YELLOW}Step 2: Install Essential Packages${NC}"
apt-get install -y \
    curl \
    git \
    vim \
    htop \
    ufw \
    fail2ban \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    postgresql-client \
    redis-tools \
    nginx \
    certbot \
    python3-certbot-nginx

echo -e "${YELLOW}Step 3: Configure Firewall${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp  # For initial testing, remove later
ufw status

echo -e "${YELLOW}Step 4: Create Deploy User${NC}"
if ! id -u ${DEPLOY_USER} >/dev/null 2>&1; then
    useradd -m -s /bin/bash ${DEPLOY_USER}
    usermod -aG sudo ${DEPLOY_USER}
    echo "${DEPLOY_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${DEPLOY_USER}
    
    # Create .ssh directory
    mkdir -p /home/${DEPLOY_USER}/.ssh
    chmod 700 /home/${DEPLOY_USER}/.ssh
    
    # Copy authorized_keys from root
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/${DEPLOY_USER}/.ssh/
        chmod 600 /home/${DEPLOY_USER}/.ssh/authorized_keys
        chown -R ${DEPLOY_USER}:${DEPLOY_USER} /home/${DEPLOY_USER}/.ssh
    fi
fi

echo -e "${YELLOW}Step 5: Install Docker${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add deploy user to docker group
    usermod -aG docker ${DEPLOY_USER}
    
    # Enable Docker service
    systemctl enable docker
    systemctl start docker
fi

echo -e "${YELLOW}Step 6: Configure Swap (if needed)${NC}"
if ! swapon --show | grep -q swap; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    
    # Optimize swappiness
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
fi

echo -e "${YELLOW}Step 7: Configure System Limits${NC}"
cat >> /etc/sysctl.conf << EOF
# Mastodon optimizations
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 65535
EOF
sysctl -p

echo -e "${YELLOW}Step 8: Setup Application Directory${NC}"
sudo -u ${DEPLOY_USER} mkdir -p ${APP_DIR}
cd ${APP_DIR}

echo -e "${YELLOW}Step 9: Configure Fail2ban${NC}"
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo -e "${YELLOW}Step 10: Configure Automatic Security Updates${NC}"
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo -e "${YELLOW}Step 11: Create Docker Networks${NC}"
docker network create troupex_external || true
docker network create troupex_internal || true

echo -e "${YELLOW}Step 12: Configure Log Rotation${NC}"
cat > /etc/logrotate.d/troupex << EOF
/home/${DEPLOY_USER}/troupex/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ${DEPLOY_USER} ${DEPLOY_USER}
    sharedscripts
    postrotate
        docker compose -f ${APP_DIR}/docker-compose.yml exec -T web kill -USR1 1
    endscript
}
EOF

echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set a password for ${DEPLOY_USER} user: passwd ${DEPLOY_USER}"
echo "2. Configure your domain DNS to point to this server"
echo "3. Run the deployment script as ${DEPLOY_USER} user"
echo "4. Configure SSL with: sudo certbot --nginx -d your-domain.com"
echo ""
echo -e "${YELLOW}Server IP: $(curl -s ifconfig.me)${NC}"