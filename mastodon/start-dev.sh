#!/bin/bash

echo "Starting Mastodon development with hot reload..."
echo "============================================="
echo ""
echo "This will run Mastodon with your local code mounted."
echo "Changes to JavaScript/TypeScript files will hot reload automatically!"
echo ""

# Stop existing containers
docker compose -f docker-compose.dev.yml down

# Start just the database and Redis
docker compose -f docker-compose.dev.yml up -d db redis

# Wait for services to be ready
echo "Waiting for database and Redis..."
sleep 5

# Run the web container with mounted volumes for hot reload
docker run -it --rm \
  --name mastodon-dev \
  --network mastodon_internal_network \
  --network mastodon_external_network \
  -p 3000:3000 \
  -p 4036:4036 \
  --env-file .env.production \
  -e RAILS_ENV=production \
  -e NODE_ENV=development \
  -v $(pwd)/app/javascript:/opt/mastodon/app/javascript:cached \
  -v $(pwd)/app/views:/opt/mastodon/app/views:cached \
  -v $(pwd)/app/styles:/opt/mastodon/app/styles:cached \
  -v $(pwd)/public/system:/opt/mastodon/public/system \
  mastodon-web:latest \
  bash -c "rm -f tmp/pids/server.pid && bin/dev"