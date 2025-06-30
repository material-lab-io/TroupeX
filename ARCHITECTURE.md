# TroupeX Architecture

This document provides a detailed overview of TroupeX's technical architecture, design decisions, and system components.

## Table of Contents

- [System Overview](#system-overview)
- [Service Architecture](#service-architecture)
- [Technology Stack](#technology-stack)
- [Data Flow](#data-flow)
- [Directory Structure](#directory-structure)
- [Key Components](#key-components)
- [Security Architecture](#security-architecture)
- [Performance Considerations](#performance-considerations)

## System Overview

TroupeX is built on Mastodon's proven multi-service architecture, enhanced with custom features for professional networking. The system follows a microservices pattern with clear separation of concerns.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│   Web Browser   │────▶│   Cloudflare    │────▶│    Load         │
│   Mobile App    │     │   Tunnel/CDN    │     │    Balancer     │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
                              ┌───────────────────────────┴───────────────────────────┐
                              │                                                       │
                              ▼                                                       ▼
                    ┌─────────────────┐                                     ┌─────────────────┐
                    │                 │                                     │                 │
                    │   Rails Web     │                                     │   Streaming     │
                    │   Application   │                                     │   Service       │
                    │   (Port 3000)   │                                     │   (Port 4000)   │
                    │                 │                                     │                 │
                    └────────┬────────┘                                     └────────┬────────┘
                             │                                                       │
                             ▼                                                       ▼
                    ┌─────────────────┐     ┌─────────────────┐           ┌─────────────────┐
                    │                 │     │                 │           │                 │
                    │   PostgreSQL    │     │     Redis       │           │   Sidekiq       │
                    │   Database      │     │     Cache       │           │   Workers       │
                    │                 │     │                 │           │                 │
                    └─────────────────┘     └─────────────────┘           └─────────────────┘
```

## Service Architecture

### 1. Web Service (Rails Application)

The core application server handling:
- HTTP requests and responses
- Business logic and data processing
- API endpoints
- Server-side rendering
- Authentication and authorization

**Key Technologies:**
- Ruby on Rails 8.0
- Puma web server
- ActiveRecord ORM
- ActionCable for WebSockets

### 2. Streaming Service (Node.js)

Real-time event streaming for:
- Timeline updates
- Notifications
- Direct messages
- Live interactions

**Key Technologies:**
- Node.js 22
- WebSocket protocol
- Redis pub/sub
- Cluster mode for scaling

### 3. Background Workers (Sidekiq)

Asynchronous job processing for:
- Email delivery
- Media processing
- Federation activities
- Scheduled maintenance

**Queue Structure:**
```yaml
default:     # General background tasks
push:        # ActivityPub delivery
pull:        # Remote content fetching  
mailers:     # Email sending
scheduler:   # Periodic tasks
ingress:     # Incoming ActivityPub
fasp:        # Fast ActivityPub Serialization
```

### 4. Frontend (React/Vite)

Modern JavaScript application:
- React 18 with hooks
- Redux for state management
- Vite for fast builds
- Progressive Web App

## Technology Stack

### Backend
- **Language:** Ruby 3.4.4
- **Framework:** Rails 8.0
- **API:** REST + GraphQL (future)
- **Authentication:** Devise + OAuth2
- **Authorization:** Pundit policies

### Frontend
- **Framework:** React 18
- **Build Tool:** Vite 6
- **State Management:** Redux + RTK
- **Styling:** SCSS + CSS Modules
- **Testing:** Vitest + React Testing Library

### Infrastructure
- **Database:** PostgreSQL 13+
- **Cache:** Redis 6.2+
- **Search:** Elasticsearch 7.x (optional)
- **File Storage:** Local/S3-compatible
- **Container:** Docker + Docker Compose

## Data Flow

### 1. Request Lifecycle

```
User Request → Cloudflare Tunnel → Rails Router → Controller
    ↓                                                  ↓
Response ← View/Serializer ← Service Object ← Model ← Database
```

### 2. Real-time Updates

```
Event Trigger → Redis Pub → Streaming Service → WebSocket → Client
                    ↓
              Sidekiq Job → Database Update
```

### 3. Federation Flow

```
Local Action → ActivityPub Object → Sidekiq Push Job → Remote Server
                                          ↓
Remote Action ← Sidekiq Pull Job ← ActivityPub Inbox ← Remote Server
```

## Directory Structure

```
TroupeX/
├── mastodon/                    # Core application
│   ├── app/                     # Rails application
│   │   ├── controllers/         # Request handlers
│   │   ├── models/             # Data models
│   │   ├── services/           # Business logic
│   │   ├── workers/            # Background jobs
│   │   ├── javascript/         # React frontend
│   │   │   ├── mastodon/       # Main app code
│   │   │   ├── styles/         # SCSS styles
│   │   │   └── images/         # Static assets
│   │   ├── serializers/        # API responses
│   │   ├── policies/           # Authorization
│   │   └── validators/         # Custom validations
│   ├── config/                 # Configuration
│   ├── db/                     # Database files
│   ├── lib/                    # Libraries
│   ├── public/                 # Static files
│   ├── spec/                   # Tests
│   └── streaming/              # Node.js service
├── docs/                       # Documentation
├── scripts/                    # Utility scripts
└── docker/                     # Docker configs
```

## Key Components

### Custom Features

#### 1. Showcase Feature
- **Location:** `app/controllers/api/v1/accounts/showcase_controller.rb`
- **Frontend:** `app/javascript/mastodon/features/account_showcase/`
- **Purpose:** Display featured posts on profile

#### 2. Professional Theme
- **Styles:** `app/javascript/styles/mastodon/troupex-theme-override.scss`
- **Components:** Custom navigation and layout components
- **Colors:** LinkedIn-inspired palette

#### 3. Enhanced Messaging
- **Backend:** `app/models/direct_message.rb`
- **Frontend:** `app/javascript/mastodon/features/messages/`
- **Real-time:** WebSocket integration

### Core Modules

#### Authentication System
```ruby
# Multi-factor authentication
class User < ApplicationRecord
  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => ENV['OTP_SECRET']
end
```

#### Federation Handler
```ruby
# ActivityPub processing
class ActivityPub::ProcessingWorker
  include Sidekiq::Worker
  
  def perform(account_id, body, headers)
    ActivityPub::ProcessCollectionService.new.call(body, account, headers)
  end
end
```

#### Media Processing
```ruby
# Image and video handling
class MediaAttachment < ApplicationRecord
  has_attached_file :file,
    styles: ->(f) { file_styles(f) },
    processors: ->(f) { file_processors(f) }
end
```

## Security Architecture

### 1. Authentication Layers
- Session-based for web
- OAuth2 for API access
- JWT for mobile apps
- WebAuthn support

### 2. Data Protection
- Encrypted passwords (bcrypt)
- Encrypted secrets (Rails credentials)
- HTTPS enforcement
- CSP headers

### 3. Rate Limiting
```ruby
# API rate limits
Rack::Attack.throttle("api", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api")
end
```

### 4. Input Validation
- Strong parameters
- XSS protection
- SQL injection prevention
- CSRF tokens

## Performance Considerations

### 1. Caching Strategy

**Multi-layer caching:**
- CDN (Cloudflare)
- Redis cache
- Rails cache
- Browser cache

```ruby
# Fragment caching example
cache ["status", status.id, status.updated_at] do
  render partial: "statuses/status", locals: { status: status }
end
```

### 2. Database Optimization

**Query optimization:**
- Eager loading associations
- Database indexes
- Query analysis
- Connection pooling

```ruby
# Optimized query with includes
Status.includes(:account, :media_attachments)
      .where(visibility: :public)
      .limit(20)
```

### 3. Asset Optimization

**Frontend performance:**
- Code splitting
- Lazy loading
- Image optimization
- Bundle size monitoring

```javascript
// Dynamic imports for code splitting
const Messages = lazy(() => import('./features/messages'));
```

### 4. Scaling Strategies

**Horizontal scaling:**
- Multiple web workers
- Sidekiq concurrency
- Read replicas
- Redis clustering

## Monitoring and Observability

### 1. Logging
- Structured logging with tags
- Log aggregation
- Error tracking (Sentry compatible)

### 2. Metrics
- Application metrics
- Business metrics
- Performance monitoring
- Custom dashboards

### 3. Health Checks
```ruby
# Health check endpoint
class HealthController < ApplicationController
  def show
    render json: {
      status: "ok",
      database: database_healthy?,
      redis: redis_healthy?,
      sidekiq: sidekiq_healthy?
    }
  end
end
```

## Development Workflow

### 1. Local Development
- Hot reload with Vite
- Docker Compose setup
- Development seeds
- Test data generation

### 2. Testing Strategy
- Unit tests (RSpec/Vitest)
- Integration tests
- E2E tests (Cypress ready)
- Performance tests

### 3. CI/CD Pipeline
- Automated testing
- Code quality checks
- Security scanning
- Deployment automation

## Future Considerations

### Planned Enhancements
1. GraphQL API implementation
2. Microservices extraction
3. Event sourcing for timeline
4. Machine learning integration
5. Advanced analytics

### Scalability Roadmap
1. Kubernetes deployment
2. Service mesh implementation
3. Global CDN distribution
4. Multi-region support

---

For implementation details and code examples, refer to the source code and inline documentation.