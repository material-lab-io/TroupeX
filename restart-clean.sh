#!/bin/bash

echo "🧹 Complete restart with all fixes..."
echo ""

# Kill ALL related processes
echo "Stopping all services..."
pkill -f "rails" 2>/dev/null
pkill -f "puma" 2>/dev/null
pkill -f "vite" 2>/dev/null
pkill -f "node.*vite" 2>/dev/null
sleep 3

# Clear everything
echo "Clearing all caches..."
cd mastodon
rm -rf tmp/cache/* public/packs-dev/* .vite/* node_modules/.vite/* 2>/dev/null

# Ensure environment is set
export RAILS_ENV=development

# Start Rails
echo "Starting Rails server..."
bundle exec rails server -b 0.0.0.0 > /tmp/rails.log 2>&1 &
RAILS_PID=$!

# Give Rails time to start
sleep 5

# Start Vite with explicit port
echo "Starting Vite dev server on port 3035..."
yarn vite --port 3035 --host > /tmp/vite.log 2>&1 &
VITE_PID=$!

sleep 5

echo ""
echo "✅ Complete restart done!"
echo ""
echo "🌐 Access at: http://localhost:3000/auth/sign_in"
echo "⚠️  Use http:// NOT https://"
echo ""
echo "Rails PID: $RAILS_PID"
echo "Vite PID: $VITE_PID"
echo ""
echo "Check if working:"
echo "  curl -I http://localhost:3000/auth/sign_in"
echo "  lsof -i :3035  # Should show Vite"