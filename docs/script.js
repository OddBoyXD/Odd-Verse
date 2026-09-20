/**
 * Odd Verse — Interactive Features & Responsiveness Controller
 * Ultra-Fast, Zero-Lag, 100% Error-Free
 * Author: OddBoyXD
 */

document.addEventListener('DOMContentLoaded', () => {
  /* ==========================================================================
     1. Mobile Slide Navigation
     ========================================================================== */
  const menuToggle = document.getElementById('menuToggle');
  const mobileNav = document.getElementById('mobileNav');
  const mobileItems = document.querySelectorAll('.mobile-item, .mobile-actions a');

  if (menuToggle && mobileNav) {
    const toggleMenu = (open) => {
      const isExpanded = open !== undefined ? open : menuToggle.getAttribute('aria-expanded') !== 'true';
      menuToggle.setAttribute('aria-expanded', isExpanded ? 'true' : 'false');
      if (isExpanded) {
        mobileNav.removeAttribute('hidden');
      } else {
        mobileNav.setAttribute('hidden', '');
      }
    };

    menuToggle.addEventListener('click', (e) => {
      e.stopPropagation();
      toggleMenu();
    });

    mobileItems.forEach(item => {
      item.addEventListener('click', () => {
        toggleMenu(false);
      });
    });

    // Close on outside click
    document.addEventListener('click', (e) => {
      if (!mobileNav.contains(e.target) && !menuToggle.contains(e.target)) {
        toggleMenu(false);
      }
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        toggleMenu(false);
      }
    });
  }

  /* ==========================================================================
     2. FAQ Smooth Accordion Handler
     ========================================================================== */
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    item.addEventListener('toggle', () => {
      if (item.open) {
        faqItems.forEach(other => {
          if (other !== item && other.open) {
            other.removeAttribute('open');
          }
        });
      }
    });
  });

  /* ==========================================================================
     3. GitHub Release Sync & Download Links
     ========================================================================== */
  const repo = 'OddBoyXD/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.assets && data.assets.length > 0) {
        data.assets.forEach(asset => {
          if (asset.name.includes('arm64-v8a')) {
            const el = document.querySelector('a[href*="arm64-v8a"]');
            if (el) el.href = asset.browser_download_url;
          } else if (asset.name.includes('universal')) {
            const el = document.querySelector('a[href*="universal"]');
            if (el) el.href = asset.browser_download_url;
          } else if (asset.name.includes('armeabi-v7a')) {
            const el = document.querySelector('a[href*="armeabi-v7a"]');
            if (el) el.href = asset.browser_download_url;
          } else if (asset.name.includes('x86_64')) {
            const el = document.querySelector('a[href*="x86_64"]');
            if (el) el.href = asset.browser_download_url;
          }
        });
      }
    })
    .catch(() => {
      // Fallback is already hardcoded to reliable direct v1.0.0 URLs in HTML
    });
});
