#!/bin/bash

echo "🚀 Starting Cloudflare Tunnel to troupex-dev.materiallab.io"
echo "=========================================================="
echo ""

# Check if tunnel exists
if cloudflared tunnel list | grep -q "troupex-dev"; then
    echo "✅ Tunnel 'troupex-dev' exists"
else
    echo "❌ Tunnel 'troupex-dev' not found. Creating it..."
    cloudflared tunnel create troupex-dev
    echo "🔗 Routing DNS..."
    cloudflared tunnel route dns troupex-dev troupex-dev.materiallab.io
fi

echo ""
echo "🌐 Starting tunnel..."
echo "   Local: http://localhost:3000"
echo "   Public: https://troupex-dev.materiallab.io"
echo ""

# Run the tunnel
cloudflared tunnel run --config ~/.cloudflared/troupex-dev-config.yml troupex-dev