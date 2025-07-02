import { useCallback, useEffect } from 'react';

import { useIntl, defineMessages, FormattedMessage } from 'react-intl';

import classNames from 'classnames';
import { NavLink, useRouteMatch } from 'react-router-dom';

import AccountCircleActiveIcon from '@/material-icons/400-24px/account_circle-fill.svg?react';
import AccountCircleIcon from '@/material-icons/400-24px/account_circle.svg?react';
import AddIcon from '@/material-icons/400-24px/add.svg?react';
import HomeActiveIcon from '@/material-icons/400-24px/home-fill.svg?react';
import HomeIcon from '@/material-icons/400-24px/home.svg?react';
import SearchIcon from '@/material-icons/400-24px/search.svg?react';
import { openModal } from 'mastodon/actions/modal';
import { fetchServer } from 'mastodon/actions/server';
import { Icon } from 'mastodon/components/icon';
import { useIdentity } from 'mastodon/identity_context';
import { registrationsOpen, sso_redirect, me } from 'mastodon/initial_state';
import { useAppDispatch, useAppSelector } from 'mastodon/store';

export const messages = defineMessages({
  home: { id: 'tabs_bar.home', defaultMessage: 'Home' },
  search: { id: 'tabs_bar.search', defaultMessage: 'Search' },
  publish: { id: 'tabs_bar.publish', defaultMessage: 'New Post' },
  profile: {
    id: 'tabs_bar.profile',
    defaultMessage: 'Profile',
  },
});

const IconLabelButton: React.FC<{
  to: string;
  icon?: React.ReactNode;
  activeIcon?: React.ReactNode;
  title: string;
}> = ({ to, icon, activeIcon, title }) => {
  const match = useRouteMatch(to);

  return (
    <NavLink
      className='ui__navigation-bar__item'
      activeClassName='active'
      to={to}
      aria-label={title}
    >
      {match && activeIcon ? activeIcon : icon}
    </NavLink>
  );
};

const ProfileButton = () => {
  const intl = useIntl();
  const { signedIn } = useIdentity();
  const username = useAppSelector((state) => {
    if (!me) return null;
    const account = state.accounts.get(me);
    return account?.get('username');
  });

  if (!signedIn || !username) return null;

  return (
    <IconLabelButton
      title={intl.formatMessage(messages.profile)}
      to={`/@${username}`}
      icon={<Icon id='person' icon={AccountCircleIcon} />}
      activeIcon={<Icon id='person' icon={AccountCircleActiveIcon} />}
    />
  );
};

const LoginOrSignUp: React.FC = () => {
  const dispatch = useAppDispatch();
  const signupUrl = useAppSelector(
    (state) =>
      (state.server.getIn(['server', 'registrations', 'url'], null) as
        | string
        | null) ?? '/auth/sign_up',
  );

  const openClosedRegistrationsModal = useCallback(() => {
    dispatch(openModal({ modalType: 'CLOSED_REGISTRATIONS', modalProps: {} }));
  }, [dispatch]);

  useEffect(() => {
    dispatch(fetchServer());
  }, [dispatch]);

  if (sso_redirect) {
    return (
      <div className='ui__navigation-bar__sign-up'>
        <a
          href={sso_redirect}
          data-method='post'
          className='button button--block button-tertiary'
        >
          <FormattedMessage
            id='sign_in_banner.sso_redirect'
            defaultMessage='Login or Register'
          />
        </a>
      </div>
    );
  } else {
    let signupButton;

    if (registrationsOpen) {
      signupButton = (
        <a href={signupUrl} className='button'>
          <FormattedMessage
            id='sign_in_banner.create_account'
            defaultMessage='Create account'
          />
        </a>
      );
    } else {
      signupButton = (
        <button className='button' onClick={openClosedRegistrationsModal}>
          <FormattedMessage
            id='sign_in_banner.create_account'
            defaultMessage='Create account'
          />
        </button>
      );
    }

    return (
      <div className='ui__navigation-bar__sign-up'>
        {signupButton}
        <a href='/auth/sign_in' className='button button-tertiary'>
          <FormattedMessage
            id='sign_in_banner.sign_in'
            defaultMessage='Login'
          />
        </a>
      </div>
    );
  }
};

export const NavigationBar: React.FC = () => {
  const { signedIn } = useIdentity();
  const intl = useIntl();

  return (
    <div className='ui__navigation-bar'>
      {!signedIn && <LoginOrSignUp />}

      <div
        className={classNames('ui__navigation-bar__items', {
          active: signedIn,
        })}
      >
        {signedIn && (
          <>
            <IconLabelButton
              title={intl.formatMessage(messages.home)}
              to='/home'
              icon={<Icon id='' icon={HomeIcon} />}
              activeIcon={<Icon id='' icon={HomeActiveIcon} />}
            />
            <IconLabelButton
              title={intl.formatMessage(messages.search)}
              to='/explore'
              icon={<Icon id='' icon={SearchIcon} />}
            />
            <IconLabelButton
              title={intl.formatMessage(messages.publish)}
              to='/publish'
              icon={<Icon id='' icon={AddIcon} />}
            />
            <ProfileButton />
          </>
        )}
      </div>
    </div>
  );
};
