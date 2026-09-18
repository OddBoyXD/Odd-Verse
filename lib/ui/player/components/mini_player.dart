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
      duration: const Duration(milliseconds: 180),
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
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 300.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final totalHeight = Get.find<PlayerController>().playerPanelMinHeight.value;
    final targetHeight = totalHeight > 0 ? totalHeight : 80.0;

    if (velocity > 120 || _dragOffset > 25.0) {
      _isDismissing = true;
      _dragAnimation = Tween<double>(
        begin: _dragOffset,
        end: targetHeight + 40.0,
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
        curve: Curves.easeOutCubic,
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
                  (1.0 - dragRatio * 0.85))
              .clamp(0.0, 1.0);

      return Transform.translate(
        offset: Offset(0.0, _dragOffset),
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
              width: size.width,
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              child: Center(
                child: Column(
                children: [
                  !isWideScreen || bottomNavEnabled
                      ? GetX<PlayerController>(
                          builder: (controller) => Container(
                              height: 3,
                              color: Theme.of(context)
                                  .progressIndicatorTheme
                                  .color,
                              child: MiniPlayerProgressBar(
                                  progressBarStatus:
                                      controller.progressBarStatus.value,
                                  progressBarColor: Theme.of(context)
                                          .progressIndicatorTheme
                                          .linearTrackColor ??
                                      Colors.white)),
                        )
                      : GetX<PlayerController>(builder: (controller) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 15.0, top: 8, right: 15, bottom: 0),
                            child: ProgressBar(
                              timeLabelLocation: TimeLabelLocation.sides,
                              thumbRadius: 7,
                              barHeight: 4,
                              thumbGlowRadius: 15,
                              baseBarColor: Theme.of(context)
                                  .sliderTheme
                                  .inactiveTrackColor,
                              bufferedBarColor: Theme.of(context)
                                  .sliderTheme
                                  .valueIndicatorColor,
                              progressBarColor: Theme.of(context)
                                  .sliderTheme
                                  .activeTrackColor,
                              thumbColor:
                                  Theme.of(context).sliderTheme.thumbColor,
                              timeLabelTextStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              progress:
                                  controller.progressBarStatus.value.current,
                              total: controller.progressBarStatus.value.total,
                              buffered:
                                  controller.progressBarStatus.value.buffered,
                              onSeek: controller.seek,
                            ),
                          );
                        }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 17.0, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            playerController.currentSong.value != null
                                ? ImageWidget(
                                    size: 50,
                                    song: playerController.currentSong.value!,
                                  )
                                : const SizedBox(
                                    height: 50,
                                    width: 50,
                                  ),
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (DragEndDetails details) {
                              if (details.primaryVelocity! < 0) {
                                playerController.next();
                              } else if (details.primaryVelocity! > 0) {
                                playerController.prev();
                              }
                            },
                            child: ColoredBox(
                              color: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: Text(
                                      playerController.currentSong.value != null
                                          ? playerController
                                              .currentSong.value!.title
                                          : "",
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    child: Marquee(
                                      id: "${playerController.currentSong.value}_mini",
                                      delay: const Duration(milliseconds: 300),
                                      duration: const Duration(seconds: 5),
                                      child: Text(
                                        playerController.currentSong.value !=
                                                null
                                            ? playerController
                                                .currentSong.value!.artist!
                                            : "",
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        //player control
                        SizedBox(
                          width: isWideScreen && !bottomNavEnabled ? 450 : 90,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (isWideScreen && !bottomNavEnabled)
                                Row(
                                  children: [
                                    IconButton(
                                        iconSize: 20,
                                        onPressed:
                                            playerController.toggleFavourite,
                                        icon: Obx(() => Icon(
                                              playerController
                                                      .isCurrentSongFav.isFalse
                                                  ? Icons.favorite_border
                                                  : Icons.favorite,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .color,
                                            ))),
                                    IconButton(
                                        iconSize: 20,
                                        onPressed:
                                            playerController.toggleShuffleMode,
                                        icon: Obx(() => Icon(
                                              Ionicons.shuffle,
                                              color: playerController
                                                      .isShuffleModeEnabled
                                                      .value
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .color
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .color!
                                                      .withOpacity(0.2),
                                            ))),
                                  ],
                                ),
                              if (isWideScreen && !bottomNavEnabled)
                                SizedBox(
                                    width: 40,
                                    child: InkWell(
                                      onTap: (playerController
                                                  .currentQueue.isEmpty ||
                                              (playerController
                                                      .currentQueue.first.id ==
                                                  playerController
                                                      .currentSong.value?.id))
                                          ? null
                                          : playerController.prev,
                                      child: Icon(
                                        Icons.skip_previous,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .color,
                                        size: 35,
                                      ),
                                    )),
                              isWideScreen && !bottomNavEnabled
                                  ? Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      width: 58,
                                      height: 58,
                                      child: Center(
                                          child: AnimatedPlayButton(
                                        iconSize: isWideScreen ? 43 : 35,
                                      )))
                                  : SizedBox.square(
                                      dimension: 50,
                                      child: Center(
                                          child: AnimatedPlayButton(
                                        iconSize: isWideScreen ? 43 : 35,
                                      ))),
                              SizedBox(
                                  width: 40,
                                  child: Obx(() {
                                    final isLastSong =
                                        playerController.currentQueue.isEmpty ||
                                            (!(playerController
                                                        .isShuffleModeEnabled
                                                        .isTrue ||
                                                    playerController
                                                        .isQueueLoopModeEnabled
                                                        .isTrue) &&
                                                (playerController
                                                        .currentQueue.last.id ==
                                                    playerController.currentSong
                                                        .value?.id));
                                    return InkWell(
                                      onTap: isLastSong
                                          ? null
                                          : playerController.next,
                                      child: Icon(
                                        Icons.skip_next,
                                        color: isLastSong
                                            ? Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .color!
                                                .withOpacity(0.2)
                                            : Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .color,
                                        size: 35,
                                      ),
                                    );
                                  })),
                              if (isWideScreen && !bottomNavEnabled)
                                Row(
                                  children: [
                                    IconButton(
                                        iconSize: 20,
                                        onPressed:
                                            playerController.toggleLoopMode,
                                        icon: Icon(
                                          Icons.all_inclusive,
                                          color: playerController
                                                  .isLoopModeEnabled.value
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .color
                                              : Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .color!
                                                  .withOpacity(0.2),
                                        )),
                                    IconButton(
                                        iconSize: 20,
                                        onPressed: () {
                                          playerController.showLyrics();
                                          showDialog(
                                                  builder: (context) =>
                                                      const LyricsDialog(),
                                                  context: context)
                                              .whenComplete(() {
                                            playerController
                                                    .isDesktopLyricsDialogOpen =
                                                false;
                                            playerController
                                                .showLyricsflag.value = false;
                                          });
                                          playerController
                                              .isDesktopLyricsDialogOpen = true;
                                        },
                                        icon: Icon(Icons.lyrics_outlined,
                                            color: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .color)),
                                  ],
                                ),
                              if (isWideScreen && !bottomNavEnabled)
                                const SizedBox(
                                  width: 20,
                                )
                            ],
                          ),
                        ),
                        if (isWideScreen && !bottomNavEnabled)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: size.width < 1004 ? 0 : 30.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(
                                        right: 20, left: 10),
                                    height: 20,
                                    width: (size.width > 860) ? 220 : 180,
                                    child: Obx(() {
                                      final volume =
                                          playerController.volume.value;
                                      return Row(
                                        children: [
                                          SizedBox(
                                              width: 20,
                                              child: InkWell(
                                                onTap: playerController.mute,
                                                child: Icon(
                                                  volume == 0
                                                      ? Icons.volume_off
                                                      : volume > 0 &&
                                                              volume < 50
                                                          ? Icons.volume_down
                                                          : Icons.volume_up,
                                                  size: 20,
                                                ),
                                              )),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                trackHeight: 2,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                        enabledThumbRadius:
                                                            6.0),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                        overlayRadius: 10.0),
                                              ),
                                              child: Slider(
                                                value: playerController
                                                        .volume.value /
                                                    100,
                                                onChanged: (value) {
                                                  playerController.setVolume(
                                                      (value * 100).toInt());
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            playerController
                                                .homeScaffoldkey.currentState!
                                                .openEndDrawer();
                                          },
                                          icon: const Icon(Icons.queue_music),
                                        ),
                                        if (size.width > 860)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10.0),
                                            child: IconButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 500),
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                    10.0)),
                                                  ),
                                                  isScrollControlled: true,
                                                  context: playerController
                                                      .homeScaffoldkey
                                                      .currentState!
                                                      .context,
                                                  barrierColor: Colors
                                                      .transparent
                                                      .withAlpha(100),
                                                  builder: (context) =>
                                                      const SleepTimerBottomSheet(),
                                                );
                                              },
                                              icon: Icon(playerController
                                                      .isSleepTimerActive.isTrue
                                                  ? Icons.timer
                                                  : Icons.timer_outlined),
                                            ),
                                          ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const SongDownloadButton(
                                          calledFromPlayer: true,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            final currentSong = playerController
                                                .currentSong.value;
                                            if (currentSong != null) {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AddToPlaylist(
                                                        [currentSong]),
                                              ).whenComplete(() => Get.delete<
                                                  AddToPlaylistController>());
                                            }
                                          },
                                          icon: const Icon(Icons.playlist_add),
                                        ),
                                        if (size.width > 965)
                                          IconButton(
                                            onPressed: () {
                                              final currentSong =
                                                  playerController
                                                      .currentSong.value;
                                              if (currentSong != null) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      SongInfoDialog(
                                                    song: currentSong,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.info,
                                                size: 22),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ],
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
