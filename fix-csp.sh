#!/bin/bash

echo "Fixing CSP and WebSocket issues..."
echo ""

# Fix Vite configuration for WebSocket
cd mastodon

# Update the vite config to use port 3035 instead of 3036
sed -i 's/"port": 3036/"port": 3035/g' config/vite.json

# Remove external font imports from SCSS
echo "Removing external font imports..."
find app/javascript/styles -name "*.scss" -exec grep -l "@import.*fonts\." {} \; | while read file; do
    echo "Updating $file"
    sed -i '/@import.*fonts\./d' "$file"
done

# Clear caches
rm -rf tmp/cache/* public/packs-dev/* .vite/manifest* 2>/dev/null

echo ""
echo "✅ CSP fixes applied!"
echo ""
echo "Now restart the server with:"
echo "  cd .. && ./restart-troupex.sh"