import {
  useCallback,
  useRef,
  useState,
  useId,
} from 'react';

import { defineMessages, useIntl } from 'react-intl';

import classNames from 'classnames';
import { animated, useSpring } from '@react-spring/web';
import { useDrag } from '@use-gesture/react';

import { Avatar } from '@/mastodon/components/avatar';
import { Icon } from '@/mastodon/components/icon';
import { IconButton } from '@/mastodon/components/icon_button';
import AddPhotoAlternateIcon from '@/material-icons/400-24px/add_photo_alternate.svg?react';
import ChevronLeftIcon from '@/material-icons/400-24px/chevron_left.svg?react';
import ChevronRightIcon from '@/material-icons/400-24px/chevron_right.svg?react';
import { autoPlayGif } from 'mastodon/initial_state';
import type { Account } from 'mastodon/models/account';

const messages = defineMessages({
  previous: { id: 'profile_carousel.previous', defaultMessage: 'Previous photo' },
  next: { id: 'profile_carousel.next', defaultMessage: 'Next photo' },
  slide: {
    id: 'profile_carousel.slide',
    defaultMessage: 'Photo {index} of {total}',
  },
  editPhoto: { id: 'profile.photo.edit', defaultMessage: 'Edit profile photo' },
  viewPhoto: { id: 'profile.photo.view', defaultMessage: 'View profile photo' },
  carousel: { id: 'profile.photo.carousel', defaultMessage: 'Profile photo carousel' },
});

interface ProfilePhoto {
  url: string;
  thumbnail?: string;
  description?: string;
  srcSet?: string;
}

