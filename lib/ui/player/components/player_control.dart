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
        Row(
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
                            fontSize: 20,
                            letterSpacing: -0.3,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            IconButton(
              iconSize: 26,
              onPressed: playerController.toggleFavourite,
              icon: Obx(
                () => Icon(
                  playerController.isCurrentSongFav.isFalse
                      ? Icons.favorite_border_rounded
                      : Icons.favorite_rounded,
                  color: playerController.isCurrentSongFav.isTrue
                      ? Colors.redAccent
                      : theme.textTheme.titleMedium?.color,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Modern Sleek Progress Bar
        GetX<PlayerController>(builder: (controller) {
          return ProgressBar(
            thumbRadius: 7.5,
            thumbGlowRadius: 18,
            barHeight: 4.5,
            baseBarColor: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            bufferedBarColor: isDark
                ? Colors.white.withOpacity(0.24)
                : Colors.black.withOpacity(0.16),
            progressBarColor: theme.colorScheme.secondary,
            thumbColor: theme.colorScheme.secondary,
            timeLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
            ),
            progress: controller.progressBarStatus.value.current,
            total: controller.progressBarStatus.value.total,
            buffered: controller.progressBarStatus.value.buffered,
            onSeek: controller.seek,
          );
        }),

        const SizedBox(height: 10),

        // Main Playback Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shuffle Button
            IconButton(
              iconSize: 24,
              onPressed: playerController.toggleShuffleMode,
              icon: Obx(
                () => Icon(
                  Ionicons.shuffle,
                  color: playerController.isShuffleModeEnabled.value
                      ? theme.colorScheme.secondary
                      : theme.textTheme.titleLarge?.color?.withOpacity(0.35),
                ),
              ),
            ),

            // Previous Button
            _previousButton(playerController, context),

            // Elevated Circular Play/Pause Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary
                        .withOpacity(isDark ? 0.35 : 0.22),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 34,
                child: AnimatedPlayButton(
                  key: Key("playButton"),
                ),
              ),
            ),

            // Next Button
            _nextButton(playerController, context),

            // Repeat / Loop Button
            Obx(() {
              return IconButton(
                iconSize: 24,
                onPressed: playerController.toggleLoopMode,
                icon: Icon(
                  Icons.all_inclusive_rounded,
                  color: playerController.isLoopModeEnabled.value
                      ? theme.colorScheme.secondary
                      : theme.textTheme.titleLarge?.color?.withOpacity(0.35),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 8),

        // Quick Actions Toolbar (Speed/Pitch, Sleep Timer, Song Info)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed & Pitch Modulation Button with Live Badge
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) =>
                      const PlaybackSpeedPitchBottomSheet(),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Obx(() {
                      final speed = playerController.playbackSpeed.value;
                      final pitch = playerController.playbackPitch.value;
                      final isModified = speed != 1.0 || pitch != 1.0;
                      return Text(
                        isModified
                            ? "${speed.toStringAsFixed(1)}x / ${pitch.toStringAsFixed(1)}p"
                            : "1.0x",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isModified ? FontWeight.bold : FontWeight.w500,
                          color: isModified
                              ? theme.colorScheme.secondary
                              : theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Sleep Timer Action
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 20),
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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

            const SizedBox(width: 8),

            // Song Info Action
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 20),
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
    return IconButton(
      icon: Icon(
        Icons.skip_previous_rounded,
        color: theme.textTheme.titleMedium?.color,
      ),
      iconSize: 32,
      onPressed: playerController.prev,
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
    return IconButton(
      icon: Icon(
        Icons.skip_next_rounded,
        color: isLastSong
            ? theme.textTheme.titleLarge?.color?.withOpacity(0.25)
            : theme.textTheme.titleMedium?.color,
      ),
      iconSize: 32,
      onPressed: playerController.next,
    );
  });
}
