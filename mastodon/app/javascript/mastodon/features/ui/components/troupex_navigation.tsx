import { useCallback } from 'react';

import { useHistory, useLocation } from 'react-router-dom';

import ArrowBackIcon from '@/material-icons/400-24px/arrow_back.svg?react';
import MenuIcon from '@/material-icons/400-24px/menu.svg?react';
import { toggleNavigation } from 'mastodon/actions/navigation';
import { Icon } from 'mastodon/components/icon';
import { useAppDispatch } from 'mastodon/store';

export const TroupeXNavigation: React.FC = () => {
  const dispatch = useAppDispatch();
  const history = useHistory();
  const location = useLocation();

  const handleMenuClick = useCallback(() => {
    dispatch(toggleNavigation());
  }, [dispatch]);

  const handleBackClick = useCallback(() => {
    history.goBack();
  }, [history]);

  // Show back button on profile pages and other detail pages
  const showBackButton = /^\/(@[^/]+|statuses\/|accounts\/)/.test(location.pathname);

  return (
    <div className='troupex-top-nav'>
      <div className='troupex-nav-left'>
        {showBackButton && (
          <button 
            className='troupex-back-button'
            onClick={handleBackClick}
            aria-label='Back'
          >
            <Icon id='back' icon={ArrowBackIcon} />
          </button>
        )}
        
        <a href='/home' className='troupex-wordmark'>
          <span className='troupe-text'>Troupe</span>
          <span className='troupex-x'>X</span>
        </a>
      </div>
      
      <button 
        className='troupex-hamburger'
        onClick={handleMenuClick}
        aria-label='Menu'
      >
        <span className='hamburger-icon'>
          <Icon id='menu' icon={MenuIcon} />
        </span>
      </button>
    </div>
  );
};