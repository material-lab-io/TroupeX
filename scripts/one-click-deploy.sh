#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              TroupeX One-Click Deployment Script              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration file
CONFIG_FILE=".troupex-deploy.conf"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -c, --config FILE    Use specific config file (default: .troupex-deploy.conf)"
    echo "  -n, --new-droplet    Create new DigitalOcean droplet"
    echo "  -e, --existing       Deploy to existing droplet"
    echo "  -s, --setup-only     Only set up infrastructure, don't deploy"
    echo "  -d, --deploy-only    Only deploy application (skip setup)"
    echo "  --skip-backup        Skip backup creation"
    echo "  --skip-health-check  Skip health checks"
    echo ""
    echo "Examples:"
    echo "  $0 --new-droplet     # Create new droplet and deploy"
    echo "  $0 --existing        # Deploy to existing droplet"
    echo "  $0 --setup-only      # Only set up infrastructure"
    exit 0
}

# Parse command line arguments
DEPLOY_MODE=""
SKIP_BACKUP=false
SKIP_HEALTH_CHECK=false
SETUP_ONLY=false
DEPLOY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -n|--new-droplet)
            DEPLOY_MODE="new"
            shift
            ;;
        -e|--existing)
            DEPLOY_MODE="existing"
            shift
            ;;
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -d|--deploy-only)
            DEPLOY_ONLY=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-health-check)
            SKIP_HEALTH_CHECK=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    local missing=()
    
    # Check required tools
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v ssh >/dev/null 2>&1 || missing+=("ssh")
    command -v scp >/dev/null 2>&1 || missing+=("scp")
    command -v base64 >/dev/null 2>&1 || missing+=("base64")
    
    if [ "$DEPLOY_MODE" = "new" ]; then
        command -v doctl >/dev/null 2>&1 || missing+=("doctl")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing required tools: ${missing[*]}${NC}"
        echo "Please install missing tools and try again."
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Function to load or create configuration
load_configuration() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}Loading configuration from $CONFIG_FILE${NC}"
        source "$CONFIG_FILE"
    else
        echo -e "${YELLOW}No configuration file found. Creating new configuration...${NC}"
        create_configuration
    fi
}

