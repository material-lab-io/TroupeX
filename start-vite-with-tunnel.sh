#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting integrated Vite + Tunnel setup${NC}"

# Kill existing processes
echo -e "${YELLOW}Cleaning up existing processes...${NC}"
pkill -f "cloudflared.*3036" || true
pkill -f "socat.*3037" || true

# Start Vite if not running
cd /home/kanaba/troupex4/mastodon
if ! lsof -i:3036 &> /dev/null; then
    echo -e "${YELLOW}Starting Vite dev server...${NC}"
    yarn dev &
    sleep 5
else
    echo -e "${GREEN}✓ Vite already running${NC}"
fi

# Create a proxy that handles path rewriting
echo -e "${GREEN}Setting up proxy...${NC}"
# Use socat to create a simple proxy that preserves paths
socat TCP-LISTEN:3037,fork,reuseaddr TCP:localhost:3036 &
PROXY_PID=$!

sleep 2

# Create tunnel to the proxy
echo -e "${GREEN}Creating Cloudflare tunnel...${NC}"
cloudflared tunnel --url http://localhost:3037 > ../cloudflare-tunnel-new.log 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel
echo -e "${YELLOW}Waiting for tunnel to establish...${NC}"
sleep 5

# Extract URL
TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare.com' ../cloudflare-tunnel-new.log | head -1)

if [ ! -z "$TUNNEL_URL" ]; then
    echo -e "${GREEN}✅ Success! Vite dev server is accessible via tunnel${NC}"
    echo -e "${GREEN}🌐 Tunnel URL: $TUNNEL_URL${NC}"
    echo -e "${GREEN}📦 Assets URL: $TUNNEL_URL/packs-dev/${NC}"
    echo -e "${GREEN}⚡ Vite Client: $TUNNEL_URL/packs-dev/@vite/client${NC}"
    echo ""
    echo -e "${YELLOW}To integrate with your Mastodon instance:${NC}"
    echo -e "1. Configure your app to use this URL for assets"
    echo -e "2. Update VITE_RUBY_DEV_SERVER_URL=$TUNNEL_URL in your environment"
    echo ""
    echo -e "PIDs: Proxy=$PROXY_PID, Tunnel=$TUNNEL_PID"
    echo -e "Logs: tail -f ../cloudflare-tunnel-new.log"
    
    # Test the connection
    echo -e "${YELLOW}Testing connection...${NC}"
    if curl -s "$TUNNEL_URL/packs-dev/" | grep -q "Vite Ruby"; then
        echo -e "${GREEN}✅ Tunnel is working correctly!${NC}"
    else
        echo -e "${RED}⚠️  Tunnel may not be working properly${NC}"
    fi
else
    echo -e "${RED}❌ Failed to establish tunnel${NC}"
fi