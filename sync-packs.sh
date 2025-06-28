#!/bin/bash

echo "📋 Syncing packs-dev to packs..."

cd /home/kanaba/troupex4/mastodon

# Copy from packs-dev to packs
rm -rf public/packs/*
cp -r public/packs-dev/* public/packs/

# Get container name
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "⚠️  Could not find web container. Using default name..."
    CONTAINER_NAME="mastodon_web_1"
fi

echo "📦 Syncing to container: $CONTAINER_NAME"

# Sync to container
docker exec $CONTAINER_NAME rm -rf /mastodon/public/packs/*
docker cp public/packs/. $CONTAINER_NAME:/mastodon/public/packs/

# Clear Rails cache
docker exec $CONTAINER_NAME bash -c "rm -rf /mastodon/tmp/cache/assets/*" 2>/dev/null || true

echo "✅ Done! Refresh your browser with Ctrl+Shift+R"