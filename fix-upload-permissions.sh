#!/bin/bash

echo "Fixing upload directory permissions..."
echo "Please run these commands with sudo:"
echo ""
echo "sudo chown -R kanaba:kanaba /home/kanaba/troupex4/mastodon/public/system/"
echo "sudo chmod -R 755 /home/kanaba/troupex4/mastodon/public/system/"
echo ""
echo "This will allow Rails to write uploaded files to the system directory."