#!/bin/bash

# Script to copy renamed assets from temp to Mastodon and generate all icons

echo "=== Copying Renamed Assets to Mastodon ==="
echo ""

TEMP_DIR="/home/kanaba/troupex4/temp"
DEST_DIR="/home/kanaba/troupex4/mastodon/app/javascript/images"

# Check required files exist in temp
echo "Checking for required files in temp directory..."
MISSING_FILES=0

check_file() {
    local filename=$1
    local description=$2
    if [ -f "$TEMP_DIR/$filename" ]; then
        echo "  ✓ Found: $filename ($description)"
    else
        echo "  ✗ Missing: $filename ($description)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
}

check_file "logo.svg" "main logo"
check_file "logo-symbol-icon.svg" "icon version"
check_file "logo-symbol-wordmark.svg" "wordmark version"
check_file "app-icon.svg" "app icon"

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "⚠️  Warning: $MISSING_FILES required files are missing!"
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Create backup
echo ""
echo "Creating backup of existing logos..."
BACKUP_DIR="$DEST_DIR/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing files
for file in logo.svg logo-symbol-icon.svg logo-symbol-wordmark.svg app-icon.svg; do
    if [ -f "$DEST_DIR/$file" ]; then
        cp "$DEST_DIR/$file" "$BACKUP_DIR/"
        echo "  Backed up: $file"
    fi
done

# Copy files from temp to destination
echo ""
echo "Copying assets to Mastodon..."

copy_file() {
    local filename=$1
    if [ -f "$TEMP_DIR/$filename" ]; then
        cp "$TEMP_DIR/$filename" "$DEST_DIR/$filename"
        chmod 644 "$DEST_DIR/$filename"
        chown kanaba:kanaba "$DEST_DIR/$filename"
        echo "  ✓ Copied: $filename"
    else
        echo "  ⚠ Skipped: $filename (not found)"
    fi
}

copy_file "logo.svg"
copy_file "logo-symbol-icon.svg"
copy_file "logo-symbol-wordmark.svg"
copy_file "app-icon.svg"

# Generate all derived assets
echo ""
echo "Generating favicons, app icons, and email assets..."
cd /home/kanaba/troupex4/mastodon

# Run the branding generation task
bundle exec rake branding:generate

echo ""
echo "✅ Branding update complete!"
echo ""
echo "Generated assets:"
echo "  - Favicons in: /app/javascript/icons/"
echo "  - Email images in: /app/javascript/images/mailer/"
echo "  - App icons in various sizes"
echo ""
echo "To apply changes:"
echo "1. Restart Mastodon services"
echo "2. Clear browser cache"
echo ""
echo "Backup saved in: $BACKUP_DIR"

# Clean temp directory
echo ""
read -p "Clean temp directory? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$TEMP_DIR"/*.svg
    echo "Temp directory cleaned."
fi