import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/media_Item_builder.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '../utils/helper.dart';
import 'permission_service.dart';

class LocalMusicService {
  static const MethodChannel _mediaStoreChannel =
      MethodChannel('com.oddverse.dc/media_store');

  static const List<String> supportedExtensions = [
    '.mp3',
    '.m4a',
    '.flac',
    '.wav',
    '.aac',
    '.ogg',
    '.opus',
    '.wma'
  ];

  static const List<String> defaultIgnorePatterns = [
    '/android',
    '/android/',
    'android/data',
    'android/media',
    'android/obb',
    'whatsapp',
    'whatsapp audio',
    'whatsapp voice notes',
    'whatsapp animated gifs',
    'com.whatsapp',
    'recordings',
    'callrecordings',
    'soundrecorder',
    'miui/sound_recorder',
    'voice recorder',
    'voice_recorder',
    'call_recordings',
    'ringtones',
    'notifications',
    'alarms',
    '.thumbnails',
    '.trash',
    'cache',
    '.cache',
  ];

  static Future<List<MediaItem>> getLocalSongs({bool forceRescan = false}) async {
    final localSongsBox = await Hive.openBox("LocalSongsCache");
    final appPrefs = Hive.box("AppPrefs");
    final List<String> excludedFolders = List<String>.from(
        appPrefs.get("excluded_local_folders", defaultValue: <String>[]) ?? []);

    if (forceRescan) {
      await localSongsBox.clear();
    }

    if (!forceRescan && localSongsBox.isNotEmpty) {
      final List<MediaItem> cachedSongs = [];
      final List<String> staleKeys = [];

      for (var key in localSongsBox.keys) {
        try {
          final data = localSongsBox.get(key);
          if (data is Map) {
            final String filePath = data['url'] ?? data['path'] ?? '';
            final filePathLower = filePath.toLowerCase();

            // Check if file still exists and is not excluded
            if (filePath.isNotEmpty && File(filePath).existsSync()) {
              bool isDefaultIgnored = defaultIgnorePatterns
                  .any((pattern) => filePathLower.contains(pattern));
              bool isUserExcluded = excludedFolders
                  .any((folder) => filePathLower.startsWith(folder.toLowerCase()));

              if (!isDefaultIgnored && !isUserExcluded) {
                cachedSongs.add(MediaItemBuilder.fromJson(data));
              }
            } else {
              staleKeys.add(key.toString());
            }
          }
        } catch (_) {}
      }

      for (var staleKey in staleKeys) {
        localSongsBox.delete(staleKey);
      }

      if (cachedSongs.isNotEmpty) {
        return cachedSongs;
      }
    }

    return await scanStorage(excludedFolders: excludedFolders);
  }

  static Future<List<MediaItem>> scanStorage({List<String>? excludedFolders}) async {
    final localSongsBox = await Hive.openBox("LocalSongsCache");
    final appPrefs = Hive.box("AppPrefs");
    final List<String> excluded = excludedFolders ??
        List<String>.from(
            appPrefs.get("excluded_local_folders", defaultValue: <String>[]) ??
                []);

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission && GetPlatform.isAndroid) {
      printINFO("LocalMusicService: Storage permission not granted");
      return [];
    }

    final List<MediaItem> resultSongs = [];

    // 1. Android Native MediaStore Query (Scans Internal + All SD Cards Instantly)
    if (GetPlatform.isAndroid) {
      try {
        final List<dynamic>? rawList =
            await _mediaStoreChannel.invokeMethod<List<dynamic>>("queryAudioFiles");
        if (rawList != null && rawList.isNotEmpty) {
          printINFO("LocalMusicService: MediaStore returned ${rawList.length} items");
          for (var raw in rawList) {
            if (raw is Map) {
              final path = (raw['path'] ?? '').toString();
              final pathLower = path.toLowerCase();

              // Check default ignore patterns
              if (defaultIgnorePatterns.any((pattern) => pathLower.contains(pattern))) {
                continue;
              }

              // Check user excluded folders
              if (excluded.any((ex) => pathLower.startsWith(ex.toLowerCase()))) {
                continue;
              }

              final id = "local_${raw['id']}";
              final title = (raw['title'] ?? 'Unknown').toString();
              final artist = (raw['artist'] ?? 'Unknown Artist').toString();
              final album = (raw['album'] ?? 'Device Audio').toString();
              final durationSec = (raw['duration'] ?? 0) as int;
              final date = (raw['date'] ?? 0) as int;
              final artUri = (raw['artUri'] ?? '').toString();

              final mediaItemData = {
                'videoId': id,
                'title': title,
                'album': {'name': album},
                'artists': [
                  {'name': artist}
                ],
                'duration': durationSec,
                'length': formatDuration(Duration(seconds: durationSec)),
                'url': path,
                'path': path,
                'isLocal': true,
                'lastModified': date,
                'thumbnails': [
                  {'url': artUri}
                ],
                'date': date,
              };

              localSongsBox.put(id, mediaItemData);
              resultSongs.add(MediaItemBuilder.fromJson(mediaItemData));
            }
          }

          if (resultSongs.isNotEmpty) {
            return resultSongs;
          }
        }
      } catch (e) {
        printINFO("LocalMusicService: MediaStore query failed, falling back to FS scan: $e");
      }
    }

    // 2. Filesystem Fallback (Desktop / Fallback)
    final List<Directory> scanRoots = await _getScanDirectories();
    final List<File> audioFiles = [];

    for (var dir in scanRoots) {
      if (dir.existsSync()) {
        _scanDirectoryRecursively(dir, audioFiles, excluded);
      }
    }

