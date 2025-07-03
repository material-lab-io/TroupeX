import { useEffect, useCallback, useState } from 'react';
import { useIdentity } from 'mastodon/identity_context';
import logoWordmark from 'mastodon/../images/logo-symbol-wordmark.svg';

// Constants for better maintainability
const ANIMATION_DURATION = '8s';
const THUMB_REACH_OFFSET = '20vh';
const DESKTOP_OFFSET = '10vh';

interface ExploreWrapperProps {
  children: React.ReactNode;
}

/**
 * ExploreWrapper component that provides a minimalist landing page for non-authenticated users
 * and renders the normal explore content for authenticated users.
 * 
 * @component
 * @param {ExploreWrapperProps} props - Component props
 * @returns {JSX.Element} The wrapped explore content or landing page
 */
const ExploreWrapper: React.FC<ExploreWrapperProps> = ({ children }): JSX.Element => {
  const { signedIn } = useIdentity();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Add a small delay to prevent flash of content
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 100);

    // Add class to body when not signed in on explore page
    if (!signedIn) {
      document.body.classList.add('explore-not-logged-in');
      return () => {
        clearTimeout(timer);
        document.body.classList.remove('explore-not-logged-in');
      };
    }
    
    return () => clearTimeout(timer);
  }, [signedIn]);

  const handleGetStarted = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    try {
      window.location.href = '/auth/sign_in';
    } catch (error) {
      console.error('Failed to redirect to sign-in page:', error);
      // Fallback: try using window.location.assign
      window.location.assign('/auth/sign_in');
    }
  }, []);

  if (isLoading) {
    return <div className='explore-loading' aria-label='Loading' />;
  }

  if (!signedIn) {
    return (
      <div className='explore-page-wrapper no-logged-in' role='main' aria-label='Welcome to TroupeX'>
        <div className='explore-minimal-container'>
          <div className='explore-minimal-content'>
            <img src={logoWordmark} alt='TroupeX' className='troupex-wordmark-minimal' />
            <p className='minimal-tagline' role='heading' aria-level={2}>Creative professionals network</p>
          </div>
          <div className='explore-cta-container'>
            <button 
              className='btn-get-started'
              onClick={handleGetStarted}
              type='button'
              aria-label='Get started with TroupeX - Sign in or create account'
            >
              Get Started
            </button>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};

export default ExploreWrapper;