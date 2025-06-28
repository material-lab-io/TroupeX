#!/bin/bash

echo "Debugging status card black background issue..."
echo

echo "1. Checking for any hardcoded black colors in the codebase:"
grep -r "background.*#000\|background.*black\|backgroundColor.*#000\|backgroundColor.*black" app/javascript/styles/ | grep -v "node_modules" | grep -v ".map" | head -20

echo
echo "2. Checking CSS variable definitions:"
grep -r "surface-variant-background-color" app/javascript/styles/ | grep -E "(:|=)" | head -10

echo
echo "3. Checking if theme class is properly set:"
grep -r "theme-mastodon-light" app/javascript/ | grep -v "styles" | head -10

echo
echo "4. Checking troupe-cards.scss for potential issues:"
grep -n "background" app/javascript/styles/mastodon/troupe-cards.scss | head -10

echo
echo "5. Checking for any CSS that might override .status background:"
grep -r "\.status\s*{" app/javascript/styles/ | grep -v "status__" | head -20

echo
echo "Done. Please check if:"
echo "- The browser shows 'theme-mastodon-light' class on the body element"
echo "- The computed styles for .status show the correct CSS variables"
echo "- Any browser extensions might be interfering"