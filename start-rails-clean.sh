#!/bin/bash

echo "Starting TroupeX Rails Server (HTTP only)..."
echo "==========================================="
echo ""

# Kill any existing Rails processes
pkill -f "rails server" 2>/dev/null
sleep 2

cd mastodon

# Start Rails in development mode on HTTP
echo "Starting Rails on http://localhost:3000"
echo ""
echo "IMPORTANT: Use http:// NOT https://"
echo "Access at: http://localhost:3000/auth/sign_in"
echo ""
echo "Press Ctrl+C to stop"
echo ""

bundle exec rails server -b 0.0.0.0 -e development