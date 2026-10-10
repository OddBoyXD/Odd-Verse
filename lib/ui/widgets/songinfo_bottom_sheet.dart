import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/downloader.dart';
import '../screens/Playlist/playlist_screen_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import '/utils/helper.dart';
import '/services/piped_service.dart';
import '/ui/widgets/sleep_timer_bottom_sheet.dart';
import '/ui/player/player_controller.dart';
import '../screens/Library/library_controller.dart';
import '/ui/widgets/add_to_playlist.dart';
import '/ui/widgets/snackbar.dart';
import '../../models/media_Item_builder.dart';
import '../../models/playlist.dart';
import '../navigator.dart';
import 'song_download_btn.dart';
import 'image_widget.dart';
import 'song_info_dialog.dart';
import 'share_song_bottom_sheet.dart';
import 'playback_speed_pitch_bottom_sheet.dart';

class SongInfoBottomSheet extends StatelessWidget {
  const SongInfoBottomSheet(this.song,
      {super.key,
      this.playlist,
      this.calledFromPlayer = false,
      this.calledFromQueue = false});
  final MediaItem song;
  final Playlist? playlist;
  final bool calledFromPlayer;
  final bool calledFromQueue;

  @override
  Widget build(BuildContext context) {
    final songInfoController =
        Get.put(SongInfoController(song, calledFromPlayer));
    final playerController = Get.find<PlayerController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.98)
            : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        left: 12,
        right: 12,
        bottom: Get.mediaQuery.padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(isDark ? 0.6 : 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.08 : 0.04),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ImageWidget(
                      song: song,
                      size: 54,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Fav / Info Icon
                  calledFromPlayer
                      ? IconButton(
                          onPressed: () => showDialog(
                                context: context,
                                builder: (context) => SongInfoDialog(
                                  song: song,
                                ),
                              ),
                          icon: Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.secondary,
                            size: 24,
                          ))
                      : IconButton(
                          onPressed: songInfoController.toggleFav,
                          icon: Obx(() => Icon(
                                songInfoController.isCurrentSongFav.isFalse
                                    ? Icons.favorite_border_rounded
                                    : Icons.favorite_rounded,
                                color: songInfoController.isCurrentSongFav.isTrue
                                    ? Colors.redAccent
                                    : theme.textTheme.titleMedium?.color,
                                size: 24,
                              ))),
                  SongDownloadButton(
                    song_: song,
                    isDownloadingDoneCallback:
                        songInfoController.setDownloadStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Quick Action Chips
            Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    context: context,
                    icon: Icons.sensors_rounded,
                    label: "startRadio".tr,
                    onTap: () {
                      Navigator.of(context).pop();
                      playerController.startRadio(song);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickActionButton(
                    context: context,
                    icon: Icons.playlist_add_rounded,
                    label: "addToPlaylist".tr,
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AddToPlaylist([song]),
                      ).whenComplete(() => Get.delete<AddToPlaylistController>());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickActionButton(
                    context: context,
                    icon: Icons.share_rounded,
                    label: "shareSong".tr,
                    onTap: () {
                      Navigator.of(context).pop();
                      ShareSongBottomSheet.show(context, song);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Actions List Section
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(isDark ? 0.45 : 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.03),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  if (!calledFromPlayer && !calledFromQueue) ...[
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.playlist_play_rounded),
                      title: Text("playNext".tr),
                      onTap: () {
                        Navigator.of(context).pop();
                        playerController.playNext(song);
                        ScaffoldMessenger.of(context).showSnackBar(snackbar(
                            context, "${"playnextMsg".tr} ${song.title}",
                            size: SanckBarSize.BIG));
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.merge_rounded),
                      title: Text("enqueueSong".tr),
                      onTap: () {
                        playerController.enqueueSong(song).whenComplete(() {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(snackbar(
                              context, "songEnqueueAlert".tr,
                              size: SanckBarSize.MEDIUM));
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  if (song.extras!['album'] != null)
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.album_rounded),
                      title: Text("goToAlbum".tr),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (calledFromPlayer || calledFromQueue) {
                          playerController.playerPanelController.close();
                        }
                        Get.toNamed(ScreenNavigationSetup.albumScreen,
                            id: ScreenNavigationSetup.id,
                            arguments: (null, song.extras!['album']['id']));
                      },
                    ),
                  ...artistWidgetList(song, context),
                  if (calledFromPlayer) ...[
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.timer_outlined),
                      title: Text("sleepTimer".tr),
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          constraints: const BoxConstraints(maxWidth: 500),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.0)),
                          ),
                          isScrollControlled: true,
                          context: playerController
                              .homeScaffoldkey.currentState!.context,
                          barrierColor: Colors.transparent.withAlpha(100),
                          builder: (context) =>
                              const SleepTimerBottomSheet(),
                        );
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.speed_rounded),
                      title: const Text("Playback Speed & Pitch"),
                      trailing: Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${playerController.playbackSpeed.value.toStringAsFixed(2)}x",
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          constraints: const BoxConstraints(maxWidth: 500),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.0)),
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
                  ],
                  // Open In (YouTube / YouTube Music)
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    leading: const Icon(Icons.open_in_new_rounded),
                    title: Text("openIn".tr),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            launchUrl(Uri.parse(
                                "https://youtube.com/watch?v=${song.id}"));
                          },
                          icon: const Icon(Ionicons.logo_youtube,
                              color: Colors.redAccent, size: 22),
                        ),
                        IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            launchUrl(Uri.parse(
                                "https://music.youtube.com/watch?v=${song.id}"));
                          },
                          icon: Icon(Ionicons.play_circle,
                              color: theme.colorScheme.secondary, size: 22),
                        )
                      ],
                    ),
                  ),
                  // Playlist remove / Queue remove / Delete Download
                  if ((playlist != null &&
                          !playlist!.isCloudPlaylist &&
                          !(playlist!.playlistId == "LIBRP")) ||
                      (playlist != null && playlist!.isPipedPlaylist))
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      title: Text(
                        playlist!.title == "Library Songs"
                            ? "removeFromLib".tr
                            : "removeFromPlaylist".tr,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        songInfoController
                            .removeSongFromPlaylist(song, playlist!)
                            .whenComplete(() => ScaffoldMessenger.of(Get.context!)
                                .showSnackBar(snackbar(Get.context!,
                                    "Removed from ${playlist!.title}",
                                    size: SanckBarSize.MEDIUM)));
                      },
                    ),
                  if (calledFromQueue)
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent),
                      title: Text("removeFromQueue".tr,
                          style: const TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (playerController.currentSong.value!.id == song.id) {
                          ScaffoldMessenger.of(context).showSnackBar(snackbar(
                              context, "songRemovedfromQueueCurrSong".tr,
                              size: SanckBarSize.BIG));
                        } else {
                          playerController.removeFromQueue(song);
                          ScaffoldMessenger.of(context).showSnackBar(snackbar(
                              context, "songRemovedfromQueue".tr,
                              size: SanckBarSize.MEDIUM));
                        }
                      },
                    ),
                  Obx(
                    () => (songInfoController.isDownloaded.isTrue &&
                            (playlist?.playlistId != "SongDownloads" &&
                                playlist?.playlistId != "SongsCache"))
                        ? ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            leading: const Icon(Icons.delete_forever_rounded,
                                color: Colors.redAccent),
                            title: Text("deleteDownloadData".tr,
                                style: const TextStyle(color: Colors.redAccent)),
                            onTap: () {
                              Navigator.of(context).pop();
                              final box = Hive.box("SongDownloads");
                              Get.find<LibrarySongsController>()
                                  .removeSong(song, true,
                                      url: box.get(song.id)['url'])
                                  .then((value) async {
                                box.delete(song.id).then((value) {
                                  if (playlist != null) {
                                    Get.find<PlaylistScreenController>(
                                            tag: Key(playlist!.playlistId)
                                                .hashCode
                                                .toString())
                                        .checkDownloadStatus();
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        snackbar(context,
                                            "deleteDownloadedDataAlert".tr,
                                            size: SanckBarSize.BIG));
                                  }
                                });
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(isDark ? 0.5 : 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.04),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.secondary),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> artistWidgetList(MediaItem song, BuildContext context) {
    final artistList = [];
    final artists = song.extras!['artists'];
    if (artists != null) {
      for (dynamic each in artists) {
        if (each.containsKey("id") && each['id'] != null) artistList.add(each);
      }
    }
    return artistList.isNotEmpty
        ? artistList
            .map((e) => ListTile(
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (calledFromPlayer) {
                      Get.find<PlayerController>()
                          .playerPanelController
                          .close();
                    }
                    if (calledFromQueue) {
                      final playerController = Get.find<PlayerController>();
                      playerController.playerPanelController.close();
                    }
                    await Get.toNamed(ScreenNavigationSetup.artistScreen,
                        id: ScreenNavigationSetup.id,
                        preventDuplicates: true,
                        arguments: [true, e['id']]);
                  },
                  tileColor: Colors.transparent,
                  leading: const Icon(Icons.person),
                  title: Text("${"viewArtist".tr} (${e['name']})"),
                ))
            .toList()
        : [const SizedBox.shrink()];
  }
}

