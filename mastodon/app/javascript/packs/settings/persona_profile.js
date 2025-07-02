import '../public-path';
import React from 'react';
import { createRoot } from 'react-dom/client';

import { IntlProvider } from 'react-intl';

import { PersonaProfileEditor } from 'mastodon/features/settings/persona_profile_editor';
import { getLocale, onProviderError } from 'mastodon/locales';
import { loadPolyfills } from 'mastodon/polyfills';
import ready from 'mastodon/ready';

import { start } from '../common';

start();

function loaded() {
  const mountNode = document.getElementById('persona-profile-editor');
  
  if (mountNode) {
    const locale = getLocale();
    const { messages } = locale;
    
    const root = createRoot(mountNode);
    root.render(
      <IntlProvider locale={locale.locale} messages={messages} onError={onProviderError}>
        <PersonaProfileEditor />
      </IntlProvider>
    );
  }
}

function main() {
  ready(loaded);
}

loadPolyfills()
  .then(main)
  .catch(error => {
    console.error(error);
  });