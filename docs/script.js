document.addEventListener('DOMContentLoaded', () => {
  // 1. Non-Glitchy Slide-Over Mobile Sidebar
  const drawerToggle = document.getElementById('drawerToggle');
  const closeDrawerBtn = document.getElementById('closeDrawerBtn');
  const mobileSidebar = document.getElementById('mobileSidebar');
  const drawerBackdrop = document.getElementById('drawerBackdrop');
  const sidebarItems = document.querySelectorAll('.sidebar-item');

  function openSidebar() {
    if (mobileSidebar && drawerBackdrop) {
      mobileSidebar.classList.add('open');
      drawerBackdrop.classList.add('active');
      mobileSidebar.setAttribute('aria-hidden', 'false');
      document.body.style.overflow = 'hidden';
    }
  }

  function closeSidebar() {
    if (mobileSidebar && drawerBackdrop) {
      mobileSidebar.classList.remove('open');
      drawerBackdrop.classList.remove('active');
      mobileSidebar.setAttribute('aria-hidden', 'true');
      document.body.style.overflow = '';
    }
  }

  if (drawerToggle) drawerToggle.addEventListener('click', openSidebar);
  if (closeDrawerBtn) closeDrawerBtn.addEventListener('click', closeSidebar);
  if (drawerBackdrop) drawerBackdrop.addEventListener('click', closeSidebar);

  sidebarItems.forEach(item => {
    item.addEventListener('click', closeSidebar);
  });

  // 2. Interactive Soundstage Simulation
  const playToggleBtn = document.getElementById('playToggleBtn');
  const equalizerVisualizer = document.getElementById('equalizerVisualizer');
  const scrubProgress = document.getElementById('scrubProgress');
  const scrubTrack = document.getElementById('scrubTrack');
  const currentTimeDisplay = document.getElementById('currentTimeDisplay');
  const prevTrackBtn = document.getElementById('prevTrackBtn');
  const nextTrackBtn = document.getElementById('nextTrackBtn');
  const trackTitle = document.getElementById('trackTitle');
  const trackArtist = document.getElementById('trackArtist');
  const lyricsList = document.getElementById('lyricsList');

  let isPlaying = true;
  let progressPercent = 37;
  let currentSecond = 84; // 01:24
  const totalSeconds = 225; // 03:45
  let playInterval = null;

  const demoTracks = [
    {
      title: "Odd Verse Soundstage",
      artist: "Native C++ Audio Pipeline • Saturated 5MB Socket",
      lyrics: [
        { orig: "तारों से सजी रात में", roman: "Taaron se saji raat mein" },
        { orig: "संगीत की गूँज हवाओं में", roman: "Sangeet ki goonj hawaon mein" },
        { orig: "हर धड़कन में बसता है तराना", roman: "Har dhadkan mein basta hai taraana" },
        { orig: "ऑड वर्स के साथ खो जाना", roman: "Odd Verse ke saath kho jaana" }
      ]
    },
    {
      title: "Lossless Symphony No. 1",
      artist: "150ms Instant Start • ExoPlayer Engine",
      lyrics: [
        { orig: "ਸੁਰਾਂ ਦੀ ਛਣਕ ਸੁਣੋ", roman: "Suraan di chhanak suno" },
        { orig: "ਦਿਲ ਦੀ ਗਹਿਰਾਈ ਤੱਕ ਜਾਵੇ", roman: "Dil di gehraai takk jaave" },
        { orig: "ਬਿਨਾਂ ਰੁਕੇ ਚੱਲੇ ਸੰਗੀਤ", roman: "Bina ruke challe sangeet" },
        { orig: "ਰੂਹ ਨੂੰ ਸਕੂਨ ਮਿਲ ਜਾਵੇ", roman: "Rooh nu sukoon mil jaave" }
      ]
    }
  ];

  let currentTrackIdx = 0;

  function formatTime(sec) {
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  }

  function updateLyrics(track) {
    if (!lyricsList) return;
    lyricsList.innerHTML = '';
    track.lyrics.forEach((line, idx) => {
      const div = document.createElement('div');
      div.className = `lyric-row ${idx === 1 ? 'active' : (idx < 1 ? 'past' : 'future')}`;
      div.innerHTML = `
        <div class="lyric-orig">${line.orig}</div>
        <div class="lyric-roman">${line.roman}</div>
      `;
      lyricsList.appendChild(div);
    });
  }

  function startPlaybackTicker() {
    clearInterval(playInterval);
    playInterval = setInterval(() => {
      if (isPlaying) {
        currentSecond++;
        if (currentSecond >= totalSeconds) currentSecond = 0;
        progressPercent = (currentSecond / totalSeconds) * 100;
        if (scrubProgress) scrubProgress.style.width = `${progressPercent}%`;
        if (currentTimeDisplay) currentTimeDisplay.textContent = formatTime(currentSecond);
      }
    }, 1000);
  }

  function setPlayingState(play) {
    isPlaying = play;
    if (playToggleBtn) playToggleBtn.textContent = isPlaying ? '⏸' : '▶';
    if (equalizerVisualizer) {
      const bars = equalizerVisualizer.querySelectorAll('.eq-bar');
      bars.forEach(b => {
        b.style.animationPlayState = isPlaying ? 'running' : 'paused';
      });
    }
  }

  if (playToggleBtn) {
    playToggleBtn.addEventListener('click', () => {
      setPlayingState(!isPlaying);
    });
  }

  if (scrubTrack) {
    scrubTrack.addEventListener('click', (e) => {
      const rect = scrubTrack.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const width = rect.width;
      progressPercent = Math.max(0, Math.min(100, (clickX / width) * 100));
      currentSecond = Math.floor((progressPercent / 100) * totalSeconds);
      if (scrubProgress) scrubProgress.style.width = `${progressPercent}%`;
      if (currentTimeDisplay) currentTimeDisplay.textContent = formatTime(currentSecond);
    });
  }

  function switchTrack(idx) {
    currentTrackIdx = idx;
    const t = demoTracks[currentTrackIdx];
    if (trackTitle) trackTitle.textContent = t.title;
    if (trackArtist) trackArtist.textContent = t.artist;
    currentSecond = 0;
    updateLyrics(t);
    setPlayingState(true);
  }

  if (prevTrackBtn) {
    prevTrackBtn.addEventListener('click', () => {
      const newIdx = currentTrackIdx === 0 ? demoTracks.length - 1 : currentTrackIdx - 1;
      switchTrack(newIdx);
    });
  }

  if (nextTrackBtn) {
    nextTrackBtn.addEventListener('click', () => {
      const newIdx = (currentTrackIdx + 1) % demoTracks.length;
      switchTrack(newIdx);
    });
  }

  startPlaybackTicker();

  // 3. Dynamic GitHub Release Auto-Linker
  const repo = 'OddBoyXdxd69/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.tag_name) {
        const releasePill = document.querySelector('.release-pill');
        if (releasePill) releasePill.textContent = data.tag_name;

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
