import 'dart:io';

import 'package:get/get.dart';
import '/models/media_Item_builder.dart';
import '/ui/screens/Library/library_controller.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/utils.dart';
import 'helper.dart';

void startHouseKeeping() {
  removeExpiredSongsUrlFromDb();
  compactHiveBoxes();
  pruneThumbnailCache();
}

Future<void> compactHiveBoxes() async {
  try {
    final boxesToCompact = [
      "SongsUrlCache",
      "SongDownloads",
      "SongsCache",
      "searchQuery",
      "AppPrefs",
    ];
    for (final boxName in boxesToCompact) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).compact();
      }
    }
  } catch (e) {
    printERROR("Error in compactHiveBoxes: $e");
  }
}

Future<void> pruneThumbnailCache() async {
  try {
    final supportDir = (await getApplicationSupportDirectory()).path;
    final thumbDir = Directory("$supportDir/thumbnails");
    if (!await thumbDir.exists()) return;

    final songDownloadsBox = Hive.box("SongDownloads");
    final validSongIds = songDownloadsBox.keys.toSet();

    final files = thumbDir.listSync();
    int totalBytes = 0;
    List<File> orphanFiles = [];

    for (var fileEntity in files) {
      if (fileEntity is File) {
        final length = await fileEntity.length();
        totalBytes += length;
        final filename = fileEntity.uri.pathSegments.last;
        final songId = filename.replaceAll(".png", "");
        if (!validSongIds.contains(songId)) {
          orphanFiles.add(fileEntity);
        }
      }
    }

    // If total thumbnail cache exceeds 50 MB, prune orphaned files
    if (totalBytes > 50 * 1024 * 1024) {
      for (var f in orphanFiles) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  } catch (e) {
    printERROR("Error in pruneThumbnailCache: $e");
  }
}

Future<void> removeExpiredSongsUrlFromDb() async {
  try {
    final songsUrlCacheBox = Hive.box("SongsUrlCache");
    final songsUrlCacheKeysList =
        songsUrlCacheBox.keys.whereType<String>().toList();
    for (var i = 0; i < songsUrlCacheKeysList.length; i++) {
      final songUrlKey = songsUrlCacheKeysList[i];
      final streamData = songsUrlCacheBox.get(songUrlKey)[1];
      if (streamData == null ||
          streamData.runtimeType == String ||
          (streamData != null && isExpired(url: streamData['url'] as String))) {
        await songsUrlCacheBox.delete(songUrlKey);
      }
    }
  } catch (e) {
    printERROR("Error in removeExpiredSongsUrlFromDb: $e");
  } finally {
    removeDeletedOfflineSongsFromDb();
  }
}

Future<void> removeDeletedOfflineSongsFromDb() async {
  final supportDir = (await getApplicationSupportDirectory()).path;
  try {
    final songDownloadsBox = Hive.box("SongDownloads");
    final downloadedSongs = songDownloadsBox.values.toList();
    final LibrarySongsController librarySongsController =
        Get.find<LibrarySongsController>();
    for (var i = 0; i < downloadedSongs.length; i++) {
      final songKey = downloadedSongs[i]['videoId'];
      final songUrl = downloadedSongs[i]['url'];
      if (await File(songUrl).exists() == false) {
        await songDownloadsBox.delete(songKey);
        await librarySongsController.removeSong(
            MediaItemBuilder.fromJson(downloadedSongs[i]), true);
        final thumbNailPath = "$supportDir/thumbnails/$songKey.png";
        if (await File(thumbNailPath).exists()) {
          await File(thumbNailPath).delete();
        }
      }
    }
  } catch (e) {
    printERROR("Error in removeDeletedOfflineSongsFromDb: $e");
  }
}
