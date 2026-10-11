# 🚀 Odd Verse Changelog

## [v1.0.3] - Latest Release

### 💊 Truly Floating Miniplayer Pill (Zero Square Artifacts)
- **Eliminated Dynamic Color Bleed**: Prevented background panel sheet and big player canvas from rendering behind the mini player while collapsed.
- **Pure Floating Pill Design**: In all dynamic album art themes and dark/light modes, the floating pill now floats cleanly with zero square borders or color artifacts.

### 🌌 Genuine Hardware DSP PresetReverb ("Slowed + Reverb")
- **Real 3D Acoustic Echo**: Integrated Android's hardware `PresetReverb` (`PRESET_LARGEHALL`). Tapping the "Slowed + Reverb" preset engages true spacious room reverberation alongside 0.80x speed and pitch with **0 MB extra RAM**.
- **Clean Disengagement**: Switching back to "Original" or resetting sound vibes instantly deactivates the DSP reverb.

### 💎 Unified Glassmorphic Top Bars & Luxury Exit Badge
- **Glassmorphic Screen Headers**: Upgraded the Library and Artist top tab bars with frosted glassmorphic pill containers, subtle glowing borders, and gradient indicators matching the Settings screen.
- **Floating Exit Capsule Badge**: Replaced basic snackbar with a luxury frosted glass floating capsule badge displaying *"Press back again to exit"*, preventing accidental exits while preserving background audio.

### 🚀 High-Speed Multi-Chunk Parallel Downloads
- **Burst Multi-Chunk Downloads**: Implemented 4MB multi-part HTTP range downloads in `downloader.dart`, bypassing YouTube's 74 KB/s throttling for **maximum-speed audio downloads**.
- **Accurate Download Estimation**: Format-aware size calculations for M4A and Opus with live `%` progress indicators.
- **Accidental Deletion Protection**: Checkmark click protection prevents accidental re-downloads or deletions.

### 🎛️ Two-Way Miniplayer Pill Gestures & Glitch Fixes
- **Smooth 2-Way Transitions**: Swipe UP on the pill expands to the Big Player; Swipe DOWN on the Big Player collapses back to the pill; Swipe DOWN on the pill dismisses playback cleanly.
- **Back-Button Queue Glitch Resolved**: Back button closes the queue panel first, eliminating stray songs rendering beneath the floating pill.
- **Clean Task Manager Teardown**: Swiping Odd-Verse away from Android's Recent Apps/Task Manager cleanly stops playback and dismisses the media notification (`stopPlyabackOnSwipeAway = true` by default).

### 📉 Performance, Low RAM & Faster Builds
- **Smart Image Downsampling**: Clamped thumbnail memory decode limits (`memCacheWidth` & `memCacheHeight`), saving **~40 MB of RAM** while maintaining retina crispness.
- **1-Song Prebuffering Default**: Changed prebuffering default from 2 songs down to 1 song (15s), reducing audio buffer memory while keeping gapless transitions.
- **GitHub Actions Gradle Caching**: Integrated `actions/cache@v4` in CI workflow, slashing build times from **~10 minutes down to ~5 minutes**!

## [v1.0.2] - Previous Release

### 🎤 Multi-Provider Synced & Plain Lyrics Engine
- **YouTube Captions to LRC**: Native timed-text subtitles auto-converted to synced lyrics (`.lrc`) timestamps with 100% millisecond precision.
- **Netease Cloud Music Sync Integration**: Multi-tier international lyrics database covering global, Asian, anime, and Indic releases.
- **Unified Dual-Mode Fallback**: Instant auto-switching between synced lyrics and clean plain text when timestamps are unavailable.
- **0ms Local Offline Cache**: Lyrics are permanently cached in local Hive storage for zero-delay offline recall.

### ⚡ Fast-Loading Audio & Stream Engine
- **Muxed Audio Fallback**: Official YouTube music videos and standard uploads automatically extract high-quality audio streams, eliminating "Playback not available" errors.
- **Background Stream Pre-Buffering**: Pre-fetches stream manifests for upcoming queue items to enable instant, zero-lag song transitions.
- **Connection Socket Recycling**: Managed client lifecycle with automatic cleanup to prevent socket exhaustion and timeouts.

