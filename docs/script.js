document.addEventListener('DOMContentLoaded', () => {
  // Mobile Menu Toggle
  const menuToggle = document.getElementById('menuToggle');
  const mobileDrawer = document.getElementById('mobileDrawer');
  const drawerLinks = document.querySelectorAll('.drawer-item');

  if (menuToggle && mobileDrawer) {
    menuToggle.addEventListener('click', () => {
      mobileDrawer.classList.toggle('active');
    });

    drawerLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileDrawer.classList.remove('active');
      });
    });
  }

  // Visualizer Play / Pause Toggle Simulation
  const playBtn = document.getElementById('playPreviewBtn');
  const audioWaves = document.getElementById('audioWaves');
  let isPlaying = true;

  if (playBtn && audioWaves) {
    playBtn.addEventListener('click', () => {
      isPlaying = !isPlaying;
      playBtn.textContent = isPlaying ? '⏸' : '▶';
      const waveBars = audioWaves.querySelectorAll('.wave-bar');
      waveBars.forEach(bar => {
        bar.style.animationPlayState = isPlaying ? 'running' : 'paused';
      });
    });
  }

  // Dynamic GitHub Release Auto-Linker
  const repo = 'OddBoyXdxd69/Odd-Verse';
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then(res => res.json())
    .then(data => {
      if (data && data.tag_name) {
        const brandTag = document.querySelector('.brand-tag');
        if (brandTag) {
          brandTag.textContent = data.tag_name;
        }

        // If there are assets, update download URLs dynamically
        if (data.assets && data.assets.length > 0) {
          data.assets.forEach(asset => {
            if (asset.name.includes('arm64-v8a')) {
              const arm64Btn = document.querySelector('a[href*="arm64-v8a"]');
              if (arm64Btn) arm64Btn.href = asset.browser_download_url;
            } else if (asset.name.includes('armeabi-v7a')) {
              const arm32Btn = document.querySelector('a[href*="armeabi-v7a"]');
              if (arm32Btn) arm32Btn.href = asset.browser_download_url;
            } else if (asset.name.includes('x86_64')) {
              const x86Btn = document.querySelector('a[href*="x86_64"]');
              if (x86Btn) x86Btn.href = asset.browser_download_url;
            } else if (asset.name.includes('universal')) {
              const univBtn = document.querySelector('a[href*="universal"]');
              if (univBtn) univBtn.href = asset.browser_download_url;
            }
          });
        }
      }
    })
    .catch(err => {
      console.log('GitHub Release API auto-linker fallback active');
    });
});
