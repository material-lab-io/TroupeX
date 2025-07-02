#!/bin/bash

echo "🔄 Restarting TroupeX with dark theme..."
echo ""

# Kill existing processes
echo "Stopping existing services..."
pkill -f "rails\|puma\|vite" 2>/dev/null
sleep 3

# Clear all caches
echo "Clearing caches..."
cd mastodon
rm -rf tmp/cache/* public/packs-dev/* .vite/manifest* 2>/dev/null

# Set environment
export RAILS_ENV=development

# Start Rails
echo "Starting Rails server..."
nohup bundle exec rails server -b 0.0.0.0 > /tmp/rails.log 2>&1 &
RAILS_PID=$!

# Start Vite
echo "Starting Vite dev server..."
nohup yarn dev > /tmp/vite.log 2>&1 &
VITE_PID=$!

sleep 5

echo ""
echo "✅ TroupeX restarted!"
echo ""
echo "🌐 Access at: http://localhost:3000/auth/sign_in"
echo "⚠️  Use http:// NOT https://"
echo ""
echo "Rails PID: $RAILS_PID"
echo "Vite PID: $VITE_PID"
echo ""
echo "Logs:"
echo "  Rails: tail -f /tmp/rails.log"
echo "  Vite: tail -f /tmp/vite.log"