# Function to create configuration
create_configuration() {
    echo -e "${BLUE}=== TroupeX Deployment Configuration ===${NC}"
    echo ""
    
    read -p "Domain name (e.g., example.com): " DOMAIN
    read -p "Email for notifications: " EMAIL
    read -p "DigitalOcean API token (leave empty if deploying to existing): " DO_API_TOKEN
    read -p "Cloudflare email: " CF_EMAIL
    read -p "Cloudflare API token: " CF_API_TOKEN
    read -p "GitHub repository (default: material-lab-io/TroupeX): " GITHUB_REPO
    GITHUB_REPO=${GITHUB_REPO:-material-lab-io/TroupeX}
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# TroupeX Deployment Configuration
DOMAIN="$DOMAIN"
EMAIL="$EMAIL"
DO_API_TOKEN="$DO_API_TOKEN"
CF_EMAIL="$CF_EMAIL"
CF_API_TOKEN="$CF_API_TOKEN"
GITHUB_REPO="$GITHUB_REPO"
DROPLET_NAME="troupex-${DOMAIN//./-}"
DROPLET_REGION="nyc3"
DROPLET_SIZE="s-2vcpu-4gb"
DROPLET_IMAGE="ubuntu-22-04-x64"
EOF
    
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

# Function to create new droplet
create_droplet() {
    echo -e "${BLUE}Creating new DigitalOcean droplet...${NC}"
    
    # Configure doctl
    doctl auth init -t "$DO_API_TOKEN"
    
    # Generate SSH key if needed
    if [ ! -f ~/.ssh/troupex_deploy ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/troupex_deploy -N "" -C "troupex@$DOMAIN"
    fi
    
    # Add SSH key to DigitalOcean
    KEY_ID=$(doctl compute ssh-key list --format ID,Name --no-header | grep "troupex_deploy" | awk '{print $1}')
    if [ -z "$KEY_ID" ]; then
        KEY_ID=$(doctl compute ssh-key create troupex_deploy --public-key "$(cat ~/.ssh/troupex_deploy.pub)" --format ID --no-header)
    fi
    
    # Create droplet
    echo "Creating droplet: $DROPLET_NAME"
    DROPLET_ID=$(doctl compute droplet create \
        "$DROPLET_NAME" \
        --image "$DROPLET_IMAGE" \
        --size "$DROPLET_SIZE" \
        --region "$DROPLET_REGION" \
        --ssh-keys "$KEY_ID" \
        --enable-monitoring \
        --enable-backups \
        --format ID \
        --no-header \
        --wait)
    
    # Get droplet IP
    DROPLET_IP=$(doctl compute droplet get "$DROPLET_ID" --format PublicIPv4 --no-header)
    
    echo -e "${GREEN}✓ Droplet created: $DROPLET_IP${NC}"
    
    # Update configuration
    echo "DROPLET_IP=\"$DROPLET_IP\"" >> "$CONFIG_FILE"
    echo "DROPLET_ID=\"$DROPLET_ID\"" >> "$CONFIG_FILE"
    
    # Wait for SSH to be ready
    echo "Waiting for SSH to be ready..."
    while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/troupex_deploy root@"$DROPLET_IP" exit 2>/dev/null; do
        echo -n "."
        sleep 5
    done
    echo ""
}

# Function to set up droplet
setup_droplet() {
    echo -e "${BLUE}Setting up droplet infrastructure...${NC}"
    
    # Copy setup script
    scp -o StrictHostKeyChecking=no -i ~/.ssh/troupex_deploy \
        scripts/setup-digitalocean-droplet.sh root@"$DROPLET_IP":/tmp/
    
    # Run setup script
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/troupex_deploy root@"$DROPLET_IP" \
        "bash /tmp/setup-digitalocean-droplet.sh"
    
    echo -e "${GREEN}✓ Droplet infrastructure ready${NC}"
}

# Function to generate secrets
generate_secrets() {
    echo -e "${BLUE}Generating application secrets...${NC}"
    
    # Create temporary directory for secrets
    SECRETS_DIR=$(mktemp -d)
    
    # Generate database password
    DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Create .env.production
    cat > "$SECRETS_DIR/.env.production" << EOF
# TroupeX Production Environment
LOCAL_DOMAIN=$DOMAIN
WEB_DOMAIN=$DOMAIN

# Database
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=$DB_PASS
DB_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Rails
RAILS_ENV=production
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=false
RAILS_LOG_TO_STDOUT=enabled

# Email
SMTP_FROM_ADDRESS=notifications@$DOMAIN
SMTP_DOMAIN=$DOMAIN

# Streaming
STREAMING_API_BASE_URL=wss://$DOMAIN

# Features
SINGLE_USER_MODE=false
LIMITED_FEDERATION_MODE=false
AUTHORIZED_FETCH=false

# Security
IP_RETENTION_PERIOD=31556952
SESSION_RETENTION_PERIOD=31556952

# Reply fetching
FETCH_REPLIES_ENABLED=true
FETCH_REPLIES_COOLDOWN_MINUTES=15
EOF
    
    echo -e "${YELLOW}Note: You'll need to add Rails secrets, VAPID keys, and SMTP settings manually${NC}"
}

# Function to set up Cloudflare
setup_cloudflare() {
    echo -e "${BLUE}Setting up Cloudflare tunnel...${NC}"
    
    # Create tunnel configuration
    TUNNEL_NAME="troupex-${DOMAIN//./-}"
    
    cat > "$SECRETS_DIR/tunnel-config.yml" << EOF
tunnel: $TUNNEL_NAME
credentials-file: /home/deploy/.cloudflared/$TUNNEL_NAME.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:3000
    originRequest:
      noTLSVerify: false
      connectTimeout: 30s
      tcpKeepAlive: 30s
      httpHostHeader: $DOMAIN
      originServerName: $DOMAIN
  
  - hostname: $DOMAIN
    path: /api/v1/streaming/*
    service: http://localhost:4000
  
  - service: http_status:404
EOF
    
    echo -e "${YELLOW}Note: You'll need to create the tunnel manually using cloudflared CLI${NC}"
    echo "Commands to run:"
    echo "  cloudflared tunnel login"
    echo "  cloudflared tunnel create $TUNNEL_NAME"
    echo "  cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN"
}

# Function to deploy application
deploy_application() {
    echo -e "${BLUE}Deploying TroupeX application...${NC}"
    
    # Create deployment package
    DEPLOY_DIR=$(mktemp -d)
    
    # Copy files
    cp "$SECRETS_DIR/.env.production" "$DEPLOY_DIR/"
    cp "$SECRETS_DIR/tunnel-config.yml" "$DEPLOY_DIR/"
    cp docker-compose.production.yml "$DEPLOY_DIR/"
    cp -r scripts "$DEPLOY_DIR/"
    
    # Upload to server
    scp -r -o StrictHostKeyChecking=no -i ~/.ssh/troupex_deploy \
        "$DEPLOY_DIR"/* deploy@"$DROPLET_IP":/home/deploy/troupex/
    
    # Run deployment
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/troupex_deploy deploy@"$DROPLET_IP" << 'ENDSSH'
        cd /home/deploy/troupex
        
        # Clone repository if needed
        if [ ! -d .git ]; then
            git clone https://github.com/material-lab-io/TroupeX.git .
        else
            git pull origin main
        fi
        
        # Move environment file
        mv .env.production mastodon/
        
        # Start deployment
        chmod +x scripts/deploy.sh
        ./scripts/deploy.sh
ENDSSH
    
    echo -e "${GREEN}✓ Application deployed${NC}"
}

# Function to verify deployment
verify_deployment() {
    echo -e "${BLUE}Verifying deployment...${NC}"
    
    # Check local services
    echo "Checking Docker services..."
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/troupex_deploy deploy@"$DROPLET_IP" \
        "cd /home/deploy/troupex && docker compose ps"
    
    # Check public access
    echo "Checking public endpoints..."
    
    # Health check
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Health check passed${NC}"
    else
        echo -e "${YELLOW}⚠ Health check returned: $response${NC}"
    fi
    
    # API check
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/api/v1/instance" || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ API accessible${NC}"
    else
        echo -e "${YELLOW}⚠ API returned: $response${NC}"
    fi
}

# Function to display summary
display_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Deployment Summary                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
    echo ""
    echo "Access your TroupeX instance:"
    echo -e "  URL: ${BLUE}https://$DOMAIN${NC}"
    echo -e "  SSH: ${BLUE}ssh deploy@$DROPLET_IP${NC}"
    echo ""
    echo "Important files:"
    echo "  - Configuration: $CONFIG_FILE"
    echo "  - SSH Key: ~/.ssh/troupex_deploy"
    echo "  - Secrets: $SECRETS_DIR/"
    echo ""
    echo "Next steps:"
    echo "  1. Add missing secrets to .env.production"
    echo "  2. Configure SMTP settings"
    echo "  3. Create admin user"
    echo "  4. Set up backups"
    echo ""
    echo -e "${YELLOW}Security reminder:${NC}"
    echo "  - Store all secrets securely"
    echo "  - Enable 2FA on all accounts"
    echo "  - Review firewall settings"
    echo "  - Set up monitoring"
}

# Main execution
main() {
    echo -e "${BLUE}Starting TroupeX deployment...${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Load configuration
    load_configuration
    
    # Determine deployment mode
    if [ -z "$DEPLOY_MODE" ]; then
        echo "Select deployment mode:"
        echo "  1) Create new DigitalOcean droplet"
        echo "  2) Deploy to existing droplet"
        read -p "Choice (1-2): " choice
        case $choice in
            1) DEPLOY_MODE="new" ;;
            2) DEPLOY_MODE="existing" ;;
            *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
        esac
    fi
    
    # Execute deployment steps
    if [ "$DEPLOY_MODE" = "new" ] && [ "$DEPLOY_ONLY" = false ]; then
        create_droplet
        setup_droplet
    fi
    
    if [ "$SETUP_ONLY" = false ]; then
        generate_secrets
        setup_cloudflare
        deploy_application
        
        if [ "$SKIP_HEALTH_CHECK" = false ]; then
            verify_deployment
        fi
    fi
    
    # Display summary
    display_summary
    
    # Cleanup
    rm -rf "$SECRETS_DIR" "$DEPLOY_DIR" 2>/dev/null || true
}

# Run main function
main