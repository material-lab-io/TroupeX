import React from 'react';

import { FormattedMessage } from 'react-intl';

import { Icon } from '@/mastodon/components/icon';
import PersonIcon from '@/material-icons/400-24px/person.svg?react';

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ProfileErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log to console in development
    if (process.env.NODE_ENV === 'development') {
      console.error('Profile component error:', error);
      console.error('Error info:', errorInfo);
    }
    
    // In production, you might want to send this to an error tracking service
    // Example: Sentry.captureException(error, { extra: errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className='profile-error-boundary' role='alert' aria-live='assertive'>
          <div className='profile-error-boundary__content'>
            <Icon id='person' icon={PersonIcon} aria-hidden='true' />
            <h3 className='profile-error-boundary__title'>
              <FormattedMessage
                id='profile.error.title'
                defaultMessage='Unable to load profile'
              />
            </h3>
            <p className='profile-error-boundary__message'>
              <FormattedMessage
                id='profile.error.message'
                defaultMessage='There was an error loading this profile. Please try refreshing the page.'
              />
            </p>
            {process.env.NODE_ENV === 'development' && this.state.error && (
              <details className='profile-error-boundary__details'>
                <summary>Error details</summary>
                <pre>{this.state.error.stack}</pre>
              </details>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}