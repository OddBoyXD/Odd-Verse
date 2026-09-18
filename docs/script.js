document.addEventListener('DOMContentLoaded', () => {
  // Mobile Dropdown Menu Toggle
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const mobileDropdown = document.getElementById('mobileDropdown');
  const mobileLinks = document.querySelectorAll('.mobile-link');

  if (mobileMenuBtn && mobileDropdown) {
    mobileMenuBtn.addEventListener('click', () => {
      const isOpen = mobileDropdown.classList.toggle('active');
      mobileMenuBtn.classList.toggle('active', isOpen);
    });

    mobileLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileDropdown.classList.remove('active');
        mobileMenuBtn.classList.remove('active');
      });
    });
  }

  // Interactive Player Mockup Scrubber & Play State
  const playBtn = document.getElementById('playBtn');
  const equalizer = document.getElementById('equalizer');
  const progressFill = document.getElementById('progressFill');
  const progressBar = document.getElementById('progressBar');
  const currentTime = document.getElementById('currentTime');

  let isPlaying = true;
  let currentSec = 78; // 01:18
  const totalSec = 225; // 03:45

  function formatTime(s) {
    const min = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${min < 10 ? '0' : ''}${min}:${sec < 10 ? '0' : ''}${sec}`;
  }

  setInterval(() => {
    if (isPlaying) {
      currentSec = (currentSec + 1) % totalSec;
      const pct = (currentSec / totalSec) * 100;
      if (progressFill) progressFill.style.width = `${pct}%`;
      if (currentTime) currentTime.textContent = formatTime(currentSec);
    }
  }, 1000);

  if (playBtn) {
    playBtn.addEventListener('click', () => {
      isPlaying = !isPlaying;
      playBtn.textContent = isPlaying ? '⏸' : '▶';
      if (equalizer) {
        const bars = equalizer.querySelectorAll('span');
        bars.forEach(b => {
          b.style.animationPlayState = isPlaying ? 'running' : 'paused';
        });
      }
    });
  }

  if (progressBar) {
    progressBar.addEventListener('click', (e) => {
      const rect = progressBar.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const pct = Math.max(0, Math.min(100, (clickX / rect.width) * 100));
      currentSec = Math.floor((pct / 100) * totalSec);
      if (progressFill) progressFill.style.width = `${pct}%`;
      if (currentTime) currentTime.textContent = formatTime(currentSec);
    });
  }

  // Live GitHub Releases Sync
  const repo = 'OddBoyXdxd69/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.tag_name) {
        const versionTag = document.querySelector('.version-tag');
        if (versionTag) versionTag.textContent = data.tag_name.replace(/^v/, '');

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
