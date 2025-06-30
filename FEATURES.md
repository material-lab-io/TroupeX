# TroupeX Features

This document details the custom features and enhancements that make TroupeX unique, beyond the standard Mastodon functionality.

## Table of Contents

- [Professional Theme](#professional-theme)
- [Showcase Feature](#showcase-feature)
- [Enhanced Messaging](#enhanced-messaging)
- [Custom Navigation](#custom-navigation)
- [Developer Features](#developer-features)
- [Performance Enhancements](#performance-enhancements)
- [Upcoming Features](#upcoming-features)

## Professional Theme

### Overview
TroupeX features a LinkedIn-inspired professional theme designed for business and professional networking contexts.

### Design Elements

#### Color Palette
```scss
// Primary colors
$troupex-primary: #0077b5;        // Professional blue
$troupex-background: #f3f2ef;     // Light gray background
$troupex-surface: #ffffff;        // White surfaces
$troupex-text: #000000e6;         // High contrast text

// Secondary colors
$troupex-secondary: #057642;      // Success green
$troupex-accent: #cc1016;         // Attention red
$troupex-muted: #666666;          // Muted text
```

#### Typography
- **Primary Font:** -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto
- **Heading Weight:** 600 (semi-bold)
- **Body Weight:** 400 (regular)
- **Line Height:** 1.5 for optimal readability

#### Components Styling
```scss
// Card-based design
.status {
  background: $troupex-surface;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  margin-bottom: 8px;
}

// Professional buttons
.button {
  border-radius: 24px;
  font-weight: 600;
  transition: all 0.2s ease;
  
  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }
}
```

### Theme Application
The theme is automatically applied across:
- Timeline views
- Profile pages
- Settings interface
- Modals and dialogs
- Form elements

## Showcase Feature

### Purpose
Allow users to pin and highlight their best content on a dedicated showcase tab on their profile.

### How It Works

1. **Adding to Showcase**
   - Click the three-dot menu on any of your posts
   - Select "Add to Showcase"
   - Post appears in your showcase tab

2. **Showcase Management**
   ```ruby
   # Maximum showcase items per user
   SHOWCASE_LIMIT = 10
   
   # Showcase visibility follows post visibility
   showcase_items.where(status: { visibility: :public })
   ```

3. **Profile Integration**
   - New tab at `/@username/showcase`
   - Displays pinned posts in chronological order
   - Respects original post privacy settings

### API Endpoints

```http
# Get showcase items
GET /api/v1/accounts/:id/showcase

# Add to showcase
POST /api/v1/statuses/:id/showcase

# Remove from showcase
DELETE /api/v1/statuses/:id/showcase
```

### Implementation Files
- Backend: `app/controllers/api/v1/accounts/showcase_controller.rb`
- Frontend: `app/javascript/mastodon/features/account_showcase/`
- Model: `app/models/showcase_item.rb`

## Enhanced Messaging

### Direct Messaging System
A built-in messaging feature for private conversations between users.

### Features

1. **Message Threading**
   - Conversation-based organization
   - Unread message indicators
   - Message timestamps and read receipts

2. **Real-time Updates**
   - WebSocket integration for instant delivery
   - Typing indicators
   - Online/offline status

3. **Rich Media Support**
   - Image attachments
   - Link previews
   - Emoji reactions

### Usage

```javascript
// Send a message
const message = {
  recipient_id: userId,
  content: "Hello!",
  media_ids: []
};

api.post('/api/v1/messages', message);
```

### Privacy & Security
- End-to-end encryption ready
- Message retention policies
- Block/report functionality

## Custom Navigation

### Enhanced Navigation Panel

The navigation has been redesigned for better user experience:

1. **Profile Integration**
   ```jsx
   <NavigationPanelProfile
     account={currentAccount}
     showStats={true}
     compact={false}
   />
   ```

2. **Smart Navigation**
   - Context-aware menu items
   - Quick access to frequently used features
   - Customizable navigation order

3. **Mobile Optimization**
   - Swipe gestures
   - Bottom navigation bar
   - Adaptive layout

### Settings Navigation

Improved settings organization:
- Grouped by category
- Search functionality
- Quick toggles for common settings

## Developer Features

### Hot Reload Development

Advanced development setup with automatic synchronization:

```bash
# Start hot reload development
./troupe-hot-reload.sh

# Features:
# - Instant style updates
# - Component hot swapping
# - State preservation
# - Error overlay
```

### Cloudflare Tunnel Integration

Built-in support for secure tunnel development:

```bash
# Setup tunnel
./setup-vite-tunnel.sh

# Access your dev instance at:
# https://troupex-dev.materiallab.io
```

### Development Scripts

Comprehensive script collection:
- `complete-dev-setup.sh` - One-command setup
- `debug-500-error.sh` - Error debugging
- `fix-upload-permissions.sh` - Permission fixes
- `populate-admin-timeline.rb` - Test data generation

### Vite Configuration

Custom Vite setup for optimal DX:
```javascript
// vite.config.js enhancements
{
  server: {
    hmr: {
      protocol: 'wss',
      clientPort: 443,
      overlay: true
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', '@reduxjs/toolkit']
  }
}
```

## Performance Enhancements

### Optimized Asset Loading

1. **Code Splitting**
   ```javascript
   // Automatic route-based splitting
   const Messages = lazy(() => import('./features/messages'));
   ```

2. **Image Optimization**
   - WebP conversion
   - Lazy loading
   - Responsive images
   - CDN integration

3. **Bundle Optimization**
   - Tree shaking
   - Minification
   - Compression
   - Cache busting

### Database Optimizations

1. **Query Optimization**
   ```ruby
   # Optimized timeline queries
   Status.includes(:account, :media_attachments)
         .merge(Account.without_suspended)
         .paginate_by_id(limit, params)
   ```

2. **Caching Strategy**
   - Redis caching for hot data
   - Fragment caching for views
   - API response caching
   - CDN for static assets

### Frontend Performance

1. **React Optimizations**
   - Memoization for expensive operations
   - Virtual scrolling for long lists
   - Optimistic UI updates
   - Debounced API calls

2. **Service Worker**
   - Offline support
   - Background sync
   - Push notifications
   - Cache strategies

## Upcoming Features

### In Development

1. **Professional Profiles**
   - Resume/CV integration
   - Skills endorsements
   - Professional achievements
   - Work history

2. **Advanced Analytics**
   - Post performance metrics
   - Audience insights
   - Engagement analytics
   - Growth tracking

3. **Team Collaboration**
   - Organization accounts
   - Team messaging
   - Shared drafts
   - Approval workflows

4. **AI Integration**
   - Smart content suggestions
   - Automated moderation
   - Translation services
   - Content summarization

### Planned Enhancements

1. **Mobile Apps**
   - Native iOS app
   - Native Android app
   - Desktop app (Electron)

2. **Enterprise Features**
   - SSO integration
   - Advanced admin tools
   - Compliance features
   - Audit logging

3. **Developer API v2**
   - GraphQL endpoint
   - Webhook support
   - Rate limit improvements
   - SDK libraries

## Feature Configuration

### Enabling/Disabling Features

```ruby
# config/settings.yml
features:
  showcase: true
  messaging: true
  professional_theme: true
  analytics: false  # Coming soon
```

### Feature Flags

```ruby
# Check feature availability
if Feature.enabled?(:showcase, current_user)
  # Show showcase functionality
end
```

### Custom Configuration

```javascript
// Client-side feature detection
if (features.messaging) {
  import('./features/messages');
}
```

---

For feature requests and bug reports, please visit our [GitHub Issues](https://github.com/material-lab-io/TroupeX/issues).