#!/bin/bash

# Script to prepare and rename branding assets before copying to Mastodon

echo "=== Mastodon Branding Asset Preparation ==="
echo ""

# Check if source directory is provided
if [ -z "$1" ]; then
    echo "Usage: ./prepare-branding-assets.sh <source-directory>"
    echo "Example: ./prepare-branding-assets.sh /path/to/your/assets"
    echo ""
    echo "This script will:"
    echo "1. Copy files to ~/troupex4/temp/"
    echo "2. Help you rename them to match Mastodon's expected names"
    echo "3. Then copy to the Mastodon project folder"
    echo ""
    exit 1
fi

SOURCE_DIR="$1"
TEMP_DIR="/home/kanaba/troupex4/temp"
FINAL_DIR="/home/kanaba/troupex4/mastodon/app/javascript/images"

# Required file names for Mastodon
echo "Required Mastodon asset names:"
echo "  - logo.svg              (main logo)"
echo "  - logo-symbol-icon.svg  (square icon version)"
echo "  - logo-symbol-wordmark.svg (text/wordmark version)"
echo "  - app-icon.svg          (app icon for favicons)"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist!"
    exit 1
fi

# Create temp directory
echo "Creating temp directory..."
mkdir -p "$TEMP_DIR"
rm -f "$TEMP_DIR"/*.svg  # Clean any existing SVGs

# List source files
echo ""
echo "Files found in source directory:"
ls -la "$SOURCE_DIR"/*.svg 2>/dev/null || echo "No SVG files found!"
ls -la "$SOURCE_DIR"/*.png 2>/dev/null || echo "No PNG files found!"

echo ""
echo "Copying all image files to temp directory..."
cp "$SOURCE_DIR"/*.svg "$TEMP_DIR"/ 2>/dev/null || echo "No SVG files to copy"
cp "$SOURCE_DIR"/*.png "$TEMP_DIR"/ 2>/dev/null || echo "No PNG files to copy"

echo ""
echo "Files in temp directory:"
ls -la "$TEMP_DIR"

echo ""
echo "=== RENAMING GUIDE ==="
echo ""
echo "Please rename your files in $TEMP_DIR to match these names:"
echo ""
echo "1. logo.svg - Your main full logo (can include icon + text)"
echo "2. logo-symbol-icon.svg - Just the icon/symbol part (square aspect ratio preferred)"
echo "3. logo-symbol-wordmark.svg - Just the text/wordmark part"
echo "4. app-icon.svg - Icon for app/favicon (must be square)"
echo ""
echo "Current files in temp:"
for file in "$TEMP_DIR"/*; do
    if [ -f "$file" ]; then
        basename "$file"
    fi
done

echo ""
echo "You can rename files using:"
echo "  mv $TEMP_DIR/old-name.svg $TEMP_DIR/new-name.svg"
echo ""
echo "Once renamed correctly, run:"
echo "  ./copy-renamed-assets.sh"
echo ""