class SongInfoController extends GetxController
    with RemoveSongFromPlaylistMixin {
  final isCurrentSongFav = false.obs;
  final MediaItem song;
  final bool calledFromPlayer;
  List artistList = [].obs;
  final isDownloaded = false.obs;
  SongInfoController(this.song, this.calledFromPlayer) {
    _setInitStatus(song);
  }
  _setInitStatus(MediaItem song) async {
    isDownloaded.value = Hive.box("SongDownloads").containsKey(song.id);
    isCurrentSongFav.value =
        (await Hive.openBox("LIBFAV")).containsKey(song.id);
    final artists = song.extras!['artists'];
    if (artists != null) {
      for (dynamic each in artists) {
        if (each.containsKey("id") && each['id'] != null) artistList.add(each);
      }
    }
  }

  void setDownloadStatus(bool isDownloaded_) {
    if (isDownloaded_) {
      Future.delayed(const Duration(milliseconds: 100),
          () => isDownloaded.value = isDownloaded_);
    }
  }

  Future<void> toggleFav() async {
    if (calledFromPlayer) {
      final cntrl = Get.find<PlayerController>();
      if (cntrl.currentSong.value == song) {
        cntrl.toggleFavourite();
        isCurrentSongFav.value = !isCurrentSongFav.value;
        return;
      }
    }
    final box = await Hive.openBox("LIBFAV");
    isCurrentSongFav.isFalse
        ? box.put(song.id, MediaItemBuilder.toJson(song))
        : box.delete(song.id);
    isCurrentSongFav.value = !isCurrentSongFav.value;
    if (Get.find<SettingsScreenController>()
            .autoDownloadFavoriteSongEnabled
            .isTrue &&
        isCurrentSongFav.isTrue) {
      Get.find<Downloader>().download(song);
    }
  }
}

