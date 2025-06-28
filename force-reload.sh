#!/bin/bash

echo "🔄 Force Reload Troupe Assets"
echo "============================="

# Get container name
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ Error: Could not find Mastodon web container"
    exit 1
fi

echo "Container: $CONTAINER_NAME"
echo ""

echo "1️⃣ Clearing Rails cache..."
docker exec $CONTAINER_NAME bash -c "cd /mastodon && RAILS_ENV=production bundle exec rails tmp:cache:clear"

echo "2️⃣ Clearing asset digests..."
docker exec $CONTAINER_NAME bash -c "rm -rf /mastodon/tmp/cache/assets/*"

echo "3️⃣ Precompiling assets..."
docker exec $CONTAINER_NAME bash -c "cd /mastodon && RAILS_ENV=production bundle exec rails assets:precompile"

echo "4️⃣ Restarting web workers..."
docker exec $CONTAINER_NAME bash -c "pkill -HUP -f puma || touch /mastodon/tmp/restart.txt"

echo ""
echo "✅ Done! Please:"
echo "   1. Clear your browser cache (Ctrl+Shift+R)"
echo "   2. Or open an incognito/private window"
echo "   3. Visit https://troupex-dev.materiallab.io"