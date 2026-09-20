/**
 * Odd Verse — Interactive Features & Responsiveness Controller
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
      playIcon.style.display = 'none';
      pauseIcon.style.display = 'block';
      if (audioVisualizer) audioVisualizer.classList.remove('paused');
      startProgressTimer();
    } else {
      playIcon.style.display = 'block';
      pauseIcon.style.display = 'none';
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
    const titleEl = document.querySelector('.player-title');
    const artistEl = document.querySelector('.player-artist');
    const badgeEl = document.querySelector('.badge-chip');

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
     3. Showcase Tab & Thumbnail Switcher
     ========================================================================== */
  const tabBtns = document.querySelectorAll('.tab-btn');
  const thumbItems = document.querySelectorAll('.thumb-item');
  const showcaseImg = document.getElementById('showcaseImg');
  const captionTag = document.getElementById('captionTag');
  const captionTitle = document.getElementById('captionTitle');
  const captionText = document.getElementById('captionText');
  const captionFeatures = document.getElementById('captionFeatures');

  const showcaseScreens = [
    {
      img: 'assets/screenshots/1.jpg',
      tag: 'SCREEN 01 • NOW PLAYING',
      title: 'Lossless Audio & Dynamic Material You',
      text: 'Enjoy high-fidelity streaming with automatic color harmonization extracted directly from the active album cover. Full hardware equalizer and soundstage controls right at your fingertips.',
      features: ['Lossless FLAC', 'Material 3 Palette', '10-Band EQ']
    },
    {
      img: 'assets/screenshots/2.jpg',
      tag: 'SCREEN 02 • SYNCED LYRICS',
      title: 'Real-Time Indic Transliteration',
      text: 'Sing along in any language. Lyrics in Hindi, Punjabi, and regional scripts automatically romanize phonetically in sync with 3-second auto-snap viewport centering.',
      features: ['Devanagari to Roman', 'Gurmukhi Support', '3s Auto-Snap']
    },
    {
      img: 'assets/screenshots/3.jpg',
      tag: 'SCREEN 03 • STORAGE TOOLS',
      title: 'Deep Cache Purge & Offline Engine',
      text: 'Granular controls give you transparent insights into audio files, cover art, and search caches. Purge unwanted data in one tap or export lossless M4A tracks.',
      features: ['1-Tap Cache Flush', 'M4A Export', 'Zero Leftover Files']
    },
    {
      img: 'assets/screenshots/4.jpg',
      tag: 'SCREEN 04 • DISCOVERY & HOME',
      title: 'Lightning Fast Search & Clean Library',
      text: 'Sub-2 millisecond search queries powered by Hive encrypted binary databases. No sponsored algorithmic push feeds—just your pure music library.',
      features: ['Sub-2ms Queries', 'Hive Encrypted DB', 'Zero Algorithmic Ads']
    }
  ];

  const switchScreen = (index) => {
    const data = showcaseScreens[index];
    if (!data) return;

    // Update active tab buttons
    tabBtns.forEach((btn, i) => {
      const isActive = i === index;
      btn.classList.toggle('active', isActive);
      btn.setAttribute('aria-selected', isActive ? 'true' : 'false');
    });

    // Update thumbnail strip
    thumbItems.forEach((thumb, i) => {
      thumb.classList.toggle('active', i === index);
    });

    // Smooth image transition
    if (showcaseImg) {
      showcaseImg.style.opacity = '0';
      setTimeout(() => {
        showcaseImg.src = data.img;
        showcaseImg.style.opacity = '1';
      }, 150);
    }

    // Update captions
    if (captionTag) captionTag.textContent = data.tag;
    if (captionTitle) captionTitle.textContent = data.title;
    if (captionText) captionText.textContent = data.text;

    if (captionFeatures) {
      captionFeatures.innerHTML = data.features
        .map(f => `<span class="feature-tag">${f}</span>`)
        .join('');
    }
  };

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = parseInt(btn.getAttribute('data-target'), 10);
      switchScreen(target);
    });
  });

  thumbItems.forEach(thumb => {
    thumb.addEventListener('click', () => {
      const idx = parseInt(thumb.getAttribute('data-index'), 10);
      switchScreen(idx);
    });
  });

  /* ==========================================================================
     4. FAQ Smooth Accordion Handler
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
     5. GitHub Release Sync & Download Links
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
