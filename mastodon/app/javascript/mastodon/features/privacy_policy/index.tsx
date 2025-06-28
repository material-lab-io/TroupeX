import { useState, useEffect } from 'react';

import { FormattedMessage, useIntl, defineMessages } from 'react-intl';

import { Helmet } from 'react-helmet';

import { apiGetPrivacyPolicy } from 'mastodon/api/instance';
import type { ApiPrivacyPolicyJSON } from 'mastodon/api_types/instance';
import { Column } from 'mastodon/components/column';
import { FormattedDateWrapper } from 'mastodon/components/formatted_date';
import { Skeleton } from 'mastodon/components/skeleton';

const messages = defineMessages({
  title: { id: 'privacy_policy.title', defaultMessage: 'Privacy Policy' },
});

const PrivacyPolicy: React.FC<{
  multiColumn: boolean;
}> = ({ multiColumn }) => {
  const intl = useIntl();

  const troupePrivacyContent = `
    <div style="max-width: 800px; margin: 0 auto; padding: 20px; color: #e0e0e0;">
      <h1 style="color: #d4af37; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;">Troupe Privacy Policy</h1>
      <p style="opacity: 0.8; margin-bottom: 30px;">Last updated: June 28, 2025</p>
      
      <h2 style="color: #ffffff; margin-top: 30px;">Your Privacy Matters</h2>
      <p>At Troupe, we respect your privacy and are committed to protecting your personal data. This privacy policy explains how we handle your information when you use our platform.</p>
      
      <h2 style="color: #ffffff; margin-top: 30px;">What We Collect</h2>
      <ul>
        <li>Account information (username, email, profile data)</li>
        <li>Content you create (posts, media, interactions)</li>
        <li>Technical data (IP address, browser type, device info)</li>
      </ul>
      
      <h2 style="color: #ffffff; margin-top: 30px;">How We Use Your Data</h2>
      <ul>
        <li>To provide and improve our services</li>
        <li>To communicate with you about your account</li>
        <li>To ensure platform safety and security</li>
        <li>To comply with legal obligations</li>
      </ul>
      
      <h2 style="color: #ffffff; margin-top: 30px;">Data Sharing</h2>
      <p>We do not sell your personal data. We only share your information:</p>
      <ul>
        <li>With your explicit consent</li>
        <li>To comply with legal requirements</li>
        <li>To protect our rights and safety</li>
      </ul>
      
      <h2 style="color: #ffffff; margin-top: 30px;">Your Rights</h2>
      <p>You have the right to:</p>
      <ul>
        <li>Access your personal data</li>
        <li>Correct inaccurate data</li>
        <li>Delete your account and data</li>
        <li>Export your data</li>
        <li>Object to certain processing</li>
      </ul>
      
      <h2 style="color: #ffffff; margin-top: 30px;">Contact Us</h2>
      <p>For privacy-related questions, please contact us through the platform's support channels.</p>
      
      <p style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #2a2a2a; opacity: 0.8;">
        Troupe is built on open-source technology with privacy by design.
      </p>
    </div>
  `;

  return (
    <Column
      bindToDocument={!multiColumn}
      label={intl.formatMessage(messages.title)}
    >
      <div className='scrollable privacy-policy' style={{ background: '#000000' }}>
        <div
          className='privacy-policy__body'
          dangerouslySetInnerHTML={{ __html: troupePrivacyContent }}
        />
      </div>

      <Helmet>
        <title>Troupe - Privacy Policy</title>
        <meta name='robots' content='all' />
      </Helmet>
    </Column>
  );
};

// eslint-disable-next-line import/no-default-export
export default PrivacyPolicy;
