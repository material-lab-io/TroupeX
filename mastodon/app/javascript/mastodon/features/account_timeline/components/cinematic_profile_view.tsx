import { useMemo, useCallback } from 'react';

import { defineMessages, useIntl } from 'react-intl';

import classNames from 'classnames';

import BadgeIcon from '@/material-icons/400-24px/badge.svg?react';
import EditIcon from '@/material-icons/400-24px/edit.svg?react';
import MovieIcon from '@/material-icons/400-24px/movie.svg?react';
import PublicIcon from '@/material-icons/400-24px/public.svg?react';
import ShareIcon from '@/material-icons/400-24px/share.svg?react';
import StarIcon from '@/material-icons/400-24px/star.svg?react';
import { Icon } from 'mastodon/components/icon';
import { IconButton } from 'mastodon/components/icon_button';
import { me } from 'mastodon/initial_state';
import type { Account } from 'mastodon/models/account';

const messages = defineMessages({
  about: { id: 'cinematic_profile.about', defaultMessage: 'About' },
  experience: { id: 'cinematic_profile.experience', defaultMessage: 'Experience' },
  skills: { id: 'cinematic_profile.skills', defaultMessage: 'Skills' },
  achievements: { id: 'cinematic_profile.achievements', defaultMessage: 'Achievements' },
  inspirations: { id: 'cinematic_profile.inspirations', defaultMessage: 'Inspirations' },
  editProfile: { id: 'account.edit_profile', defaultMessage: 'Edit profile' },
  shareProfile: { id: 'account.share', defaultMessage: 'Share @{name}\'s profile' },
});

interface CinematicProfileViewProps {
  account: Account;
  isEditing?: boolean;
}

interface ParsedProfileData {
  title?: string;
  about?: string;
  experience?: string[];
  skills?: string[];
  achievements?: string[];
  inspirations?: string[];
}

// Parse bio text for structured data using special markers
const parseProfileData = (bio: string, fields: { name: string; value: string }[]): ParsedProfileData => {
  const data: ParsedProfileData = {};
  
  // Keep the full bio as about text
  data.about = bio;
  
  // Parse custom fields for structured data
  fields.forEach(field => {
    const name = field.name.toLowerCase();
    const value = field.value;
    
    if (name.includes('skill')) {
      data.skills = value.split(',').map(s => s.trim());
    } else if (name.includes('experience') || name.includes('work')) {
      data.experience = value.split('|').map(s => s.trim());
    } else if (name.includes('achievement')) {
      data.achievements = value.split('|').map(s => s.trim());
    } else if (name.includes('inspiration')) {
      data.inspirations = value.split('|').map(s => s.trim());
    }
  });
  
  return data;
};

