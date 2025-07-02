// Profile-related constants
export const PROFILE_IMAGE_SIZE = {
  MAX_WIDTH: 800,
  MAX_WIDTH_MOBILE: '90vw',
  ASPECT_RATIO: '3/4',
  MOBILE_MAX_HEIGHT: '60vh',
  THUMBNAIL_SIZE: 120,
  BORDER_RADIUS: 32,
  BORDER_RADIUS_MOBILE: 16,
  PADDING: 16,
  PADDING_MOBILE: 8,
} as const;

export const PROFILE_ANIMATION = {
  TRANSITION_DURATION: '0.3s',
  TRANSITION_EASING: 'ease',
  SPRING_TENSION: 200,
  SPRING_FRICTION: 25,
} as const;

export const PROFILE_LAYOUT = {
  BIO_MAX_WIDTH: 800,
  BIO_FONT_SIZE: 18,
  BIO_LINE_HEIGHT: 1.6,
  ACTION_BUTTON_SIZE: 48,
  ACTION_BUTTON_ICON_SIZE: 24,
  FLOATING_ACTIONS_SPACING: 10,
} as const;

export const NEUMORPHIC_SHADOWS = {
  LIGHT: {
    DEFAULT: '30px 30px 80px #bebebe, -30px -30px 80px #ffffff, inset 2px 2px 4px rgba(255, 255, 255, 0.8), inset -2px -2px 4px rgba(0, 0, 0, 0.1)',
    HOVER: '35px 35px 90px #bebebe, -35px -35px 90px #ffffff, inset 2px 2px 4px rgba(255, 255, 255, 0.9), inset -2px -2px 4px rgba(0, 0, 0, 0.15)',
  },
  DARK: {
    DEFAULT: '20px 20px 60px #0a0a0a, -20px -20px 60px #3a3a3a, inset 1px 1px 2px rgba(255, 255, 255, 0.1), inset -1px -1px 2px rgba(0, 0, 0, 0.5)',
    HOVER: '25px 25px 75px #0a0a0a, -25px -25px 75px #3a3a3a, inset 1px 1px 2px rgba(255, 255, 255, 0.15), inset -1px -1px 2px rgba(0, 0, 0, 0.6)',
  },
} as const;