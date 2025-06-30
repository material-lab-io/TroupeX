#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing Vite tunnel setup${NC}"

# Kill ALL existing tunnels for port 3036
echo -e "${YELLOW}Stopping all existing tunnels...${NC}"
pkill -f "cloudflared.*3036" || true
sleep 2

# Verify Vite is running
if ! lsof -i:3036 &> /dev/null; then
    echo -e "${RED}Vite is not running! Starting it...${NC}"
    cd /home/kanaba/troupex4/mastodon
    yarn dev &
    sleep 5
fi

# Test local Vite
echo -e "${YELLOW}Testing local Vite server...${NC}"
if curl -s http://localhost:3036/packs-dev/@vite/client | grep -q "HMRContext"; then
    echo -e "${GREEN}✓ Vite server is working locally${NC}"
else
    echo -e "${RED}✗ Vite server not responding correctly${NC}"
    exit 1
fi

# Create a new tunnel with explicit path handling
echo -e "${GREEN}Creating new tunnel...${NC}"
cloudflared tunnel --url http://localhost:3036 --no-tls-verify > vite-tunnel-new.log 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel
echo -e "${YELLOW}Waiting for tunnel to establish...${NC}"
sleep 8

# Get the URL
TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare.com' vite-tunnel-new.log | head -1)

if [ ! -z "$TUNNEL_URL" ]; then
    echo -e "${GREEN}✅ Tunnel created: $TUNNEL_URL${NC}"
    
    # Test the tunnel
    echo -e "${YELLOW}Testing tunnel access...${NC}"
    TEST_RESULT=$(curl -s -o /dev/null -w '%{http_code}' "$TUNNEL_URL/packs-dev/@vite/client")
    
    if [ "$TEST_RESULT" = "200" ]; then
        echo -e "${GREEN}✅ SUCCESS! Tunnel is working!${NC}"
        echo ""
        echo -e "${GREEN}Access your Vite dev server at:${NC}"
        echo -e "  Base URL: $TUNNEL_URL"
        echo -e "  Assets: $TUNNEL_URL/packs-dev/"
        echo -e "  Client: $TUNNEL_URL/packs-dev/@vite/client"
        echo ""
        echo -e "${YELLOW}For HMR to work in your app:${NC}"
        echo -e "1. Set environment variable: export VITE_RUBY_HOST=$TUNNEL_URL"
        echo -e "2. Or update your vite.json config"
        echo ""
        echo -e "Tunnel PID: $TUNNEL_PID"
    else
        echo -e "${RED}✗ Tunnel created but not working properly (HTTP $TEST_RESULT)${NC}"
        echo -e "Check logs: tail -f vite-tunnel-new.log"
    fi
else
    echo -e "${RED}✗ Failed to create tunnel${NC}"
fi