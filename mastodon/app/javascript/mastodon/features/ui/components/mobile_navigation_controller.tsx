import { useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';

import { closeNavigation } from 'mastodon/actions/navigation';
import { NavigationPanel } from 'mastodon/features/navigation_panel/index';
import { useAppDispatch, useAppSelector } from 'mastodon/store';

export const MobileNavigationController: React.FC = () => {
  const dispatch = useAppDispatch();
  const isOpen = useAppSelector((state) => state.navigation.open);

  const handleClose = useCallback(() => {
    dispatch(closeNavigation());
  }, [dispatch]);

  // Close navigation when clicking overlay
  const handleOverlayClick = useCallback((e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      handleClose();
    }
  }, [handleClose]);

  // Handle keyboard interactions for overlay
  const handleOverlayKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClose();
    }
  }, [handleClose]);

  // Close navigation on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        handleClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.classList.add('navigation-open');
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.classList.remove('navigation-open');
    };
  }, [isOpen, handleClose]);

  // Only render on mobile (using media query check)
  useEffect(() => {
    const mediaQuery = window.matchMedia('(max-width: 767px)');
    if (!mediaQuery.matches && isOpen) {
      handleClose();
    }
  }, [isOpen, handleClose]);

  if (!isOpen) {
    return null;
  }

  // Portal to render outside of normal DOM hierarchy
  return createPortal(
    <>
      <div 
        className='navigation-panel__overlay active' 
        onClick={handleOverlayClick}
        onKeyDown={handleOverlayKeyDown}
        role='button'
        tabIndex={0}
        aria-label='Close navigation'
      />
      <div className='navigation-panel active'>
        <NavigationPanel />
      </div>
    </>,
    document.body
  );
};