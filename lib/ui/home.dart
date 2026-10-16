import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/ui/screens/Home/home_screen_controller.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../utils/helper.dart';
import '../ui/navigator.dart';
import '../ui/player/player.dart';
import 'player/components/mini_player.dart';
import 'player/player_controller.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/scroll_to_hide.dart';
import 'widgets/sliding_up_panel.dart';
import 'widgets/snackbar.dart';
import 'widgets/up_next_queue.dart';

class Home extends StatelessWidget {
  const Home({super.key});
  static const routeName = '/appHome';
  static DateTime? _lastBackPressTime;
  @override
  Widget build(BuildContext context) {
    printINFO("Home");
    final PlayerController playerController = Get.find<PlayerController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    final homeScreenController = Get.find<HomeScreenController>();
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;
    if (!playerController.initFlagForPlayer &&
        settingsScreenController.isBottomNavBarEnabled.isFalse) {
      if (isWideScreen) {
        playerController.playerPanelMinHeight.value =
            105 + Get.mediaQuery.padding.bottom;
      } else {
        playerController.playerPanelMinHeight.value =
            75 + Get.mediaQuery.padding.bottom;
      }
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // 1. If any modal bottom sheet (e.g. lyrics search sheet) or dialog is open, pop it first!
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        // 2. If queue panel is open, close queue panel
        if (playerController.queuePanelController.isAttached &&
            playerController.queuePanelController.isPanelOpen) {
          playerController.queuePanelController.close();
          return;
        }
        // 3. If big player is open:
        if (playerController.playerPanelController.isAttached &&
            playerController.playerPanelController.isPanelOpen) {
          // If lyrics are showing, back button should dismiss lyrics to album art
          if (playerController.showLyricsflag.isTrue) {
            playerController.showLyricsflag.value = false;
            return;
          }
          if (playerController.queuePanelController.isAttached &&
              !playerController.queuePanelController.isPanelClosed) {
            playerController.queuePanelController.close();
          }
          playerController.playerPanelController.close();
          return;
        } else {
          if (Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.canPop()) {
            Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
          } else {
            if (homeScreenController.tabIndex.value != 0) {
              settingsScreenController.isBottomNavBarEnabled.isTrue
                  ? homeScreenController.onBottonBarTabSelected(0)
                  : homeScreenController.onSideBarTabSelected(0);
            } else {
              final now = DateTime.now();
              if (Home._lastBackPressTime == null ||
                  now.difference(Home._lastBackPressTime!) >
                      const Duration(seconds: 2)) {
                Home._lastBackPressTime = now;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.only(
                      bottom: (settingsScreenController.isBottomNavBarEnabled.isTrue ? 80 : 25) +
                          Get.mediaQuery.padding.bottom,
                      left: 45,
                      right: 45,
                    ),
                    content: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E24).withOpacity(0.92)
                              : Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.08),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.exit_to_app_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Press back again to exit",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                return;
              }

              // Double back confirmed - clean exit
              if (playerController.buttonState.value ==
                  PlayButtonState.playing) {
                SystemNavigator.pop();
              } else {
                await Get.find<AudioHandler>().customAction("saveSession");
                SystemNavigator.pop();
              }
            }
          }
        }
      },
      child: CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.space): playerController.playPause
        },
        child: Obx(
          () => Scaffold(
              bottomNavigationBar: settingsScreenController
                      .isBottomNavBarEnabled.isTrue
                  ? ScrollToHideWidget(
                      isVisible: homeScreenController.isHomeSreenOnTop.isTrue &&
                          playerController.isPanelGTHOpened.isFalse,
                      child: const BottomNavBar())
                  : null,
              key: playerController.homeScaffoldkey,
              endDrawer: GetPlatform.isDesktop || isWideScreen
                  ? Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10)),
                        border: Border(
                          left: BorderSide(
                              color: Theme.of(context).colorScheme.secondary),
                          top: BorderSide(
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      margin: const EdgeInsets.only(
                        top: 5,
                        bottom: 106,
                      ),
                      child: SizedBox(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 60,
                              child: ColoredBox(
                                color: Theme.of(context).canvasColor,
                                child: Center(
                                    child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0, right: 15),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          "${playerController.currentQueue.length} ${"songs".tr}"),
                                      Text(
                                        "upNext".tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              playerController
                                                  .toggleQueueLoopMode();
                                            },
                                            child: Obx(
                                              () => Container(
                                                height: 30,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                decoration: BoxDecoration(
                                                  color: playerController
                                                          .isQueueLoopModeEnabled
                                                          .isFalse
                                                      ? Colors.white24
                                                      : Colors.white
                                                          .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Center(
                                                    child:
                                                        Text("queueLoop".tr)),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                if (playerController
                                                    .isShuffleModeEnabled
                                                    .isTrue) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(snackbar(
                                                          context,
                                                          "queueShufflingDeniedMsg"
                                                              .tr,
                                                          size: SanckBarSize
                                                              .BIG));
                                                  return;
                                                }
                                                playerController.shuffleQueue();
                                              },
                                              icon: const Icon(Icons.shuffle)),
                                          IconButton(
                                              onPressed: () {
                                                playerController.clearQueue();
                                              },
                                              icon: const Icon(
                                                  Icons.playlist_remove)),
                                        ],
                                      )
                                    ],
                                  ),
                                )),
                              ),
                            ),
                            const Expanded(
                              child: UpNextQueue(
                                isQueueInSlidePanel: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
              drawerScrimColor: Colors.transparent,
              body: Obx(() => SlidingUpPanel(
                    color: Colors.transparent,
                    boxShadow: const [],
                    renderPanelSheet: false,
                    onPanelSlide: playerController.panellistener,
                    controller: playerController.playerPanelController,
                    minHeight: playerController.playerPanelMinHeight.value,
                    maxHeight: size.height,
                    isDraggable: !isWideScreen,
                    panel: const Player(),
                    body: const ScreenNavigation(),
                    header: const MiniPlayer(),
                  ))),
        ),
      ),
    );
  }
}
