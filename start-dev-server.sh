#!/bin/bash

echo "Starting TroupeX Development Server..."
echo "======================================="
echo ""

cd mastodon

# Check if .env.development exists
if [ ! -f .env.development ]; then
    echo "Error: .env.development file not found!"
    echo "Please run the setup scripts first."
    exit 1
fi

# Start Rails server
echo "Starting Rails server on http://localhost:3000"
echo "Press Ctrl+C to stop"
echo ""

RAILS_ENV=development bundle exec rails server