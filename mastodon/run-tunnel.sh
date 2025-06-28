#!/bin/bash

echo "🚀 Starting Cloudflare Tunnel for troupex-dev.materiallab.io"
echo "=========================================================="
echo ""
echo "✅ Tunnel already exists and DNS is configured!"
echo ""
echo "Starting tunnel..."
echo "Local: http://localhost:3000"
echo "Public: https://troupex-dev.materiallab.io"
echo ""

# Run the tunnel
cloudflared tunnel --config ~/.cloudflared/troupex-dev-config.yml run troupex-dev