export const CinematicProfileView: React.FC<CinematicProfileViewProps> = ({ account, isEditing }) => {
  const intl = useIntl();
  
  const profileData = useMemo(() => {
    const fieldsArray = account.fields?.toArray() || [];
    return parseProfileData(account.note_plain || '', fieldsArray);
  }, [account.note_plain, account.fields]);
  
  const displayName = account.display_name || account.username;
  const fieldsArray = account.fields?.toArray() || [];
  const location = fieldsArray.find(f => f.name.toLowerCase().includes('location'))?.value;
  
  const handleShare = useCallback(() => {
    if (navigator.share) {
      void navigator.share({
        title: `@${account.acct}`,
        text: intl.formatMessage(messages.shareProfile, { name: account.acct }),
        url: account.url,
      }).catch(() => {
        // User cancelled or share failed
      });
    } else {
      // Fallback to copying URL
      void navigator.clipboard.writeText(account.url);
    }
  }, [account.acct, account.url, intl]);
  
  return (
    <div className={classNames('cinematic-profile-view', { 'editing': isEditing })}>
      <div className='cinematic-profile-hero' style={{ backgroundImage: `url(${account.header})` }}>
        <div className='cinematic-profile-hero__overlay' />
        <div className='cinematic-profile-hero__content'>
          <div className='cinematic-profile-hero__info'>
            <h1 className='cinematic-profile-hero__name'>{displayName}</h1>
            {location && (
              <div className='cinematic-profile-hero__location'>
                <Icon id='location' icon={PublicIcon} />
                <span>{location}</span>
              </div>
            )}
            
            {/* Stats inline under name */}
            <div className='cinematic-profile-hero__stats'>
              <div className='cinematic-profile-stat'>
                <span className='cinematic-profile-stat__value'>{account.statuses_count}</span>
                <span className='cinematic-profile-stat__label'>Posts</span>
              </div>
              <div className='cinematic-profile-stat'>
                <span className='cinematic-profile-stat__value'>{account.followers_count}</span>
                <span className='cinematic-profile-stat__label'>Followers</span>
              </div>
              <div className='cinematic-profile-stat'>
                <span className='cinematic-profile-stat__value'>{account.following_count}</span>
                <span className='cinematic-profile-stat__label'>Following</span>
              </div>
            </div>
          </div>
          
          {/* Action buttons */}
          <div className='cinematic-profile-hero__actions'>
            {me === account.id ? (
              <a href='/settings/profile' className='cinematic-profile-action-btn' title={intl.formatMessage(messages.editProfile)}>
                <Icon id='edit' icon={EditIcon} />
              </a>
            ) : null}
            <IconButton
              className='cinematic-profile-action-btn'
              icon='share'
              iconComponent={ShareIcon}
              title={intl.formatMessage(messages.shareProfile, { name: account.acct })}
              onClick={handleShare}
            />
          </div>
        </div>
      </div>
      
      <div className='cinematic-profile-content'>
        {profileData.about && (
          <section className='cinematic-profile-section'>
            <h2 className='cinematic-profile-section__title'>
              {intl.formatMessage(messages.about)}
            </h2>
            <p className='cinematic-profile-section__content'>{profileData.about}</p>
          </section>
        )}
        
        {/* Custom fields from profile metadata */}
        {fieldsArray.length > 0 && fieldsArray.map((field, idx) => {
          if (!field.value || field.value.trim() === '') return null;
          return (
            <section key={idx} className='cinematic-profile-section'>
              <h2 className='cinematic-profile-section__title'>
                {field.name}
              </h2>
              <p className='cinematic-profile-section__content'>{field.value}</p>
            </section>
          );
        })}
        
        {profileData.experience && profileData.experience.length > 0 && (
          <section className='cinematic-profile-section'>
            <h2 className='cinematic-profile-section__title'>
              <Icon id='work' icon={BadgeIcon} />
              {intl.formatMessage(messages.experience)}
            </h2>
            <ul className='cinematic-profile-list'>
              {profileData.experience.map((exp, idx) => (
                <li key={idx} className='cinematic-profile-list__item'>{exp}</li>
              ))}
            </ul>
          </section>
        )}
        
        {profileData.skills && profileData.skills.length > 0 && (
          <section className='cinematic-profile-section'>
            <h2 className='cinematic-profile-section__title'>
              {intl.formatMessage(messages.skills)}
            </h2>
            <div className='cinematic-profile-tags'>
              {profileData.skills.map((skill, idx) => (
                <span key={idx} className='cinematic-profile-tag'>{skill}</span>
              ))}
            </div>
          </section>
        )}
        
        {profileData.achievements && profileData.achievements.length > 0 && (
          <section className='cinematic-profile-section'>
            <h2 className='cinematic-profile-section__title'>
              <Icon id='star' icon={StarIcon} />
              {intl.formatMessage(messages.achievements)}
            </h2>
            <ul className='cinematic-profile-list'>
              {profileData.achievements.map((achievement, idx) => (
                <li key={idx} className='cinematic-profile-list__item'>{achievement}</li>
              ))}
            </ul>
          </section>
        )}
        
        {profileData.inspirations && profileData.inspirations.length > 0 && (
          <section className='cinematic-profile-section'>
            <h2 className='cinematic-profile-section__title'>
              <Icon id='movie' icon={MovieIcon} />
              {intl.formatMessage(messages.inspirations)}
            </h2>
            <div className='cinematic-profile-inspirations'>
              {profileData.inspirations.map((inspiration, idx) => (
                <span key={idx} className='cinematic-profile-inspiration'>{inspiration}</span>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
};