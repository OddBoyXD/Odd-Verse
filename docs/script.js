/**
 * Odd Verse — Interactive Features & Responsiveness Controller
 * Fast, Lightweight, and Error-Free
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
     2. Interactive Soundstage Player Simulator
     ========================================================================== */
  const playPauseBtn = document.getElementById('playPauseBtn');
  const playIcon = document.getElementById('playIcon');
  const pauseIcon = document.getElementById('pauseIcon');
  const audioVisualizer = document.getElementById('audioVisualizer');
  const progressBarFill = document.getElementById('progressBarFill');
  const progressBarBg = document.getElementById('progressBarBg');
  const timeElapsed = document.getElementById('timeElapsed');
  const translitBtn = document.getElementById('translitBtn');
  const translitLabel = document.getElementById('translitLabel');
  const currentLyric = document.getElementById('currentLyric');
  const subLyric = document.getElementById('subLyric');
  const prevTrackBtn = document.getElementById('prevTrackBtn');
  const nextTrackBtn = document.getElementById('nextTrackBtn');

  let isPlaying = true;
  let progressPercent = 42;
  let elapsedSeconds = 84;
  const totalSeconds = 200;
  let progressTimer = null;

  const tracks = [
    {
      title: "Chaleya (Precision Stream)",
      artist: "Anirudh Ravichander, Arijit Singh • Odd Verse Engine",
      lyricLatin: '"Ishq mein dil bana hai, ishq mein dil fana hai"',
      lyricNative: "(इश्क़ में दिल बना है, इश्क़ में दिल फ़ना है)",
      badge: "150ms START"
    },
    {
      title: "Starboy (Lossless Master)",
      artist: "The Weeknd, Daft Punk • Odd Verse Engine",
      lyricLatin: '"Look what you\'ve done, I\'m a motherf***in\' starboy"',
      lyricNative: "(Hardware DAC 24-bit/48kHz Direct Render)",
      badge: "FLAC LOSSLESS"
    },
    {
      title: "Pasoori (Synced Indic)",
      artist: "Ali Sethi, Shae Gill • Odd Verse Engine",
      lyricLatin: '"Agg laavan majboori nu, aan jaan di pasoori nu"',
      lyricNative: "(ਅੱਗ ਲਾਵਾਂ ਮਜਬੂਰੀ ਨੂੰ, ਆਣ ਜਾਣ ਦੀ ਪਸੂਰੀ ਨੂੰ)",
      badge: "GURMUKHI SYNC"
    }
  ];
  let currentTrackIdx = 0;

  const formatTime = (secs) => {
    const m = Math.floor(secs / 60).toString().padStart(2, '0');
    const s = Math.floor(secs % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const updatePlayState = (playing) => {
    isPlaying = playing;
    if (isPlaying) {
      if (playIcon) playIcon.style.display = 'none';
      if (pauseIcon) pauseIcon.style.display = 'block';
      if (audioVisualizer) audioVisualizer.classList.remove('paused');
      startProgressTimer();
    } else {
      if (playIcon) playIcon.style.display = 'block';
      if (pauseIcon) pauseIcon.style.display = 'none';
      if (audioVisualizer) audioVisualizer.classList.add('paused');
      clearInterval(progressTimer);
    }
  };

  const startProgressTimer = () => {
    clearInterval(progressTimer);
    progressTimer = setInterval(() => {
      elapsedSeconds = (elapsedSeconds + 1) % totalSeconds;
      progressPercent = (elapsedSeconds / totalSeconds) * 100;
      if (progressBarFill) progressBarFill.style.width = `${progressPercent}%`;
      if (timeElapsed) timeElapsed.textContent = formatTime(elapsedSeconds);
    }, 1000);
  };

  if (playPauseBtn) {
    playPauseBtn.addEventListener('click', () => {
      updatePlayState(!isPlaying);
    });
    // Start playback simulation on load
    updatePlayState(true);
  }

  // Seeking on progress bar click
  if (progressBarBg) {
    progressBarBg.addEventListener('click', (e) => {
      const rect = progressBarBg.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const ratio = Math.max(0, Math.min(1, clickX / rect.width));
      elapsedSeconds = Math.floor(ratio * totalSeconds);
      progressPercent = ratio * 100;
      if (progressBarFill) progressBarFill.style.width = `${progressPercent}%`;
      if (timeElapsed) timeElapsed.textContent = formatTime(elapsedSeconds);
    });
  }

  // Indic Transliteration Toggle Simulation
  let translitActive = true;
  if (translitBtn && currentLyric && subLyric) {
    translitBtn.addEventListener('click', () => {
      translitActive = !translitActive;
      const track = tracks[currentTrackIdx];
      currentLyric.style.opacity = '0';
      subLyric.style.opacity = '0';

      setTimeout(() => {
        if (translitActive) {
          translitLabel.textContent = "Indic Translit: ON";
          currentLyric.textContent = track.lyricLatin;
          subLyric.textContent = track.lyricNative;
        } else {
          translitLabel.textContent = "Indic Translit: OFF";
          currentLyric.textContent = track.lyricNative;
          subLyric.textContent = track.lyricLatin;
        }
        currentLyric.style.opacity = '1';
        subLyric.style.opacity = '1';
      }, 150);
    });
  }

  // Track Next / Prev Switchers
  const loadTrack = (idx) => {
    currentTrackIdx = (idx + tracks.length) % tracks.length;
    const track = tracks[currentTrackIdx];
    const titleEl = document.getElementById('trackTitle');
    const artistEl = document.getElementById('trackArtist');
    const badgeEl = document.getElementById('trackBadge');

    if (titleEl) titleEl.textContent = track.title;
    if (artistEl) artistEl.textContent = track.artist;
    if (badgeEl) badgeEl.textContent = track.badge;

    if (currentLyric && subLyric) {
      if (translitActive) {
        currentLyric.textContent = track.lyricLatin;
        subLyric.textContent = track.lyricNative;
      } else {
        currentLyric.textContent = track.lyricNative;
        subLyric.textContent = track.lyricLatin;
      }
    }

    elapsedSeconds = 0;
    progressPercent = 0;
    if (progressBarFill) progressBarFill.style.width = '0%';
    if (timeElapsed) timeElapsed.textContent = '00:00';
    updatePlayState(true);
  };

  if (prevTrackBtn) {
    prevTrackBtn.addEventListener('click', () => loadTrack(currentTrackIdx - 1));
  }
  if (nextTrackBtn) {
    nextTrackBtn.addEventListener('click', () => loadTrack(currentTrackIdx + 1));
  }

  /* ==========================================================================
     3. FAQ Smooth Accordion Handler
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
     4. GitHub Release Sync & Download Links
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
