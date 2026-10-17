# 🚀 Odd Verse Changelog

## [v1.0.3] - Latest Release

### ✨ Fluid Synchronized Lyrics & Smart Display
- **Real-Time Word-by-Word Sweeping**: Lyrics glide smoothly with the music at high refresh rates with locked audio synchronization.
- **Intelligent Lyrics Display**: Automatically selects the best available synchronized word-by-word or plain lyrics for every song with beautiful bold typography.
- **Instant Seek Navigation**: Tap any line to instantly jump to that point in the song with precise audio playback.

### 📜 Interactive Lyrics Browsing & Smooth Auto-Centering
- **Unrestricted Lyrics Browsing**: Freely scroll through lyrics at your own pace without interruption while the song continues playing.
- **Smooth Auto-Centering**: When you stop scrolling, the lyrics view smoothly glides back to center on the active singing line after 3 seconds of inactivity.
- **Universal Multi-Language Transliteration**: Real-time romanization button allows you to read foreign-language song lyrics in English characters instantly.

### 🎨 Modernized Player Controls & Stationary Layout
- **Symmetrical Quick-Action Toolbar**: Clean, uniform circular glass action buttons for Playback Speed & Pitch, Sleep Timer, Song Info, and Lyrics.
- **At-a-Glance Status Indicators**: Subtle active badges and glowing accents clearly display your active playback speed and sleep timer state.
- **Stationary Player Controls**: The progress bar, play/pause buttons, and quick actions remain rock-solid and anchored at the bottom with fluid cross-fade transitions when switching to lyrics.

### ⚡ Deep Performance & Memory Optimization
- **Ultra-Light RAM Usage**: Enhanced audio queue buffering and intelligent memory management keep memory consumption light and efficient throughout extended listening sessions.
- **100% Lossless Quality**: All optimizations preserve full-resolution local artwork caching and original high-fidelity audio quality.
- **Faster App Responsiveness**: Smooth, stutter-free performance across all device types and screen sizes.

### ☁️ Cloud Library Synchronization
- **Real-Time Favorites Sync**: Seamlessly syncs your liked songs and favorites to the cloud in real-time.
- **One-Tap Library Import**: Easily import your saved music library with one tap.

### 📦 Official Release Variants (v1.0.3)
- `OddVerse-v1.0.3-arm64-v8a.apk` (64-bit ARM - Recommended for modern phones)
- `OddVerse-v1.0.3-universal.apk` (Universal architecture - Compatible with all devices)
- `OddVerse-v1.0.3-armeabi-v7a.apk` (32-bit ARM - Legacy phones)
- `OddVerse-v1.0.3-x86_64.apk` (64-bit Intel/AMD & Emulators)

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