# 🚀 Odd Verse Changelog

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