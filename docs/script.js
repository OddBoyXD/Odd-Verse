document.addEventListener('DOMContentLoaded', () => {
  // Mobile Nav Dropdown Toggle
  const menuToggle = document.getElementById('menuToggle');
  const mobileNav = document.getElementById('mobileNav');
  const mobileItems = document.querySelectorAll('.mobile-item');

  if (menuToggle && mobileNav) {
    menuToggle.addEventListener('click', () => {
      mobileNav.classList.toggle('active');
    });

    mobileItems.forEach(item => {
      item.addEventListener('click', () => {
        mobileNav.classList.remove('active');
      });
    });
  }

  // Sync Download Links from Latest GitHub Release
  const repo = 'OddBoyXdxd69/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.assets && data.assets.length > 0) {
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
    })
    .catch(() => {});
});