mixin RemoveSongFromPlaylistMixin {
  Future<void> removeSongFromPlaylist(MediaItem item, Playlist playlist) async {
    final box = await Hive.openBox(playlist.playlistId);
    //Library songs case
    if (playlist.playlistId == "SongsCache") {
      if (!box.containsKey(item.id)) {
        Hive.box("SongDownloads").delete(item.id);
        Get.find<LibrarySongsController>().removeSong(item, true);
      } else {
        Get.find<LibrarySongsController>().removeSong(item, false);
        box.delete(item.id);
      }
    } else if (playlist.playlistId == "SongDownloads") {
      box.delete(item.id);
      Get.find<LibrarySongsController>().removeSong(item, true);
    } else if (!playlist.isPipedPlaylist) {
      //Other playlist song case
      final index =
          box.values.toList().indexWhere((ele) => ele['videoId'] == item.id);
      await box.deleteAt(index);
    }

    // this try catch block is to handle the case when song is removed from libsongs sections
    try {
      final plstCntroller = Get.find<PlaylistScreenController>(
          tag: Key(playlist.playlistId).hashCode.toString());
      if (playlist.isPipedPlaylist) {
        final res = await Get.find<PipedServices>()
            .getPlaylistSongs(playlist.playlistId);
        final songIndex = res.indexWhere((element) => element.id == item.id);
        if (songIndex != -1) {
          final res = await Get.find<PipedServices>()
              .removeFromPlaylist(playlist.playlistId, songIndex);
          if (res.code == 1) {
            plstCntroller.addNRemoveItemsinList(item, action: 'remove');
          }
        }
        return;
      }

      try {
        plstCntroller.addNRemoveItemsinList(item, action: 'remove');
        // ignore: empty_catches
      } catch (e) {}
    } catch (e) {
      printERROR("Some Error in removeSongFromPlaylist (might irrelavant): $e");
    }

    if (playlist.playlistId == "SongDownloads" ||
        playlist.playlistId == "SongsCache") {
      return;
    }
    box.close();
  }
}
