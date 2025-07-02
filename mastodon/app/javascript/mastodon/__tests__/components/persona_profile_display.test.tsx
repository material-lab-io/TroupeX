import { render, screen } from '@testing-library/react';

import { IntlProvider } from 'react-intl';

import { PersonaProfileDisplay } from '@/mastodon/components/persona_profile_display';
import type { Account } from '@/mastodon/models/account';

// Mock account factory
const createMockAccount = (fields: Array<{ name: string; value: string; value_plain?: string }>): Account => ({
  id: '1',
  username: 'testuser',
  display_name: 'Test User',
  avatar: '/test-avatar.jpg',
  avatar_static: '/test-avatar-static.jpg',
  fields: {
    toArray: () => fields,
  },
} as unknown as Account);

describe('PersonaProfileDisplay', () => {
  const renderWithIntl = (component: React.ReactElement) => {
    return render(
      <IntlProvider locale='en'>
        {component}
      </IntlProvider>
    );
  };

  it('should not render when no role is set', () => {
    const account = createMockAccount([]);
    const { container } = renderWithIntl(
      <PersonaProfileDisplay account={account} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('should render creative persona for actor role', () => {
    const account = createMockAccount([
      { name: 'Role', value: 'Actor', value_plain: 'Actor' },
    ]);
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    expect(screen.getByText('Actor')).toBeInTheDocument();
    const roleElement = screen.getByText('Actor').closest('.persona-profile__role');
    expect(roleElement).toHaveStyle({ backgroundColor: 'rgb(233, 30, 99)' });
  });

  it('should render technical persona for cinematographer role', () => {
    const account = createMockAccount([
      { name: 'Role', value: 'Cinematographer', value_plain: 'Cinematographer' },
    ]);
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    expect(screen.getByText('Cinematographer')).toBeInTheDocument();
    const roleElement = screen.getByText('Cinematographer').closest('.persona-profile__role');
    expect(roleElement).toHaveStyle({ backgroundColor: 'rgb(33, 150, 243)' });
  });

  it('should parse and display credits correctly', () => {
    const credits = [
      { project: 'Test Movie', year: '2023', role: 'Lead Actor' },
      { project: 'Another Film', year: '2022' },
    ];
    
    const account = createMockAccount([
      { name: 'Role', value: 'Actor', value_plain: 'Actor' },
      { name: 'Credits', value: JSON.stringify(credits), value_plain: JSON.stringify(credits) },
    ]);
    
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    expect(screen.getByText('Test Movie')).toBeInTheDocument();
    expect(screen.getByText('2023')).toBeInTheDocument();
    expect(screen.getByText('Lead Actor')).toBeInTheDocument();
    expect(screen.getByText('Another Film')).toBeInTheDocument();
    expect(screen.getByText('2022')).toBeInTheDocument();
  });

  it('should handle malformed JSON gracefully', () => {
    const account = createMockAccount([
      { name: 'Role', value: 'Director', value_plain: 'Director' },
      { name: 'Credits', value: 'Movie 1, Movie 2, Movie 3', value_plain: 'Movie 1, Movie 2, Movie 3' },
    ]);
    
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    expect(screen.getByText('Movie 1')).toBeInTheDocument();
    expect(screen.getByText('Movie 2')).toBeInTheDocument();
    expect(screen.getByText('Movie 3')).toBeInTheDocument();
  });

  it('should display aspirations section when one day or dream is set', () => {
    const account = createMockAccount([
      { name: 'Role', value: 'Producer', value_plain: 'Producer' },
      { name: 'One Day', value: 'Win an Oscar', value_plain: 'Win an Oscar' },
      { name: 'Dream', value: 'Create meaningful cinema', value_plain: 'Create meaningful cinema' },
    ]);
    
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    expect(screen.getByText(/Win an Oscar/)).toBeInTheDocument();
    expect(screen.getByText(/Create meaningful cinema/)).toBeInTheDocument();
  });

  it('should display favorites as tags', () => {
    const favorites = ['Hitchcock', 'Kubrick', 'Scorsese'];
    const account = createMockAccount([
      { name: 'Role', value: 'Editor', value_plain: 'Editor' },
      { name: 'Favorites', value: JSON.stringify(favorites), value_plain: JSON.stringify(favorites) },
    ]);
    
    renderWithIntl(<PersonaProfileDisplay account={account} />);
    
    favorites.forEach(favorite => {
      expect(screen.getByText(favorite)).toBeInTheDocument();
    });
  });
});