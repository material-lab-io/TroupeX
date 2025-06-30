# TroupeX

<div align="center">
  <img src="mastodon/app/javascript/images/logo_full.svg" alt="TroupeX Logo" width="300"/>
  
  **A Professional Social Network Built on Mastodon**
  
  [![Ruby](https://img.shields.io/badge/Ruby-3.4.4-red.svg)](https://www.ruby-lang.org/)
  [![Rails](https://img.shields.io/badge/Rails-8.0-red.svg)](https://rubyonrails.org/)
  [![Node](https://img.shields.io/badge/Node.js-22-green.svg)](https://nodejs.org/)
  [![React](https://img.shields.io/badge/React-18-blue.svg)](https://reactjs.org/)
  [![License](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](LICENSE)
</div>

## Overview

TroupeX is a customized Mastodon deployment designed for professional networking and community building. It features a LinkedIn-inspired theme, enhanced navigation, direct messaging capabilities, and powerful development tools for easy customization and deployment.

### Key Features

- 🎨 **Professional Theme** - Clean, LinkedIn-style interface with light gray backgrounds
- 💬 **Enhanced Messaging** - Built-in direct messaging system
- 🔧 **Developer-Friendly** - Hot reload, Docker support, and Cloudflare tunnel integration
- 📱 **Progressive Web App** - Full mobile support with offline capabilities
- 🌐 **Federation Ready** - Compatible with the ActivityPub protocol
- 🎯 **Showcase Feature** - Highlight your best content on your profile

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Development](#development)
- [Deployment](#deployment)
- [Custom Features](#custom-features)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/material-lab-io/TroupeX.git
cd TroupeX

# Run the setup script
./setup-dev-deps.sh

# Start all services
cd mastodon && bin/dev

# Access the application
# Web: http://localhost:3000
# Streaming: http://localhost:4000
```

## Prerequisites

### Required Software

- **Ruby**: 3.2.0 - 3.4.x (recommended: 3.4.4)
- **Node.js**: 20+ (recommended: 22)
- **PostgreSQL**: 13+
- **Redis**: 6.2+
- **Yarn**: 4.9.2
- **ImageMagick**: 7+
- **ffmpeg**: 4.4+

### Optional Software

- **Elasticsearch**: 7.x (for full-text search)
- **Docker & Docker Compose**: For containerized deployment
- **Cloudflared**: For tunnel access

## Installation

### Local Development Setup

1. **Install Dependencies**
   ```bash
   # Run the automated setup script
   ./setup-dev-deps.sh
   
   # Or install manually
   sudo apt-get update
   sudo apt-get install -y \
     postgresql postgresql-contrib \
     redis-server \
     imagemagick ffmpeg \
     libpq-dev libxml2-dev libxslt1-dev \
     libidn11-dev libicu-dev libjemalloc-dev
   ```

2. **Setup the Database**
   ```bash
   cd mastodon
   
   # Create and setup the database
   RAILS_ENV=development bin/setup
   
   # Load sample data (optional)
   bundle exec rails dev:populate_sample_data
   ```

3. **Configure Environment**
   ```bash
   # Copy the sample configuration
   cp .env.production.sample .env.development
   
   # Edit .env.development with your settings
   # Key variables to set:
   # - LOCAL_DOMAIN=localhost:3000
   # - REDIS_URL=redis://localhost:6379
   # - DATABASE_URL=postgresql://user:pass@localhost/mastodon_dev
   ```

4. **Start Development Services**
   ```bash
   # Start all services with hot reload
   bin/dev
   
   # Or use Docker
   docker-compose up -d
   ```

### Docker Setup

```bash
# Build custom images
docker build -t mastodon-custom:latest .
docker build -f streaming/Dockerfile -t mastodon-streaming-custom:latest .

# Run with docker-compose
cd mastodon
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Development

### Development Commands

```bash
# Start development server
cd mastodon && bin/dev

# Run tests
yarn test              # All frontend tests
bundle exec rspec      # All backend tests

# Linting
yarn lint              # Frontend linting
bundle exec rubocop    # Backend linting

# Format code
yarn format            # Frontend formatting
bundle exec rubocop -A # Backend formatting
```

### Hot Reload Development

For theme and UI development with hot reload:

```bash
# Start hot reload development
./troupe-hot-reload.sh

# Or for full container sync
./troupe-dev.sh
```

### Creating an Admin User

```bash
cd mastodon
bundle exec rails mastodon:accounts:create \
  USERNAME=admin \
  EMAIL=admin@example.com \
  ROLE=Owner \
  --confirmed
```

## Deployment

### Production Deployment with Docker

1. **Configure Environment**
   ```bash
   cp mastodon/.env.production.sample mastodon/.env.production
   # Edit .env.production with your production settings
   ```

2. **Build and Deploy**
   ```bash
   # Build production images
   docker build --build-arg RAILS_ENV=production -t troupex:latest .
   
   # Run database migrations
   docker-compose run --rm web rails db:migrate
   
   # Precompile assets
   docker-compose run --rm web rails assets:precompile
   
   # Start services
   docker-compose up -d
   ```

### Cloudflare Tunnel Setup

For public access via Cloudflare tunnels:

```bash
# Setup Vite tunnel for development
./setup-vite-tunnel.sh

# Configure tunnel for production
./configure-vite-tunnel.sh
```

Default domain: `troupex-dev.materiallab.io`

## Custom Features

### Showcase Tab
Display featured posts on your profile at `/@username/showcase`

### Professional Theme
- LinkedIn-inspired design
- Light gray backgrounds (#f3f2ef)
- Clean navigation with profile integration

### Enhanced Navigation
- Custom navigation panel with user profile
- Responsive design for mobile and desktop
- Settings navigation improvements

### Direct Messaging
Built-in messaging system for private conversations

## Architecture

TroupeX follows Mastodon's multi-service architecture:

- **Web Service** (Rails): Main application server
- **Streaming Service** (Node.js): Real-time WebSocket updates  
- **Sidekiq Workers**: Background job processing
- **PostgreSQL**: Primary database
- **Redis**: Cache and job queue
- **Vite**: Frontend build tool with HMR

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code style and standards
- Development workflow
- Testing requirements
- Pull request process

## Security

For security vulnerabilities, please email security@materiallab.io instead of using the issue tracker.

## License

TroupeX is licensed under the GNU Affero General Public License v3.0. See [LICENSE](LICENSE) for the full license text.

---

<div align="center">
  Built with ❤️ by the Material Lab team
  
  [Website](https://materiallab.io) • [Documentation](docs/) • [Support](https://github.com/material-lab-io/TroupeX/issues)
</div>