import 'dart:ui';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/ui/player/components/gesture_player.dart';
import '/ui/player/components/standard_player.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../utils/helper.dart';
import '../widgets/snackbar.dart';
import '../widgets/up_next_queue.dart';
import '/ui/player/player_controller.dart';
import '../widgets/sliding_up_panel.dart';

/// Player screen
/// Contains the player ui
///
/// Player ui can be standard player or gesture player
class Player extends StatelessWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    printINFO("player");
    final size = MediaQuery.of(context).size;
    final PlayerController playerController = Get.find<PlayerController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    return Obx(() {
      final fullPlayerOpacity =
          (1.0 - playerController.playerPaneOpacity.value).clamp(0.0, 1.0);
      if (fullPlayerOpacity <= 0.01) {
        return const SizedBox.shrink();
      }
      return Opacity(
        opacity: fullPlayerOpacity,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          /// SlidingUpPanel is used to create a panel that can slide up and down
          /// It is used to show the current queue panel in mobile
          body: Stack(
            children: [
              SlidingUpPanel(
                color: Colors.transparent,
                boxShadow: const [],
                minHeight: 0,
                maxHeight: size.height,
                isDraggable: !GetPlatform.isDesktop,
                onPanelSlide: (position) {
                  playerController.queueSlidePosition.value = position;
                },
                onPanelOpened: () {
                  playerController.queueSlidePosition.value = 1.0;
                },
                onPanelClosed: () {
                  playerController.queueSlidePosition.value = 0.0;
                },
                controller: GetPlatform.isDesktop
                    ? null
                    : playerController.queuePanelController,

                /// Panel for queue
                panelBuilder:
                    (ScrollController sc, onReorderStart, onReorderEnd) {
                  playerController.scrollController = sc;
                  return Stack(
                    children: [
                      /// Stack first child
                      /// UpNextQueue widget contains list of songs in queue
                      UpNextQueue(
                        onReorderEnd: onReorderEnd,
                        onReorderStart: onReorderStart,
                      ),

                      /// Stack second child
                      /// This contains the bottom bar with queue loop, shuffle, clear queue buttons
                      /// and number of songs in queue
                      /// BackdropFilter is used to blur the background
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.only(
                                  top: 15, bottom: 10, left: 10, right: 10),
                              decoration: BoxDecoration(
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black54)
                                  ],
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)),
                              height: 60 + Get.mediaQuery.padding.bottom,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    /// number of songs in queue
                                    Obx(
                                      () => Text(
                                        "${playerController.currentQueue.length} ${"songs".tr}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color),
                                      ),
                                    ),

                                    /// queue loop button
                                    InkWell(
                                      onTap: () {
                                        playerController.toggleQueueLoopMode();
                                      },
                                      child: Obx(
                                        () => Container(
                                          height: 30,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: playerController
                                                    .isQueueLoopModeEnabled
                                                    .isFalse
                                                ? Colors.white24
                                                : Colors.white.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                              child: Text("queueLoop".tr)),
                                        ),
                                      ),
                                    ),

                                    /// queue shuffle button
                                    InkWell(
                                      onTap: () {
                                        if (playerController
                                            .isShuffleModeEnabled.isTrue) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackbar(
                                                  context,
                                                  "queueShufflingDeniedMsg".tr,
                                                  size: SanckBarSize.BIG));
                                          return;
                                        }
                                        playerController.shuffleQueue();
                                      },
                                      child: Container(
                                        height: 30,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Center(
                                            child: Icon(Icons.shuffle,
                                                color: Colors.black)),
                                      ),
                                    ),

                                    /// clear queue button
                                    InkWell(
                                      onTap: () {
                                        playerController.clearQueue();
                                      },
                                      child: Container(
                                        height: 30,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Center(
                                            child: Icon(Icons.playlist_remove,
                                                color: Colors.black)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },

                /// show player ui based on selected player ui in settings
                /// Gesture player is only applicable for mobile
                body: settingsScreenController.playerUi.value == 0
                    ? const StandardPlayer()
                    : const GesturePlayer(),
              ),

              /// Dynamic animated arrow synchronized with queue slide position
              if (!GetPlatform.isDesktop)
                Obx(() {
                  final p =
                      playerController.queueSlidePosition.value.clamp(0.0, 1.0);
                  final bottomPadding = Get.mediaQuery.padding.bottom;
                  final topPadding = Get.mediaQuery.padding.top;
                  final bottomY = size.height - (55 + bottomPadding);
                  final topY = topPadding + 4;
                  final currentY = bottomY - p * (bottomY - topY);

                  return Positioned(
                    top: currentY,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (p < 0.5) {
                          playerController.queuePanelController.open();
                        } else {
                          playerController.queuePanelController.close();
                        }
                      },
                      onVerticalDragUpdate: (details) {
                        final delta = details.primaryDelta ?? 0;
                        final newPos =
                            (playerController.queueSlidePosition.value -
                                    delta / (size.height * 0.75))
                                .clamp(0.0, 1.0);
                        if (playerController.queuePanelController.isAttached) {
                          playerController
                              .queuePanelController.panelPosition = newPos;
                        }
                        playerController.queueSlidePosition.value = newPos;
                      },
                      onVerticalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity < -300) {
                          playerController.queuePanelController.open();
                        } else if (velocity > 300) {
                          playerController.queuePanelController.close();
                        } else if (playerController
                                .queueSlidePosition.value >
                            0.4) {
                          playerController.queuePanelController.open();
                        } else {
                          playerController.queuePanelController.close();
                        }
                      },
                      child: Container(
                        height: 50 + (1.0 - p) * bottomPadding,
                        width: double.infinity,
                        alignment: Alignment.topCenter,
                        color: Colors.transparent,
                        padding: const EdgeInsets.only(top: 4),
                        child: Transform.rotate(
                          angle: p * 3.141592653589793,
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .color
                                ?.withOpacity(0.7),
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    });
  }
}
