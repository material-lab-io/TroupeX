#!/bin/bash

echo "🌐 Setting up Cloudflare Tunnel for troupex-dev.materiallab.io"
echo "==========================================================="
echo ""

# Create cloudflared directory
mkdir -p ~/.cloudflared

# Create tunnel config
cat > ~/.cloudflared/troupex-dev-config.yml << EOF
tunnel: troupex-dev
credentials-file: /home/kanaba/.cloudflared/troupex-dev.json

ingress:
  - hostname: troupex-dev.materiallab.io
    service: http://localhost:3000
  - service: http_status:404
EOF

echo "✅ Tunnel configuration created!"
echo ""
echo "Now you need to run these commands in your terminal:"
echo ""
echo "1. Authenticate with Cloudflare (if not already done):"
echo "   cloudflared tunnel login"
echo ""
echo "2. Create the tunnel:"
echo "   cloudflared tunnel create troupex-dev"
echo ""
echo "3. Route DNS to the tunnel:"
echo "   cloudflared tunnel route dns troupex-dev troupex-dev.materiallab.io"
echo ""
echo "4. Run the tunnel:"
echo "   cloudflared tunnel run --config ~/.cloudflared/troupex-dev-config.yml troupex-dev"
echo ""
echo "Once the tunnel is running, you can access your Mastodon instance at:"
echo "https://troupex-dev.materiallab.io"
echo ""
echo "The Showcase feature will be available on all user profiles!"