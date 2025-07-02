#!/bin/bash

echo ""
echo "🚀 TroupeX Development Server"
echo "============================="
echo ""
echo "The server is running at:"
echo ""
echo "  http://localhost:3000/auth/sign_in"
echo ""
echo "⚠️  IMPORTANT: Use http:// NOT https://"
echo ""
echo "If your browser shows an SSL error:"
echo "1. Clear the URL bar completely"
echo "2. Type exactly: http://localhost:3000/auth/sign_in"
echo "3. Press Enter"
echo ""
echo "Test credentials:"
echo "  Email: admin@localhost"
echo "  Password: mastodonadmin"
echo ""

# Try to open in browser
if command -v xdg-open > /dev/null; then
    xdg-open "http://localhost:3000/auth/sign_in" 2>/dev/null
elif command -v open > /dev/null; then
    open "http://localhost:3000/auth/sign_in" 2>/dev/null
else
    echo "Please open your browser manually to the URL above."
fi