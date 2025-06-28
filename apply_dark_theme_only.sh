#!/bin/bash
set -e

echo "Applying dark theme only configuration..."

# Run the Ruby script to update all users
echo "Running user update script..."
docker exec mastodon_web_1 ruby /mastodon/force_dark_theme.rb

# Restart the web service
echo "Restarting web service..."
docker restart mastodon_web_1

echo "Done! Dark theme is now enforced for all users."
echo ""
echo "Changes made:"
echo "1. Removed light and contrast themes from themes.yml"
echo "2. Set default theme to 'default' (dark) in settings.yml"
echo "3. Updated theme helper to always load dark theme"
echo "4. Removed theme selectors from user and admin settings"
echo "5. Updated all existing users to use dark theme"
echo ""
echo "The theme selector has been removed from the UI and only dark theme will be available."