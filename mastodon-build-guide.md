# Mastodon Custom Build Guide

## Overview
This guide explains how to build custom Docker images for Mastodon instead of using the prebuilt ones.

## Repository Structure
- **Main Dockerfile**: `/Dockerfile` - Builds the main Mastodon application (web, sidekiq workers)
- **Streaming Dockerfile**: `/streaming/Dockerfile` - Builds the Node.js streaming service
- **docker-compose.yml**: Configured to use prebuilt images by default

## Building Custom Images

### 1. Main Mastodon Image
The main Dockerfile uses multi-stage builds:
- Base image: Ruby 3.4.4 on Debian Bookworm
- Includes libvips 8.17.0 (compiled from source)
- Includes ffmpeg 7.1 (compiled from source)
- Node.js 22 for asset compilation

To build:
```bash
docker build -t mastodon-custom:latest .
```

### 2. Streaming Service Image
The streaming service uses Node.js 22:
```bash
docker build -f streaming/Dockerfile -t mastodon-streaming-custom:latest .
```

## Modifying docker-compose.yml

Replace the image references with your custom builds:

```yaml
web:
  build: .
  # image: ghcr.io/mastodon/mastodon:v4.3.8
  # ... rest of configuration

streaming:
  build:
    dockerfile: ./streaming/Dockerfile
    context: .
  # image: ghcr.io/mastodon/mastodon-streaming:v4.3.8
  # ... rest of configuration

sidekiq:
  build: .
  # image: ghcr.io/mastodon/mastodon:v4.3.8
  # ... rest of configuration
```

## Build Arguments
You can customize the build with these arguments:
- `RUBY_VERSION`: Ruby version (default: 3.4.4)
- `NODE_MAJOR_VERSION`: Node.js major version (default: 22)
- `VIPS_VERSION`: libvips version (default: 8.17.0)
- `FFMPEG_VERSION`: ffmpeg version (default: 7.1)
- `UID/GID`: User/group IDs (default: 991)

Example:
```bash
docker build --build-arg RUBY_VERSION=3.4.4 --build-arg NODE_MAJOR_VERSION=22 -t mastodon-custom:latest .
```

## Development Workflow
1. Make your code changes
2. Build the custom images
3. Update docker-compose.yml to use build context instead of prebuilt images
4. Run `docker-compose up` to test your changes

## Required Environment File
Create `.env.production` with your Mastodon configuration before running docker-compose.