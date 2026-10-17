import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../screens/Settings/settings_screen_controller.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/playback_speed_pitch_bottom_sheet.dart';
import '../player_controller.dart';
import 'albumart_lyrics.dart';
import 'backgroud_image.dart';
import 'lyrics_switch.dart';
import 'lyrics_top_bar.dart';
import 'lyrics_widget.dart';
import 'player_control.dart';

/// Standard player widget
///
/// This widget is used to display the player in the standard mode
///
/// It contains the album art image, lyrics switch, album art with lyrics and player controls
/// and is used in the [Player] widget
class StandardPlayer extends StatelessWidget {
  const StandardPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final PlayerController playerController = Get.find<PlayerController>();
    final SettingsScreenController settingsController =
        Get.find<SettingsScreenController>();

    double playerArtImageSize =
        size.width - 60; //((size.height < 750) ? 90 : 60);
    //playerArtImageSize = playerArtImageSize > 350 ? 350 : playerArtImageSize;
    final spaceAvailableForArtImage =
        size.height - (70 + Get.mediaQuery.padding.bottom + 330);
    playerArtImageSize = playerArtImageSize > spaceAvailableForArtImage
        ? spaceAvailableForArtImage
        : playerArtImageSize;
    return Obx(() {
      final fullPlayerOpacity =
          (1.0 - playerController.playerPaneOpacity.value).clamp(0.0, 1.0);
      if (fullPlayerOpacity <= 0.01) {
        return const SizedBox.shrink();
      }
      final isLiteMode =
          settingsController.isTransitionAnimationDisabled.isTrue;

      final backgroundOverlay = Stack(
        children: [
          /// opacity effect on background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isLiteMode
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.8),
              ),
            ),
          ),

          /// used to hide queue header when player is minimized
          /// gradient to used here
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 65 + Get.mediaQuery.padding.bottom + 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.4),
                    Theme.of(context).primaryColor.withOpacity(0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0, 0.5, 0.8, 1],
                ),
              ),
            ),
          ),
        ],
      );

      return Opacity(
        opacity: fullPlayerOpacity,
        child: Stack(
          children: [
            /// Stack first child
            /// Album art image in background covering the whole screen (skipped in Lite Mode to save RAM)
            if (!isLiteMode)
              BackgroudImage(
                key: Key("${playerController.currentSong.value?.id}_background"),
                cacheHeight: 200,
              ),

            /// Stack child
            /// Blur effect on background (bypassed in Lite Mode for 0 GPU overhead)
            if (isLiteMode)
              backgroundOverlay
            else
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: backgroundOverlay,
              ),

        /// Stack child
        /// Player content in landscape mode
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: (context.isLandscape)
              ? Obx(() {
                  final isLyrics = playerController.showLyricsflag.value;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: size.width * .45,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 90.0, top: 40),
                          child: Center(
                            child: isLyrics
                                ? Column(
                                    children: [
                                      const LyricsTopBar(),
                                      Expanded(
                                        child: const LyricsWidget(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                    ],
                                  )
                                : AlbumArtNLyrics(
                                    playerArtImageSize: size.width * .29,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: size.width * .48,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 10.0,
                              right: 10,
                              bottom: Get.mediaQuery.padding.bottom),
                          child: const PlayerControlWidget(),
                        ),
                      ),
                    ],
                  );
                })
              :
              Column(
                children: [
                  Expanded(
                    child: Obx(() {
                      final isLyrics = playerController.showLyricsflag.value;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: isLyrics
                            ? KeyedSubtree(
                                key: const ValueKey("lyrics_screen"),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: Get.mediaQuery.padding.top + 56,
                                    ),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 500),
                                      child: const LyricsTopBar(),
                                    ),
                                    Expanded(
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 500),
                                        child: const LyricsWidget(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey("album_art_screen"),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: size.height < 750 ? 110 : 140,
                                    ),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 500),
                                      child: AlbumArtNLyrics(
                                          playerArtImageSize:
                                              playerArtImageSize),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                      );
                    }),
                  ),
                  // Player Controls Container - 100% STATIC & ANCHORED AT THE BOTTOM
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: 80 + Get.mediaQuery.padding.bottom),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: const PlayerControlWidget(),
                    ),
                  ),
                ],
              ),
        ),

        /// Stack child
        /// Contains [Minimize button], Playing from [Album name], [More button] for current song context
        /// This is not visible in mobile devices in landscape mode
        if (!(context.isLandscape && GetPlatform.isMobile))
          Padding(
            padding: EdgeInsets.only(
                top: Get.mediaQuery.padding.top + 10, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Minimize button
                IconButton(
                  tooltip: "Minimize",
                  splashRadius: 22,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    if (playerController.showLyricsflag.value) {
                      playerController.showLyricsflag.value = false;
                      return;
                    }
                    if (playerController.queuePanelController.isAttached &&
                        !playerController.queuePanelController.isPanelClosed) {
                      playerController.queuePanelController.close();
                    }
                    playerController.playerPanelController.close();
                  },
                ),

                /// Playing from [Album name]
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playerController.playinfrom.value.typeString.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\"${playerController.playinfrom.value.nameString}\"",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                /// More button for current song context
                IconButton(
                  tooltip: "More options",
                  splashRadius: 22,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      constraints: const BoxConstraints(maxWidth: 500),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10.0)),
                      ),
                      isScrollControlled: true,
                      context: playerController
                          .homeScaffoldkey.currentState!.context,
                      barrierColor: Colors.transparent.withAlpha(100),
                      builder: (context) => SongInfoBottomSheet(
                        playerController.currentSong.value!,
                        calledFromPlayer: true,
                      ),
                    ).whenComplete(() => Get.delete<SongInfoController>());
                  },
                ),
              ],
            ),
          )
      ],
    ),
  );
});
}
}
