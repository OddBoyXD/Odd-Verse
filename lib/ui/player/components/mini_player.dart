import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/player/player_controller.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/mini_player_progress_bar.dart';
import 'animated_play_button.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final size = MediaQuery.of(context).size;

    return Obx(() {
      final panelVisible = playerController.isPlayerpanelTopVisible.value;
      final minHeight = playerController.playerPanelMinHeight.value;

      if (!panelVisible || minHeight <= 0.0) {
        return const SizedBox.shrink();
      }

      final effectiveOpacity =
          playerController.playerPaneOpacity.value.clamp(0.0, 1.0);

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Opacity(
        opacity: effectiveOpacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            playerController.playerPanelController.open();
          },
          child: Container(
                width: size.width,
                height: minHeight,
                alignment: Alignment.topCenter,
                child: Container(
                  height: 64.0,
                  width: size.width - 20.0,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.cardColor.withOpacity(0.94)
                        : theme.cardColor.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Main Pill Content Row
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: Album Art Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: playerController.currentSong.value !=
                                          null
                                      ? ImageWidget(
                                          size: 46,
                                          song: playerController
                                              .currentSong.value!,
                                        )
                                      : const SizedBox(
                                          width: 46,
                                          height: 46,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Middle: Song Title & Artist (Expanded Centered)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Marquee(
                                        delay: const Duration(
                                            milliseconds: 300),
                                        duration:
                                            const Duration(seconds: 10),
                                        id: "${playerController.currentSong.value}_title",
                                        child: Text(
                                          playerController.currentSong
                                                      .value !=
                                                  null
                                              ? playerController
                                                  .currentSong.value!.title
                                              : "No Song Playing",
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Marquee(
                                        delay: const Duration(
                                            milliseconds: 300),
                                        duration:
                                            const Duration(seconds: 10),
                                        id: "${playerController.currentSong.value}_subtitle",
                                        child: Text(
                                          playerController.currentSong
                                                      .value !=
                                                  null
                                              ? (playerController
                                                      .currentSong
                                                      .value!
                                                      .artist ??
                                                  "Odd-Verse")
                                              : "Odd-Verse",
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme
                                                .textTheme.labelSmall?.color
                                                ?.withOpacity(0.75),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Right: Control Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Previous Song Button
                                    IconButton(
                                      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                      icon: const Icon(
                                        Icons.skip_previous_rounded,
                                        size: 24,
                                      ),
                                      onPressed: playerController.prev,
                                    ),

                                    // Play / Pause Animated Button
                                    const AnimatedPlayButton(
                                      key: Key("miniPlayButton"),
                                    ),

                                    // Next Song Button
                                    IconButton(
                                      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                      icon: const Icon(
                                        Icons.skip_next_rounded,
                                        size: 24,
                                      ),
                                      onPressed: playerController.next,
                                    ),

                                    // Favorite Button
                                    IconButton(
                                      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                      onPressed:
                                          playerController.toggleFavourite,
                                      icon: Obx(
                                        () => Icon(
                                          playerController
                                                  .isCurrentSongFav.isFalse
                                              ? Icons.favorite_border_rounded
                                              : Icons.favorite_rounded,
                                          color: playerController
                                                  .isCurrentSongFav.isTrue
                                              ? Colors.redAccent
                                              : theme.textTheme.titleMedium
                                                  ?.color,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Integrated Progress Line
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: GetX<PlayerController>(
                            builder: (controller) => SizedBox(
                              height: 2.5,
                              child: MiniPlayerProgressBar(
                                progressBarStatus:
                                    controller.progressBarStatus.value,
                                progressBarColor: theme
                                        .colorScheme.secondary
                                        .withOpacity(0.95),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      }
    }
