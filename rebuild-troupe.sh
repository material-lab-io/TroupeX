#!/bin/bash

echo "🎬 Rebuilding Troupe with new theme..."

cd /home/kanaba/troupex4/mastodon

# Build the Docker images with our changes
echo "🏗️ Building Docker images..."
docker-compose build --no-cache web streaming sidekiq

# Restart the services
echo "🔄 Restarting services..."
docker-compose down
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 10

# Show status
echo "📊 Service status:"
docker-compose ps

echo ""
echo "✅ Troupe rebuild complete!"
echo "🌐 Please clear your browser cache completely (Ctrl+Shift+Delete)"
echo "   Then visit: https://troupex-dev.materiallab.io"
echo ""
echo "💡 If you still see the old theme, try:"
echo "   1. Open in incognito/private mode"
echo "   2. Hard refresh with Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   3. Clear site data in browser developer tools"