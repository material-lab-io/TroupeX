#!/bin/bash

echo "Fixing Mastodon upload permissions for container user..."
echo "======================================================="
echo ""
echo "The Mastodon container runs as UID/GID 991"
echo "Please run this command with sudo:"
echo ""
echo "sudo chown -R 991:991 ./public/system/"
echo ""
echo "This will allow the container to write uploaded files."