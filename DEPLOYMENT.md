# TroupeX Deployment Guide

This guide covers various deployment methods for TroupeX, from development environments to production-ready setups.

## Table of Contents

- [Deployment Options](#deployment-options)
- [Prerequisites](#prerequisites)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Manual Deployment](#manual-deployment)
- [Cloudflare Tunnel Setup](#cloudflare-tunnel-setup)
- [Environment Configuration](#environment-configuration)
- [Post-Deployment](#post-deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Deployment Options

### Quick Comparison

| Method | Best For | Complexity | Scalability |
|--------|----------|------------|-------------|
| Docker Compose | Small to medium deployments | Low | Medium |
| Kubernetes | Large scale deployments | High | High |
| Manual | Development/Custom setups | Medium | Low |
| Cloudflare Tunnel | Public access without static IP | Low | N/A |

## Prerequisites

### System Requirements

**Minimum (1-100 users):**
- 2 CPU cores
- 4GB RAM
- 20GB storage
- Ubuntu 20.04+ or similar

**Recommended (100-1000 users):**
- 4 CPU cores
- 8GB RAM
- 100GB storage
- Dedicated database server

**Production (1000+ users):**
- 8+ CPU cores
- 16GB+ RAM
- 500GB+ SSD storage
- Load balancer
- CDN integration

### Required Software

```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER

# Install other dependencies
sudo apt-get update
sudo apt-get install -y \
  git nginx certbot \
  python3-certbot-nginx \
  postgresql-client \
  redis-tools
```

## Docker Deployment

### 1. Production Docker Setup

```bash
# Clone the repository
git clone https://github.com/material-lab-io/TroupeX.git
cd TroupeX

# Create environment file
cp mastodon/.env.production.sample mastodon/.env.production
```

### 2. Configure Environment

Edit `mastodon/.env.production`:

```bash
# Federation domain
LOCAL_DOMAIN=your-domain.com
WEB_DOMAIN=your-domain.com

# Database
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=your-secure-password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Secrets (generate with: bundle exec rails secret)
SECRET_KEY_BASE=your-secret-key
OTP_SECRET=your-otp-secret

# Email (SMTP)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_ADDRESS=notifications@your-domain.com

# Storage (S3-compatible)
S3_ENABLED=true
S3_BUCKET=troupex-media
S3_REGION=us-east-1
S3_ENDPOINT=https://s3.amazonaws.com
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Optional features
SINGLE_USER_MODE=false
STREAMING_API_BASE_URL=wss://your-domain.com
```

### 3. Build and Deploy

```bash
# Build custom images
docker build -t troupex-web:latest .
docker build -f streaming/Dockerfile -t troupex-streaming:latest .

# Create Docker Compose override
cat > docker-compose.override.yml << EOF
version: '3.8'

services:
  web:
    image: troupex-web:latest
    environment:
      - RAILS_ENV=production
      - NODE_ENV=production
    volumes:
      - ./public/system:/mastodon/public/system
      - ./public/assets:/mastodon/public/assets
      - ./public/packs:/mastodon/public/packs

  streaming:
    image: troupex-streaming:latest
    environment:
      - NODE_ENV=production

  sidekiq:
    image: troupex-web:latest
    environment:
      - RAILS_ENV=production
EOF

# Start services
docker-compose up -d

# Run database migrations
docker-compose run --rm web rails db:migrate

# Precompile assets
docker-compose run --rm web rails assets:precompile

# Create admin user
docker-compose run --rm web rails mastodon:accounts:create \
  USERNAME=admin EMAIL=admin@your-domain.com ROLE=Owner --confirmed
```

### 4. Nginx Configuration

```nginx
# /etc/nginx/sites-available/troupex
server {
    server_name your-domain.com;
    root /path/to/TroupeX/mastodon/public;

    client_max_body_size 99M;

    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_buffering off;
    }

    location /api/v1/streaming {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 5. SSL Certificate

```bash
# Enable SSL with Let's Encrypt
sudo certbot --nginx -d your-domain.com
```

## Kubernetes Deployment

### 1. Prepare Kubernetes Manifests

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: troupex

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: troupex-config
  namespace: troupex
data:
  LOCAL_DOMAIN: "your-domain.com"
  RAILS_ENV: "production"
  NODE_ENV: "production"

---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: troupex-secrets
  namespace: troupex
type: Opaque
stringData:
  SECRET_KEY_BASE: "your-secret-key"
  OTP_SECRET: "your-otp-secret"
  DB_PASS: "your-db-password"

---
# deployment-web.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: troupex-web
  namespace: troupex
spec:
  replicas: 3
  selector:
    matchLabels:
      app: troupex-web
  template:
    metadata:
      labels:
        app: troupex-web
    spec:
      containers:
      - name: web
        image: troupex-web:latest
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: troupex-config
        - secretRef:
            name: troupex-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

### 2. Deploy to Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n troupex

# Run migrations
kubectl exec -it deployment/troupex-web -n troupex -- \
  bundle exec rails db:migrate
```

## Manual Deployment

### 1. System Setup

```bash
# Create user
sudo useradd -m -s /bin/bash mastodon
sudo usermod -aG sudo mastodon

# Install Ruby
sudo apt-get install -y rbenv ruby-build
rbenv install 3.4.4
rbenv global 3.4.4

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Yarn
corepack enable
corepack prepare yarn@4.9.2 --activate
```

### 2. Application Setup

```bash
# Clone and setup
cd /home/mastodon
git clone https://github.com/material-lab-io/TroupeX.git
cd TroupeX/mastodon

# Install dependencies
bundle install --deployment --without development test
yarn install --production

# Setup database
RAILS_ENV=production bundle exec rails db:setup

# Precompile assets
RAILS_ENV=production bundle exec rails assets:precompile
```

### 3. Systemd Services

```ini
# /etc/systemd/system/troupex-web.service
[Unit]
Description=TroupeX Web Service
After=network.target

[Service]
Type=simple
User=mastodon
WorkingDirectory=/home/mastodon/TroupeX/mastodon
Environment="RAILS_ENV=production"
Environment="PORT=3000"
ExecStart=/home/mastodon/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start services
sudo systemctl enable troupex-web troupex-streaming troupex-sidekiq
sudo systemctl start troupex-web troupex-streaming troupex-sidekiq
```

## Cloudflare Tunnel Setup

### 1. Install Cloudflared

```bash
# Download and install
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

### 2. Create Tunnel

```bash
# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create troupex

# Create config file
cat > ~/.cloudflared/config.yml << EOF
url: http://localhost:3000
tunnel: <TUNNEL_ID>
credentials-file: /home/mastodon/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: troupex.your-domain.com
    service: http://localhost:3000
  - hostname: streaming.troupex.your-domain.com
    service: http://localhost:4000
  - service: http_status:404
EOF
```

### 3. Run Tunnel

```bash
# Test tunnel
cloudflared tunnel run troupex

# Install as service
sudo cloudflared service install
sudo systemctl start cloudflared
```

## Environment Configuration

### Production Checklist

- [ ] Generate secure secrets
- [ ] Configure email settings
- [ ] Setup file storage (local/S3)
- [ ] Configure backup strategy
- [ ] Setup monitoring
- [ ] Configure rate limiting
- [ ] Enable HTTPS
- [ ] Setup CDN
- [ ] Configure firewall rules

### Security Hardening

```bash
# Firewall setup
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Fail2ban for brute force protection
sudo apt-get install fail2ban
sudo systemctl enable fail2ban
```

## Post-Deployment

### 1. Health Checks

```bash
# Check service status
docker-compose ps
# or
systemctl status troupex-*

# Test endpoints
curl https://your-domain.com/health
curl https://your-domain.com/api/v1/instance
```

### 2. Initial Configuration

```bash
# Set site settings
docker-compose run --rm web rails c
> Setting.site_title = "TroupeX"
> Setting.site_short_description = "Professional networking"
> Setting.site_contact_email = "admin@your-domain.com"
```

### 3. Enable Features

```bash
# Enable full-text search
docker-compose up -d elasticsearch
docker-compose run --rm web rails chewy:upgrade

# Enable trending hashtags
docker-compose run --rm web rails mastodon:feeds:build
```

## Monitoring

### 1. Application Monitoring

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### 2. Log Management

```bash
# View logs
docker-compose logs -f web
docker-compose logs -f sidekiq

# Log rotation
cat > /etc/logrotate.d/troupex << EOF
/var/log/troupex/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 mastodon mastodon
    sharedscripts
}
EOF
```

## Troubleshooting

### Common Issues

#### 1. Assets Not Loading
```bash
# Recompile assets
docker-compose run --rm web rails assets:precompile
docker-compose restart web
```

#### 2. Database Connection Errors
```bash
# Check database connection
docker-compose run --rm web rails db:migrate:status

# Reset database (WARNING: Data loss)
docker-compose run --rm web rails db:reset
```

#### 3. Redis Connection Issues
```bash
# Test Redis connection
docker-compose run --rm web rails c
> Redis.current.ping
```

#### 4. Streaming Not Working
```bash
# Check streaming logs
docker-compose logs -f streaming

# Verify WebSocket connection
wscat -c wss://your-domain.com/api/v1/streaming
```

### Performance Tuning

```bash
# Increase Sidekiq workers
# In docker-compose.yml
command: bundle exec sidekiq -c 25

# Optimize PostgreSQL
# In postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
```

### Backup and Recovery

```bash
# Backup database
docker-compose run --rm db pg_dump -U mastodon mastodon_production > backup.sql

# Backup media files
tar -czf media-backup.tar.gz public/system

# Restore database
docker-compose run --rm db psql -U mastodon mastodon_production < backup.sql
```

---

For additional support, check the [troubleshooting guide](docs/troubleshooting.md) or open an issue on GitHub.