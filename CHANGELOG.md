# 🚀 Odd Verse Changelog

## [v1.0.3] - Latest Release

### 🍎 Multi-Provider Synced Lyrics & Search Engine (BitChord Full Parity)
- **All Top Lyrics Providers Integrated**: Combined the industry's most comprehensive provider chain:
  - **`lrc.red`**: Apple Music TTML syllable timings by recording/ISRC (Tier 0 word-synced).
  - **`BetterLyrics`**: Apple Music word-synced TTML mirror with zero-key instant lookup (Tier 0.5 word-synced).
  - **`KuGou`**: Massive catalog coverage across international, English, Hindi, and Asian music via KuGou mobile endpoints.
  - **`LRCLIB`**: High-availability line-synced catalog with exact duration verification.
  - **`Netease Cloud`**: Global cloud music synced database.
  - **`YouTube Captions`**: Millisecond-accurate video subtitle matching for live versions, unofficial uploads, and remixes.
- **Search Across Providers (Manual Picker)**: Added a sleek "Search Lyrics Across Providers" bottom sheet in the player. Users can search by track title/artist, view matches categorized by provider (`Apple Word-Synced 🍎`, `KuGou`, `LRCLIB`), and apply any result instantly to the current song with 1 tap.
- **Word-by-Word Radiant Golden Illumination**: Active lines render in high-fidelity `Text.rich` spans. Words illuminate in glowing radiant gold (`0xFFFFD54F` with double-layer warm bloom shadows) exactly as vocalized, with 50% dimmed upcoming words and zero GPU shader overhead.

### 🎧 Full YouTube Music Listening History Sync
- **Official Playback Tracking Pipeline**: Replaced basic endpoint calls with YouTube Music's official `playbackTracking` protocol. Extracts `videostatsPlaybackUrl`, `videostatsWatchtimeUrl`, and `atrUrl` using authorized player sessions with client playback nonce (`cpn`).
- **Guaranteed History Updates**: Sends authenticated playback start and watchtime duration pings directly to `s.youtube.com`, ensuring all played tracks immediately register in your official YouTube Music account history and feed into your recommendation profile.

### 👤 YouTube Music Profile & Account Display
- **Live Account Profile Banner**: Displays your signed-in Google account name, email, and high-resolution profile avatar directly on the Home feed header and Settings page with a dedicated "Connected" indicator.
- **Security Block Bypass & Cookie Importer**: Removed custom webview user-agent to resolve Google's "Couldn't sign you in - This browser or app may not be secure" screen, and added a quick "Paste Cookies" dialog in the login screen for instant 1-second sign-in from exported browser cookies.

### 🎵 Enhanced YouTube Music Shelves & Mixes

### ⚡ Lite Mode (Save Battery & RAM)
- **Zero Transition Overhead**: Repurposed transition animation toggle to "Lite Mode (Save Battery & RAM)". Enabling Lite Mode turns off page transitions for instant zero-lag screen swapping.
- **Complete GPU Blur Bypass**: Completely bypasses costly real-time GPU `BackdropFilter` convolution passes (sigma 10–30) across Standard Player, Gesture Player, and the queue bar, reducing CPU/GPU overhead, thermals, and battery consumption.
- **Memory Conservation**: Skips redundant background thumbnail decoding in standard player during Lite Mode, saving extra megabytes of RAM.
- **Intact Gesture Mechanics**: Bottom queue sliding up/down, rotating chevron arrow, and miniplayer expansion/collapse animations remain 100% intact and fluid.

