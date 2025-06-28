# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Mastodon deployment - a Ruby on Rails social network server with React frontend and Node.js streaming service. The codebase is located in the `/mastodon` subdirectory.

## Common Development Commands

### Running the Application
```bash
# Recommended: Start all development services at once
cd mastodon && bin/dev

# Or run services individually:
# Rails server (from mastodon directory)
cd mastodon && bundle exec rails server

# Vite development server with hot reload
cd mastodon && yarn dev

# Streaming service
cd mastodon && yarn start

# Background job processor
cd mastodon && bundle exec sidekiq
```

### Building and Testing
```bash
# JavaScript/Frontend
cd mastodon && yarn build:development  # Development build
cd mastodon && yarn build:production   # Production build
cd mastodon && yarn test              # Run all tests (lint + typecheck + JS tests)
cd mastodon && yarn test:js           # JavaScript tests only
cd mastodon && yarn typecheck         # TypeScript type checking

# Ruby/Rails
cd mastodon && bundle exec rspec      # Run all RSpec tests
cd mastodon && bundle exec rspec spec/models/user_spec.rb  # Run specific test file
cd mastodon && bundle exec flatware-rspec  # Run tests in parallel

# Linting and Formatting
cd mastodon && yarn lint              # Run all linters
cd mastodon && yarn lint:js           # JavaScript linting
cd mastodon && yarn lint:css          # CSS linting
cd mastodon && yarn fix              # Auto-fix linting issues
cd mastodon && yarn format           # Format code with Prettier
cd mastodon && bundle exec rubocop   # Ruby linting
```

### Docker Commands
```bash
# Build custom images (from root directory)
docker build -t mastodon-custom:latest .
docker build -f streaming/Dockerfile -t mastodon-streaming-custom:latest .

# Run with docker-compose (from mastodon directory)
cd mastodon && docker-compose up -d
cd mastodon && docker-compose logs -f  # View logs
cd mastodon && docker-compose ps       # List containers
```

### Custom Development Scripts
```bash
# Hot reload development for theming/styling (from root directory)
./troupe-dev.sh              # Start dev mode with auto-sync to container
./troupe-hot-reload.sh        # Hot reload for theme development
./hot-reload.sh               # General hot reload script

# Theme and branding deployment
./deploy-troupe-theme.sh      # Deploy custom Troupe theme
./apply_dark_theme_only.sh    # Apply dark theme configuration
./rebuild-troupe.sh           # Full rebuild of Troupe customizations

# Service management
./restart-mastodon.sh         # Restart all Mastodon services
./restart-mastodon-services.sh # Alternative restart script

# Debugging utilities
./debug-500-error.sh          # Debug 500 errors
./debug-status-background.sh  # Debug status background issues
```

### Database and Setup
```bash
# Initial setup (from mastodon directory)
cd mastodon && RAILS_ENV=development bin/setup

# Database commands
cd mastodon && bundle exec rails db:create
cd mastodon && bundle exec rails db:migrate
cd mastodon && bundle exec rails db:seed
cd mastodon && bundle exec rails dev:populate_sample_data  # Add sample data

# Create admin user
cd mastodon && bundle exec rails mastodon:accounts:create USERNAME=admin EMAIL=admin@example.com ROLE=Owner --confirmed
```

## Architecture Overview

### Multi-Service Architecture
- **Web Service**: Rails application serving the UI and API (port 3000)
- **Streaming Service**: Node.js WebSocket server for real-time updates (port 4000)
- **Sidekiq Workers**: Background job processing (multiple queues: default, push, pull, mailers, scheduler, ingress)
- **Dependencies**: PostgreSQL 13+, Redis 6.2+, optional Elasticsearch

### Key Directories
- `/mastodon/app` - Rails application code
  - `/controllers` - HTTP request handlers
  - `/models` - ActiveRecord models
  - `/services` - Business logic
  - `/workers` - Background jobs
  - `/javascript` - React frontend
  - `/serializers` - JSON API formatting
  - `/policies` - Authorization policies (Pundit)
  - `/validators` - Custom validations
- `/mastodon/streaming` - Node.js streaming service
- `/mastodon/spec` - RSpec test suite
- `/mastodon/config` - Rails configuration
- `/mastodon/public` - Static assets and uploads

### Frontend Architecture
- React with Redux for state management
- Vite for build tooling
- Progressive Web App capabilities
- Internationalization support
- Storybook for component development (`yarn storybook`)

### Important Configuration
- Environment configuration: `.env.production`
- Docker orchestration: `docker-compose.yml` (and override files)
- Sidekiq queues: `config/sidekiq.yml`
- Database config: `config/database.yml`
- Custom deployment scripts for Cloudflare tunnels in root directory
- Custom build guide: `mastodon-build-guide.md`

### Custom Deployment Setup
This repository includes custom deployment scripts and configuration:
- Cloudflare tunnel setup for public access
- Custom Docker image builds with specific versions (Ruby 3.4.4, Node.js 22, libvips 8.17.0, ffmpeg 7.1)
- Hot reload development workflow for container-based development
- Troupe theme customizations and branding assets
- Custom systemd service management scripts

## Development Considerations

### When Adding Features
1. Check existing patterns in similar components/services
2. Follow Rails conventions for backend code
3. Use existing React component patterns for frontend
4. Add tests for new functionality (RSpec for Ruby, Vitest for JS)
5. Run linters before committing

### Background Jobs
Sidekiq queues have specific purposes:
- `default`: General background tasks
- `push`: ActivityPub delivery
- `pull`: Remote content fetching
- `mailers`: Email sending
- `scheduler`: Periodic tasks
- `ingress`: Incoming ActivityPub processing

### API Development
- Controllers use ActiveModel Serializers for JSON responses
- Authorization handled by Pundit policies
- OAuth2 provider for API authentication

## Development Tips
- Use `bin/dev` to start all services efficiently
- For container-based development, use `./troupe-dev.sh` for hot reload
- The project uses hot reload for frontend development
- Run `yarn format` and `bundle exec rubocop` before committing
- Use `bundle exec rails console` for interactive debugging
- Logs are in `log/development.log` for Rails and console output for other services
- When developing themes/styling, changes auto-sync to containers via custom scripts
- Use the debugging scripts for troubleshooting deployment issues