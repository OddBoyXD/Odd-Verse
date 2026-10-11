import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/downloader.dart';
import 'package:harmonymusic/ui/player/player_controller.dart';
import 'package:hive/hive.dart';

import 'loader.dart';
import 'snackbar.dart';

class SongDownloadButton extends StatelessWidget {
  const SongDownloadButton(
      {super.key,
      this.calledFromPlayer = false,
      this.song_,
      this.isDownloadingDoneCallback});
  final bool calledFromPlayer;
  final MediaItem? song_;
  final void Function(bool)? isDownloadingDoneCallback;

  String _getEstimatedDownloadSize(MediaItem? song) {
    if (song == null) return "";
    final format =
        Hive.box("AppPrefs").get("downloadingFormat", defaultValue: "m4a");
    final bitrateKbps = format == "opus" ? 160 : 140;
    final durationSec = song.duration?.inSeconds ?? 0;
    if (durationSec <= 0) return "~4.5 MB";
    final sizeMB = (durationSec * bitrateKbps) / (8 * 1024);
    return "~${sizeMB.toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final downloader = Get.find<Downloader>();
    final playerController = Get.find<PlayerController>();
    return Obx(() {
      final song =
          calledFromPlayer ? playerController.currentSong.value : song_;
      if (song == null) return const SizedBox.shrink();
      final currentSongItem = song;
      final isDownloadingDone = (downloader.songQueue.contains(currentSongItem) &&
          downloader.currentSong == currentSongItem &&
          downloader.songDownloadingProgress.value == 100);
      if (isDownloadingDoneCallback != null) {
        isDownloadingDoneCallback!(isDownloadingDone);
      }

      final isDownloaded = isDownloadingDone ||
          Hive.box("SongDownloads").containsKey(currentSongItem.id);
      final isCurrentlyDownloading = downloader.songQueue.contains(currentSongItem) &&
          downloader.isJobRunning.isTrue &&
          downloader.currentSong == currentSongItem;
      final isQueued = downloader.songQueue.contains(currentSongItem);

      Widget buttonWidget;
      if (isDownloaded) {
        buttonWidget = IconButton(
          tooltip: "Downloaded",
          icon: Icon(
            Icons.download_done_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(snackbar(
              context,
              "songAlreadyOfflineAlert".tr,
              size: SanckBarSize.MEDIUM,
            ));
          },
        );
      } else if (isCurrentlyDownloading) {
        buttonWidget = InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            downloader.cancelSongDownload(currentSongItem, deleteFile: true);
            ScaffoldMessenger.of(context).showSnackBar(snackbar(
              context,
              "Cancelled download for ${currentSongItem.title}",
              size: SanckBarSize.MEDIUM,
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LoadingIndicator(
                  dimension: 30,
                  strokeWidth: 3,
                  value: (downloader.songDownloadingProgress.value) / 100,
                ),
                const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        );
      } else if (isQueued) {
        buttonWidget = InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            downloader.cancelSongDownload(currentSongItem, deleteFile: true);
            ScaffoldMessenger.of(context).showSnackBar(snackbar(
              context,
              "Removed from download queue",
              size: SanckBarSize.MEDIUM,
            ));
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LoadingIndicator(dimension: 26, strokeWidth: 2.5),
                Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
              ],
            ),
          ),
        );
      } else {
        buttonWidget = IconButton(
          tooltip: "Download",
          icon: Icon(
            Icons.download_rounded,
            color: Theme.of(context).textTheme.titleMedium!.color,
            size: 24,
          ),
          onPressed: () {
            Hive.openBox("SongsCache").then((box) {
              if (box.containsKey(currentSongItem.id)) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(snackbar(
                    context, "songAlreadyOfflineAlert".tr,
                    size: SanckBarSize.BIG));
              } else {
                downloader.download(currentSongItem);
              }
            });
          },
        );
      }

      Widget bottomText;
      if (isCurrentlyDownloading) {
        bottomText = Text(
          "${downloader.songDownloadingProgress.value}%",
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        );
      } else if (isQueued) {
        bottomText = Text(
          "Queued",
          style: TextStyle(
            fontSize: 9.5,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        );
      } else if (isDownloaded) {
        bottomText = Text(
          "Downloaded",
          style: TextStyle(
            fontSize: 9.5,
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        );
      } else {
        bottomText = Text(
          _getEstimatedDownloadSize(song),
          style: TextStyle(
            fontSize: 9.5,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buttonWidget,
          bottomText,
        ],
      );
    });
  }
}
