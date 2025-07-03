import { useEffect, useCallback } from 'react';
import { useIdentity } from 'mastodon/identity_context';
import logoWordmark from 'mastodon/../images/logo-symbol-wordmark.svg';

interface ExploreWrapperProps {
  children: React.ReactNode;
}

const ExploreWrapper: React.FC<ExploreWrapperProps> = ({ children }) => {
  const { signedIn } = useIdentity();

  useEffect(() => {
    // Add class to body when not signed in on explore page
    if (!signedIn) {
      document.body.classList.add('explore-not-logged-in');
      return () => {
        document.body.classList.remove('explore-not-logged-in');
      };
    }
    return undefined;
  }, [signedIn]);

  const handleGetStarted = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    window.location.href = '/auth/sign_in';
  }, []);


  if (!signedIn) {
    return (
      <div className='explore-page-wrapper no-logged-in'>
        <div className='explore-minimal-container'>
          <div className='explore-minimal-content'>
            <img src={logoWordmark} alt='TroupeX' className='troupex-wordmark-minimal' />
            <p className='minimal-tagline'>Creative professionals network</p>
          </div>
          <div className='explore-cta-container'>
            <button 
              className='btn-get-started'
              onClick={handleGetStarted}
              type='button'
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