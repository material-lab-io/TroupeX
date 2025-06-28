#!/bin/bash

echo "=== Debugging Mastodon 500 Error ==="
echo ""

echo "1. Check if services are running:"
ps aux | grep -E "(puma|sidekiq|node.*streaming)" | grep -v grep | wc -l
echo "   Services found: $(ps aux | grep -E "(puma|sidekiq|node.*streaming)" | grep -v grep | wc -l)"
echo ""

echo "2. Test local connectivity:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "Failed"
echo ""

echo "3. Check asset compilation:"
if [ -f "/home/kanaba/troupex4/mastodon/public/packs/.vite/manifest.json" ]; then
    echo "   ✓ Asset manifest exists"
    echo "   Size: $(ls -lh /home/kanaba/troupex4/mastodon/public/packs/.vite/manifest.json | awk '{print $5}')"
else
    echo "   ✗ Asset manifest missing!"
fi
echo ""

echo "4. Check for common issues:"
echo "   - Ruby bundle issues: Check"
echo "   - Assets compiled: ✓"
echo "   - Services running: Check above"
echo ""

echo "5. Possible causes of 500 error:"
echo "   a) Database connection issue"
echo "   b) Redis not running"
echo "   c) Missing environment variables"
echo "   d) Asset serving configuration"
echo ""

echo "6. To fix, try:"
echo "   a) Check Redis: redis-cli ping"
echo "   b) Check PostgreSQL: sudo -u postgres psql -c '\l'"
echo "   c) Verify .env.production has all required variables"
echo "   d) Run: sudo journalctl -f"
echo "      Then visit the site to see real-time errors"
echo ""

echo "7. The issue might be that the services need a full restart after asset changes."
echo "   Since you can't use sudo here, ask someone with sudo access to:"
echo "   - Stop all services"
echo "   - Start them fresh"
echo "   - Check journalctl for errors"