### 🎤 Enhanced Multi-Tier Synced Lyrics & Radiant Golden Glow
- **Instant Vertical Centering & Zero Lag**: Integrated dynamic vertical viewport padding via `LayoutBuilder`, ensuring every active lyric line (from the first to the very last line) scrolls smoothly to the exact vertical middle with zero delay.
- **Eliminated Touch Lockup & 3-Second Stutter**: Removed screen touch pointer interceptor that previously froze auto-scrolling for 3 seconds after touch, ensuring auto-scroll triggers instantly on every lyric change.
- **Eliminated Previous Line Highlight Flash**: Enforced instant `Duration.zero` background cleanup when a line becomes inactive, completely removing the lingering yellow background flash on the preceding line during transitions.
- **Radiant Golden Glow & Smooth Line Interpolation**: Transformed the active synced lyric presentation with dual-layer radiant text shadows (`0xCCFFD54F` sharp glow + `0x55FFA000` ambient warm bloom) and fluid `AnimatedDefaultTextStyle` interpolation, providing an Apple Music / Karaoke-grade luminous glow transition without performance or battery overhead.
- **YouTube Subtitle Vocal Onset Auto-Alignment**: Engineered millisecond-accurate auto-alignment between YouTube video audio and studio lyrics databases. Detects the exact millisecond when singing begins in the specific YouTube upload and automatically time-shifts studio `.lrc` lines by the exact delta, ensuring 100% flawless sync on unofficial uploads, fan edits, slowed/reverb tracks, and trending music videos without extra CPU or RAM usage.
- **Priority YouTube Captions Matching**: Upgraded YouTube Closed Captions engine to prioritize official tracks across English, Hindi, and regional languages with direct video-synchronized timestamp generation.
- **Unified SponsorBlock Lyrics Alignment**: Intelligently synchronizes studio lyrics timestamps (`lrclib`, `netease`) with music video intro/sponsor skits. Whether SponsorBlock auto-skip is enabled (jumping past the intro to +introSec) or disabled (playing through the intro), studio lyrics automatically receive the exact `+introSec` time shift so lyrics are 100% in sync with the audio playback position at all times.
- **Source-Aware Provider Tracking**: Distinguishes natively video-aligned timestamps (`youtube_captions`) from studio album lyrics, ensuring YouTube captions never receive redundant time shifts.

### ⏱️ 5-Second Playback Rule for History & Recommendations
- **Protected History & Taste Profile**: Songs are strictly saved to Recently Played (`LIBRP`), `recentSongId`, and recommendation triggers only after the track has played for at least 5 seconds.
- **Zero Skip Pollution**: Rapidly skipping through tracks in a playlist or queue no longer pollutes your listening history or skews recommendation seeds.
- **YouTube Music Playback Sync**: Automatically reports playback to YouTube Music history after the 5-second mark when logged in.

### 🎯 Seamless Smart Home Recommendations & Conflict Resolution
- **Dynamic YouTube Music Shelf Recognition**: Intelligently detects and parses personalized YouTube Music top shelves (`"Listen again"`, `"Mixed for you"`, `"From your library"`, `"Speed dial"`, `"Forgotten favorites"`) for authenticated users, with clean fallback to `"Quick picks"` or the top song shelf.
- **Fresh Network Updates**: Eliminated stale cache lock where cached offline data previously prevented fresh network recommendations from refreshing.
- **Anonymous Taste Blending**: For anonymous users, blends global/regional shelves with related recommendations seeded by recent listening.
- **Title Formatting & Preservation**: Fixed title mangling in `QuickPicksWidget`, preserving proper spaces, capitalization, and artist names for custom/non-dictionary shelf headers.
- **Zero Duplicate Shelves**: Deduplicated `fixedContent` against `middleContent` and `quickPicks` to ensure identical shelves never repeat.
- **Hidden Blank Space**: Hidden the empty 340px box whenever recommendation items are empty.

### 🖤 Pure AMOLED Pitch Black Theme ("AMOLED Dark")
- **True #000000 Deep Black**: Added dedicated Pure AMOLED Black theme preset (`ThemeType.amoled`) providing 100% pitch black backgrounds on scaffold, canvas, cards, and modal sheets with zero grey tint, saving battery on OLED displays.
- **Matching Dark Mode Grey Accent**: Configured buttons, indicators, and accents to use the exact same clean grey tone as Dark mode (`Colors.grey[700]`), eliminating neon blue/light blue tint while keeping true `#000000` pitch black backgrounds.
- **Unified Dialog & Sheet Styling**: Dialogs, bottom sheets, and navigation bars adopt pitch black styling with subtle edge highlights for high-contrast visibility.
- **Dedicated Theme Selector Entry**: Added "AMOLED Dark (Pitch Black)" option directly in the Theme Mode selector dialog and settings.

