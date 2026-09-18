# 🚀 Odd Verse Changelog

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