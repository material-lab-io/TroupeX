#!/bin/bash

echo "Setting up to use existing mastodon-tunnel..."
echo "============================================="
echo ""

# Find the config for mastodon-tunnel
TUNNEL_PID=$(ps aux | grep "cloudflared.*mastodon-tunnel" | grep -v grep | awk '{print $2}')
echo "Found mastodon-tunnel running with PID: $TUNNEL_PID"

# Create a new config for the existing tunnel
cat > ~/.cloudflared/mastodon-tunnel-config.yml << 'EOF'
tunnel: f26253a1-e7e3-46c4-af34-7ff466f6e76d
credentials-file: /home/kanaba/.cloudflared/f26253a1-e7e3-46c4-af34-7ff466f6e76d.json

ingress:
  - hostname: troupex-dev.materiallab.io
    service: http://localhost:3000
    originRequest:
      httpHostHeader: "troupex-dev.materiallab.io"
  - service: http_status:404
EOF

echo ""
echo "Configuration created!"
echo ""
echo "Now you need to:"
echo "1. Stop the current mastodon-tunnel (kill $TUNNEL_PID)"
echo "2. Restart it with the new config:"
echo "   cloudflared tunnel --config ~/.cloudflared/mastodon-tunnel-config.yml run mastodon-tunnel"
echo ""
echo "Or route the domain to the existing tunnel:"
echo "   cloudflared tunnel route dns f26253a1-e7e3-46c4-af34-7ff466f6e76d troupex-dev.materiallab.io"