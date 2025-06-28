#!/bin/bash

echo "🚀 Starting Mastodon with Showcase feature..."
echo "============================================"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Use the correct docker compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo "📦 Building Docker images with your Showcase feature..."
$COMPOSE_CMD -f docker-compose.dev.yml build

echo ""
echo "🗄️  Setting up database (if needed)..."
$COMPOSE_CMD -f docker-compose.dev.yml run --rm web rails db:create db:migrate

echo ""
echo "🎯 Starting Mastodon services..."
$COMPOSE_CMD -f docker-compose.dev.yml up -d

echo ""
echo "✅ Mastodon is starting up!"
echo ""
echo "📱 Access Mastodon at: http://localhost:3000"
echo ""
echo "🎉 To test the Showcase feature:"
echo "   1. Create an account or login"
echo "   2. Visit any user profile"
echo "   3. Look for the new 'Showcase' tab between 'Featured' and 'Posts'"
echo ""
echo "🛑 To stop: $COMPOSE_CMD -f docker-compose.dev.yml down"
echo ""
echo "📋 To view logs: $COMPOSE_CMD -f docker-compose.dev.yml logs -f"