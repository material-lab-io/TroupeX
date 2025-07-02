import { useState, useCallback } from 'react';

import { Link } from 'react-router-dom';

import EditIcon from '@/material-icons/400-24px/edit.svg?react';
import LockIcon from '@/material-icons/400-24px/lock.svg?react';
import LogoutIcon from '@/material-icons/400-24px/logout.svg?react';
import SettingsIcon from '@/material-icons/400-24px/settings.svg?react';
import ShieldIcon from '@/material-icons/400-24px/shield_question.svg?react';
import TagIcon from '@/material-icons/400-24px/tag.svg?react';
import { openModal } from 'mastodon/actions/modal';
import { Avatar } from 'mastodon/components/avatar';
import { Icon } from 'mastodon/components/icon';
import { me } from 'mastodon/initial_state';
import { useAppSelector, useAppDispatch } from 'mastodon/store';

interface ActionLink {
  id: string;
  href: string;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  label: string;
  onClick?: () => void;
}

export const SimplifiedNavigationProfile: React.FC = () => {
  const account = useAppSelector(state => me ? state.accounts.get(me) : null);
  const dispatch = useAppDispatch();
  const [expanded, setExpanded] = useState(false);
  
  const handleToggleExpanded = useCallback(() => {
    setExpanded(!expanded);
  }, [expanded]);

  const handleLogout = useCallback(() => {
    dispatch(openModal({ modalType: 'CONFIRM_LOG_OUT', modalProps: {} }));
  }, [dispatch]);

  const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      handleToggleExpanded();
    }
  }, [handleToggleExpanded]);

  const handleLogoutKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (expanded) {
        handleLogout();
      } else {
        handleToggleExpanded();
      }
    }
  }, [expanded, handleLogout, handleToggleExpanded]);
  
  if (!account || !me) return null;

  const actionLinks: ActionLink[] = [
    {
      id: 'edit-profile',
      href: '/settings/profile',
      icon: EditIcon,
      label: 'Edit Profile'
    },
    {
      id: 'preferences',
      href: '/settings/preferences',
      icon: SettingsIcon,
      label: 'Preferences'
    },
    {
      id: 'privacy',
      href: '/settings/preferences#privacy',
      icon: LockIcon,
      label: 'Privacy'
    },
    {
      id: 'hashtags',
      href: '/settings/preferences#hashtags',
      icon: TagIcon,
      label: 'Hashtags'
    },
    {
      id: 'admin',
      href: '/admin/dashboard',
      icon: ShieldIcon,
      label: 'Admin'
    }
  ];

  return (
    <div className='simplified-navigation-profile'>
      {/* User Info Section */}
      <div className='simplified-navigation-profile__user'>
        <Link to={`/@${account.get('username')}`} className='simplified-navigation-profile__avatar'>
          <Avatar account={account} size={48} />
        </Link>
        
        <div className='simplified-navigation-profile__info'>
          <div className='simplified-navigation-profile__name'>
            {account.get('display_name') || account.get('username')}
          </div>
          <div className='simplified-navigation-profile__username'>
            @{account.get('username')}
          </div>
        </div>
      </div>

      {/* Action Icons */}
      <div className='simplified-navigation-profile__actions'>
        <div className='simplified-navigation-profile__icons'>
          {actionLinks.map((link) => (
            <div
              key={link.id}
              className={`simplified-navigation-profile__icon ${expanded ? 'expanded' : ''}`}
              onClick={expanded ? undefined : handleToggleExpanded}
              onKeyDown={expanded ? undefined : handleKeyDown}
              role="button"
              tabIndex={expanded ? -1 : 0}
            >
              {expanded ? (
                <Link 
                  to={link.href} 
                  className='simplified-navigation-profile__link'
                  title={link.label}
                >
                  <Icon id={link.id} icon={link.icon} />
                  <span className='simplified-navigation-profile__label'>
                    {link.label}
                  </span>
                </Link>
              ) : (
                <Icon id={link.id} icon={link.icon} title={link.label} />
              )}
            </div>
          ))}
          
          {/* Logout button */}
          <div
            className={`simplified-navigation-profile__icon logout ${expanded ? 'expanded' : ''}`}
            onClick={expanded ? handleLogout : handleToggleExpanded}
            onKeyDown={handleLogoutKeyDown}
            role="button"
            tabIndex={0}
          >
            <Icon id='logout' icon={LogoutIcon} title='Logout' />
            {expanded && (
              <span className='simplified-navigation-profile__label'>
                Logout
              </span>
            )}
          </div>
        </div>

        {/* Collapse button when expanded */}
        {expanded && (
          <button 
            className='simplified-navigation-profile__collapse'
            onClick={handleToggleExpanded}
            aria-label='Collapse actions'
          >
            ×
          </button>
        )}
      </div>
    </div>
  );
};