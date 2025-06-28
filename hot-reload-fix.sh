#!/bin/bash

echo "🎬 Troupe Hot Reload Development (Fixed)"
echo "========================================"

cd /home/kanaba/troupex4/mastodon

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get container name
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}❌ Error: Could not find Mastodon web container${NC}"
    echo "Make sure the container is running"
    exit 1
fi

echo -e "${GREEN}✓ Found container: $CONTAINER_NAME${NC}"

# Function to build and sync
build_and_sync() {
    echo -e "${YELLOW}🔨 Building assets...${NC}"
    
    # Build for development (faster and includes source maps)
    yarn build:development
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build failed!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📦 Syncing to container...${NC}"
    
    # Clear old assets and copy new ones
    docker exec $CONTAINER_NAME rm -rf /mastodon/public/packs/*
    docker cp public/packs/. $CONTAINER_NAME:/mastodon/public/packs/
    
    # Clear Rails asset cache
    docker exec $CONTAINER_NAME bash -c "rm -rf /mastodon/tmp/cache/assets/* 2>/dev/null || true"
    
    # Touch restart.txt to trigger Passenger restart (if using Passenger)
    docker exec $CONTAINER_NAME bash -c "touch /mastodon/tmp/restart.txt 2>/dev/null || true"
    
    # Send HUP signal to puma workers to reload (if using Puma)
    docker exec $CONTAINER_NAME bash -c "pkill -HUP -f puma 2>/dev/null || true"
    
    echo -e "${GREEN}✅ Done! Clear browser cache (Ctrl+Shift+R) and refresh.${NC}"
    echo -e "${YELLOW}💡 Tip: Open DevTools and disable cache in Network tab${NC}"
    echo ""
}

# Function to check if files have changed
check_changes() {
    # Create a timestamp file if it doesn't exist
    if [ ! -f .last_build_time ]; then
        touch .last_build_time
    fi
    
    # Find files newer than our timestamp
    find app/javascript/styles app/javascript/images app/javascript/mastodon \
        -type f \( -name "*.scss" -o -name "*.css" -o -name "*.svg" -o -name "*.png" -o -name "*.tsx" -o -name "*.ts" \) \
        -newer .last_build_time 2>/dev/null
}

# Initial build
echo -e "${YELLOW}🚀 Starting initial build...${NC}"
build_and_sync
touch .last_build_time

echo "👀 Watching for changes in:"
echo "   - app/javascript/styles/ (SCSS/CSS files)"
echo "   - app/javascript/images/ (images)"
echo "   - app/javascript/mastodon/ (React components)"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Watch for changes
while true; do
    CHANGED=$(check_changes)
    
    if [ ! -z "$CHANGED" ]; then
        echo -e "${YELLOW}📝 Changes detected:${NC}"
        echo "$CHANGED" | head -5
        
        build_and_sync
        touch .last_build_time
    fi
    
    sleep 1
done