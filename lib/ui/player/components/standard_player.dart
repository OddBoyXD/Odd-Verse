import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/playback_speed_pitch_bottom_sheet.dart';
import '../player_controller.dart';
import 'albumart_lyrics.dart';
import 'backgroud_image.dart';
import 'lyrics_switch.dart';
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
      return Opacity(
        opacity: fullPlayerOpacity,
        child: Stack(
          children: [
            /// Stack first child
            /// Album art image in background covering the whole screen
            BackgroudImage(
              key: Key("${playerController.currentSong.value?.id}_background"),
              cacheHeight: 200,
            ),

        /// Stack child
        /// Blur effect on background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Stack(
            children: [
              /// opacity effect on background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
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
          ),
        ),

        /// Stack child
        /// Player content in landscape mode
        Padding(
          padding: const EdgeInsets.only(left: 25, right: 25),
          child: (context.isLandscape)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Album art with lyrics in .45  of width
                    SizedBox(
                      width: size.width * .45,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 90.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: AlbumArtNLyrics(
                              playerArtImageSize: size.width * .29,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Player controls in .48 of width
                    SizedBox(
                        width: size.width * .48,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 10.0,
                              right: 10,
                              bottom: Get.mediaQuery.padding.bottom),
                          child: const PlayerControlWidget(),
                        ))
                  ],
                )
              :

              /// Player content in portrait mode
              Column(
                  children: [
                    /// Work as top padding depending on the lyrics visibility and screen size
                    Obx(
                      () => playerController.showLyricsflag.value
                          ? SizedBox(
                              height: size.height < 750 ? 60 : 90,
                            )
                          : SizedBox(
                              height: size.height < 750 ? 110 : 140,
                            ),
                    ),

                    /// Contains the lyrics switch and album art with lyrics
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LyricsSwitch(),
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: AlbumArtNLyrics(
                                playerArtImageSize: playerArtImageSize)),
                      ],
                    ),

                    /// Extra space container
                    Expanded(child: Container()),

                    /// Contains the player controls
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: 80 + Get.mediaQuery.padding.bottom),
                      child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: const PlayerControlWidget()),
                    )
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
                  onPressed: playerController.playerPanelController.close,
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

                /// Playback Speed & Pitch micro-badge button
                IconButton(
                  tooltip: "Playback Speed & Pitch",
                  splashRadius: 20,
                  icon: Obx(() {
                    final speed = playerController.playbackSpeed.value;
                    final isModified = speed != 1.0 ||
                        playerController.playbackPitch.value != 1.0;
                    return Container(
                      width: 44,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isModified
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.35)
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isModified
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white.withOpacity(0.22),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        "${speed.toStringAsFixed(1)}x",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isModified
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                        ),
                      ),
                    );
                  }),
                  onPressed: () {
                    showModalBottomSheet(
                      constraints: const BoxConstraints(maxWidth: 500),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24.0)),
                      ),
                      isScrollControlled: true,
                      context: playerController
                          .homeScaffoldkey.currentState!.context,
                      barrierColor: Colors.transparent.withAlpha(100),
                      builder: (context) =>
                          const PlaybackSpeedPitchBottomSheet(),
                    );
                  },
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
