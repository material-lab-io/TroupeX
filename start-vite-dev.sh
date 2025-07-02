#!/bin/bash

echo "Starting Vite Development Server for HMR..."
echo "==========================================="
echo ""

cd mastodon

# Start Vite dev server
echo "Starting Vite on http://localhost:3036"
echo "This provides Hot Module Replacement for React components"
echo "Press Ctrl+C to stop"
echo ""

yarn dev