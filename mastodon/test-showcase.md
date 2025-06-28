# Testing the Showcase Feature

## What we've implemented:
1. **New Showcase Tab**: Added between "Featured" and "Posts" tabs on profile pages
2. **Route**: `/@username/showcase` (e.g., `/@troupe_admin/showcase`)
3. **Component**: Displays featured/pinned posts in a showcase format

## To test:

### 1. Start the Mastodon development server:
```bash
# Start Rails server (in one terminal)
bundle exec rails server

# Start Webpack dev server (in another terminal)  
yarn dev
```

### 2. Access a profile page:
- Navigate to any user profile (e.g., `http://localhost:3000/@username`)
- You should see the new "Showcase" tab in the navigation: 
  `Featured | Showcase | Posts | Posts and replies | Media`

### 3. Click on the Showcase tab:
- The URL should change to `/@username/showcase`
- The showcase view will display the user's pinned/featured posts
- Each showcase item shows:
  - Author avatar and name
  - Post timestamp
  - Star icon (indicating showcase status)
  - Post content
  - Media preview (if any)
  - Open button

### 4. Interaction:
- Clicking on a showcase item should open the full post modal
- The styling should match Mastodon's design system

## Expected behavior:
- If the user has pinned posts, they will appear in the showcase
- If no pinned posts exist, an empty state message will be shown
- The component reuses the existing pinned posts timeline data

## Files modified:
1. `/app/javascript/mastodon/features/account_showcase/index.tsx` - Main component
2. `/app/javascript/mastodon/features/account_showcase/components/showcase_item.tsx` - Item component
3. `/app/javascript/mastodon/features/account_timeline/components/account_header.tsx` - Added nav tab
4. `/app/javascript/mastodon/features/ui/index.jsx` - Added routing
5. `/app/javascript/mastodon/features/ui/util/async-components.js` - Added lazy loading
6. `/app/javascript/styles/mastodon/components.scss` - Added styles