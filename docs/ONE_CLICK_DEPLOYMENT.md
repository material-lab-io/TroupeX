# TroupeX One-Click Deployment Guide

This guide provides a complete walkthrough for deploying TroupeX to production with automated CI/CD using GitHub Actions and Cloudflare Tunnels.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Deployment Methods](#deployment-methods)
5. [Configuration](#configuration)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)
8. [Security](#security)
9. [Disaster Recovery](#disaster-recovery)

## Overview

The TroupeX deployment system provides:
- 🚀 **One-click deployment** to DigitalOcean
- 🔄 **Automated CI/CD** with GitHub Actions
- 🌐 **Cloudflare Tunnel** for secure public access
- 🔐 **Secrets management** via GitHub Secrets
- 📦 **Docker-based** containerization
- 🔄 **Automatic backups** and rollback capability
- 📊 **Health monitoring** and notifications

## Prerequisites

### Required Accounts
- [ ] **GitHub account** with repository access
- [ ] **DigitalOcean account** with API access
- [ ] **Cloudflare account** with a domain
- [ ] **SMTP provider** for emails (Gmail, SendGrid, etc.)
- [ ] **S3-compatible storage** (AWS S3, DigitalOcean Spaces, etc.)

### Local Tools
```bash
# Install required tools
brew install git ssh doctl cloudflared

# Or on Ubuntu/Debian
apt-get install git ssh-client
# Install doctl: https://docs.digitalocean.com/reference/doctl/how-to/install/
# Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/
```

## Quick Start

### Method 1: Automated One-Click Deployment

```bash
# Clone the repository
git clone https://github.com/material-lab-io/TroupeX.git
cd TroupeX

# Run one-click deployment
./scripts/one-click-deploy.sh --new-droplet
```

### Method 2: GitHub Actions Deployment

1. Fork the repository
2. Set up GitHub Secrets (see [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md))
3. Push to main branch or manually trigger the workflow

### Method 3: Manual Deployment to Existing Server

```bash
# On your server
curl -sSL https://raw.githubusercontent.com/material-lab-io/TroupeX/main/scripts/setup-digitalocean-droplet.sh | sudo bash

# Deploy application
./scripts/one-click-deploy.sh --existing
```

## Deployment Methods

### 1. New Infrastructure Deployment

Complete setup of new DigitalOcean droplet with all dependencies:

```bash
./scripts/one-click-deploy.sh --new-droplet
```

This will:
- Create a new DigitalOcean droplet
- Install all system dependencies
- Set up Docker and Docker Compose
- Configure firewall and security
- Install Cloudflare tunnel
- Deploy the application

### 2. Existing Infrastructure Deployment

Deploy to an already configured server:

```bash
./scripts/one-click-deploy.sh --existing
```

### 3. GitHub Actions CI/CD

Automatic deployment on push to main branch:

```yaml
# .github/workflows/deploy-with-tunnel.yml
on:
  push:
    branches: [ main ]
```

Manual deployment:
```bash
# Trigger via GitHub UI or API
gh workflow run deploy-with-tunnel.yml
```

## Configuration

### Environment Variables

Create your production environment file:

```bash
# Extract template
./scripts/extract-production-config.sh

# Edit the generated template
nano deployment-config/env.production.template
```

Key variables to configure:

```env
# Domain Configuration
LOCAL_DOMAIN=your-domain.com
WEB_DOMAIN=your-domain.com

# Database
DB_PASS=<generate-secure-password>

# Rails Secrets (generate with: bundle exec rails secret)
SECRET_KEY_BASE=<rails-secret>
OTP_SECRET=<rails-secret>

# Email Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Storage (S3 or Spaces)
S3_ENABLED=true
S3_BUCKET=troupex-media
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
```

### Cloudflare Tunnel Setup

1. **Install Cloudflared**
   ```bash
   # macOS
   brew install cloudflare/cloudflare/cloudflared
   
   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Create Tunnel**
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create troupex-production
   cloudflared tunnel route dns troupex-production your-domain.com
   ```

3. **Configure Tunnel**
   ```yaml
   # ~/.cloudflared/config.yml
   tunnel: <tunnel-id>
   credentials-file: /home/deploy/.cloudflared/<tunnel-id>.json
   
   ingress:
     - hostname: your-domain.com
       service: http://localhost:3000
     - hostname: your-domain.com
       path: /api/v1/streaming/*
       service: http://localhost:4000
     - service: http_status:404
   ```

### GitHub Secrets Configuration

Set up all required secrets in your GitHub repository:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `PRODUCTION_ENV` | Base64 encoded .env.production | `base64 -w 0 .env.production` |
| `SSH_PRIVATE_KEY` | Deployment SSH key | `cat ~/.ssh/troupex_deploy` |
| `DROPLET_IP` | Server IP address | DigitalOcean dashboard |
| `CLOUDFLARE_TUNNEL_TOKEN` | Tunnel credentials | `base64 -w 0 ~/.cloudflared/<id>.json` |

See [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md) for detailed instructions.

## Deployment Workflow

### Pre-deployment Checklist

- [ ] All environment variables configured
- [ ] Database passwords generated
- [ ] SMTP credentials tested
- [ ] S3/Spaces bucket created
- [ ] Cloudflare tunnel created
- [ ] GitHub secrets added
- [ ] SSH keys configured

### Deployment Process

1. **Build Phase**
   - Docker images built
   - Assets compiled
   - Images pushed to registry

2. **Deploy Phase**
   - Backup current deployment
   - Pull new images
   - Run database migrations
   - Start services
   - Configure Cloudflare tunnel

3. **Verification Phase**
   - Health checks
   - Service status
   - Public endpoint tests

4. **Post-deployment**
   - Clear caches
   - Clean old images
   - Send notifications

## Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check logs
docker compose logs -f web
docker compose logs -f sidekiq

# Restart services
docker compose restart

# Check service status
docker compose ps
```

#### Database Connection Errors
```bash
# Test connection
docker compose exec web rails db:migrate:status

# Check PostgreSQL
docker compose exec db psql -U mastodon -d mastodon_production
```

#### Cloudflare Tunnel Issues
```bash
# Check tunnel status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Test tunnel
cloudflared tunnel info <tunnel-name>
```

#### Asset Compilation Errors
```bash
# Recompile assets
docker compose run --rm web rails assets:precompile

# Clear cache
docker compose run --rm web rails tmp:clear
```

### Debug Commands

```bash
# SSH to server
ssh deploy@<droplet-ip>

# Check deployment logs
tail -f ~/troupex/deployments.log

# Monitor resources
./monitor.sh

# View all logs
docker compose logs --tail 100 -f

# Check disk space
df -h

# Check memory
free -h
```

## Maintenance

### Regular Tasks

#### Daily
- Monitor service health
- Check error logs
- Review disk usage

#### Weekly
- Update dependencies
- Review security alerts
- Backup verification

#### Monthly
- Rotate secrets
- Update system packages
- Performance review

### Backup Management

Automatic backups run daily at 3 AM:
```bash
# Manual backup
./backup.sh

# Restore from backup
cd backups/backup_YYYYMMDD_HHMMSS
docker compose down
psql mastodon_production < database.sql
docker compose up -d
```

### Updates and Upgrades

```bash
# Update application
git pull origin main
./deploy.sh

# Update system packages
sudo apt update && sudo apt upgrade

# Update Docker images
docker compose pull
docker compose up -d
```

## Security

### Best Practices

1. **Access Control**
   - Use SSH keys only
   - Disable root login
   - Configure fail2ban

2. **Secrets Management**
   - Rotate secrets quarterly
   - Use strong passwords (25+ chars)
   - Never commit secrets

3. **Network Security**
   - Firewall configured (UFW)
   - Only required ports open
   - Cloudflare tunnel for HTTPS

4. **Monitoring**
   - Set up alerts
   - Review logs regularly
   - Monitor resource usage

### Security Checklist

- [ ] 2FA enabled on all accounts
- [ ] SSH key authentication only
- [ ] Firewall rules configured
- [ ] Fail2ban active
- [ ] Regular security updates
- [ ] Encrypted backups
- [ ] Access logs reviewed

## Disaster Recovery

### Backup Strategy

1. **Database**: Daily automated backups
2. **Media files**: Weekly S3 sync
3. **Configuration**: Version controlled
4. **Secrets**: Securely stored offline

### Recovery Procedures

#### Complete System Failure
```bash
# 1. Create new droplet
./scripts/one-click-deploy.sh --new-droplet

# 2. Restore from backup
scp backup.tar.gz deploy@new-ip:/tmp/
ssh deploy@new-ip
tar -xzf /tmp/backup.tar.gz
./restore.sh
```

#### Database Corruption
```bash
# Stop services
docker compose stop web sidekiq

# Restore database
gunzip < backup.sql.gz | docker compose exec -T db psql -U mastodon

# Start services
docker compose start web sidekiq
```

#### Rollback Deployment
```bash
# GitHub Actions includes automatic rollback
# Manual rollback:
cd /home/deploy/troupex
git checkout <previous-commit>
./deploy.sh
```

### Emergency Contacts

Document your emergency procedures:
- Infrastructure provider support
- Domain registrar support
- Team escalation chain

## Advanced Configuration

### Scaling Options

#### Horizontal Scaling
- Multiple web workers
- Sidekiq concurrency
- Redis clustering
- Database read replicas

#### Performance Tuning
```yaml
# docker-compose.production.yml
services:
  web:
    deploy:
      replicas: 3
    environment:
      - WEB_CONCURRENCY=4
      
  sidekiq:
    command: bundle exec sidekiq -c 50
```

### Monitoring Setup

```bash
# Prometheus + Grafana
docker compose -f docker-compose.monitoring.yml up -d

# Custom alerts
curl -X POST https://api.your-monitoring.com/alert \
  -d "service=troupex&status=down"
```

## Support

- **Documentation**: [TroupeX Docs](https://github.com/material-lab-io/TroupeX/tree/main/docs)
- **Issues**: [GitHub Issues](https://github.com/material-lab-io/TroupeX/issues)
- **Community**: [Discussions](https://github.com/material-lab-io/TroupeX/discussions)

---

Remember: **Always test in staging before production deployment!**