#!/bin/bash

echo "🎬 Troupe Hot Reload with Volume Mounting"
echo "========================================="
echo ""
echo "This script enables hot reload by:"
echo "1. Mounting local directories into the container"
echo "2. Building assets locally and syncing them"
echo "3. Watching for changes and rebuilding automatically"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if override file exists
if [ ! -f docker-compose.override.yml ]; then
    echo -e "${RED}❌ docker-compose.override.yml not found!${NC}"
    echo "Please create it first with volume mounts"
    exit 1
fi

# Skip container restart if already running
if [ "$1" != "--no-restart" ]; then
    echo -e "${YELLOW}📦 Restarting containers with volume mounts...${NC}"
    docker-compose down web
    docker-compose up -d web
    echo -e "${YELLOW}⏳ Waiting for container to be ready...${NC}"
    sleep 10
fi

echo -e "${YELLOW}⏳ Waiting for container to be ready...${NC}"
sleep 10

# Get container name
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "mastodon.*web" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}❌ Could not find web container${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Container ready: $CONTAINER_NAME${NC}"

cd mastodon

# Function to build and clear cache
build_and_clear() {
    echo -e "${YELLOW}🔨 Building assets...${NC}"
    
    # Build for development
    yarn build:development
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build failed!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📋 Copying from packs-dev to packs...${NC}"
    rm -rf public/packs/*
    cp -r public/packs-dev/* public/packs/
    
    echo -e "${YELLOW}🧹 Clearing Rails cache...${NC}"
    docker exec $CONTAINER_NAME bash -c "rm -rf /mastodon/tmp/cache/assets/*"
    
    # Touch restart file for Passenger/Puma
    docker exec $CONTAINER_NAME bash -c "touch /mastodon/tmp/restart.txt"
    
    echo -e "${GREEN}✅ Done! Refresh browser (Ctrl+Shift+R)${NC}"
    echo -e "${BLUE}💡 Tip: Disable cache in DevTools Network tab${NC}"
    echo ""
}

# Initial build
build_and_clear

echo "👀 Watching for changes..."
echo "   Press Ctrl+C to stop"
echo ""

# Watch for changes using inotifywait if available, else fall back to polling
if command -v inotifywait &> /dev/null; then
    echo -e "${GREEN}Using inotifywait for efficient file watching${NC}"
    
    while true; do
        inotifywait -r -e modify,create,delete \
            --include '.*\.(scss|css|tsx|ts|jsx|js|svg|png)$' \
            app/javascript/ 2>/dev/null
        
        echo -e "${YELLOW}📝 Changes detected!${NC}"
        build_and_clear
    done
else
    echo -e "${YELLOW}Using polling (install inotify-tools for better performance)${NC}"
    
    # Create timestamp file
    touch .last_build_time
    
    while true; do
        # Find changed files
        CHANGED=$(find app/javascript -type f \
            \( -name "*.scss" -o -name "*.css" -o -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" -o -name "*.svg" -o -name "*.png" \) \
            -newer .last_build_time 2>/dev/null)
        
        if [ ! -z "$CHANGED" ]; then
            echo -e "${YELLOW}📝 Changes detected:${NC}"
            echo "$CHANGED" | head -5
            
            build_and_clear
            touch .last_build_time
        fi
        
        sleep 1
    done
fi