### 🛡️ Smart Cache Conflict Prevention & Stylish Popups
- **Coordinated Cache Toggles**: Prevents conflicting cache settings from clashing. Enabling "Cache Songs while playing" when "Auto Cache Cleaner" is active triggers a stylish conflict dialog warning that auto cleaner would purge offline songs, with a 1-tap action to turn off Auto Cleaner and enable song caching.
- **Auto Cleaner Protection**: Enabling "Auto Cache Cleaner" when "Cache Songs" is enabled warns the user and provides a 1-tap toggle to resolve the conflict.
- **Lightweight Home Cache Independent**: "Cache Home screen data" remains lightweight and unaffected without any popups.
- **Offline Cache Protection**: Guarded `cachedSongs/` directory in `checkAndCleanCacheIfNeeded()` so offline songs are never purged accidentally during auto cleanup.
- **Stylish Confirmation Dialogs**: Manual "Clear App Cache" and "Clear Image Cache" actions prompt modern confirmation dialogs detailing what will be deleted with "Cancel" and "Clear" actions.

### 🎵 Dynamic Flowing Wave Progress Bar
- **Sleek Progress Line Track**: Clean, professional baseline track across the player width with inactive, buffered, and active states.
- **Dynamic Audio Wave Strictly Above Playing Track**: Smooth continuous sine wave ripples gracefully only above the played portion of the track up to the current playback position, with a calm clean line for the unplayed track.
- **100% Seamless Infinite Loop**: Synchronized harmonic wave frequencies to integer phase multipliers, eliminating cuts and jumps for fluid, infinite looping.
- **True Up-and-Down Wave Undulation**: Natural sinusoidal crests and troughs with layered dual-wave depth floating above the active line.
- **Glowing Playhead Thumb Indicator**: Thumb with glowing halo cleanly connects the wave crest back to the baseline at the exact playback position.
- **Full Interactive Seeking**: Tap or horizontally drag/scrub across the waveform with live preview timestamp updates and smooth seek dispatch.
- **Toggleable in Settings**: Added a setting under Music & Playback to switch between the Dynamic Wave and standard progress bars.

### ⬇️ Clean Big Player: Zero Queue Bleed & Synchronized Animated Arrow
- **Bottom-Only Queue Opening**: Removed screen-wide swipe trigger (`onSwipeUp`) on the main player so scrolling/swiping on album art, lyrics, or playback controls never accidentally triggers the queue. The queue only opens when swiping/scrolling directly from the bottom edge.
- **Synchronized Animated Arrow Motion**: The arrow dynamically animates upward in 100% sync with the sliding queue panel. As the queue rises from bottom to top, the arrow rides along its leading edge while smoothly rotating 180° from an upward chevron (`^`) into a downward chevron (`v`).
- **Interactive Drag & Tap**: Supports continuous vertical dragging directly from the bottom arrow handle with real-time tracking, flinging open/closed, and 1-tap toggling.
- **Zero Queue Bar Bleed**: Set queue panel `minHeight: 0`, completely removing the bottom queue bar and peeking songs from showing when the Big Player is open.
- **Pure Transparent Background**: Floating arrow chevron floats directly on the canvas with 100% transparent background and zero black box or strip behind it.
- **Restored Dark/AMOLED Player Background Gradient**: Reverted the background gradient in `StandardPlayer` to its original dark blend so the player maintains its original dark depth without thumbnail color overexposure.

### 💊 Perfect Floating Pill Centering (Zero Square Artifacts)
- **Symmetric Centering (Equal 10px Margins)**: Fixed horizontal misalignment by constraining the sliding panel header with exact edge bounds (`left: 0`, `right: 0`, full width) and responsive horizontal padding. The pill now has mathematically identical 10px margins on both left and right sides on all device resolutions.
- **Zero Square Shadow Clipping**: Replaced overflowing blur/spread with a soft, non-clipping shadow (`spreadRadius: 0`, `blurRadius: 14`), completely eliminating sharp-cut rectangular shadows.
- **Clean Standard Floating Pill**: Preserved standard smooth panel sliding without unnecessary bounce or scaling, ensuring clean and native responsiveness.
- **Eliminated Dynamic Color Bleed**: Prevented background panel sheet and big player canvas from rendering behind the mini player while collapsed with zero square background artifacts in all dynamic album art themes and dark/light modes.

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