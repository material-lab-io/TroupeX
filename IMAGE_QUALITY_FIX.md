# Fix for Blurred Images in Mastodon

## Problem
Images appear blurred because the "small" version is limited to 640x360 pixels (230,400 total pixels), which is very low resolution for modern displays.

## Solution Options

### Option 1: Quick Fix - Increase Small Image Size (Recommended)

Edit `/mastodon/app/models/media_attachment.rb`:

```ruby
# Find this section around line 77-81:
small: {
  pixels: 230_400, # 640x360px
  file_geometry_parser: FastGeometryParser,
  blurhash: BLURHASH_OPTIONS,
}.freeze,

# Change to:
small: {
  pixels: 2_073_600, # 1920x1080px (Full HD)
  file_geometry_parser: FastGeometryParser,
  blurhash: BLURHASH_OPTIONS,
}.freeze,
```

Or for a more moderate increase:
```ruby
small: {
  pixels: 921_600, # 1280x720px (HD)
  file_geometry_parser: FastGeometryParser,
  blurhash: BLURHASH_OPTIONS,
}.freeze,
```

### Option 2: Increase JPEG Quality

Edit the same file, find `GLOBAL_CONVERT_OPTIONS` around line 174:

```ruby
GLOBAL_CONVERT_OPTIONS = {
  all: '-quality 90 +profile "!icc,*" +set date:modify +set date:create +set date:timestamp -define jpeg:dct-method=float',
}.freeze

# Change to:
GLOBAL_CONVERT_OPTIONS = {
  all: '-quality 95 +profile "!icc,*" +set date:modify +set date:create +set date:timestamp -define jpeg:dct-method=float',
}.freeze
```

### Option 3: Use Original Images for Display

Modify the frontend to use original images instead of small versions where appropriate. This requires frontend changes.

## Apply the Fix

1. **Edit the file**:
   ```bash
   nano mastodon/app/models/media_attachment.rb
   ```

2. **Make the change** (Option 1 recommended)

3. **Restart services**:
   ```bash
   docker-compose -f docker-compose.dev.yml restart
   ```

4. **Clear processed images** (optional):
   For existing images to be reprocessed, you'd need to run:
   ```bash
   docker-compose -f docker-compose.dev.yml run --rm web bundle exec rails mastodon:media:reprocess
   ```

## Considerations

- **Storage Impact**: Larger images = more S3 storage costs
  - 640x360 → 1920x1080 = ~9x larger files
  - 640x360 → 1280x720 = ~4x larger files
  
- **Bandwidth Impact**: Larger images = more bandwidth usage

- **Performance Impact**: Minimal, as images are processed asynchronously

## Recommended Settings

For a professional social network like TroupeX:
```ruby
small: {
  pixels: 1_440_000, # 1600x900px - Good balance
  file_geometry_parser: FastGeometryParser,
  blurhash: BLURHASH_OPTIONS,
}.freeze,
```

This provides:
- Clear images on most screens
- Reasonable file sizes
- Good performance