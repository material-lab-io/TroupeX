#!/bin/bash

echo "Testing local Mastodon access..."
echo "================================"
echo ""

# Test 1: Basic health check
echo "1. Health check:"
curl -s http://localhost:3000/health
echo ""
echo ""

# Test 2: Homepage with proper headers
echo "2. Homepage with forwarded headers:"
curl -s -o /dev/null -w "Status: %{http_code}\n" \
  -H "Host: troupex-dev.materiallab.io" \
  -H "X-Forwarded-Proto: https" \
  -H "X-Forwarded-For: 1.2.3.4" \
  http://localhost:3000/
echo ""

# Test 3: Check if we get actual HTML content
echo "3. Getting actual content:"
curl -s \
  -H "Host: troupex-dev.materiallab.io" \
  -H "X-Forwarded-Proto: https" \
  -H "X-Forwarded-For: 1.2.3.4" \
  http://localhost:3000/ | head -n 5 | grep -E "<title>|DOCTYPE"
echo ""

echo "If all tests pass, the issue is with the tunnel configuration, not Mastodon."