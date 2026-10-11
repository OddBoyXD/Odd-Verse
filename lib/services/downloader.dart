import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../ui/screens/Album/album_screen_controller.dart';
import '../ui/screens/Playlist/playlist_screen_controller.dart';
import '/services/stream_service.dart';
import '../ui/widgets/snackbar.dart';
import '/services/permission_service.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '/utils/helper.dart';
import '/models/media_Item_builder.dart';
import '../ui/screens/Library/library_controller.dart';
import 'music_service.dart';
//import '../models/thumbnail.dart' as th;

class Downloader extends GetxService {
  final _dio = Dio();
  CancelToken? _currentCancelToken;
  String? _currentDownloadingFilePath;
  MediaItem? currentSong;
  RxMap<String, List<MediaItem>> playlistQueue =
      <String, List<MediaItem>>{}.obs;
  final currentPlaylistId = "".obs;
  final songDownloadingProgress = 0.obs;
  final playlistDownloadingProgress = 0.obs;
  final isJobRunning = false.obs;

  RxList<MediaItem> songQueue = <MediaItem>[].obs;

  Future<bool> checkPermissionNDir() async {
    final settingsScreenController = Get.find<SettingsScreenController>();

    if (!settingsScreenController.isCurrentPathsupportDownDir &&
        !await PermissionService.getExtStoragePermission()) {
      return false;
    }

    final dirPath =
        Get.find<SettingsScreenController>().downloadLocationPath.string;
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return true;
  }

  Future<void> downloadPlaylist(
      String playlistId, List<MediaItem> songList) async {
    if (!(await checkPermissionNDir())) return;

    // for toggle between downloading request & cancelling
    if (playlistQueue.containsKey(playlistId)) {
      songQueue.removeWhere((element) => songList.contains(element));
      playlistQueue.remove(playlistId);
      return;
    }

    playlistQueue[playlistId] = songList;
    songQueue.addAll(songList);

    if (isJobRunning.isFalse) {
      await triggerDownloadingJob();
    }
  }

  Future<void> download(MediaItem? song, {List<MediaItem>? songList}) async {
    if (!(await checkPermissionNDir())) return;
    if (songList != null) {
      songQueue.addAll(songList);
    } else {
      songQueue.add(song!);
    }
    if (isJobRunning.isFalse) {
      await triggerDownloadingJob();
    }
  }

  Future<void> triggerDownloadingJob() async {
    //check if playlist download in queue => download playlistsongs else download from general songs queue
    if (playlistQueue.isNotEmpty) {
      isJobRunning.value = true;
      for (String playlistId in playlistQueue.keys.toList()) {
        //checked in case download cancel request
        if (playlistQueue.containsKey(playlistId)) {
          currentPlaylistId.value = playlistId;
          await downloadSongList((playlistQueue[playlistId]!).toList(),
              isPlaylist: true);
          if (Get.isRegistered<PlaylistScreenController>(
                  tag: Key(playlistId).hashCode.toString()) &&
              playlistQueue.containsKey(playlistId)) {
            Get.find<PlaylistScreenController>(
                    tag: Key(playlistId).hashCode.toString())
                .isDownloaded
                .value = true;
          } 
          // in case of album
          else if (Get.isRegistered<AlbumScreenController>(
                  tag: Key(playlistId).hashCode.toString()) &&
              playlistQueue.containsKey(playlistId)) {
            Get.find<AlbumScreenController>(
                    tag: Key(playlistId).hashCode.toString())
                .isDownloaded
                .value = true;
          }
          playlistQueue.remove(playlistId);
        }
        currentPlaylistId.value = "";
        playlistDownloadingProgress.value = 0;
      }
    } else {
      isJobRunning.value = true;
      await downloadSongList(songQueue.toList());
    }

    if (songQueue.isNotEmpty) {
      triggerDownloadingJob();
    } else {
      isJobRunning.value = false;
      currentSong = null;
    }
  }

