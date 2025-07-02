import { FormattedMessage } from 'react-intl';

import EditIcon from '@/material-icons/400-24px/edit.svg?react';
import FlagIcon from '@/material-icons/400-24px/flag.svg?react';
import ListAltIcon from '@/material-icons/400-24px/list_alt.svg?react';
import MovieIcon from '@/material-icons/400-24px/movie.svg?react';
import PhotoCameraIcon from '@/material-icons/400-24px/photo_camera.svg?react';
import SettingsIcon from '@/material-icons/400-24px/settings.svg?react';
import StarIcon from '@/material-icons/400-24px/star.svg?react';
import type { IconProp } from 'mastodon/components/icon';
import { Icon } from 'mastodon/components/icon';
import type { Account } from 'mastodon/models/account';

export type PersonaType = 'creative' | 'technical' | 'production' | 'support';

interface PersonaConfig {
  icon: IconProp;
  color: string;
  roles: string[];
}

const PERSONA_CONFIGS: Record<PersonaType, PersonaConfig> = {
  creative: {
    icon: EditIcon,
    color: '#e91e63', // Pink
    roles: ['Actor', 'Artist', 'Writer', 'Composer', 'Choreographer'],
  },
  technical: {
    icon: PhotoCameraIcon, 
    color: '#2196f3', // Blue
    roles: ['Cinematographer', 'Lighting Expert', 'VFX Artist', 'Camera Operator', 'Gaffer'],
  },
  production: {
    icon: MovieIcon,
    color: '#ff6f00', // Orange
    roles: ['Director', 'Producer', 'Assistant Director', 'Production Manager', 'Casting Director'],
  },
  support: {
    icon: SettingsIcon,
    color: '#4caf50', // Green
    roles: ['Editor', 'Sound Designer', 'Makeup Artist', 'Costume Designer', 'Set Designer'],
  },
};

const getPersonaFromRole = (role: string): PersonaType => {
  for (const [persona, config] of Object.entries(PERSONA_CONFIGS)) {
    if (config.roles.some(r => role.toLowerCase().includes(r.toLowerCase()))) {
      return persona as PersonaType;
    }
  }
  return 'creative'; // Default
};

interface ProfileField {
  name: string;
  value: string;
  value_plain?: string;
}

interface ParsedProfile {
  role: string;
  persona: PersonaType;
  credits: { project: string; year?: string; role?: string }[];
  oneDay: string;
  dream: string;
  favorites: string[];
}

const parseProfileFields = (fields: ProfileField[]): ParsedProfile => {
  const profile: ParsedProfile = {
    role: '',
    persona: 'creative',
    credits: [],
    oneDay: '',
    dream: '',
    favorites: [],
  };

  fields.forEach(field => {
    const value = field.value_plain ?? field.value;
    
    switch (field.name.toLowerCase()) {
      case 'role':
      case 'profession':
        profile.role = value;
        profile.persona = getPersonaFromRole(value);
        break;
        
      case 'credits':
      case 'projects':
        try {
          const parsed = JSON.parse(value) as unknown;
          if (Array.isArray(parsed)) {
            profile.credits = parsed as { project: string; year?: string; role?: string }[];
          }
        } catch (error) {
          // Log parsing error in development
          if (process.env.NODE_ENV === 'development') {
            console.warn('Failed to parse credits JSON:', error);
            console.warn('Falling back to text parsing for value:', value);
          }
          // Try to parse as simple text list
          profile.credits = value.split(/[,\n]/).map(credit => ({
            project: credit.trim(),
          })).filter(c => c.project);
        }
        break;
        
      case 'one day':
      case 'oneday':
      case 'dream':
      case 'aspiration':
        if (field.name.toLowerCase().includes('one') || field.name.toLowerCase().includes('day')) {
          profile.oneDay = value;
        } else {
          profile.dream = value;
        }
        break;
        
      case 'favorites':
      case 'inspirations':
      case 'influences':
        try {
          const parsed = JSON.parse(value) as unknown;
          if (Array.isArray(parsed)) {
            profile.favorites = parsed as string[];
          }
        } catch (error) {
          // Log parsing error in development
          if (process.env.NODE_ENV === 'development') {
            console.warn('Failed to parse favorites JSON:', error);
            console.warn('Falling back to text parsing for value:', value);
          }
          profile.favorites = value.split(/[,\n]/).map(f => f.trim()).filter(Boolean);
        }
        break;
    }
  });

  return profile;
};

export const PersonaProfileDisplay: React.FC<{
  account: Account;
}> = ({ account }) => {
  // Convert Immutable List to array if needed
  const fields = account.fields.toArray ? account.fields.toArray() : [];
  const profile = parseProfileFields(fields as ProfileField[]);
  const PersonaIcon = PERSONA_CONFIGS[profile.persona].icon;
  const personaColor = PERSONA_CONFIGS[profile.persona].color;

  if (!profile.role) {
    return null; // Don't display if no role is set
  }

  return (
    <div className='persona-profile'>
      <div className='persona-profile__header'>
        <div 
          className='persona-profile__role'
          style={{ backgroundColor: personaColor }}
        >
          <Icon id={profile.persona} icon={PersonaIcon} />
          <span>{profile.role}</span>
        </div>
      </div>

      {profile.credits.length > 0 && (
        <div className='persona-profile__section'>
          <h4 className='persona-profile__section-title'>
            <Icon id='calendar' icon={ListAltIcon} />
            <FormattedMessage id='persona.credits' defaultMessage='Credits' />
          </h4>
          <div className='persona-profile__credits'>
            {profile.credits.map((credit, index) => (
              <div key={index} className='persona-profile__credit'>
                <span className='persona-profile__credit-project'>{credit.project}</span>
                {credit.year && (
                  <span className='persona-profile__credit-year'>{credit.year}</span>
                )}
                {credit.role && (
                  <span className='persona-profile__credit-role'>{credit.role}</span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {(profile.oneDay || profile.dream) && (
        <div className='persona-profile__section'>
          <h4 className='persona-profile__section-title'>
            <Icon id='rocket' icon={FlagIcon} />
            <FormattedMessage id='persona.aspirations' defaultMessage='Aspirations' />
          </h4>
          {profile.oneDay && (
            <div className='persona-profile__aspiration'>
              <strong>
                <FormattedMessage id='persona.one_day' defaultMessage='One Day' />:
              </strong>{' '}
              {profile.oneDay}
            </div>
          )}
          {profile.dream && (
            <div className='persona-profile__aspiration'>
              <strong>
                <FormattedMessage id='persona.dream' defaultMessage='Dream' />:
              </strong>{' '}
              {profile.dream}
            </div>
          )}
        </div>
      )}

      {profile.favorites.length > 0 && (
        <div className='persona-profile__section'>
          <h4 className='persona-profile__section-title'>
            <Icon id='favorite' icon={StarIcon} />
            <FormattedMessage id='persona.favorites' defaultMessage='Favorites & Inspirations' />
          </h4>
          <div className='persona-profile__favorites'>
            {profile.favorites.map((favorite, index) => (
              <span key={index} className='persona-profile__favorite'>
                {favorite}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};