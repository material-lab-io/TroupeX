#!/bin/bash

echo "To fix image upload issues, run this command:"
echo ""
echo "sudo chown -R $USER:$USER ./public/system/"
echo ""
echo "This will fix the permissions so Mastodon can write uploaded files."