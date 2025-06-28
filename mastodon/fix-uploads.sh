#!/bin/bash

echo "Fixing Mastodon upload permissions..."
echo "====================================="
echo ""

# Create the directories if they don't exist
mkdir -p ./public/system/media_attachments
mkdir -p ./public/system/cache
mkdir -p ./public/system/accounts

echo "Please run the following command with sudo to fix permissions:"
echo ""
echo "sudo chown -R 991:991 ./public/system/"
echo ""
echo "Where 991 is the UID/GID of the mastodon user in the container."
echo ""
echo "Alternatively, you can make the directories world-writable (less secure):"
echo "chmod -R 777 ./public/system/"
echo ""
echo "After fixing permissions, try uploading an image again."