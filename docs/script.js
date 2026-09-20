/**
 * Odd Verse — Official Website Interactive Engine
 * GitHub API Release Fetcher, Screenshot Switcher, FAQ Accordion & Analytics
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Fetch Latest GitHub Release Details
  fetchLatestRelease();

  // 2. Interactive Screenshot Tabs
  initScreenshotTabs();

  // 3. FAQ Accordion Logic
  initFaqAccordion();

  // 4. Copy to Clipboard Utility
  initCopyButtons();

  // 5. Sticky Navbar Blur Enhancement
  initNavbarScroll();
});

/**
 * Fetch latest release stats and update download tags
 */
async function fetchLatestRelease() {
  const versionElement = document.getElementById('announce-version');
  const releaseCountElement = document.getElementById('total-downloads');

  try {
    const response = await fetch('https://api.github.com/repos/OddBoyXD/Odd-Verse/releases/latest');
    if (!response.ok) return;

    const data = await response.json();
    if (data.tag_name && versionElement) {
      versionElement.textContent = data.tag_name;
    }

    // Calculate total download count if element exists
    if (data.assets && releaseCountElement) {
      const totalDownloads = data.assets.reduce((sum, asset) => sum + (asset.download_count || 0), 0);
      if (totalDownloads > 0) {
        releaseCountElement.textContent = `${totalDownloads.toLocaleString()}+ Downloads`;
      }
    }
  } catch (error) {
    console.debug('Using fallback release metadata:', error);
  }
}

/**
 * Screenshot Showcase Tab Switcher
 */
function initScreenshotTabs() {
  const tabButtons = document.querySelectorAll('.tab-btn');
  const phoneImages = document.querySelectorAll('.phone-frame');

  if (!tabButtons.length || !phoneImages.length) return;

  tabButtons.forEach((btn, index) => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const targetCategory = btn.getAttribute('data-tab');
      phoneImages.forEach((img, imgIndex) => {
        if (targetCategory === 'all') {
          img.style.display = 'block';
        } else if (btn.getAttribute('data-index') !== null) {
          const activeIndex = parseInt(btn.getAttribute('data-index'), 10);
          img.style.display = imgIndex === activeIndex ? 'block' : 'none';
        }
      });
    });
  });
}

/**
 * Interactive FAQ Accordions
 */
function initFaqAccordion() {
  const faqItems = document.querySelectorAll('.faq-item');

  faqItems.forEach(item => {
    const question = item.querySelector('.faq-question');
    const answer = item.querySelector('.faq-answer');

    if (!question || !answer) return;

    question.addEventListener('click', () => {
      const isOpen = item.classList.contains('active');

      // Close all other accordions
      faqItems.forEach(otherItem => {
        otherItem.classList.remove('active');
        const otherAnswer = otherItem.querySelector('.faq-answer');
        if (otherAnswer) otherAnswer.style.maxHeight = null;
      });

      // Toggle current accordion
      if (!isOpen) {
        item.classList.add('active');
        answer.style.maxHeight = `${answer.scrollHeight + 30}px`;
      } else {
        item.classList.remove('active');
        answer.style.maxHeight = null;
      }
    });
  });
}

/**
 * 1-Click Copy Buttons
 */
function initCopyButtons() {
  const copyButtons = document.querySelectorAll('.btn-copy');

  copyButtons.forEach(button => {
    button.addEventListener('click', async () => {
      const textToCopy = button.getAttribute('data-copy');
      if (!textToCopy) return;

      try {
        await navigator.clipboard.writeText(textToCopy);
        const originalText = button.innerHTML;
        button.innerHTML = '<span>✓ Copied!</span>';
        button.classList.add('copied');

        setTimeout(() => {
          button.innerHTML = originalText;
          button.classList.remove('copied');
        }, 2000);
      } catch (err) {
        console.error('Failed to copy text:', err);
      }
    });
  });
}

/**
 * Sticky Navbar Blur Effect
 */
function initNavbarScroll() {
  const header = document.querySelector('.site-header');
  if (!header) return;

  window.addEventListener('scroll', () => {
    if (window.scrollY > 30) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  });
}
