#!/bin/bash

echo "🌐 Setting up Cloudflare Tunnel for Mastodon Showcase"
echo "===================================================="
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "📦 Installing cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
fi

echo "🔧 Creating Cloudflare tunnel configuration..."

# Create tunnel config directory
mkdir -p ~/.cloudflared

# Create config file for the tunnel
cat > ~/.cloudflared/troupex-dev-config.yml << EOF
tunnel: troupex-dev
credentials-file: /home/kanaba/.cloudflared/troupex-dev.json

ingress:
  - hostname: troupex-dev.materiallab.io
    service: http://localhost:3000
  - service: http_status:404
EOF

echo ""
echo "📝 Next steps:"
echo ""
echo "1. Authenticate with Cloudflare (if not already done):"
echo "   cloudflared tunnel login"
echo ""
echo "2. Create the tunnel:"
echo "   cloudflared tunnel create troupex-dev"
echo ""
echo "3. Route the tunnel to your domain:"
echo "   cloudflared tunnel route dns troupex-dev troupex-dev.materiallab.io"
echo ""
echo "4. Start the tunnel:"
echo "   cloudflared tunnel run --config ~/.cloudflared/troupex-dev-config.yml troupex-dev"
echo ""
echo "Or use the quick start script: ./start-tunnel.sh"