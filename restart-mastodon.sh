#!/bin/bash
# Script to restart Mastodon services to apply CSS changes

echo "Restarting Mastodon services..."
sudo systemctl restart mastodon-web mastodon-streaming mastodon-sidekiq

echo "Services restarted. Please refresh your browser to see the changes."
echo "Note: You may need to clear your browser cache (Ctrl+Shift+R) to see the updated styles."