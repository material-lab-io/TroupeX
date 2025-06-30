#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Vite HMR with Cloudflare Tunnel${NC}"

# Get the tunnel URL from argument or use the existing one
TUNNEL_URL="${1:-https://sick-tex-yards-latter.trycloudflare.com}"

echo -e "${YELLOW}Using tunnel URL: $TUNNEL_URL${NC}"

# Create environment file for Rails
cat > /home/kanaba/troupex4/mastodon/.env.development.local << EOF
# Vite dev server configuration for HMR through tunnel
VITE_DEV_SERVER_PUBLIC=$(echo $TUNNEL_URL | sed 's|https://||')
VITE_RUBY_HOST=$TUNNEL_URL
VITE_RUBY_HTTPS=false
VITE_RUBY_DEV_SERVER_CONNECT_TIMEOUT=120
EOF

echo -e "${GREEN}✅ Created .env.development.local${NC}"

# Update the running Rails app to use the tunnel
echo -e "${YELLOW}Configuration complete!${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Restart your Rails server to pick up the new environment:"
echo -e "   ${YELLOW}cd mastodon && bundle exec rails server${NC}"
echo ""
echo -e "2. Make sure Vite dev server is running:"
echo -e "   ${YELLOW}cd mastodon && yarn dev${NC}"
echo ""
echo -e "3. Visit your app at: ${GREEN}https://troupex-dev.materiallab.io${NC}"
echo ""
echo -e "${GREEN}Your assets will now be served from:${NC}"
echo -e "  $TUNNEL_URL/packs-dev/"
echo ""
echo -e "${YELLOW}⚡ HMR should work automatically!${NC}"
echo ""
echo -e "Test URLs:"
echo -e "  Vite status: $TUNNEL_URL/packs-dev/"
echo -e "  Vite client: $TUNNEL_URL/packs-dev/@vite/client"