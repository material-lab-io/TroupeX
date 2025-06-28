// Force white background on status cards for light theme
// This is a fallback in case CSS doesn't work

document.addEventListener('DOMContentLoaded', () => {
  const fixStatusCards = () => {
    const isLightTheme = document.body.classList.contains('theme-mastodon-light') || 
                        document.documentElement.getAttribute('data-theme') === 'mastodon-light';
    
    if (isLightTheme) {
      // Force white background on all status cards
      const statusCards = document.querySelectorAll('.status, .detailed-status, .notification, .account-card');
      statusCards.forEach(card => {
        card.style.backgroundColor = '#ffffff';
        card.style.background = '#ffffff';
      });
      
      // Force gray background on main areas
      const mainAreas = document.querySelectorAll('.columns-area, .scrollable');
      mainAreas.forEach(area => {
        area.style.backgroundColor = '#f3f2ef';
        area.style.background = '#f3f2ef';
      });
    }
  };
  
  // Run immediately
  fixStatusCards();
  
  // Run on any DOM changes
  const observer = new MutationObserver(fixStatusCards);
  observer.observe(document.body, { childList: true, subtree: true });
  
  // Run periodically as fallback
  setInterval(fixStatusCards, 1000);
});

export default {};