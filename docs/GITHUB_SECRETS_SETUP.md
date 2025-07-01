# GitHub Secrets Setup for TroupeX CI/CD

This guide explains how to set up all required GitHub secrets for automated TroupeX deployment.

## Required Secrets Checklist

### 🔐 Essential Secrets

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `PRODUCTION_ENV` | Base64 encoded `.env.production` file | See [Environment Variables](#environment-variables) section |
| `SSH_PRIVATE_KEY` | SSH key for droplet access | See [SSH Setup](#ssh-setup) section |
| `KNOWN_HOSTS` | SSH known hosts for droplet | `ssh-keyscan -H <droplet-ip>` |
| `DROPLET_IP` | Your DigitalOcean droplet IP | From DigitalOcean dashboard |
| `DROPLET_USER` | SSH username (usually `deploy`) | Default: `deploy` |
| `SITE_URL` | Your production URL | `https://your-domain.com` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare tunnel credentials | See [Cloudflare Setup](#cloudflare-setup) section |
| `CLOUDFLARE_TUNNEL_CONFIG` | Tunnel configuration (base64) | See [Cloudflare Setup](#cloudflare-setup) section |

### 🔔 Optional Secrets

| Secret Name | Description | Purpose |
|-------------|-------------|---------|
| `SLACK_WEBHOOK` | Slack webhook URL | Deployment notifications |
| `DO_API_TOKEN` | DigitalOcean API token | Automated infrastructure |
| `DOCKER_REGISTRY_TOKEN` | GitHub Container Registry token | Private images |

## Environment Variables

### 1. Create your `.env.production` file

```bash
# Copy the template
cp mastodon/.env.production.sample mastodon/.env.production

# Edit with your values
nano mastodon/.env.production
```

### 2. Required environment variables

```env
# Core Configuration
LOCAL_DOMAIN=your-domain.com
WEB_DOMAIN=your-domain.com

# Database
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=<generate-secure-password>

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Rails Secrets (generate with: bundle exec rails secret)
SECRET_KEY_BASE=<rails-secret>
OTP_SECRET=<rails-secret>

# Encryption (generate with: bin/rails db:encryption:init)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<key>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<salt>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<key>

# Web Push (generate with: rails mastodon:webpush:generate_vapid_key)
VAPID_PRIVATE_KEY=<private-key>
VAPID_PUBLIC_KEY=<public-key>

# Email
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_ADDRESS=notifications@your-domain.com

# Storage (S3 or DigitalOcean Spaces)
S3_ENABLED=true
S3_BUCKET=troupex-media
S3_REGION=nyc3
S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
```

### 3. Encode for GitHub Secrets

```bash
# Encode the file
base64 -w 0 mastodon/.env.production > production_env_base64.txt

# Copy the content and add to GitHub Secrets as PRODUCTION_ENV
cat production_env_base64.txt
```

## SSH Setup

### 1. Generate SSH key pair (if needed)

```bash
# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/troupex_deploy -C "github-actions@troupex"

# Add public key to droplet
ssh-copy-id -i ~/.ssh/troupex_deploy.pub deploy@<droplet-ip>
```

### 2. Add to GitHub Secrets

```bash
# Copy private key
cat ~/.ssh/troupex_deploy

# Add as SSH_PRIVATE_KEY secret
```

### 3. Get known hosts

```bash
# Scan droplet
ssh-keyscan -H <droplet-ip> > known_hosts.txt

# Copy content
cat known_hosts.txt

# Add as KNOWN_HOSTS secret
```

## Cloudflare Setup

### 1. Create Cloudflare tunnel

```bash
# On your local machine or server
cloudflared tunnel login
cloudflared tunnel create troupex-production

# This creates ~/.cloudflared/<tunnel-id>.json
```

### 2. Configure DNS

```bash
# Route your domain to the tunnel
cloudflared tunnel route dns troupex-production your-domain.com
```

### 3. Create tunnel configuration

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /home/deploy/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: your-domain.com
    service: http://localhost:3000
    originRequest:
      noTLSVerify: false
      connectTimeout: 30s
  
  - hostname: your-domain.com
    path: /api/v1/streaming/*
    service: http://localhost:4000
  
  - service: http_status:404
```

### 4. Add to GitHub Secrets

```bash
# Encode tunnel credentials
cat ~/.cloudflared/<tunnel-id>.json | base64 -w 0 > tunnel_token.txt

# Add as CLOUDFLARE_TUNNEL_TOKEN

# Encode tunnel config
cat ~/.cloudflared/config.yml | base64 -w 0 > tunnel_config.txt

# Add as CLOUDFLARE_TUNNEL_CONFIG
```

## Adding Secrets to GitHub

1. Go to your repository: `https://github.com/material-lab-io/TroupeX`
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:
   - **Name**: Use exact names from the table above
   - **Value**: Paste the secret value
5. Click **Add secret**

## Verifying Your Setup

Run this checklist to ensure everything is configured:

- [ ] All required secrets are added to GitHub
- [ ] SSH connection works: `ssh deploy@<droplet-ip>`
- [ ] Environment file has all required variables
- [ ] Cloudflare tunnel credentials are valid
- [ ] Database passwords are strong and unique
- [ ] Email configuration is tested
- [ ] S3/Spaces credentials are correct

## Security Best Practices

1. **Rotate secrets regularly** (every 90 days)
2. **Use strong passwords** (25+ characters)
3. **Enable 2FA** on all accounts:
   - GitHub
   - DigitalOcean
   - Cloudflare
   - Email provider
4. **Audit access logs** monthly
5. **Never commit secrets** to Git
6. **Use separate credentials** for production

## Troubleshooting

### SSH Connection Fails
```bash
# Test connection
ssh -v deploy@<droplet-ip>

# Check key permissions
chmod 600 ~/.ssh/troupex_deploy
```

### Environment Variables Missing
```bash
# Validate base64 encoding
echo $PRODUCTION_ENV | base64 -d

# Check for special characters
cat .env.production | grep -E '[^[:print:]]'
```

### Cloudflare Tunnel Issues
```bash
# Test tunnel locally
cloudflared tunnel run --config config.yml <tunnel-name>

# Check DNS
dig your-domain.com
```

## Next Steps

Once all secrets are configured:

1. Run the deployment workflow
2. Monitor the Actions tab for progress
3. Check deployment logs
4. Verify site accessibility

For automated one-click deployment, see [ONE_CLICK_DEPLOY.md](./ONE_CLICK_DEPLOY.md).