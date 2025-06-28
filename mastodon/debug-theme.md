# LinkedIn-Style Theme Debugging Guide

## Issue
The LinkedIn-style theme changes aren't applying properly in light mode. Status cards are showing as black instead of white on gray background.

## What We've Done

1. **Updated CSS Variables** in `/app/javascript/styles/mastodon-light/css_variables.scss`:
   - Set `--background-color: #f3f2ef` (LinkedIn gray)
   - Set `--surface-background-color: #ffffff` (white cards)
   - Set `--surface-variant-background-color: #ffffff` (white cards)

2. **Added LinkedIn-style overrides** in `/app/javascript/styles/mastodon-light/diff.scss`:
   - Removed !important flags (they were being stripped during compilation)
   - Used higher specificity selectors
   - Applied white backgrounds to status cards, notifications, etc.

3. **Rebuilt assets** successfully:
   - New CSS file generated: `mastodon-light-DgWFMGMe.css`
   - Confirmed our styles are in the compiled CSS

## How to Debug in Browser

1. **Clear browser cache completely**:
   - Chrome: Ctrl+Shift+Del (or Cmd+Shift+Del on Mac)
   - Select "Cached images and files"
   - Clear data

2. **Check which theme is active**:
   - Go to Preferences > Appearance
   - Make sure "mastodon-light" (or "Light") theme is selected
   - Save changes

3. **Force reload the page**:
   - Ctrl+F5 (or Cmd+Shift+R on Mac)

4. **Inspect the CSS**:
   - Right-click on a status card
   - Select "Inspect Element"
   - Look for the `.status` class
   - Check the "Computed" tab to see which styles are being applied

5. **Check CSS variables**:
   - In DevTools Console, run:
   ```javascript
   getComputedStyle(document.body).getPropertyValue('--surface-variant-background-color')
   ```
   - Should return: `#ffffff`

## Troubleshooting

### If cards are still black:

1. **Check theme CSS is loaded**:
   - In DevTools Network tab, search for "mastodon-light"
   - Verify the CSS file is loaded and returns 200 status

2. **Check for inline styles**:
   - Some JavaScript might be applying inline styles
   - Look for `style=""` attributes on status elements

3. **Check CSS specificity**:
   - Our LinkedIn styles might be overridden by more specific selectors
   - Use DevTools to see which rules are winning

### Server-side fixes if needed:

1. **Clear Rails cache**:
   ```bash
   cd /home/kanaba/troupex4/mastodon
   RAILS_ENV=production bundle exec rails tmp:cache:clear
   ```

2. **Restart services**:
   ```bash
   sudo systemctl restart mastodon-web
   sudo systemctl restart mastodon-streaming
   ```

3. **Precompile assets in production**:
   ```bash
   cd /home/kanaba/troupex4/mastodon
   RAILS_ENV=production bundle exec rails assets:precompile
   ```

## Expected Result

When working correctly:
- Background should be light gray (#f3f2ef)
- Status cards should be white (#ffffff)
- Cards should have subtle borders and shadows
- LinkedIn-style professional appearance