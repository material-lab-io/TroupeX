#!/bin/bash

echo "🔄 Force restarting Mastodon web service to apply theme changes..."

# Clear all caches
docker exec mastodon_web_1 bash -c "rm -rf /mastodon/tmp/cache/*"

# Restart the web container
docker-compose restart web

echo "⏳ Waiting for service to come up..."
sleep 10

echo "✅ Done! Please:"
echo "1. Clear your browser cache completely (Ctrl+Shift+Delete)"
echo "2. Make sure you have 'Mastodon (Light)' selected in Preferences > Appearance"
echo "3. Do a hard refresh (Ctrl+Shift+R)"
echo ""
echo "If status cards are still black, try:"
echo "- Opening in an incognito/private window"
echo "- Switching to dark theme, saving, then back to light theme"