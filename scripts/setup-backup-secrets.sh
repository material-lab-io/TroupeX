#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GitHub Secrets Setup for PostgreSQL Backup ===${NC}"
echo ""
echo "This script will help you add the required secrets to your GitHub repository."
echo "You'll need:"
echo "  - GitHub CLI (gh) installed and authenticated"
echo "  - Your DigitalOcean Spaces credentials"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install it with: brew install gh (macOS) or see https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo -e "${YELLOW}Warning: Could not detect repository. Make sure you're in the repo directory.${NC}"
    read -p "Enter repository (owner/name): " REPO
fi

echo -e "${BLUE}Repository: ${REPO}${NC}"
echo ""

# Function to add secret
add_secret() {
    local name=$1
    local value=$2
    echo -n "Adding secret ${name}... "
    if echo "$value" | gh secret set "$name" -R "$REPO" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Check existing secrets
echo "Checking existing secrets..."
existing_secrets=$(gh secret list -R "$REPO" | awk '{print $1}')

check_secret() {
    local name=$1
    if echo "$existing_secrets" | grep -q "^${name}$"; then
        echo -e "  ${GREEN}✓${NC} ${name}"
        return 0
    else
        echo -e "  ${RED}✗${NC} ${name}"
        return 1
    fi
}

echo ""
echo "Required secrets for backup:"
check_secret "DROPLET_IP" || missing_deploy=1
check_secret "DROPLET_USER" || missing_deploy=1
check_secret "SSH_PRIVATE_KEY" || missing_deploy=1
check_secret "KNOWN_HOSTS" || missing_deploy=1
check_secret "DO_SPACES_ACCESS_KEY" || missing_spaces=1
check_secret "DO_SPACES_SECRET_KEY" || missing_spaces=1

echo ""
echo "Optional secrets:"
check_secret "SLACK_WEBHOOK" || echo "    (for notifications)"

# Add missing secrets
if [ "${missing_spaces:-0}" = "1" ]; then
    echo ""
    echo -e "${YELLOW}Setting up DigitalOcean Spaces credentials${NC}"
    echo "You provided these earlier:"
    echo "  Space: troupex-backup (blr1 region)"
    echo "  Access Key: DO801AJC2ZH34HTM2DYY"
    echo ""
    
    read -p "Do you want to use these credentials? (y/n): " use_provided
    if [ "$use_provided" = "y" ]; then
        add_secret "DO_SPACES_ACCESS_KEY" "DO801AJC2ZH34HTM2DYY"
        add_secret "DO_SPACES_SECRET_KEY" "FoUnIT1iJbh16NTo81AfFQI1USv7yMwbQAMaJFhRI5k"
    else
        read -p "Enter DigitalOcean Spaces Access Key: " access_key
        read -s -p "Enter DigitalOcean Spaces Secret Key: " secret_key
        echo ""
        add_secret "DO_SPACES_ACCESS_KEY" "$access_key"
        add_secret "DO_SPACES_SECRET_KEY" "$secret_key"
    fi
fi

if [ "${missing_deploy:-0}" = "1" ]; then
    echo ""
    echo -e "${RED}Warning: Some deployment secrets are missing${NC}"
    echo "The backup workflow requires SSH access to your droplet."
    echo "Please ensure these secrets are set up correctly."
fi

# Optional Slack webhook
echo ""
read -p "Do you want to set up Slack notifications? (y/n): " setup_slack
if [ "$setup_slack" = "y" ]; then
    read -p "Enter Slack Webhook URL: " slack_webhook
    add_secret "SLACK_WEBHOOK" "$slack_webhook"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Go to: https://github.com/${REPO}/actions/workflows/backup-postgres.yml"
echo "2. Click 'Run workflow' to test the backup"
echo "3. Check the Actions tab for results"
echo ""
echo "The backup will run automatically every day at 3:00 AM IST."
echo ""
echo "For more information, see: docs/postgres-backup-setup.md"