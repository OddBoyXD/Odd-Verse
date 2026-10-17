import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/player/components/animated_play_button.dart';
import '../../widgets/playback_speed_pitch_bottom_sheet.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/dynamic_waveform_progress_bar.dart';
import '../../screens/Settings/settings_screen_controller.dart';
import '../player_controller.dart';

class PlayerControlWidget extends StatelessWidget {
  const PlayerControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title & Artist + Favorite Heart Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Colors.transparent
                      ],
                    ).createShader(
                        Rect.fromLTWH(0, 0, rect.width, rect.height));
                  },
                  blendMode: BlendMode.dstIn,
                  child: Obx(() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(seconds: 10),
                          id: "${playerController.currentSong.value}_title",
                          child: Text(
                            playerController.currentSong.value != null
                                ? playerController.currentSong.value!.title
                                : "No Song Playing",
                            textAlign: TextAlign.start,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Marquee(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(seconds: 10),
                          id: "${playerController.currentSong.value}_subtitle",
                          child: Text(
                            playerController.currentSong.value != null
                                ? playerController.currentSong.value!.artist!
                                : "Odd-Verse",
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              // Favorite Heart Button with Glow
              Obx(() => IconButton(
                    tooltip: "Favorite",
                    splashRadius: 24,
                    icon: Icon(
                      playerController.isCurrentSongFav.isFalse
                          ? Icons.favorite_border_rounded
                          : Icons.favorite_rounded,
                      color: playerController.isCurrentSongFav.isTrue
                          ? Colors.redAccent
                          : theme.textTheme.titleMedium?.color,
                      size: 28,
                    ),
                    onPressed: playerController.toggleFavourite,
                  )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Dynamic Waveform or Sleek Progress Bar
        GetX<PlayerController>(builder: (controller) {
          final settingsController = Get.find<SettingsScreenController>();
          final songId = controller.currentSong.value?.id ?? "oddverse";

          if (settingsController.dynamicWaveformProgressBar.value) {
            return DynamicWaveformProgressBar(
              progress: controller.progressBarStatus.value.current,
              total: controller.progressBarStatus.value.total,
              buffered: controller.progressBarStatus.value.buffered,
              onSeek: controller.seek,
              activeColor: theme.colorScheme.secondary,
              bufferedColor: isDark
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.18),
              inactiveColor: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
              seedKey: songId,
              timeLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            );
          }

          return ProgressBar(
            thumbRadius: 8.0,
            thumbGlowRadius: 20.0,
            barHeight: 5.0,
            baseBarColor: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            bufferedBarColor: isDark
                ? Colors.white.withOpacity(0.25)
                : Colors.black.withOpacity(0.18),
            progressBarColor: theme.colorScheme.secondary,
            thumbColor: theme.colorScheme.secondary,
            timeLabelLocation: TimeLabelLocation.sides,
            timeLabelPadding: 6,
            timeLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
            progress: controller.progressBarStatus.value.current,
            total: controller.progressBarStatus.value.total,
            buffered: controller.progressBarStatus.value.buffered,
            onSeek: controller.seek,
          );
        }),

        const SizedBox(height: 12),

        // Main Playback Controls Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shuffle Button with Active Glow Ring
              Obx(() {
                final isShuffle = playerController.isShuffleModeEnabled.value;
                return IconButton(
                  tooltip: "Shuffle",
                  splashRadius: 24,
                  onPressed: playerController.toggleShuffleMode,
                  icon: Icon(
                    Icons.shuffle_rounded,
                    size: 24,
                    color: isShuffle
                        ? theme.colorScheme.secondary
                        : Colors.white.withOpacity(0.70),
                  ),
                );
              }),

              // Previous Track Button
              IconButton(
                tooltip: "Previous",
                splashRadius: 24,
                onPressed: playerController.prev,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              // Hero Elevated Circular Play/Pause Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary
                          .withOpacity(isDark ? 0.40 : 0.28),
                      blurRadius: 24,
                      spreadRadius: 3,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 36,
                  child: AnimatedPlayButton(
                    key: Key("playButton"),
                  ),
                ),
              ),

              // Next Track Button
              Obx(() {
                final isLastSong = playerController.currentQueue.isEmpty ||
                    (!(playerController.isShuffleModeEnabled.isTrue ||
                            playerController.isQueueLoopModeEnabled.isTrue) &&
                        (playerController.currentQueue.last.id ==
                            playerController.currentSong.value?.id));
                return IconButton(
                  tooltip: "Next",
                  splashRadius: 24,
                  onPressed: isLastSong ? null : playerController.next,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: isLastSong
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white,
                    size: 34,
                  ),
                );
              }),

              // Loop / Repeat Button with Active Glow Ring
              Obx(() {
                final isLoop = playerController.isLoopModeEnabled.value;
                return IconButton(
                  tooltip: "Repeat",
                  splashRadius: 24,
                  onPressed: playerController.toggleLoopMode,
                  icon: Icon(
                    isLoop ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    size: 24,
                    color: isLoop
                        ? theme.colorScheme.secondary
                        : Colors.white.withOpacity(0.70),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick Actions Toolbar (Speed/Pitch, Sleep Timer, Song Info, Lyrics)
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Speed & Pitch
                Obx(() {
                  final speed = playerController.playbackSpeed.value;
                  final pitch = playerController.playbackPitch.value;
                  final isModified = speed != 1.0 || pitch != 1.0;

                  return Tooltip(
                    message: isModified
                        ? "Speed: ${speed.toStringAsFixed(1)}x"
                        : "Speed & Pitch",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28)),
                          ),
                          builder: (context) =>
                              const PlaybackSpeedPitchBottomSheet(),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isModified
                                  ? theme.colorScheme.secondary.withOpacity(0.18)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.05)),
                              border: Border.all(
                                color: isModified
                                    ? theme.colorScheme.secondary.withOpacity(0.5)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.12)
                                        : Colors.black.withOpacity(0.06)),
                                width: 1.1,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: isModified
                                  ? theme.colorScheme.secondary
                                  : Colors.white.withOpacity(0.80),
                            ),
                          ),
                          if (isModified)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${speed.toStringAsFixed(1)}x",
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                // 2. Sleep Timer Action
                Obx(() {
                  final isTimerActive = playerController.isSleepTimerActive.isTrue;
                  return Tooltip(
                    message: isTimerActive ? "Sleep Timer Active" : "Sleep Timer",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24)),
                          ),
                          builder: (context) => const SleepTimerBottomSheet(),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTimerActive
                              ? theme.colorScheme.secondary.withOpacity(0.18)
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05)),
                          border: Border.all(
                            color: isTimerActive
                                ? theme.colorScheme.secondary.withOpacity(0.5)
                                : (isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06)),
                            width: 1.1,
                          ),
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: isTimerActive
                              ? theme.colorScheme.secondary
                              : Colors.white.withOpacity(0.80),
                        ),
                      ),
                    ),
                  );
                }),

                // 3. Song Info Action
                Tooltip(
                  message: "Song Info",
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      if (playerController.currentSong.value != null) {
                        showModalBottomSheet(
                          constraints: const BoxConstraints(maxWidth: 500),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.0)),
                          ),
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => SongInfoBottomSheet(
                            playerController.currentSong.value!,
                            calledFromPlayer: true,
                          ),
                        ).whenComplete(() => Get.delete<SongInfoController>());
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.06),
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Colors.white.withOpacity(0.80),
                      ),
                    ),
                  ),
                ),

                // 4. Dedicated Lyrics Action Button
                Obx(() {
                  final isLyricsOpen = playerController.showLyricsflag.value;
                  return Tooltip(
                    message: isLyricsOpen ? "Close Lyrics" : "Lyrics",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        playerController.showLyrics();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLyricsOpen
                              ? const Color(0x28FFD54F)
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05)),
                          border: Border.all(
                            color: isLyricsOpen
                                ? const Color(0x88FFD54F)
                                : (isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06)),
                            width: 1.1,
                          ),
                        ),
                        child: Icon(
                          isLyricsOpen
                              ? Icons.lyrics_rounded
                              : Icons.lyrics_outlined,
                          size: 20,
                          color: isLyricsOpen
                              ? const Color(0xFFFFD54F)
                              : Colors.white.withOpacity(0.80),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
