# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is TroupeX, a customized Mastodon deployment - a Ruby on Rails 8.0 social network server with React frontend and Node.js streaming service. The codebase is located in the `/mastodon` subdirectory. This deployment includes custom theming, Docker configurations, and deployment scripts for Cloudflare tunnels.

**Stack Requirements**:
- Ruby: >= 3.2.0, < 3.5.0
- Node.js: 20+
- PostgreSQL: 13+
- Redis: 6.2+
- Optional: Elasticsearch for full-text search

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

### Essential Commands for Task Completion
```bash
# IMPORTANT: Always run these after making code changes
cd mastodon && yarn lint              # Lint JavaScript/TypeScript code
cd mastodon && yarn typecheck         # Check TypeScript types
cd mastodon && bundle exec rubocop   # Lint Ruby code

# Run a single test file
cd mastodon && bundle exec rspec spec/path/to/specific_spec.rb
cd mastodon && yarn test:js path/to/specific.test.js

# Rails console for debugging
cd mastodon && bundle exec rails console

# Check service logs
cd mastodon && tail -f log/development.log  # Rails logs
```

### Building and Testing
```bash
# JavaScript/Frontend
cd mastodon && yarn build:development  # Development build
cd mastodon && yarn build:production   # Production build
cd mastodon && yarn test              # Run all tests (lint + typecheck + JS tests)
cd mastodon && yarn test:js           # JavaScript tests only
cd mastodon && yarn typecheck         # TypeScript type checking
cd mastodon && yarn chromatic         # Visual regression testing with Chromatic

# Ruby/Rails
cd mastodon && bundle exec rspec      # Run all RSpec tests
cd mastodon && bundle exec rspec spec/models/user_spec.rb  # Run specific test file
cd mastodon && bundle exec rspec spec/controllers  # Test controllers only
cd mastodon && bundle exec rspec spec/models       # Test models only
cd mastodon && bundle exec rspec spec/services     # Test services only
cd mastodon && bundle exec flatware-rspec  # Run tests in parallel

# Linting and Formatting
cd mastodon && yarn lint              # Run all linters
cd mastodon && yarn lint:js           # JavaScript linting
cd mastodon && yarn lint:css          # CSS linting
cd mastodon && yarn fix              # Auto-fix linting issues
cd mastodon && yarn format           # Format code with Prettier
cd mastodon && yarn format:check     # Check formatting without fixing
cd mastodon && bundle exec rubocop   # Ruby linting

# Other Utilities
cd mastodon && yarn i18n:extract     # Extract i18n strings
cd mastodon && bin/rails db:encryption:init  # Generate encryption secrets
```

### Docker Commands
```bash
# Build custom images (from root directory)
docker build -t mastodon-custom:latest .
docker build -f streaming/Dockerfile -t mastodon-streaming-custom:latest .

# Build with specific versions (as documented in mastodon-build-guide.md)
docker build --build-arg RUBY_VERSION=3.4.4 \
             --build-arg NODE_VERSION=22 \
             --build-arg LIBVIPS_VERSION=8.17.0 \
             --build-arg FFMPEG_VERSION=7.1 \
             -t mastodon-custom:latest .

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
cd mastodon && bundle exec rails dev:populate_sample_data  # Add sample data (creates @showcase_account)

# Create admin user
cd mastodon && bundle exec rails mastodon:accounts:create USERNAME=admin EMAIL=admin@example.com ROLE=Owner --confirmed

# Default development admin credentials (if using populate_sample_data):
# Email: admin@mastodon.local
# Password: mastodonadmin
```

## Architecture Overview

### Multi-Service Architecture
- **Web Service**: Rails application serving the UI and API (port 3000)
- **Streaming Service**: Node.js WebSocket server for real-time updates (port 4000)
- **Sidekiq Workers**: Background job processing (multiple queues: default, push, pull, mailers, scheduler, ingress, fasp)
- **Dependencies**: PostgreSQL 13+, Redis 6.2+, optional Elasticsearch (via Chewy gem)

