import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/player/components/animated_play_button.dart';
import '../../widgets/playback_speed_pitch_bottom_sheet.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
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
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: playerController.toggleFavourite,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Obx(
                      () => Icon(
                        playerController.isCurrentSongFav.isFalse
                            ? Icons.favorite_border_rounded
                            : Icons.favorite_rounded,
                        color: playerController.isCurrentSongFav.isTrue
                            ? Colors.redAccent
                            : theme.textTheme.titleMedium?.color,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Modern Sleek Progress Bar with Custom Thumb Glow
        GetX<PlayerController>(builder: (controller) {
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
                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: playerController.toggleShuffleMode,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Ionicons.shuffle,
                        size: 24,
                        color: isShuffle
                            ? theme.colorScheme.secondary
                            : theme.textTheme.titleLarge?.color
                                ?.withOpacity(0.35),
                      ),
                    ),
                  ),
                );
              }),

              // Previous Track Button
              _previousButton(playerController, context),

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
              _nextButton(playerController, context),

              // Loop / Repeat Button with Active Glow Ring
              Obx(() {
                final isLoop = playerController.isLoopModeEnabled.value;
                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: playerController.toggleLoopMode,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.all_inclusive_rounded,
                        size: 24,
                        color: isLoop
                            ? theme.colorScheme.secondary
                            : theme.textTheme.titleLarge?.color
                                ?.withOpacity(0.35),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Actions Toolbar (Speed/Pitch, Sleep Timer, Song Info)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed & Pitch Preset Badge Button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (context) =>
                      const PlaybackSpeedPitchBottomSheet(),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Obx(() {
                      final speed = playerController.playbackSpeed.value;
                      final pitch = playerController.playbackPitch.value;
                      final isModified = speed != 1.0 || pitch != 1.0;

                      String label = "Speed & Pitch";
                      if (isModified) {
                        if ((speed - 0.85).abs() < 0.03 && (pitch - 0.90).abs() < 0.03) {
                          label = "Slowed + Reverb";
                        } else if ((speed - 1.25).abs() < 0.03 && (pitch - 1.20).abs() < 0.03) {
                          label = "Nightcore";
                        } else {
                          label = "${speed.toStringAsFixed(1)}x / ${pitch.toStringAsFixed(1)}p";
                        }
                      }

                      return Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isModified ? FontWeight.bold : FontWeight.w600,
                          color: isModified
                              ? theme.colorScheme.secondary
                              : theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.8),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Sleep Timer Action
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 22),
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => const SleepTimerBottomSheet(),
                );
              },
            ),

            const SizedBox(width: 4),

            // Song Info Action
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 22),
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              onPressed: () {
                if (playerController.currentSong.value != null) {
                  showModalBottomSheet(
                    constraints: const BoxConstraints(maxWidth: 500),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.0)),
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _previousButton(
      PlayerController playerController, BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: playerController.prev,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.skip_previous_rounded,
            color: theme.textTheme.titleMedium?.color,
            size: 34,
          ),
        ),
      ),
    );
  }
}

Widget _nextButton(PlayerController playerController, BuildContext context) {
  final theme = Theme.of(context);
  return Obx(() {
    final isLastSong = playerController.currentQueue.isEmpty ||
        (!(playerController.isShuffleModeEnabled.isTrue ||
                playerController.isQueueLoopModeEnabled.isTrue) &&
            (playerController.currentQueue.last.id ==
                playerController.currentSong.value?.id));
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLastSong ? null : playerController.next,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.skip_next_rounded,
            color: isLastSong
                ? theme.textTheme.titleLarge?.color?.withOpacity(0.25)
                : theme.textTheme.titleMedium?.color,
            size: 34,
          ),
        ),
      ),
    );
  });
}
