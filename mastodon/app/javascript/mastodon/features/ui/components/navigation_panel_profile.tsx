import { Link } from 'react-router-dom';

import { Avatar } from 'mastodon/components/avatar';
import { me } from 'mastodon/initial_state';
import { useAppSelector } from 'mastodon/store';

export const NavigationPanelProfile: React.FC = () => {
  const account = useAppSelector(state => me ? state.accounts.get(me) : null);
  
  if (!account || !me) return null;

  return (
    <div className='navigation-panel__profile'>
      <Link to={`/@${account.get('username')}`} className='navigation-panel__profile__avatar'>
        <Avatar account={account} size={64} />
      </Link>
      
      <div className='navigation-panel__profile__name'>
        <strong>{account.get('display_name') || account.get('username')}</strong>
        <span>@{account.get('username')}</span>
      </div>
      
      <Link to='/settings/profile' className='navigation-panel__profile__edit'>
        Edit Profile
      </Link>
    </div>
  );
};