### Service Management
All services are defined in `mastodon/Procfile.dev` and managed by the Foreman gem when using `bin/dev`. The services include:
- `web`: Rails server
- `css`: Vite CSS watcher
- `js`: Vite JavaScript bundler with HMR
- `worker`: Sidekiq background jobs

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

### Code Organization Patterns
- **Controllers**: Inherit from `ApplicationController` or `Api::BaseController`
- **React Components**: Located in `/mastodon/app/javascript/mastodon/`
- **Styles**: SCSS files in `/mastodon/app/javascript/styles/`
- **API Responses**: Use ActiveModel Serializers in `/mastodon/app/serializers/`
- **Background Jobs**: Inherit from `ApplicationWorker` in `/mastodon/app/workers/`

### Storybook Commands
```bash
cd mastodon && yarn storybook        # Start Storybook development server
cd mastodon && yarn build-storybook  # Build static Storybook
cd mastodon && yarn test:storybook   # Run Storybook tests
```

### Important Configuration
- Environment configuration: `.env.production` (see `.env.production.sample` for all options)
- Docker orchestration: `docker-compose.yml` (and override files)
- Sidekiq queues: `config/sidekiq.yml`
- Database config: `config/database.yml`
- Custom deployment scripts for Cloudflare tunnels in root directory
- Custom build guide: `mastodon-build-guide.md`
- Default deployment domain: `troupex-dev.materiallab.io`

### Key Environment Variables
- `FETCH_REPLIES_ENABLED`: Enable fetching replies from other instances
- `FETCH_REPLIES_COOLDOWN_MINUTES`: Cooldown period for reply fetching
- `EXTRA_MEDIA_HOSTS`: Additional domains for media content
- `SESSION_RETENTION_PERIOD`: How long to keep user sessions (seconds)
- `IP_RETENTION_PERIOD`: How long to keep IP addresses in logs (seconds)

### Custom Deployment Setup
This repository includes custom deployment scripts and configuration:
- Cloudflare tunnel setup for public access
- Custom Docker image builds with specific versions (Ruby 3.4.4, Node.js 22, libvips 8.17.0, ffmpeg 7.1)
- Hot reload development workflow for container-based development
- Troupe theme customizations and branding assets
- Custom systemd service management scripts

### Custom Features
- **Showcase Feature**: Profile tab at `/@username/showcase` for featured posts
- **LinkedIn-style Theme**: Professional UI modifications (see `debug-theme.md` for debugging)
- **Testing Documentation**: See `test-showcase.md` for showcase feature testing guide

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
- `fasp`: Fast ActivityPub Serialization Protocol tasks

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
- The project includes Git hooks via Husky (installed automatically via yarn postinstall)
- Git pre-commit hooks run `yarn lint-staged` to format and lint staged files
- VERY IMPORTANT: When you have completed a task, you MUST run the lint and typecheck commands (eg. npm run lint, npm run typecheck, ruff, etc.) with Bash if they were provided to you to ensure your code is correct. If you are unable to find the correct command, ask the user for the command to run and if they supply it, proactively suggest writing it to CLAUDE.md so that you will know to run it next time

### Alternative Development Environments
- **Vagrant**: Supported with `vagrant-hostsupdater` plugin
- **Dev Containers**: VS Code Dev Containers specification available
- **GitHub Codespaces**: Fully supported for cloud development
- **macOS**: Use Homebrew for dependency management

## Workspace Structure
The project uses Yarn workspaces with the following packages:
- Root workspace: Main Mastodon application
- `/mastodon/streaming`: Node.js streaming service (separate workspace)

## Cloudflare Tunnel Integration
The project is configured to work with Cloudflare tunnels for public access:
- Default domain: `troupex-dev.materiallab.io`
- Vite HMR requires special tunnel configuration (see vite tunnel scripts)
- Multiple helper scripts for tunnel setup and management in root directory

## Development Memories
- Remember to reimport new CSS files when UI changes are made on application.css otherwise the docker image doesn't get built right with the latest UI.