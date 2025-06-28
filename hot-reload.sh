#!/bin/bash

echo "🎬 Troupe Hot Reload Development"
echo "================================"

cd /home/kanaba/troupex4/mastodon

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to build and sync
build_and_sync() {
    echo -e "${YELLOW}🔨 Building assets...${NC}"
    yarn build:development
    
    echo -e "${YELLOW}📋 Copying from packs-dev to packs...${NC}"
    rm -rf public/packs/*
    cp -r public/packs-dev/* public/packs/
    
    echo -e "${YELLOW}📦 Syncing to container...${NC}"
    # Get the correct container name
    CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo -e "${YELLOW}⚠️  Could not find web container. Using default name...${NC}"
        CONTAINER_NAME="mastodon_web_1"
    fi
    
    docker exec $CONTAINER_NAME rm -rf /mastodon/public/packs/*
    docker cp public/packs/. $CONTAINER_NAME:/mastodon/public/packs/
    
    # Clear Rails cache
    docker exec $CONTAINER_NAME bash -c "rm -rf /mastodon/tmp/cache/assets/*" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Done! Refresh your browser.${NC}"
    echo ""
}

# Initial build
build_and_sync

echo "👀 Watching for changes in:"
echo "   - app/javascript/styles/"
echo "   - app/javascript/images/"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Watch for SCSS and image changes
while true; do
    # Wait for file changes (using find with newer flag)
    CHANGED=$(find app/javascript/styles app/javascript/images -name "*.scss" -o -name "*.svg" -o -name "*.png" -newer public/packs 2>/dev/null)
    
    if [ ! -z "$CHANGED" ]; then
        echo -e "${YELLOW}📝 Changes detected:${NC}"
        echo "$CHANGED" | head -5
        build_and_sync
    fi
    
    sleep 2
done