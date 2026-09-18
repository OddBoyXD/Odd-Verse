# 🚀 Odd Verse Changelog

## [v1.0.1] - Next Update (In Progress)

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

### 🎨 Apple Music-Inspired Minimal Aesthetics
- **Clean Sleek Cards**: Modernized search genre cards and home headers with borderless clean aesthetics.
- **Enhanced Contrast & Spacing**: Polished typography and fluid tab switches across Artist pages.

### 🛠️ Stability & Upgradability
- **Direct Seamless App Upgrade**: Configured versionCode `2002` allowing direct in-place update over previous release builds without uninstalling.

## [v1.0.0] - Initial Release

### ⚡ Performance & Streaming Engine
- **Instant Playback Start (0–0.5s)**: Fine-tuned ExoPlayer `AndroidLoadControl` (`bufferForPlaybackDuration: 150ms`) for instantaneous audio start on song tap.
- **5 MB Network Burst Buffering**: Saturated socket data streams to leverage high-speed 5G & Wi-Fi connections, eliminating stutter and buffering.
- **Stale-While-Revalidate Home Screen**: Cached homepage loads in ~2ms from local Hive storage, seamlessly followed by silent background refreshes.
- **Predictive Upcoming Song Pre-buffering**: Pre-fetches stream URLs for upcoming queue items for seamless next-track transitions.

### 🛡️ Features & Audio Experience
- **Indic Script Transliteration**: Automatic romanization of Hindi, Punjabi, and Gurmukhi synced lyrics.
- **Integrated SponsorBlock**: Automatic silent skipping of intros, sponsor intervals, and non-music sections.
- **Pure Audio Sharing**: Direct m4a/aac extraction with clean tags.
- **100% Cache Purge**: Added granular and complete cache cleanup options in Settings.
- **Zero Ads & Privacy-Focused**: No ads, no trackers, and no telemetry.

### 📦 Release Variants
- Full suite of APK builds available:
  - `OddVerse-v1.0.0-arm64-v8a.apk` (64-bit ARM - Recommended)
  - `OddVerse-v1.0.0-armeabi-v7a.apk` (32-bit ARM - Legacy)
  - `OddVerse-v1.0.0-x86_64.apk` (64-bit Intel/AMD)
  - `OddVerse-v1.0.0-universal.apk` (All architectures)