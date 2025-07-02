import { render, screen, fireEvent } from '@testing-library/react';

import { IntlProvider } from 'react-intl';

import { ProfilePhotoCarousel } from '@/mastodon/components/profile_photo_carousel';
import type { Account } from '@/mastodon/models/account';

// Mock account factory
const createMockAccount = (carouselPhotos?: Array<{ url: string; description?: string }>): Account => ({
  id: '1',
  username: 'testuser',
  display_name: 'Test User',
  avatar: '/test-avatar.jpg',
  avatar_static: '/test-avatar-static.jpg',
  fields: carouselPhotos ? [
    {
      name: 'carousel_photos',
      value: JSON.stringify(carouselPhotos),
      value_plain: JSON.stringify(carouselPhotos),
    }
  ] : [],
} as unknown as Account);

describe('ProfilePhotoCarousel', () => {
  const renderWithIntl = (component: React.ReactElement) => {
    return render(
      <IntlProvider locale='en'>
        {component}
      </IntlProvider>
    );
  };

  it('should render single photo in frame mode', () => {
    const account = createMockAccount();
    const { container } = renderWithIntl(
      <ProfilePhotoCarousel account={account} displayMode='frame' />
    );
    
    const carousel = container.querySelector('.profile-photo-carousel--frame');
    expect(carousel).toBeInTheDocument();
    
    const img = screen.getByRole('img');
    expect(img).toHaveAttribute('src', '/test-avatar.jpg');
    expect(img).toHaveAttribute('alt', 'Test User');
  });

  it('should render edit overlay when editable', () => {
    const account = createMockAccount();
    const { container } = renderWithIntl(
      <ProfilePhotoCarousel account={account} editable displayMode='frame' />
    );
    
    const editOverlay = container.querySelector('.profile-photo-carousel__edit-overlay');
    expect(editOverlay).toBeInTheDocument();
  });

  it('should handle click events', () => {
    const account = createMockAccount();
    const handleClick = vi.fn();
    
    renderWithIntl(
      <ProfilePhotoCarousel 
        account={account} 
        editable
        onPhotoClick={handleClick}
        displayMode='frame'
      />
    );
    
    const photoElement = screen.getByRole('button');
    fireEvent.click(photoElement);
    
    expect(handleClick).toHaveBeenCalledWith(0);
  });

  it('should handle keyboard navigation', () => {
    const account = createMockAccount();
    const handleClick = vi.fn();
    
    renderWithIntl(
      <ProfilePhotoCarousel 
        account={account} 
        editable
        onPhotoClick={handleClick}
        displayMode='frame'
      />
    );
    
    const photoElement = screen.getByRole('button');
    
    // Test Enter key
    fireEvent.keyDown(photoElement, { key: 'Enter' });
    expect(handleClick).toHaveBeenCalledWith(0);
    
    // Test Space key
    vi.clearAllMocks();
    fireEvent.keyDown(photoElement, { key: ' ' });
    expect(handleClick).toHaveBeenCalledWith(0);
  });

  it('should render multiple photos in carousel mode', () => {
    const carouselPhotos = [
      { url: '/photo1.jpg', description: 'Photo 1' },
      { url: '/photo2.jpg', description: 'Photo 2' },
    ];
    
    const account = createMockAccount(carouselPhotos);
    const { container } = renderWithIntl(
      <ProfilePhotoCarousel account={account} displayMode='circle' />
    );
    
    // Should have 3 photos total (avatar + 2 carousel photos)
    const indicators = container.querySelectorAll('.profile-photo-carousel__indicator');
    expect(indicators).toHaveLength(3);
    
    // Should show navigation controls
    const prevButton = screen.getByLabelText('Previous photo');
    const nextButton = screen.getByLabelText('Next photo');
    expect(prevButton).toBeInTheDocument();
    expect(nextButton).toBeInTheDocument();
  });

  it('should navigate between photos', () => {
    const carouselPhotos = [
      { url: '/photo1.jpg', description: 'Photo 1' },
      { url: '/photo2.jpg', description: 'Photo 2' },
    ];
    
    const account = createMockAccount(carouselPhotos);
    const { container } = renderWithIntl(
      <ProfilePhotoCarousel account={account} displayMode='circle' />
    );
    
    const nextButton = screen.getByLabelText('Next photo');
    
    // Check initial state
    let activeIndicator = container.querySelector('.profile-photo-carousel__indicator--active');
    expect(activeIndicator).toBe(container.querySelectorAll('.profile-photo-carousel__indicator')[0]);
    
    // Click next
    fireEvent.click(nextButton);
    
    // Check that second indicator is now active
    activeIndicator = container.querySelector('.profile-photo-carousel__indicator--active');
    expect(activeIndicator).toBe(container.querySelectorAll('.profile-photo-carousel__indicator')[1]);
  });

  it('should handle invalid carousel data gracefully', () => {
    const account = {
      ...createMockAccount(),
      fields: [
        {
          name: 'carousel_photos',
          value: 'invalid json',
          value_plain: 'invalid json',
        }
      ],
    } as unknown as Account;
    
    const { container } = renderWithIntl(
      <ProfilePhotoCarousel account={account} displayMode='frame' />
    );
    
    // Should still render with just the avatar
    const img = screen.getByRole('img');
    expect(img).toHaveAttribute('src', '/test-avatar.jpg');
  });

  it('should add loading state attributes', () => {
    const account = createMockAccount();
    renderWithIntl(
      <ProfilePhotoCarousel account={account} displayMode='frame' />
    );
    
    const img = screen.getByRole('img');
    expect(img).toHaveAttribute('loading', 'lazy');
    expect(img).toHaveAttribute('sizes', '(max-width: 767px) 90vw, 800px');
  });
});