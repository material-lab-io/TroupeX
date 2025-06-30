#!/bin/bash

# Simple script to expose Vite dev server through Cloudflare tunnel
# This allows HMR to work through the public URL

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Vite dev server tunnel for HMR${NC}"

# Start Vite if not running
cd /home/kanaba/troupex4/mastodon
if ! lsof -i:3036 &> /dev/null; then
    echo -e "${YELLOW}Starting Vite dev server...${NC}"
    yarn dev &
    sleep 5
else
    echo -e "${GREEN}✓ Vite already running on port 3036${NC}"
fi

# Create a simple tunnel directly to Vite
echo -e "${GREEN}Creating tunnel to Vite dev server...${NC}"

# Option 1: Quick tunnel (no domain required)
echo -e "${YELLOW}Starting quick tunnel (generates random URL)...${NC}"
cloudflared tunnel --url http://localhost:3036 2>&1 | tee cloudflare-vite.log &
TUNNEL_PID=$!

# Wait and extract the URL
sleep 5
TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare.com' cloudflare-vite.log | head -1)

if [ ! -z "$TUNNEL_URL" ]; then
    echo -e "${GREEN}✅ Vite tunnel established!${NC}"
    echo -e "${GREEN}🌐 Vite Dev Server URL: $TUNNEL_URL${NC}"
    echo ""
    echo -e "${YELLOW}To use with your Mastodon instance:${NC}"
    echo -e "1. Update your browser to load assets from: $TUNNEL_URL/packs-dev/"
    echo -e "2. Or configure your app to use this as CDN_HOST for development"
    echo ""
    echo -e "Tunnel PID: $TUNNEL_PID"
    echo -e "To stop: kill $TUNNEL_PID"
else
    echo -e "${RED}Failed to establish tunnel${NC}"
fi