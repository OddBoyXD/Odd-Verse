document.addEventListener('DOMContentLoaded', () => {
  // Mobile Navigation Toggle
  const mobileBtn = document.getElementById('mobileMenuBtn');
  const mobileMenu = document.getElementById('mobileMenu');
  const mobileLinks = document.querySelectorAll('.mobile-nav-link');

  if (mobileBtn && mobileMenu) {
    mobileBtn.addEventListener('click', () => {
      mobileMenu.classList.toggle('active');
    });

    mobileLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileMenu.classList.remove('active');
      });
    });
  }

  // Dynamic GitHub Release Synchronizer
  const repo = 'OddBoyXdxd69/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.tag_name) {
        const brandVersion = document.querySelector('.brand-version');
        if (brandVersion) brandVersion.textContent = data.tag_name;

        if (data.assets && data.assets.length > 0) {
          data.assets.forEach(asset => {
            if (asset.name.includes('arm64-v8a')) {
              const el = document.querySelector('a[href*="arm64-v8a"]');
              if (el) el.href = asset.browser_download_url;
            } else if (asset.name.includes('armeabi-v7a')) {
              const el = document.querySelector('a[href*="armeabi-v7a"]');
              if (el) el.href = asset.browser_download_url;
            } else if (asset.name.includes('x86_64')) {
              const el = document.querySelector('a[href*="x86_64"]');
              if (el) el.href = asset.browser_download_url;
            } else if (asset.name.includes('universal')) {
              const el = document.querySelector('a[href*="universal"]');
              if (el) el.href = asset.browser_download_url;
            }
          });
        }
      }
    })
    .catch(() => {});
});