  Future<void> downloadSongList(List<MediaItem> jobSongList,
      {bool isPlaylist = false}) async {
    for (MediaItem song in jobSongList) {
      // intrrupt downloading task in case of playlist download cancel request
      if (isPlaylist && !playlistQueue.containsKey(currentPlaylistId.value)) {
        currentPlaylistId.value = "";
        playlistDownloadingProgress.value = 0;
        return;
      }

      if (!Hive.box("SongDownloads").containsKey(song.id)) {
        currentSong = song;
        songDownloadingProgress.value = 0;
        await writeFileStream(song);
      }
      songQueue.remove(song);
      //for playlist downloading counter update
      if (isPlaylist) {
        playlistDownloadingProgress.value = jobSongList.indexOf(song) + 1;
      }
    }
  }

  Future<void> writeFileStream(MediaItem song) async {
    Completer<void> complete = Completer();

    final settingsScreenController = Get.find<SettingsScreenController>();
    final downloadingFormat = settingsScreenController.downloadingFormat.string;

    final playerResponse = await StreamProvider.fetch(song.id);
    // if (!playerResponse.playable) {
    //   printINFO("Network error! Check your network connection.");
    //   ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
    //       Get.context!, playerResponse.statusMSG,
    //       size: SanckBarSize.BIG,
    //       duration: const Duration(seconds: 2),
    //       top: !GetPlatform.isDesktop));
    //   complete.complete();
    //   return complete.future;
    // }

    if (!playerResponse.playable) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!,
          playerResponse.statusMSG == "networkError"
              ? playerResponse.statusMSG.tr
              : playerResponse.statusMSG,
          size: SanckBarSize.BIG,
          duration: const Duration(seconds: 2),
          top: !GetPlatform.isDesktop));
      printINFO("Requested song is not downloadable. You may try again");
      complete.complete();
      return complete.future;
    }

    Audio requiredAudioStream = downloadingFormat == "opus"
        ? playerResponse.highestBitrateOpusAudio!
        : playerResponse.highestBitrateMp4aAudio!;

    final dirPath = settingsScreenController.downloadLocationPath.string;
    final actualDownformat =
        requiredAudioStream.audioCodec.name.contains("mp") ? "m4a" : "opus";
    final RegExp invalidChar =
        RegExp(r'Container.|\/|\\|\"|\<|\>|\*|\?|\:|\!|\[|\]|\¡|\||\%');
    final songTitle = "${song.title.trim()} (${song.artist?.trim()})"
        .replaceAll(invalidChar, "");
    String filePath = "$dirPath/$songTitle.$actualDownformat";
    printINFO("Downloading filePath: $filePath");
    final totalBytes = requiredAudioStream.size;

    _currentDownloadingFilePath = filePath;
    _currentCancelToken = CancelToken();

    _downloadStreamWithBurstChunks(
      url: requiredAudioStream.url,
      filePath: filePath,
      totalBytes: totalBytes,
      cancelToken: _currentCancelToken!,
      onReceiveProgress: (count, total) {
        if (total <= 0) return;
        songDownloadingProgress.value = ((count / total) * 100).clamp(0, 100).toInt();
      },
    ).then(
      (_) async {
        printINFO("File downloaded, tagging metadata...");

        String? year;
        try {
          if (song.extras?['year'] != null) {
            year = song.extras?['year'];
          } else {
            if (song.album != null) {
              final musicServ = Get.find<MusicServices>();
              year = await musicServ.getSongYear(song.id);
            }
          }
        } catch (_) {}

        // Save Thumbnail
        try {
          final thumbDir = Directory(
              "${settingsScreenController.supportDirPath}/thumbnails");
          if (!thumbDir.existsSync()) {
            thumbDir.createSync(recursive: true);
          }
          final thumbnailPath = "${thumbDir.path}/${song.id}.png";
          if (song.artUri != null) {
            await _dio.downloadUri(song.artUri!, thumbnailPath);
          }
        } catch (e) {
          printERROR("Error saving thumbnail: $e");
        }

        song.extras?['url'] = filePath;
        final songJson = MediaItemBuilder.toJson(song);
        final streamInfoJson = requiredAudioStream.toJson();
        streamInfoJson['url'] = filePath;
        // [playbility status, info map]
        songJson["streamInfo"] = [true, streamInfoJson];

        Hive.box("SongDownloads").put(song.id, songJson);
        Get.find<LibrarySongsController>().librarySongsList.add(song);
        printINFO("Downloaded successfully");

        final trackDetails = (song.extras?['trackDetails'])?.split("/");
        final int? trackNumber = int.tryParse(trackDetails?[0] ?? "");
        final int? totalTracks = int.tryParse(trackDetails?[1] ?? "");

        try {
          /// Reverted -- Removed AudioTags as using this package, app is flagged as TROJ_GEN.R002V01K623 by TrendMicro-HouseCall
          final imageUrl = song.artUri!.toString();
          Tag tag = Tag(
              title: song.title,
              trackArtist: song.artist,
              album: song.album,
              year: int.tryParse(year ?? ""),
              trackNumber: trackNumber,
              trackTotal: totalTracks,
              albumArtist: song.artist,
              genre: song.genre,
              pictures: [
                Picture(
                    bytes: (await NetworkAssetBundle(Uri.parse((imageUrl)))
                            .load(imageUrl))
                        .buffer
                        .asUint8List(),
                    mimeType: MimeType.png,
                    pictureType: PictureType.coverFront)
              ]);

          await AudioTags.write(filePath, tag);
        } catch (e) {
          printERROR("$e");
        }
        _currentDownloadingFilePath = null;
        _currentCancelToken = null;
        complete.complete();
      },
    ).onError(
      (error, stackTrace) {
        if (CancelToken.isCancel(error as DioException)) {
          printINFO("Download cancelled by user for: ${song.title}");
        } else {
          ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
              Get.context!, "downloadError3".tr,
              size: SanckBarSize.BIG,
              duration: const Duration(seconds: 2),
              top: !GetPlatform.isDesktop));
          printINFO(
              "Downloading failed due to network/stream error! Please try again");
        }
        _currentDownloadingFilePath = null;
        _currentCancelToken = null;
        complete.complete();
      },
    );

    return complete.future;
  }

  Future<void> cancelSongDownload(MediaItem song, {bool deleteFile = true}) async {
    if (currentSong?.id == song.id) {
      try {
        _currentCancelToken?.cancel("Cancelled by user");
      } catch (_) {}
      if (deleteFile && _currentDownloadingFilePath != null) {
        try {
          final f = File(_currentDownloadingFilePath!);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (e) {
          printERROR("Error deleting partial download file: $e");
        }
      }
      songDownloadingProgress.value = 0;
      currentSong = null;
    }
    songQueue.removeWhere((item) => item.id == song.id);

    if (deleteFile && Hive.box("SongDownloads").containsKey(song.id)) {
      try {
        final songData = Hive.box("SongDownloads").get(song.id);
        final path = songData?['url'] ?? songData?['streamInfo']?[1]?['url'];
        if (path != null) {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
          }
        }
        await Hive.box("SongDownloads").delete(song.id);
        if (Get.isRegistered<LibrarySongsController>()) {
          Get.find<LibrarySongsController>()
              .librarySongsList
              .removeWhere((item) => item.id == song.id);
        }
      } catch (e) {
        printERROR("Error removing downloaded file: $e");
      }
    }

    if (songQueue.isEmpty) {
      isJobRunning.value = false;
    }
  }

  Future<void> _downloadStreamWithBurstChunks({
    required String url,
    required String filePath,
    required int totalBytes,
    required CancelToken cancelToken,
    required void Function(int count, int total) onReceiveProgress,
  }) async {
    const int chunkSize = 4 * 1024 * 1024; // 4 MB burst chunks to bypass YouTube throttling
    if (totalBytes <= chunkSize) {
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        options: Options(headers: {"Range": 'bytes=0-$totalBytes'}),
        onReceiveProgress: onReceiveProgress,
      );
      return;
    }

    final file = File(filePath);
    final raf = await file.open(mode: FileMode.write);
    int downloadedBytes = 0;

    try {
      final burstDio = Dio();
      for (int start = 0; start < totalBytes; start += chunkSize) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: url),
            type: DioExceptionType.cancel,
          );
        }
        int end = start + chunkSize - 1;
        if (end >= totalBytes) end = totalBytes - 1;

        final response = await burstDio.get<List<int>>(
          url,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {"Range": "bytes=$start-$end"},
          ),
        );

        if (response.data != null && response.data!.isNotEmpty) {
          await raf.setPosition(start);
          await raf.writeFrom(response.data!);
          downloadedBytes += response.data!.length;
          onReceiveProgress(downloadedBytes, totalBytes);
        }
      }
      await raf.flush();
    } finally {
      await raf.close();
    }
  }
}
