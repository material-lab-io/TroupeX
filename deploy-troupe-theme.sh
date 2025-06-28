#!/bin/bash

echo "🎬 Deploying Troupe theme..."

cd /home/kanaba/troupex4/mastodon

# First, let's build the assets in production mode
echo "📦 Building production assets with new theme..."
docker run --rm \
  -v $(pwd):/mastodon \
  -w /mastodon \
  node:22 \
  bash -c "yarn install && yarn build:production"

# Update docker-compose.yml to build from local source
echo "🔧 Updating docker-compose to use local build..."
sed -i 's|# build: .|build: .|' docker-compose.yml
sed -i 's|image: ghcr.io/mastodon/mastodon:v4.3.8|# image: ghcr.io/mastodon/mastodon:v4.3.8|' docker-compose.yml

# Also update streaming service if needed
sed -i '/streaming:/,/^[[:space:]]*[^[:space:]]/ s|# build:|build:|' docker-compose.yml
sed -i '/streaming:/,/^[[:space:]]*[^[:space:]]/ s|image: ghcr.io/mastodon/mastodon-streaming:v4.3.8|# image: ghcr.io/mastodon/mastodon-streaming:v4.3.8|' docker-compose.yml

# Build and restart services
echo "🏗️ Building Docker images with new theme..."
docker-compose build web streaming sidekiq

echo "🔄 Restarting services..."
docker-compose up -d

echo "✅ Troupe theme deployment complete!"
echo "🌐 Clear your browser cache and refresh https://troupex-dev.materiallab.io"