#!/bin/bash

echo "🚀 Starting Mastodon with Showcase feature and Cloudflare Tunnel"
echo "=============================================================="
echo ""

# Use the correct docker compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# Start Mastodon
echo "📦 Building and starting Mastodon..."
$COMPOSE_CMD -f docker-compose.dev.yml build
$COMPOSE_CMD -f docker-compose.dev.yml up -d

# Wait for Mastodon to be ready
echo ""
echo "⏳ Waiting for Mastodon to start..."
sleep 10

# Check if services are running
if $COMPOSE_CMD -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo "✅ Mastodon services are running!"
else
    echo "❌ Mastodon services failed to start. Check logs with:"
    echo "   $COMPOSE_CMD -f docker-compose.dev.yml logs"
    exit 1
fi

# Setup database if needed
echo ""
echo "🗄️  Ensuring database is set up..."
$COMPOSE_CMD -f docker-compose.dev.yml exec -T web rails db:create 2>/dev/null || true
$COMPOSE_CMD -f docker-compose.dev.yml exec -T web rails db:migrate

# Setup and start Cloudflare tunnel
echo ""
echo "🌐 Setting up Cloudflare tunnel..."

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
fi

# Create tunnel config
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/troupex-dev-config.yml << EOF
tunnel: troupex-dev
credentials-file: /home/kanaba/.cloudflared/troupex-dev.json

ingress:
  - hostname: troupex-dev.materiallab.io
    service: http://localhost:3000
  - service: http_status:404
EOF

echo ""
echo "📋 IMPORTANT: Run these commands in a separate terminal:"
echo ""
echo "1. If you haven't authenticated with Cloudflare yet:"
echo "   cloudflared tunnel login"
echo ""
echo "2. Create and start the tunnel:"
echo "   cloudflared tunnel create troupex-dev"
echo "   cloudflared tunnel route dns troupex-dev troupex-dev.materiallab.io"
echo "   cloudflared tunnel run --config ~/.cloudflared/troupex-dev-config.yml troupex-dev"
echo ""
echo "🎉 Once the tunnel is running, access Mastodon at:"
echo "   https://troupex-dev.materiallab.io"
echo ""
echo "🎯 To test the Showcase feature:"
echo "   1. Create an account or login"
echo "   2. Visit any user profile"  
echo "   3. Click the 'Showcase' tab (between 'Featured' and 'Posts')"
echo ""
echo "🛑 To stop everything:"
echo "   - Stop the tunnel: Ctrl+C in the tunnel terminal"
echo "   - Stop Mastodon: $COMPOSE_CMD -f docker-compose.dev.yml down"