    String supportDir = "";
    try {
      if (Get.isRegistered<SettingsScreenController>()) {
        supportDir = Get.find<SettingsScreenController>().supportDirPath;
      }
      if (supportDir.isEmpty) {
        supportDir = (await getApplicationSupportDirectory()).path;
      }
    } catch (_) {
      supportDir = (await getTemporaryDirectory()).path;
    }

    final thumbDir = Directory("$supportDir/local_thumbs");
    if (!thumbDir.existsSync()) {
      thumbDir.createSync(recursive: true);
    }

    for (var file in audioFiles) {
      try {
        final filePath = file.path;
        final fileModTime = file.lastModifiedSync().millisecondsSinceEpoch;
        final songId = "local_${filePath.hashCode}";

        if (localSongsBox.containsKey(songId)) {
          final cached = localSongsBox.get(songId);
          if (cached is Map && cached['lastModified'] == fileModTime) {
            resultSongs.add(MediaItemBuilder.fromJson(cached));
            continue;
          }
        }

        String title = p.basenameWithoutExtension(filePath);
        String artist = "Unknown Artist";
        String album = "Device Audio";
        int durationSec = 0;
        Uri? artUri;

        try {
          final tag = await AudioTags.read(filePath);
          if (tag != null) {
            if (tag.title != null && tag.title!.trim().isNotEmpty) {
              title = tag.title!.trim();
            }
            if (tag.trackArtist != null && tag.trackArtist!.trim().isNotEmpty) {
              artist = tag.trackArtist!.trim();
            } else if (tag.albumArtist != null && tag.albumArtist!.trim().isNotEmpty) {
              artist = tag.albumArtist!.trim();
            }
            if (tag.album != null && tag.album!.trim().isNotEmpty) {
              album = tag.album!.trim();
            }
            if (tag.duration != null && tag.duration! > 0) {
              durationSec = tag.duration!;
            }

            if (tag.pictures.isNotEmpty && tag.pictures.first.bytes.isNotEmpty) {
              final artHash = md5.convert(utf8.encode(filePath)).toString();
              final artFile = File("${thumbDir.path}/$artHash.jpg");
              if (!artFile.existsSync()) {
                await artFile.writeAsBytes(tag.pictures.first.bytes);
              }
              artUri = Uri.file(artFile.path);
            }
          }
        } catch (_) {}

        final duration = Duration(seconds: durationSec);
        final String durationFormatted = formatDuration(duration);

        final mediaItemData = {
          'videoId': songId,
          'title': title,
          'album': {'name': album},
          'artists': [
            {'name': artist}
          ],
          'duration': durationSec,
          'length': durationFormatted,
          'url': filePath,
          'path': filePath,
          'isLocal': true,
          'lastModified': fileModTime,
          'thumbnails': [
            {'url': artUri?.toString() ?? ''}
          ],
          'date': fileModTime,
        };

        localSongsBox.put(songId, mediaItemData);
        resultSongs.add(MediaItemBuilder.fromJson(mediaItemData));
      } catch (_) {}
    }

    return resultSongs;
  }

  static void _scanDirectoryRecursively(
      Directory dir, List<File> audioFiles, List<String> excluded) {
    try {
      final String dirPathLower = dir.path.toLowerCase();

      for (var pattern in defaultIgnorePatterns) {
        if (dirPathLower.contains(pattern)) return;
      }

      for (var ex in excluded) {
        if (dirPathLower.startsWith(ex.toLowerCase())) return;
      }

      final entities = dir.listSync(followLinks: false);
      for (var entity in entities) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;

        final entityPathLower = entity.path.toLowerCase();

        bool isIgnored = defaultIgnorePatterns.any((p) => entityPathLower.contains(p)) ||
            excluded.any((ex) => entityPathLower.startsWith(ex.toLowerCase()));
        if (isIgnored) continue;

        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            audioFiles.add(entity);
          }
        } else if (entity is Directory) {
          _scanDirectoryRecursively(entity, audioFiles, excluded);
        }
      }
    } catch (_) {}
  }

  static Future<List<Directory>> _getScanDirectories() async {
    final Set<String> paths = {};

    if (GetPlatform.isAndroid) {
      const internalBase = '/storage/emulated/0';
      if (Directory(internalBase).existsSync()) paths.add(internalBase);
      if (Directory('/sdcard').existsSync()) paths.add('/sdcard');

      try {
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null) {
          for (var d in extDirs) {
            final pStr = d.path;
            final idx = pStr.indexOf('/Android');
            if (idx != -1) {
              final root = pStr.substring(0, idx);
              if (Directory(root).existsSync()) paths.add(root);
            } else {
              if (d.existsSync()) paths.add(d.path);
            }
          }
        }
      } catch (_) {}
    } else if (GetPlatform.isWindows || GetPlatform.isLinux || GetPlatform.isMacOS) {
      try {
        final userMusic = await getDownloadsDirectory();
        if (userMusic != null && userMusic.existsSync()) paths.add(userMusic.path);
      } catch (_) {}
    }

    return paths.map((path) => Directory(path)).toList();
  }

  static Future<bool> _requestStoragePermission() async {
    if (GetPlatform.isDesktop) return true;
    try {
      final status = await Permission.audio.status;
      if (status.isGranted) return true;
      final requested = await Permission.audio.request();
      if (requested.isGranted) return true;
    } catch (_) {}

    try {
      return await PermissionService.getExtStoragePermission();
    } catch (_) {
      final res = await [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage
      ].request();
      return res.values.any((s) => s.isGranted);
    }
  }

  static String formatDuration(Duration d) {
    if (d.inSeconds <= 0) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
