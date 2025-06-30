# TroupeX Quick Deploy Guide

Deploy TroupeX to DigitalOcean in 15 minutes!

## 🚀 Quick Start

### 1. Create DigitalOcean Droplet

- Size: 4GB RAM, 2 vCPUs minimum
- OS: Ubuntu 22.04 LTS
- Enable: Backups & Monitoring
- Add your SSH key

### 2. Setup Server (5 min)

```bash
# SSH into your droplet
ssh root@<droplet-ip>

# Download and run setup
curl -fsSL https://raw.githubusercontent.com/material-lab-io/TroupeX/main/scripts/setup-droplet.sh -o setup.sh
chmod +x setup.sh && ./setup.sh

# Set deploy password
passwd deploy
```

### 3. Configure GitHub Secrets (5 min)

In your forked repo → Settings → Secrets → Actions:

| Secret | How to Get |
|--------|------------|
| `DROPLET_IP` | Your droplet's IP address |
| `DROPLET_USER` | `deploy` |
| `SSH_PRIVATE_KEY` | `cat ~/.ssh/id_rsa` (or your key) |
| `KNOWN_HOSTS` | `ssh-keyscan <droplet-ip>` |
| `PRODUCTION_ENV` | See below |
| `SITE_URL` | `https://your-domain.com` |

### 4. Create Environment File

```bash
# Create .env.production
cat > .env.production << 'EOF'
LOCAL_DOMAIN=your-domain.com
WEB_DOMAIN=your-domain.com

DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=$(openssl rand -hex 32)

REDIS_HOST=redis
REDIS_PORT=6379

SECRET_KEY_BASE=$(openssl rand -hex 64)
OTP_SECRET=$(openssl rand -hex 64)

SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_ADDRESS=noreply@your-domain.com

S3_ENABLED=false
SINGLE_USER_MODE=false
EOF

# Encode for GitHub
base64 -w 0 .env.production
# Copy output to PRODUCTION_ENV secret
```

### 5. Initial Deploy (5 min)

On your droplet as `deploy` user:

```bash
su - deploy
cd /home/deploy
git clone https://github.com/<your-username>/TroupeX.git troupex
cd troupex

# Copy your .env.production here
nano mastodon/.env.production

# First time setup
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d db redis
sleep 30
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails db:setup
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d

# Create admin
docker compose run --rm web rails mastodon:accounts:create \
  USERNAME=admin EMAIL=admin@your-domain.com ROLE=Owner --confirmed
```

### 6. Setup Domain & SSL

```bash
# Configure Nginx
sudo cp nginx/troupex.conf /etc/nginx/sites-available/troupex
sudo ln -s /etc/nginx/sites-available/troupex /etc/nginx/sites-enabled/
sudo nano /etc/nginx/sites-available/troupex  # Update domain
sudo nginx -t && sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

## ✅ Done!

Your TroupeX instance is now live at `https://your-domain.com`

### Next Steps

1. **Automated Deployments**: Push to main branch triggers deployment
2. **Backups**: Add to cron: `0 3 * * * /home/deploy/troupex/scripts/backup.sh`
3. **Monitoring**: Check DigitalOcean dashboard
4. **Updates**: `git pull && ./scripts/deploy.sh`

### Useful Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Rails console
docker compose exec web rails console

# Clear cache
docker compose exec web rails cache:clear
```

Need help? Check [full deployment guide](DIGITALOCEAN_DEPLOYMENT.md) or [troubleshooting](TROUBLESHOOTING.md).