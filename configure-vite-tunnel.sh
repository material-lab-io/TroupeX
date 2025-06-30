#!/bin/bash

TUNNEL_URL="$1"

if [ -z "$TUNNEL_URL" ]; then
    echo "Usage: ./configure-vite-tunnel.sh <tunnel-url>"
    echo "Example: ./configure-vite-tunnel.sh https://gcc-maximize-reactions-consider.trycloudflare.com"
    exit 1
fi

echo "Configuring Mastodon to use Vite tunnel: $TUNNEL_URL"

# Update environment for development
cat > /home/kanaba/troupex4/mastodon/.env.development.local << EOF
# Vite dev server tunnel for HMR
VITE_RUBY_DEV_SERVER_URL=$TUNNEL_URL
VITE_RUBY_PUBLIC_OUTPUT_DIR=packs-dev
VITE_RUBY_DEV_SERVER_HOST=$(echo $TUNNEL_URL | sed 's|https://||')
EOF

echo "✅ Configuration saved to .env.development.local"
echo ""
echo "Now you need to:"
echo "1. Restart your Rails server: cd mastodon && bundle exec rails server"
echo "2. Visit https://troupex-dev.materiallab.io"
echo "3. Your UI changes will hot-reload through the tunnel!"
echo ""
echo "Note: The assets will be loaded from $TUNNEL_URL/packs-dev/"