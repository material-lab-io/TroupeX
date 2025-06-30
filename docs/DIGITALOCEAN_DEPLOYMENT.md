# TroupeX DigitalOcean Deployment Guide

This guide walks you through deploying TroupeX on DigitalOcean with automated CI/CD using GitHub Actions.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [DigitalOcean Setup](#digitalocean-setup)
3. [GitHub Configuration](#github-configuration)
4. [Initial Deployment](#initial-deployment)
5. [Domain and SSL Setup](#domain-and-ssl-setup)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- DigitalOcean account with billing enabled
- GitHub account with the TroupeX repository forked
- Domain name (optional but recommended)
- Basic knowledge of SSH and command line

## DigitalOcean Setup

### 1. Create a Droplet

1. Log in to DigitalOcean
2. Click "Create" → "Droplets"
3. Choose the following configuration:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic
   - **CPU options**: Regular (SSD)
   - **Size**: Minimum 4GB RAM, 2 vCPUs ($24/month)
   - **Region**: Choose closest to your users
   - **VPC**: Default
   - **Authentication**: SSH keys (recommended)
   - **Hostname**: `troupex-production`
   - **Backups**: Enable (recommended)
   - **Monitoring**: Enable

4. Add your SSH key or create a new one
5. Click "Create Droplet"

### 2. Initial Server Setup

Once your droplet is created, SSH into it:

```bash
ssh root@<your-droplet-ip>
```

Run the setup script:

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/material-lab-io/TroupeX/main/scripts/setup-droplet.sh -o setup-droplet.sh
chmod +x setup-droplet.sh
./setup-droplet.sh
```

This script will:
- Update the system
- Install Docker and dependencies
- Create a deploy user
- Configure firewall
- Set up fail2ban
- Configure swap space
- Install Nginx

After the script completes:

```bash
# Set password for deploy user
passwd deploy

# Switch to deploy user
su - deploy

# Clone the repository
git clone https://github.com/material-lab-io/TroupeX.git /home/deploy/troupex
cd /home/deploy/troupex
```

## GitHub Configuration

### 1. Fork the Repository

1. Go to https://github.com/material-lab-io/TroupeX
2. Click "Fork" to create your own copy
3. Clone your fork locally for any customizations

### 2. Configure GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DROPLET_IP` | Your DigitalOcean droplet IP | `167.99.123.45` |
| `DROPLET_USER` | Deployment user | `deploy` |
| `SSH_PRIVATE_KEY` | Private SSH key for droplet access | Copy your private key |
| `KNOWN_HOSTS` | SSH known hosts | Run: `ssh-keyscan <droplet-ip>` |
| `PRODUCTION_ENV` | Base64 encoded .env.production | See below |
| `SITE_URL` | Your production URL | `https://troupex.yourdomain.com` |
| `SLACK_WEBHOOK` | (Optional) Slack webhook for notifications | Slack webhook URL |

### 3. Create Production Environment File

Create your `.env.production` file locally:

```bash
# Copy the sample
cp mastodon/.env.production.sample .env.production

# Generate secrets
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)"
echo "OTP_SECRET=$(openssl rand -hex 64)"

# Edit the file with your configuration
nano .env.production
```

Key variables to set:

```bash
# Federation
LOCAL_DOMAIN=troupex.yourdomain.com
WEB_DOMAIN=troupex.yourdomain.com

# Database
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=<generate-secure-password>

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Email (example with Gmail)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password
SMTP_FROM_ADDRESS=TroupeX <noreply@yourdomain.com>

# Storage (local or S3)
S3_ENABLED=false  # Set to true if using S3

# Security
AUTHORIZED_FETCH=true
DISALLOW_UNAUTHENTICATED_API_ACCESS=false
```

Encode the file for GitHub secrets:

```bash
base64 -w 0 .env.production
```

Copy the output and add it as the `PRODUCTION_ENV` secret in GitHub.

### 4. Generate SSH Key for Deployment

On your local machine:

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "github-actions@troupex" -f ~/.ssh/troupex-deploy

# Add the public key to the droplet
ssh-copy-id -i ~/.ssh/troupex-deploy.pub deploy@<droplet-ip>

# Get the private key for GitHub
cat ~/.ssh/troupex-deploy
```

Copy the private key and add it as the `SSH_PRIVATE_KEY` secret.

## Initial Deployment

### 1. Prepare the Droplet

SSH into your droplet as the deploy user:

```bash
ssh deploy@<droplet-ip>
cd /home/deploy/troupex

# Create necessary directories
mkdir -p mastodon/public/{system,assets,packs}
mkdir -p backups logs

# Copy the production environment file
# (You'll need to create this manually or via secure copy)
nano mastodon/.env.production
```

### 2. Manual First Deployment

For the first deployment, run manually on the droplet:

```bash
# Pull the repository
git pull origin main

# Build and start services
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d db redis

# Wait for database
sleep 30

# Run initial setup
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails db:setup

# Precompile assets
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails assets:precompile

# Start all services
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d

# Create admin user
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails mastodon:accounts:create \
  USERNAME=admin \
  EMAIL=admin@yourdomain.com \
  ROLE=Owner \
  --confirmed
```

### 3. Trigger GitHub Actions Deployment

Once the initial setup is complete, future deployments will be automatic:

1. Push to the `main` branch
2. GitHub Actions will automatically:
   - Run tests
   - Build Docker images
   - Deploy to your droplet

You can also manually trigger a deployment:
1. Go to Actions → Deploy to DigitalOcean
2. Click "Run workflow"
3. Select the branch and environment

## Domain and SSL Setup

### 1. Point Domain to Droplet

In your domain registrar's DNS settings:

1. Create an A record:
   - Host: `@` or `troupex`
   - Value: Your droplet IP
   - TTL: 3600

2. (Optional) Create a CNAME for www:
   - Host: `www`
   - Value: `troupex.yourdomain.com`

### 2. Configure Nginx

On the droplet:

```bash
# Copy the Nginx configuration
sudo cp /home/deploy/troupex/nginx/troupex.conf /etc/nginx/sites-available/troupex
sudo ln -s /etc/nginx/sites-available/troupex /etc/nginx/sites-enabled/

# Update the domain in the config
sudo nano /etc/nginx/sites-available/troupex
# Replace 'your-domain.com' with your actual domain

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 3. Set Up SSL with Let's Encrypt

```bash
# Install SSL certificate
sudo certbot --nginx -d troupex.yourdomain.com -d www.troupex.yourdomain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

### 4. Update Application Configuration

Update your `.env.production` on the droplet:

```bash
cd /home/deploy/troupex
nano mastodon/.env.production

# Update these values:
LOCAL_DOMAIN=troupex.yourdomain.com
WEB_DOMAIN=troupex.yourdomain.com

# Restart services
docker compose -f docker-compose.yml -f docker-compose.production.yml down
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

## Monitoring and Maintenance

### 1. DigitalOcean Monitoring

Enable alerts in DigitalOcean:
1. Go to your droplet → Monitoring
2. Create alerts for:
   - CPU usage > 80%
   - Memory usage > 90%
   - Disk usage > 80%

### 2. Application Health Checks

Check application status:

```bash
# View running containers
docker compose ps

# Check logs
docker compose logs -f web
docker compose logs -f sidekiq

# Check application health
curl https://troupex.yourdomain.com/health
```

### 3. Automated Backups

Set up automated backups:

```bash
# Add to crontab
crontab -e

# Add daily backup at 3 AM
0 3 * * * /home/deploy/troupex/scripts/backup.sh >> /home/deploy/troupex/logs/backup.log 2>&1

# Add weekly full media backup
0 4 * * 0 BACKUP_MEDIA=true /home/deploy/troupex/scripts/backup.sh >> /home/deploy/troupex/logs/backup.log 2>&1
```

### 4. Updates and Maintenance

Regular maintenance tasks:

```bash
# Update system packages (monthly)
sudo apt update && sudo apt upgrade

# Clean up Docker resources (weekly)
docker system prune -a -f

# Check disk usage
df -h

# Monitor logs for errors
grep ERROR /home/deploy/troupex/logs/*.log
```

## Troubleshooting

### Common Issues

#### 1. Deployment Fails

Check GitHub Actions logs:
- Go to Actions tab in GitHub
- Click on the failed workflow
- Check error messages

Common fixes:
- Verify all secrets are set correctly
- Ensure SSH key has proper permissions
- Check if droplet has enough resources

#### 2. Application Won't Start

```bash
# Check container status
docker compose ps

# View detailed logs
docker compose logs web
docker compose logs sidekiq

# Check environment file
docker compose config
```

#### 3. Database Issues

```bash
# Access database
docker compose exec db psql -U mastodon mastodon_production

# Run migrations manually
docker compose run --rm web rails db:migrate

# Check migration status
docker compose run --rm web rails db:migrate:status
```

#### 4. Asset Issues

```bash
# Recompile assets
docker compose run --rm web rails assets:clobber
docker compose run --rm web rails assets:precompile

# Clear cache
docker compose run --rm web rails cache:clear
```

### Getting Help

1. Check logs: `docker compose logs`
2. Review [troubleshooting guide](TROUBLESHOOTING.md)
3. Search [GitHub Issues](https://github.com/material-lab-io/TroupeX/issues)
4. Create a new issue with:
   - Error messages
   - Steps to reproduce
   - Environment details

## Security Best Practices

1. **Regular Updates**
   - Keep system packages updated
   - Update Docker images regularly
   - Monitor security advisories

2. **Access Control**
   - Use SSH keys only
   - Disable root login
   - Use strong passwords
   - Enable 2FA on GitHub and DigitalOcean

3. **Monitoring**
   - Enable DigitalOcean monitoring
   - Set up log aggregation
   - Monitor for suspicious activity

4. **Backups**
   - Test backup restoration
   - Store backups off-site
   - Encrypt sensitive backups

---

For more information, see the main [deployment guide](../DEPLOYMENT.md).