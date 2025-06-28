#!/bin/bash

echo "Starting file sync for hot reload..."
echo "===================================="
echo ""
echo "This script will sync your JavaScript changes to the running container."
echo "The Vite dev server in the container will automatically rebuild."
echo ""
echo "Watching for changes in app/javascript/..."
echo "Press Ctrl+C to stop"
echo ""

# Function to sync files
sync_files() {
    echo "Syncing files..."
    docker cp app/javascript/. mastodon-web-1:/opt/mastodon/app/javascript/
    echo "Files synced!"
}

# Initial sync
sync_files

# Watch for changes and sync
while true; do
    # Use inotifywait if available, otherwise fall back to simple polling
    if command -v inotifywait &> /dev/null; then
        inotifywait -r -e modify,create,delete app/javascript/
    else
        sleep 2
    fi
    sync_files
done