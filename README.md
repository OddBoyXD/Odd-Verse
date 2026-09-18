<div align="center">

# 🌌 Odd Verse

<p align="center">
  <strong>The Ultimate High-Performance, Ad-Free Music Streaming Experience</strong>
</p>

[![Release](https://img.shields.io/github/v/release/OddBoyXdxd69/Odd-Verse?color=8A2BE2&label=Latest%20Release&logo=github)](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.3-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-green.svg)](https://github.com/OddBoyXdxd69/Odd-Verse)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-yellow.svg)](https://www.gnu.org/licenses/gpl-3.0)

<br/>

<img src="assets/icons/icon.png" width="128" height="128" alt="Odd Verse Icon" />

<br/>

**Odd Verse** is a modern, blazing-fast, and open-source cross-platform music streaming client designed for zero-latency audio playback, personalized discoveries, high fidelity streaming, and full offline caching without ads or tracking.

</div>

---

## ✨ Features

- **⚡ Instant Playback Start (0–0.5s)**: Custom ExoPlayer low-latency buffering (`150ms` buffer start) ensuring instant audio playback upon tapping any track.
- **🚀 5 MB Burst Network Buffering**: Saturated socket data pipelines engineered for high-speed 5G and Wi-Fi networks to eliminate buffering stutter.
- **🧠 Stale-While-Revalidate Caching**: Home feeds and discover sections load in `~2ms` directly from local Hive cache with background silent sync.
- **🔮 Predictive Queue Pre-buffering**: Automatically pre-fetches audio stream URLs for upcoming tracks in your queue.
- **🎼 Real-Time Synced Lyrics & Transliteration**: Full synchronized karaoke-style and plain lyrics with automatic Romanization (Hinglish transliteration for Hindi, Punjabi, Gurmukhi, Tamil, Telugu, and Malayalam).
- **🛡️ Integrated SponsorBlock**: Automatically skips non-music intros, promotional intervals, and sponsored segments.
- **📤 Persistent M4A Audio Sharing**: Stream and package pure audio directly to WhatsApp, Telegram, and social apps with an active progress indicator.
- **💾 Complete Offline Cache Management**: Granular cache management with one-tap purge and customizable storage caps.
- **🎨 Fluid Dark UI**: Dynamic Material Design theming, responsive gestures, customizable bottom/side navigation, and smooth mini-player transitions.
- **🔒 Privacy-Focused**: No advertisements, no telemetry, no tracking, and no required account login.
- **📻 Infinite Autoplay Radios**: Keep listening continuously with intelligent recommendation queues.
- **🎛️ Built-in Equalizer & Loudness Normalization**: Comprehensive audio customization and loudness leveling.

---

## 📱 Download APKs

Download the latest version directly from [GitHub Releases](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest):

| Architecture | Recommended Devices | Download Link |
| :--- | :--- | :--- |
| **`arm64-v8a`** | Modern 64-bit Android Phones / Tablets | [Download ARM64 APK](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-arm64-v8a.apk) |
| **`armeabi-v7a`** | Legacy 32-bit Android Devices | [Download ARMv7 APK](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-armeabi-v7a.apk) |
| **`x86_64`** | 64-bit Emulators & ChromeOS | [Download x86_64 APK](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-x86_64.apk) |
| **`universal`** | All Android Devices (Fat APK) | [Download Universal APK](https://github.com/OddBoyXdxd69/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-universal.apk) |

---

## 🛠️ Building From Source

### Prerequisites
- [Flutter SDK 3.24.3+](https://docs.flutter.dev/get-started/install)
- [Java JDK 17](https://www.oracle.com/java/technologies/downloads/)
- Android SDK (API Level 34)

### Build Steps
```bash
# Clone the repository
git clone https://github.com/OddBoyXdxd69/Odd-Verse.git
cd Odd-Verse

# Install dependencies
flutter pub get

# Build Release APK (arm64-v8a)
flutter build apk --release --target-platform android-arm64
```

---

## 🔧 Troubleshooting

- **Background Playback Stopped by System**: If music playback stops after turning off your screen, go to `Settings > Music & Playback > Ignore Battery Optimizations` and enable it.
- **Notification Controls**: Ensure notification permissions are granted in Android system settings.

---

## 👤 Author & Maintainer

- **OddBoyXD** ([@OddBoyXdxd69](https://github.com/OddBoyXdxd69))

---

## 📄 License

Odd Verse is open-source software licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).

---

## ⚠️ Disclaimer

This project is created for educational and personal use. Any song, album art, or trademark accessed via this app remains the intellectual property of their respective owners. Odd Verse is not affiliated with, endorsed by, or sponsored by any music or media provider.
