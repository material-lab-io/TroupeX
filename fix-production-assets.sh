#!/bin/bash
# Fix production asset compilation issues

echo "🔧 Fixing production assets..."

# Remove old compiled assets
echo "📦 Cleaning old assets..."
docker-compose exec web bundle exec rails assets:clobber RAILS_ENV=production

# Recompile all assets
echo "🏗️  Compiling new assets..."
docker-compose exec web bundle exec rails assets:precompile RAILS_ENV=production

# Clear Rails cache
echo "🧹 Clearing Rails cache..."
docker-compose exec web bundle exec rails tmp:clear RAILS_ENV=production

# Restart web container
echo "🔄 Restarting web container..."
docker-compose restart web

# Wait for container to be ready
echo "⏳ Waiting for web container to start..."
sleep 10

# Check container status
echo "✅ Checking container status..."
docker-compose ps web

echo "🎉 Done! Assets should now be properly compiled."
echo "💡 Don't forget to clear your browser cache!"