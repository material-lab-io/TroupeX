#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== TroupeX Production Configuration Extractor ===${NC}"
echo -e "${YELLOW}This script will help you extract and document your production configuration${NC}"
echo ""

# Output directory
OUTPUT_DIR="./deployment-config"
mkdir -p ${OUTPUT_DIR}

# Function to mask sensitive values
mask_value() {
    local value="$1"
    local show_chars=4
    if [ ${#value} -le 8 ]; then
        echo "***"
    else
        echo "${value:0:${show_chars}}...***"
    fi
}

echo -e "${GREEN}Step 1: Extracting Environment Variables${NC}"
echo "Run this script on your production server or copy the .env.production file here"
echo ""

# Create environment template
cat > ${OUTPUT_DIR}/env.production.template << 'EOF'
# This file contains all environment variables needed for TroupeX production deployment
# Copy this to GitHub Secrets as PRODUCTION_ENV (base64 encoded)

# Federation Configuration
LOCAL_DOMAIN=<your-domain.com>
WEB_DOMAIN=<your-domain.com>

# Database Configuration
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=<generate-secure-password>
DB_PORT=5432

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Rails Configuration
RAILS_ENV=production
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=false
RAILS_LOG_TO_STDOUT=enabled

# Secrets (Generate with: docker compose run --rm web bundle exec rails secret)
SECRET_KEY_BASE=<generate-with-rails-secret>
OTP_SECRET=<generate-with-rails-secret>

# Encryption secrets (Generate with: docker compose run --rm web bin/rails db:encryption:init)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<generate-with-encryption-init>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<generate-with-encryption-init>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<generate-with-encryption-init>

# Web Push (Generate with: docker compose run --rm web bundle exec rails mastodon:webpush:generate_vapid_key)
VAPID_PRIVATE_KEY=<generate-with-webpush-command>
VAPID_PUBLIC_KEY=<generate-with-webpush-command>

# Email Configuration (SMTP)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_LOGIN=<your-email@gmail.com>
SMTP_PASSWORD=<your-app-password>
SMTP_FROM_ADDRESS=notifications@<your-domain.com>
SMTP_DOMAIN=<your-domain.com>
SMTP_ENABLE_STARTTLS=auto
SMTP_AUTH_METHOD=plain
SMTP_OPENSSL_VERIFY_MODE=peer

# Storage Configuration (S3-compatible)
S3_ENABLED=true
S3_BUCKET=<your-bucket-name>
S3_REGION=<your-region>
S3_ENDPOINT=<your-s3-endpoint>
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
S3_ALIAS_HOST=<cdn-domain-if-using>

# Optional: DigitalOcean Spaces example
# S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
# S3_BUCKET=troupex-media
# S3_REGION=nyc3

# Streaming API Configuration
STREAMING_API_BASE_URL=wss://<your-domain.com>

# Search Configuration (optional)
ES_ENABLED=false
# ES_HOST=es
# ES_PORT=9200
# ES_USER=elastic
# ES_PASS=<elasticsearch-password>

# Feature Flags
SINGLE_USER_MODE=false
LIMITED_FEDERATION_MODE=false
AUTHORIZED_FETCH=false
WHITELIST_MODE=false

# Security Settings
AUTHORIZED_FETCH=false
IP_RETENTION_PERIOD=31556952
SESSION_RETENTION_PERIOD=31556952

# Reply Fetching Configuration
FETCH_REPLIES_ENABLED=true
FETCH_REPLIES_COOLDOWN_MINUTES=15
FETCH_REPLIES_INITIAL_WAIT_MINUTES=5
FETCH_REPLIES_MAX_GLOBAL=1000
FETCH_REPLIES_MAX_SINGLE=500
FETCH_REPLIES_MAX_PAGES=500

# Custom TroupeX Settings
EXTRA_MEDIA_HOSTS=

# Cloudflare Tunnel ID (will be set by deployment script)
TUNNEL_ID=<cloudflare-tunnel-id>
EOF

echo -e "${GREEN}Step 2: Creating Cloudflare Tunnel Configuration Template${NC}"
cat > ${OUTPUT_DIR}/cloudflare-tunnel-config.yml << 'EOF'
# Cloudflare Tunnel Configuration Template
# This file should be stored as CLOUDFLARE_TUNNEL_CONFIG in GitHub Secrets (base64 encoded)

tunnel: <tunnel-name>
credentials-file: /home/deploy/.cloudflared/<tunnel-id>.json

ingress:
  # Main web application
  - hostname: <your-domain.com>
    service: http://localhost:3000
    originRequest:
      noTLSVerify: false
      connectTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 100
      keepAliveTimeout: 90s
      httpHostHeader: <your-domain.com>
      originServerName: <your-domain.com>
  
  # Streaming API WebSocket
  - hostname: <your-domain.com>
    path: /api/v1/streaming/*
    service: http://localhost:4000
    originRequest:
      noTLSVerify: false
      connectTimeout: 30s
      tcpKeepAlive: 30s
  
  # Health check endpoint
  - hostname: <your-domain.com>
    path: /health
    service: http://localhost:3000
  
  # Catch-all rule
  - service: http_status:404
EOF

echo -e "${GREEN}Step 3: Creating GitHub Secrets Documentation${NC}"
cat > ${OUTPUT_DIR}/github-secrets.md << 'EOF'
# GitHub Secrets Configuration for TroupeX

## Required Secrets

### 1. **PRODUCTION_ENV**
Base64 encoded content of your `.env.production` file.

To encode:
```bash
base64 -w 0 mastodon/.env.production > production_env_base64.txt
```

### 2. **SSH_PRIVATE_KEY**
Your SSH private key for accessing the DigitalOcean droplet.

### 3. **KNOWN_HOSTS**
SSH known hosts entry for your droplet:
```bash
ssh-keyscan -H <droplet-ip> > known_hosts.txt
```

### 4. **DROPLET_IP**
The IP address of your DigitalOcean droplet.

### 5. **DROPLET_USER**
The username for SSH access (usually `deploy` or `root`).

### 6. **SITE_URL**
Your site's URL (e.g., `https://your-domain.com`).

### 7. **CLOUDFLARE_TUNNEL_TOKEN**
The token for your Cloudflare tunnel.

To get this:
```bash
# On your production server
cat ~/.cloudflared/<tunnel-id>.json | base64 -w 0
```

### 8. **CLOUDFLARE_TUNNEL_CONFIG**
Base64 encoded Cloudflare tunnel configuration.

### 9. **DOCKER_REGISTRY_TOKEN** (Optional)
If using private Docker registry.

### 10. **SLACK_WEBHOOK** (Optional)
For deployment notifications.

### 11. **DO_API_TOKEN** (Optional)
DigitalOcean API token for automated droplet creation.

## Setting Secrets in GitHub

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact name listed above

## Security Notes

- Never commit these values to your repository
- Rotate secrets regularly
- Use strong, unique passwords
- Enable 2FA on all accounts
- Audit secret access regularly
EOF

echo -e "${GREEN}Step 4: Creating Secret Generation Helper Script${NC}"
cat > ${OUTPUT_DIR}/generate-secrets.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== TroupeX Secret Generation Helper ==="
echo ""

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Generate database password
echo "Generating database password..."
echo "DB_PASS=$(generate_password)"
echo ""

# Generate Rails secrets
echo "To generate Rails secrets, run these commands on your server:"
echo "docker compose run --rm web bundle exec rails secret"
echo ""

# Generate encryption secrets
echo "To generate encryption secrets, run:"
echo "docker compose run --rm web bin/rails db:encryption:init"
echo ""

# Generate VAPID keys
echo "To generate Web Push VAPID keys, run:"
echo "docker compose run --rm web bundle exec rails mastodon:webpush:generate_vapid_key"
echo ""

# Cloudflare tunnel
echo "To create a new Cloudflare tunnel:"
echo "1. cloudflared tunnel login"
echo "2. cloudflared tunnel create troupex-production"
echo "3. cloudflared tunnel route dns troupex-production your-domain.com"
echo ""

echo "Remember to:"
echo "- Store all secrets securely"
echo "- Never commit secrets to Git"
echo "- Use GitHub Secrets for CI/CD"
EOF

chmod +x ${OUTPUT_DIR}/generate-secrets.sh

echo -e "${GREEN}Step 5: Creating Current Configuration Extractor${NC}"
cat > ${OUTPUT_DIR}/extract-current-config.sh << 'EOF'
#!/bin/bash
# Run this on your production server to extract current configuration

echo "Extracting current TroupeX configuration..."
echo ""

# Check if we're in the right directory
if [ ! -f "mastodon/.env.production" ]; then
    echo "Error: mastodon/.env.production not found"
    echo "Please run this script from the TroupeX root directory"
    exit 1
fi

# Create output directory
mkdir -p extracted-config

# Copy environment file (without exposing secrets)
echo "Extracting environment variables..."
grep -E '^[A-Z_]+=' mastodon/.env.production | while IFS='=' read -r key value; do
    # Mask sensitive values
    case "$key" in
        *PASSWORD*|*SECRET*|*KEY*|*TOKEN*)
            echo "$key=<REDACTED>" >> extracted-config/env.production.sample
            ;;
        *)
            echo "$key=$value" >> extracted-config/env.production.sample
            ;;
    esac
done

# Extract Cloudflare configuration
echo "Extracting Cloudflare tunnel configuration..."
if [ -f ~/.cloudflared/config.yml ]; then
    cp ~/.cloudflared/config.yml extracted-config/cloudflare-tunnel.yml
    echo "Tunnel config extracted"
else
    echo "No Cloudflare tunnel config found"
fi

# Extract Docker configuration
echo "Extracting Docker configuration..."
if [ -f docker-compose.production.yml ]; then
    cp docker-compose.production.yml extracted-config/
fi

# Get system information
echo "Extracting system information..."
cat > extracted-config/system-info.txt << SYSINFO
OS: $(lsb_release -d | cut -f2)
Docker: $(docker --version)
Docker Compose: $(docker compose version)
Memory: $(free -h | grep Mem | awk '{print $2}')
CPU: $(nproc) cores
Disk: $(df -h / | tail -1 | awk '{print $2}')
SYSINFO

echo ""
echo "Configuration extracted to ./extracted-config/"
echo "Please review and remove any sensitive information before sharing"
EOF

chmod +x ${OUTPUT_DIR}/extract-current-config.sh

echo ""
echo -e "${GREEN}✅ Configuration templates created in ${OUTPUT_DIR}/${NC}"
echo ""
echo "Next steps:"
echo "1. Review and customize the templates in ${OUTPUT_DIR}/"
echo "2. Run extract-current-config.sh on your production server"
echo "3. Generate required secrets using generate-secrets.sh"
echo "4. Add all secrets to GitHub repository settings"
echo "5. Update the deployment workflow with your specific values"
echo ""
echo -e "${YELLOW}Important: Never commit actual secrets to Git!${NC}"