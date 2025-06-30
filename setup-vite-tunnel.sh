#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Cloudflare tunnel for Vite dev server...${NC}"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}cloudflared is not installed. Installing...${NC}"
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
fi

# Kill any existing cloudflared processes for Vite
echo -e "${YELLOW}Stopping any existing Vite tunnels...${NC}"
pkill -f "cloudflared.*3036" || true

# Start the Vite dev server if not already running
cd /home/kanaba/troupex4/mastodon
if ! lsof -i:3036 &> /dev/null; then
    echo -e "${YELLOW}Starting Vite dev server...${NC}"
    yarn dev &
    VITE_PID=$!
    sleep 5  # Give Vite time to start
else
    echo -e "${GREEN}Vite dev server already running on port 3036${NC}"
fi

# Create the tunnel configuration
echo -e "${GREEN}Creating Cloudflare tunnel for Vite assets...${NC}"

# Run cloudflared tunnel with proper configuration
cloudflared tunnel --url http://localhost:3036 \
    --hostname vite-dev.troupex-dev.materiallab.io \
    --origin-server-name localhost \
    --no-tls-verify \
    --http2-origin \
    > cloudflare-vite-tunnel.log 2>&1 &

TUNNEL_PID=$!

# Wait for tunnel to establish
echo -e "${YELLOW}Waiting for tunnel to establish...${NC}"
sleep 5

# Check if tunnel is running
if ps -p $TUNNEL_PID > /dev/null; then
    echo -e "${GREEN}✅ Cloudflare tunnel established!${NC}"
    echo -e "${GREEN}📍 Vite dev server accessible at: https://vite-dev.troupex-dev.materiallab.io${NC}"
    echo -e "${YELLOW}⚡ HMR WebSocket will connect through: wss://vite-dev.troupex-dev.materiallab.io${NC}"
    echo ""
    echo -e "${YELLOW}To use this with your Mastodon instance:${NC}"
    echo -e "1. Update your .env.production or environment to point assets to the tunnel URL"
    echo -e "2. Or configure your nginx/proxy to route /packs-dev/ to the tunnel"
    echo ""
    echo -e "${GREEN}Tunnel PID: $TUNNEL_PID${NC}"
    echo -e "${YELLOW}Logs: tail -f cloudflare-vite-tunnel.log${NC}"
    echo -e "${YELLOW}To stop: kill $TUNNEL_PID${NC}"
else
    echo -e "${RED}❌ Failed to establish tunnel. Check cloudflare-vite-tunnel.log for details.${NC}"
    exit 1
fi