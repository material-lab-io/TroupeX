#!/bin/bash

echo "✅ Testing TroupeX Access..."
echo ""

# Test if server is running
if lsof -i :3000 | grep -q LISTEN; then
    echo "✅ Rails server is running on port 3000"
else
    echo "❌ Rails server is NOT running"
    echo "   Run: ./start-rails-clean.sh"
    exit 1
fi

# Test HTTP access
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/auth/sign_in | grep -q "200"; then
    echo "✅ Login page is accessible via HTTP"
    echo ""
    echo "🌐 Access TroupeX at:"
    echo "   http://localhost:3000/auth/sign_in"
    echo ""
    echo "📱 Features implemented:"
    echo "   ✅ Dark theme"
    echo "   ✅ TroupeX branding with superscript X"
    echo "   ✅ Mobile-first design"
    echo "   ✅ Minimal login page"
    echo ""
    echo "🔐 Test credentials:"
    echo "   Email: admin@localhost"
    echo "   Password: mastodonadmin"
else
    echo "❌ Cannot access login page"
fi

echo ""
echo "⚠️  Remember: Use http:// NOT https://"