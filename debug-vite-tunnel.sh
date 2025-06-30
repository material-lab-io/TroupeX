#!/bin/bash

echo "🔍 Debugging Vite + Tunnel setup"
echo ""

# Check local Vite server
echo "1. Testing local Vite server (http://localhost:3036):"
echo "   Root: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/)"
echo "   /packs-dev/: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/packs-dev/)"
echo "   /packs-dev/@vite/client: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/packs-dev/@vite/client)"
echo ""

# Check tunnel
TUNNEL_URL="https://gcc-maximize-reactions-consider.trycloudflare.com"
echo "2. Testing tunnel ($TUNNEL_URL):"
echo "   Root: $(curl -s -o /dev/null -w '%{http_code}' $TUNNEL_URL/)"
echo "   /packs-dev/: $(curl -s -o /dev/null -w '%{http_code}' $TUNNEL_URL/packs-dev/)"
echo "   /packs-dev/@vite/client: $(curl -s -o /dev/null -w '%{http_code}' $TUNNEL_URL/packs-dev/@vite/client)"
echo ""

# Check what the tunnel actually returns
echo "3. Tunnel response for root:"
curl -s $TUNNEL_URL/ | head -5
echo ""

echo "4. Local Vite paths that work:"
curl -s http://localhost:3036/ | grep -o 'href="[^"]*"' | head -5