export const ProfilePhotoCarousel: React.FC<{
  account: Account;
  editable?: boolean;
  onPhotoClick?: (index: number) => void;
  displayMode?: 'circle' | 'frame';
}> = ({ account, editable = false, onPhotoClick, displayMode = 'circle' }) => {
  const intl = useIntl();
  const accessibilityId = useId();

  // Extract carousel photos from fields
  const carouselField = account.fields.find(field => field.name === 'carousel_photos');
  const photos: ProfilePhoto[] = [];
  
  // Always include the main avatar as the first photo
  photos.push({
    url: account.avatar,
    thumbnail: account.avatar_static,
    description: account.display_name,
  });

  // Add additional photos from the carousel field if present
  if (carouselField && carouselField.value) {
    try {
      const additionalPhotos = JSON.parse(carouselField.value_plain ?? carouselField.value) as unknown;
      if (Array.isArray(additionalPhotos)) {
        photos.push(...(additionalPhotos as ProfilePhoto[]));
      }
    } catch {
      // Invalid JSON, ignore
    }
  }

  // Handle slide change
  const [slideIndex, setSlideIndex] = useState(0);
  const [imageLoading, setImageLoading] = useState(true);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const handleSlideChange = useCallback(
    (direction: number) => {
      setSlideIndex((prev) => {
        const max = photos.length - 1;
        let newIndex = prev + direction;
        if (newIndex < 0) {
          newIndex = max;
        } else if (newIndex > max) {
          newIndex = 0;
        }
        return newIndex;
      });
    },
    [photos.length],
  );

  // Handle swiping animations
  const bind = useDrag(({ swipe: [swipeX] }) => {
    handleSlideChange(swipeX * -1); // Invert swipe as swiping left loads the next slide.
  });
  
  const handlePrev = useCallback(() => {
    handleSlideChange(-1);
  }, [handleSlideChange]);
  
  const handleNext = useCallback(() => {
    handleSlideChange(1);
  }, [handleSlideChange]);

  const handlePhotoClick = useCallback(() => {
    if (onPhotoClick) {
      onPhotoClick(slideIndex);
    }
  }, [onPhotoClick, slideIndex]);
  
  const handleImageLoad = useCallback(() => {
    setImageLoading(false);
  }, []);
  
  const handleImageError = useCallback(() => {
    setImageLoading(false);
  }, []);

  // Animation for slide transitions
  const slideStyles = useSpring({
    transform: `translateX(-${slideIndex * 100}%)`,
    config: { tension: 200, friction: 25 },
  });

  // Single photo mode - just show avatar
  if (photos.length === 1) {
    if (displayMode === 'frame') {
      return (
        <div className='profile-photo-carousel profile-photo-carousel--single profile-photo-carousel--frame'>
          <div 
            className={classNames('profile-photo-carousel__photo', {
              'profile-photo-carousel__photo--loading': imageLoading,
            })}
            onClick={handlePhotoClick}
            onKeyDown={(e) => { 
              if (e.key === 'Enter' || e.key === ' ') {
                handlePhotoClick();
              }
            }}
            role={editable ? 'button' : undefined}
            tabIndex={editable ? 0 : undefined}
            aria-label={editable ? intl.formatMessage(messages.editPhoto) : intl.formatMessage(messages.viewPhoto)}
          >
            <img
              src={autoPlayGif ? photos[0]?.url : (photos[0]?.thumbnail ?? photos[0]?.url)}
              srcSet={photos[0]?.srcSet}
              sizes="(max-width: 767px) 90vw, 800px"
              alt={photos[0]?.description ?? ''}
              className='profile-photo-carousel__frame-image'
              loading="lazy"
              onLoad={handleImageLoad}
              onError={handleImageError}
            />
            {imageLoading && (
              <div className='profile-photo-carousel__loading'>
                <div className='profile-photo-carousel__loading-spinner' />
              </div>
            )}
            {editable && (
              <div className='profile-photo-carousel__edit-overlay'>
                <Icon id='camera' icon={AddPhotoAlternateIcon} />
              </div>
            )}
          </div>
        </div>
      );
    }
    
    return (
      <div className='profile-photo-carousel profile-photo-carousel--single'>
        <div 
          className='profile-photo-carousel__photo'
          onClick={handlePhotoClick}
          onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handlePhotoClick(); }}
          role={editable ? 'button' : undefined}
          tabIndex={editable ? 0 : undefined}
          aria-label={editable ? intl.formatMessage(messages.editPhoto) : intl.formatMessage(messages.viewPhoto)}
        >
          <Avatar
            account={account}
            size={120}
          />
          {editable && (
            <div className='profile-photo-carousel__edit-overlay'>
              <Icon id='camera' icon={AddPhotoAlternateIcon} />
            </div>
          )}
        </div>
      </div>
    );
  }

  // Multi-photo carousel mode
  return (
    <div
      className='profile-photo-carousel'
      {...bind()}
      aria-roledescription='carousel'
      aria-label={intl.formatMessage(messages.carousel)}
      role='region'
    >
      <div className='profile-photo-carousel__container'>
        <animated.div
          className='profile-photo-carousel__slides'
          ref={wrapperRef}
          style={slideStyles}
          aria-atomic='false'
          aria-live='polite'
        >
          {photos.map((photo, index) => (
            <div
              key={index}
              className='profile-photo-carousel__slide'
              aria-label={intl.formatMessage(messages.slide, {
                index: index + 1,
                total: photos.length,
              })}
              onClick={handlePhotoClick}
              onKeyDown={(e) => { 
              if (e.key === 'Enter' || e.key === ' ') {
                handlePhotoClick();
              }
            }}
              role={editable ? 'button' : undefined}
              tabIndex={editable && index === slideIndex ? 0 : undefined}
              aria-label={editable ? intl.formatMessage(messages.editPhoto) : photo.description || intl.formatMessage(messages.viewPhoto)}
              aria-hidden={index !== slideIndex ? 'true' : undefined}
            >
              <img
                src={autoPlayGif ? photo.url : (photo.thumbnail ?? photo.url)}
                srcSet={photo.srcSet}
                sizes="(max-width: 767px) 100px, 120px"
                alt={photo.description ?? ''}
                className='profile-photo-carousel__image'
                loading="lazy"
              />
              {editable && index === slideIndex && (
                <div className='profile-photo-carousel__edit-overlay'>
                  <Icon id='camera' icon={AddPhotoAlternateIcon} />
                </div>
              )}
            </div>
          ))}
        </animated.div>

        <div className='profile-photo-carousel__controls'>
          <IconButton
            title={intl.formatMessage(messages.previous)}
            icon='chevron-left'
            iconComponent={ChevronLeftIcon}
            onClick={handlePrev}
            className='profile-photo-carousel__nav profile-photo-carousel__nav--prev'
          />
          
          <div className='profile-photo-carousel__indicators'>
            {photos.map((_, index) => (
              <button
                key={index}
                className={`profile-photo-carousel__indicator ${
                  index === slideIndex ? 'profile-photo-carousel__indicator--active' : ''
                }`}
                onClick={() => { setSlideIndex(index); }}
                aria-label={intl.formatMessage(messages.slide, {
                  index: index + 1,
                  total: photos.length,
                })}
              />
            ))}
          </div>

          <IconButton
            title={intl.formatMessage(messages.next)}
            icon='chevron-right'
            iconComponent={ChevronRightIcon}
            onClick={handleNext}
            className='profile-photo-carousel__nav profile-photo-carousel__nav--next'
          />
        </div>
      </div>
    </div>
  );
};