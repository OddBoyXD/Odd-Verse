import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/widgets/lyrics_dialog.dart';
import '/ui/widgets/song_info_dialog.dart';
import '/ui/player/player_controller.dart';
import '../../widgets/add_to_playlist.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/song_download_btn.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/mini_player_progress_bar.dart';
import 'animated_play_button.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _dragAnimation;
  double _dragOffset = 0.0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_dragAnimation != null) {
          setState(() {
            _dragOffset = _dragAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 200.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final totalHeight = Get.find<PlayerController>().playerPanelMinHeight.value;
    final targetHeight = totalHeight > 0 ? totalHeight : 75.0;

    if (velocity > 150 || _dragOffset > 30.0) {
      _isDismissing = true;
      _dragAnimation = Tween<double>(
        begin: _dragOffset,
        end: targetHeight + 50.0,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ));
      _animController.forward(from: 0.0).then((_) {
        Get.find<PlayerController>().dismissMiniPlayer();
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _isDismissing = false;
          });
        }
      });
    } else {
      _dragAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ));
      _animController.forward(from: 0.0);
    }
  }

  void _onVerticalDragCancel() {
    if (_isDismissing) return;
    _dragAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;
    final bottomNavEnabled =
        Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue;

    return Obx(() {
      final isDismissing = playerController.isDismissingMiniPlayer.value;
      final panelVisible = playerController.isPlayerpanelTopVisible.value;
      final minHeight = playerController.playerPanelMinHeight.value;

      if (!panelVisible || minHeight <= 0.0) {
        return const SizedBox.shrink();
      }

      final dragRatio =
          minHeight > 0 ? (_dragOffset / minHeight).clamp(0.0, 1.0) : 0.0;
      final effectiveOpacity = isDismissing
          ? 0.0
          : (playerController.playerPaneOpacity.value *
                  (1.0 - dragRatio * 0.95))
              .clamp(0.0, 1.0);
      final effectiveScale = (1.0 - dragRatio * 0.06).clamp(0.9, 1.0);

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Transform.translate(
        offset: Offset(0.0, _dragOffset),
        child: Transform.scale(
          scale: effectiveScale,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: effectiveOpacity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_dragOffset == 0.0) {
                  playerController.playerPanelController.open();
                }
              },
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onVerticalDragCancel: _onVerticalDragCancel,
              child: Container(
                height: minHeight,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  height: 64.0,
                  width: size.width,
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
          ),
        ),
      );
    });
  }
}
