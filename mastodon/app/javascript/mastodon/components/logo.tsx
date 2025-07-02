import wordmarkLogo from '@/images/logo-symbol-wordmark.svg';
import logo from '@/images/logo.svg';

export const WordmarkLogo: React.FC = () => (
  <img src={wordmarkLogo} alt='Mastodon' className='logo logo--wordmark' />
);

export const IconLogo: React.FC = () => (
  <svg viewBox='0 0 79 79' className='logo logo--icon' role='img'>
    <title>Mastodon</title>
    <use xlinkHref='#logo-symbol-icon' />
  </svg>
);

export const SymbolLogo: React.FC = () => (
  <img src={logo} alt='Mastodon' className='logo logo--icon' />
);
