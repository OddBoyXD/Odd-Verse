import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../utils/helper.dart';

class ShareSongBottomSheet extends StatelessWidget {
  const ShareSongBottomSheet({super.key, required this.song});
  final MediaItem song;

  static void show(BuildContext context, MediaItem song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareSongBottomSheet(song: song),
    );
  }

  Future<void> _shareAudioFile(BuildContext context) async {
    Navigator.of(context).pop();

    // Show persistent progress dialog on screen
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Preparing M4A Audio...",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Downloading audio track for sharing",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final safeTitle = "${song.title} - ${song.artist}"
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final cacheDir = (await getTemporaryDirectory()).path;

      // 1. Check if song is already downloaded
      if (Hive.isBoxOpen("SongDownloads")) {
        final downloadData = Hive.box("SongDownloads").get(song.id);
        if (downloadData != null && downloadData['path'] != null) {
          final file = File(downloadData['path']);
          if (await file.exists() && (await file.length()) > 50000) {
            final shareM4aFile = File("$cacheDir/$safeTitle.m4a");
            await file.copy(shareM4aFile.path);
            if (Get.isDialogOpen ?? false) Get.back();
            await Share.shareXFiles(
              [
                XFile(
                  shareM4aFile.path,
                  mimeType: 'audio/mp4',
                  name: '$safeTitle.m4a',
                )
              ],
              text: "${song.title} - ${song.artist}",
            );
            return;
          }
        }
      }

      // 2. Check if song is in local cache
      final cachedFile = File("$cacheDir/cachedSongs/${song.id}.mp3");
      if (await cachedFile.exists() && (await cachedFile.length()) > 50000) {
        final shareFile = File("$cacheDir/$safeTitle.m4a");
        await cachedFile.copy(shareFile.path);
        if (Get.isDialogOpen ?? false) Get.back();
        await Share.shareXFiles(
          [
            XFile(
              shareFile.path,
              mimeType: 'audio/mp4',
              name: '$safeTitle.m4a',
            )
          ],
          text: "${song.title} - ${song.artist}",
        );
        return;
      }

      // 3. Download audio stream reliably via YoutubeExplode
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(song.id);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        yt.close();
        if (Get.isDialogOpen ?? false) Get.back();
        Get.rawSnackbar(
          message: "Could not find audio streams for this track.",
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Prefer MP4/M4A AAC audio stream
      final audioStreamInfo = audioStreams.firstWhere(
        (s) =>
            s.container.name.toLowerCase().contains('mp4') ||
            s.audioCodec.toLowerCase().contains('mp4') ||
            s.audioCodec.toLowerCase().contains('aac'),
        orElse: () => audioStreams.withHighestBitrate(),
      );

      final stream = yt.videos.streamsClient.get(audioStreamInfo);
      final shareFile = File("$cacheDir/$safeTitle.m4a");
      if (await shareFile.exists()) {
        try {
          await shareFile.delete();
        } catch (_) {}
      }

      final fileStream = shareFile.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();
      yt.close();

      // Close progress dialog once download completes
      if (Get.isDialogOpen ?? false) Get.back();

      if (await shareFile.exists() && (await shareFile.length()) > 1000) {
        await Share.shareXFiles(
          [
            XFile(
              shareFile.path,
              mimeType: 'audio/mp4',
              name: '$safeTitle.m4a',
            )
          ],
          text: "${song.title} - ${song.artist}",
        );
      } else {
        Get.rawSnackbar(
          message: "Failed to create M4A audio file.",
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      printERROR("Error sharing audio file: $e");
      Get.rawSnackbar(
        message: "Failed to share audio: $e",
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _shareLink(BuildContext context) {
    Navigator.of(context).pop();
    Share.share("https://youtube.com/watch?v=${song.id}");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 20, left: 15, right: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "Share",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                "${song.title} • ${song.artist}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.audio_file_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text(
                "Share Audio File (M4A)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Send playable M4A audio file to WhatsApp, Telegram, etc.",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () => _shareAudioFile(context),
            ),
            const SizedBox(height: 5),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text(
                "Share Link",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Send YouTube Music web link",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () => _shareLink(context),
            ),
          ],
        ),
      ),
    );
  }
}
