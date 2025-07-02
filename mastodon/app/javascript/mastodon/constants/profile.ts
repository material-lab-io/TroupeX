// Profile Image Constants
export const PROFILE_IMAGE_SIZES = {
  MAX_WIDTH: 800,
  MAX_WIDTH_MOBILE: '90vw',
  ASPECT_RATIO: '3/4',
  MOBILE_MAX_HEIGHT: '60vh',
  THUMBNAIL_SIZE: 120,
} as const;

export const PROFILE_IMAGE_STYLING = {
  BORDER_RADIUS: 32,
  BORDER_RADIUS_MOBILE: 16,
  PADDING: 16,
  PADDING_MOBILE: 8,
} as const;

// Animation Constants
export const PROFILE_ANIMATIONS = {
  TRANSITION_DURATION: '0.3s',
  TRANSITION_EASING: 'ease',
  SPRING_TENSION: 200,
  SPRING_FRICTION: 25,
} as const;

// Layout Constants
export const PROFILE_LAYOUT_SIZES = {
  BIO_MAX_WIDTH: 800,
  ACTION_BUTTON_SIZE: 48,
  ACTION_BUTTON_ICON_SIZE: 24,
  FLOATING_ACTIONS_SPACING: 10,
} as const;

export const PROFILE_TYPOGRAPHY = {
  BIO_FONT_SIZE: 18,
  BIO_LINE_HEIGHT: 1.6,
  DISPLAY_NAME_SIZE: 36,
  DISPLAY_NAME_LETTER_SPACING: -0.5,
} as const;

// Shadow Effects
export const PROFILE_SHADOWS = {
  NEUMORPHIC_LIGHT: {
    DEFAULT: '30px 30px 80px #bebebe, -30px -30px 80px #ffffff, inset 2px 2px 4px rgba(255, 255, 255, 0.8), inset -2px -2px 4px rgba(0, 0, 0, 0.1)',
    HOVER: '35px 35px 90px #bebebe, -35px -35px 90px #ffffff, inset 2px 2px 4px rgba(255, 255, 255, 0.9), inset -2px -2px 4px rgba(0, 0, 0, 0.15)',
  },
  NEUMORPHIC_DARK: {
    DEFAULT: '20px 20px 60px #0a0a0a, -20px -20px 60px #3a3a3a, inset 1px 1px 2px rgba(255, 255, 255, 0.1), inset -1px -1px 2px rgba(0, 0, 0, 0.5)',
    HOVER: '25px 25px 75px #0a0a0a, -25px -25px 75px #3a3a3a, inset 1px 1px 2px rgba(255, 255, 255, 0.15), inset -1px -1px 2px rgba(0, 0, 0, 0.6)',
  },
} as const;

// Persona System Constants
export const PERSONA_COLORS = {
  CREATIVE: '#e91e63',
  TECHNICAL: '#2196f3',
  PRODUCTION: '#ff6f00',
  SUPPORT: '#4caf50',
} as const;

// Validation Rules
export const PROFILE_VALIDATION = {
  MIN_YEAR: 1900,
  MAX_YEAR_OFFSET: 5, // Allow years up to 5 years in the future
  MAX_PROJECT_LENGTH: 100,
  MAX_ROLE_LENGTH: 50,
  MAX_FAVORITE_LENGTH: 100,
} as const;