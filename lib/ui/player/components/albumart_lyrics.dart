import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '../../screens/Settings/settings_screen_controller.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import 'lyrics_sources_sheet.dart';

class AlbumArtNLyrics extends StatelessWidget {
  const AlbumArtNLyrics({super.key, required this.playerArtImageSize});
  final double playerArtImageSize;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() => playerController.currentSong.value != null
        ? Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Glowing Shadow behind Album Art
              Container(
                width: playerArtImageSize - 16,
                height: playerArtImageSize - 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(isDark ? 0.35 : 0.22),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),

              // Album Art Image with Gestures & Rounded Corners
              GestureDetector(
                onTap: () {
                  if (playerController.currentSong.value != null) {
                    playerController.toggleLyrics(playerController.currentSong.value!);
                  }
                },
                onLongPress: () {
                  showModalBottomSheet(
                    constraints: const BoxConstraints(maxWidth: 500),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.0)),
                    ),
                    isScrollControlled: true,
                    context:
                        playerController.homeScaffoldkey.currentState!.context,
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (context) => SongInfoBottomSheet(
                      playerController.currentSong.value!,
                      calledFromPlayer: true,
                    ),
                  ).whenComplete(() => Get.delete<SongInfoController>());
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (playerController.showLyricsflag.isTrue) return;
                  if (details.primaryVelocity! < 0) {
                    playerController.next();
                  } else if (details.primaryVelocity! > 0) {
                    playerController.prev();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ImageWidget(
                    size: playerArtImageSize,
                    song: playerController.currentSong.value!,
                    isPlayerArtImage: true,
                  ),
                ),
              ),



              // Sleep Timer Active Badge
              if (playerController.isSleepTimerActive.isTrue)
                SizedBox(
                  width: playerArtImageSize,
                  height: playerArtImageSize,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Obx(() {
                              final leftSec =
                                  playerController.timerDurationLeft.value;
                              final min =
                                  (leftSec ~/ 60).toString().padLeft(2, '0');
                              final sec =
                                  (leftSec % 60).toString().padLeft(2, '0');
                              return Text(
                                "$min:$sec",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
        : const SizedBox.shrink());
  }
}