### 🎨 Modern Player & Floating Mini Player
- **Floating Mini Player Pill**: Symmetric bounded pill container with 20px rounded glassmorphic finish and full playback controls.
- **Clean Standard Player Header**: Streamlined header layout; speed/pitch controls accessible in the bottom playback toolbar.
- **Refined Settings & Navigation**: Discoverable tab navigation across all 5 settings sections with zero clipping or overflow.

### 🎚️ Playback Speed & Pitch Control Engine
- **Speed & Pitch Modulation**: Adjustable playback speed (0.5x – 2.0x) and independent key pitch tuning with 1-tap presets and session persistence.

### 📈 Playlist, Album & Storage Statistics
- **Aggregate Playtime & Disk Metrics**: Live runtime calculation and storage footprint badges on playlists and albums.

### 🔄 In-App Update Engine
- **Automated & Manual Release Checks**: In-app update notifications and manual version check under settings.

## [v1.0.1] - Official Release

### 🎤 Real-Time Synced Lyrics & Auto-Snap Engine
- **Smart Viewport Centering**: Real-time RenderBox calculation ensures the active lyric line remains smoothly centered within the player view without jumping or jitter.
- **3-Second Inactivity Snap-Back**: Manual scrolling or dragging pauses auto-scrolling; after 3 seconds of inactivity, the engine smoothly snaps back to the synced lyric line.
- **Interactive Tap-to-Seek**: Tap any lyric line to instantly seek audio playback directly to that timestamp.
- **Transliteration & Romanization**: Full romanization support for Indic scripts (Hindi, Punjabi, Bengali, etc.).

### 🎵 Artist Hub Sorting Engine
- **Multiple Sort Modes**: Sort artist songs, videos, and albums by:
  - **Newest First** (Default on initial load)
  - **Most Popular / Views** (Instant ranking by play count & popularity)
  - **Oldest First** (Ascending chronological order)
  - **Alphabetical (A–Z / Z–A)** (Title-based sorting)
- **Zero-Latency In-Memory Sorting**: Instantly updates lists client-side without consuming unnecessary background network or RAM.

### 📁 Local & Offline Music Engine
- **Internal Storage & SD Card Scanner**: Automatically discovers audio files (`.mp3`, `.m4a`, `.flac`, `.wav`, `.aac`, `.ogg`, `.opus`) across internal phone memory and external MicroSD cards.
- **Dedicated "Local Songs" Library Tab**: Placed right beside online Songs (`[ Songs ] [ Local Songs ] [ Playlists ] [ Albums ] [ Artists ]`).
- **Embedded Tag & Artwork Extraction**: Displays embedded ID3/MP4 metadata, titles, artists, and embedded album cover artwork with on-demand zero-RAM caching.
- **Exclude Folders in Settings**: Easily exclude noisy directories (e.g. WhatsApp audio, recordings, ringtones) with real-time library filtering.
- **Standard Native Player Controls**: Full queue management, shuffle, repeat, background playback, notification controls, and equalizer support for all local files.
- **Complete `.ovb` Backup & Restore**: Backup playlists, settings, and local library metadata to single encrypted `.ovb` files.

### 🎨 Apple Music-Inspired Minimal Aesthetics
- **Clean Sleek Cards**: Modernized search genre cards and home headers with borderless clean aesthetics.
- **Enhanced Contrast & Spacing**: Polished typography and fluid tab switches across Artist pages.

### 🛠️ Stability, Upgradability & GitHub Migration
- **Direct Seamless App Upgrade**: Configured versionCode `2002` allowing direct in-place update over previous release builds without uninstalling.
- **Account & Repository Rebranding**: Migrated all author links, update checks, and repository endpoints to **`OddBoyXD/Odd-Verse`**.

### 📦 Official Release Variants (v1.0.1)
- `OddVerse-v1.0.1-arm64-v8a.apk` (64-bit ARM - Recommended for 99% of phones)
- `OddVerse-v1.0.1-universal.apk` (All architectures combined)
- `OddVerse-v1.0.1-armeabi-v7a.apk` (32-bit ARM - Legacy devices)
- `OddVerse-v1.0.1-x86_64.apk` (64-bit Intel/AMD & PC Emulators)