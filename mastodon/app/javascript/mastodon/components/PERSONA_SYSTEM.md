# Persona Profile System

## Overview

The Persona Profile System is a custom feature for TroupeX that allows film and creative industry professionals to showcase their roles, credits, and aspirations in a visually appealing format. It categorizes users into four main personas based on their professional roles.

## Personas

### 1. Creative (Pink - #e91e63)
- **Icon**: Edit/Pen icon
- **Roles**: Actor, Artist, Writer, Composer, Choreographer
- **Focus**: Creative talent and artistic expression

### 2. Technical (Blue - #2196f3)
- **Icon**: Camera icon
- **Roles**: Cinematographer, Lighting Expert, VFX Artist, Camera Operator, Gaffer
- **Focus**: Technical expertise and craft

### 3. Production (Orange - #ff6f00)
- **Icon**: Movie/Film icon
- **Roles**: Director, Producer, Assistant Director, Production Manager, Casting Director
- **Focus**: Leadership and production management

### 4. Support (Green - #4caf50)
- **Icon**: Settings/Gear icon
- **Roles**: Editor, Sound Designer, Makeup Artist, Costume Designer, Set Designer
- **Focus**: Post-production and support services

## How It Works

The system uses Mastodon's existing custom fields infrastructure (no database changes required). Users add specific fields to their profile:

### Required Field
- **Role** or **Profession**: Determines the persona and color scheme

### Optional Fields
- **Credits** or **Projects**: List of film/TV projects (supports JSON array or comma-separated list)
- **One Day**: Aspirational goal
- **Dream**: Long-term career dream
- **Favorites** or **Inspirations**: List of inspiring artists/works

## Implementation Details

### Components

1. **PersonaProfileDisplay** (`persona_profile_display.tsx`)
   - Main component that parses profile fields and displays persona information
   - Automatically detects persona based on role
   - Handles both JSON and plain text formats gracefully

2. **ProfilePhotoCarousel** (`profile_photo_carousel.tsx`)
   - Displays profile photos in an 800px cinematic format
   - Supports multiple photos via carousel_photos field
   - Features neumorphic design with smooth transitions

3. **ProfileErrorBoundary** (`profile_error_boundary.tsx`)
   - Gracefully handles errors in profile rendering
   - Provides user-friendly error messages
   - Shows detailed error info in development mode

### Field Format Examples

#### Credits (JSON format - preferred)
```json
[
  {"project": "The Matrix", "year": "1999", "role": "Neo"},
  {"project": "John Wick", "year": "2014", "role": "John Wick"}
]
```

#### Credits (Text format - fallback)
```
The Matrix (1999), John Wick (2014), Point Break
```

#### Favorites (JSON format)
```json
["Stanley Kubrick", "Christopher Nolan", "Roger Deakins"]
```

#### Favorites (Text format)
```
Stanley Kubrick, Christopher Nolan, Roger Deakins
```

## Styling

The persona system uses SCSS variables defined in:
- `/mastodon/app/javascript/styles/mastodon/components/_persona_profile.scss`
- `/mastodon/app/javascript/styles/mastodon/variables/_profile.scss`

Key design features:
- Neumorphic shadows for depth
- Color-coded persona badges
- Responsive layout for mobile and desktop
- Professional film industry aesthetic

## Testing

Test coverage is provided in:
- `__tests__/components/persona_profile_display.test.tsx`
- `__tests__/components/profile_photo_carousel.test.tsx`

Run tests with:
```bash
cd mastodon && yarn test:js
```

## Accessibility

All components include proper ARIA labels and roles:
- Profile sections marked as regions
- Lists properly structured with role="list"
- Icons marked as decorative with aria-hidden
- Error states announced to screen readers

## Future Enhancements

Potential improvements could include:
- IMDb integration for automatic credit import
- Verified credentials for industry professionals
- Collaboration indicators between profiles
- Project-based networking features