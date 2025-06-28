#!/bin/bash

echo "🎬 Starting Troupe UI Development Mode..."

cd /home/kanaba/troupex4/mastodon

# Function to sync assets to container
sync_assets() {
    echo "📦 Syncing assets to container..."
    # Get the correct container name
    CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "⚠️  Could not find web container. Using default name..."
        CONTAINER_NAME="mastodon_web_1"
    fi
    
    # Copy compiled assets to the running container
    docker cp public/packs/. $CONTAINER_NAME:/mastodon/public/packs/
    docker cp public/packs-dev/. $CONTAINER_NAME:/mastodon/public/packs-dev/
    echo "✅ Assets synced to $CONTAINER_NAME!"
}

# Initial sync
sync_assets

echo "🚀 Starting Vite dev server with watch mode..."
echo "📝 Make changes to CSS/JS files and they will auto-sync to the container"
echo ""

# Start Vite in development mode and watch for changes
yarn dev &
VITE_PID=$!

# Watch for changes in the public/packs directories
while true; do
    # Use inotifywait if available, otherwise fallback to polling
    if command -v inotifywait &> /dev/null; then
        inotifywait -r -e modify,create,delete public/packs public/packs-dev 2>/dev/null
    else
        sleep 2
    fi
    
    # Check if files have changed
    if [ -d "public/packs" ] || [ -d "public/packs-dev" ]; then
        sync_assets
        echo "🔄 Refresh your browser to see changes!"
    fi
done

# Cleanup on exit
trap "kill $VITE_PID 2>/dev/null" EXIT