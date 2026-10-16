import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/media_Item_builder.dart';
import '../ui/screens/Home/home_screen_controller.dart';
import '../utils/helper.dart';
import 'music_service.dart';

class YtmAuthService extends GetxService {
  final isLoggedIn = false.obs;
  final userName = "".obs;
  final userAvatar = "".obs;
  final userEmail = "".obs;

  static const String _domain = "https://music.youtube.com";

  @override
  void onInit() {
    super.onInit();
    _loadSavedAuth();
  }

  void _loadSavedAuth() {
    final box = Hive.box("AppPrefs");
    final savedLoggedIn = box.get("ytm_is_logged_in") ?? false;
    if (savedLoggedIn) {
      final cookies = box.get("ytm_cookies") as String?;
      if (cookies != null && cookies.isNotEmpty) {
        isLoggedIn.value = true;
        userName.value = box.get("ytm_user_name") ?? "YouTube User";
        userAvatar.value = box.get("ytm_user_avatar") ?? "";
        userEmail.value = box.get("ytm_user_email") ?? "";
      }
    }
  }

  String? get cookies {
    final box = Hive.box("AppPrefs");
    return box.get("ytm_cookies") as String?;
  }

  String? get sapisid {
    final cookieStr = cookies;
    if (cookieStr == null) return null;
    final patterns = [
      RegExp(r'(?:^|;\s*)__Secure-3PAPISID=([^;]+)'),
      RegExp(r'(?:^|;\s*)__Secure-1PAPISID=([^;]+)'),
      RegExp(r'(?:^|;\s*)SAPISID=([^;]+)'),
      RegExp(r'(?:^|;\s*)APISID=([^;]+)'),
    ];
    for (final pat in patterns) {
      final m = pat.firstMatch(cookieStr);
      if (m != null && m.group(1) != null && m.group(1)!.trim().isNotEmpty) {
        return m.group(1)!.trim();
      }
    }
    return null;
  }

  String? getSapisidHash() {
    final sid = sapisid;
    if (sid == null) return null;
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final strToHash = "$timestamp $sid $_domain";
    final hash = sha1.convert(utf8.encode(strToHash)).toString();
    return "SAPISIDHASH ${timestamp}_$hash";
  }

  Map<String, String> getAuthHeaders({String? videoId}) {
    if (!isLoggedIn.value || cookies == null) {
      return {};
    }
    final headers = <String, String>{
      'cookie': cookies!,
      'origin': _domain,
      'x-origin': _domain,
      'x-goog-authuser': '0',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (videoId != null && videoId.isNotEmpty) {
      headers['referer'] = 'https://music.youtube.com/watch?v=$videoId';
    } else {
      headers['referer'] = 'https://music.youtube.com/';
    }
    final authHeader = getSapisidHash();
    if (authHeader != null) {
      headers['authorization'] = authHeader;
    }
    return headers;
  }

  Future<bool> setCookies(String rawCookies,
      {String? directName, String? directAvatar, String? directEmail}) async {
    try {
      String input = rawCookies.trim();
      if (input.isEmpty) return false;

      // Clean up escaped quotes if string came from JavaScript evaluation
      if (input.startsWith('"') && input.endsWith('"')) {
        input = input.substring(1, input.length - 1);
      }
      input = input.replaceAll(r'\"', '"');

      String cleanCookies = "";

      // Case 1: JSON array format from Cookie extensions (e.g. [{"name":"SID","value":"..."}, ...])
      if (input.startsWith('[') && input.endsWith(']')) {
        try {
          final list = jsonDecode(input);
          if (list is List) {
            final buffer = StringBuffer();
            for (final item in list) {
              if (item is Map && item['name'] != null && item['value'] != null) {
                buffer.write('${item['name']}=${item['value']}; ');
              }
            }
            cleanCookies = buffer.toString().trim();
          }
        } catch (_) {}
      }

      // Case 2: Netscape / Tab-separated format (e.g. .youtube.com TRUE / FALSE 12345678 SID xxx)
      if (cleanCookies.isEmpty && input.contains('\t')) {
        final buffer = StringBuffer();
        final lines = input.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.split('\t');
          if (parts.length >= 7) {
            final name = parts[5].trim();
            final value = parts[6].trim();
            buffer.write('$name=$value; ');
          }
        }
        if (buffer.isNotEmpty) {
          cleanCookies = buffer.toString().trim();
        }
      }

      // Case 3: Multiline "Name: Value" or "Name=Value" format
      if (cleanCookies.isEmpty && input.contains('\n') && !input.contains(';')) {
        final buffer = StringBuffer();
        final lines = input.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.contains('=')) {
            buffer.write('$trimmed; ');
          } else if (trimmed.contains(':')) {
            final idx = trimmed.indexOf(':');
            buffer.write('${trimmed.substring(0, idx).trim()}=${trimmed.substring(idx + 1).trim()}; ');
          }
        }
        if (buffer.isNotEmpty) {
          cleanCookies = buffer.toString().trim();
        }
      }

      // Case 4: Standard Header string (e.g. SID=xxx; HSID=yyy; ...)
      if (cleanCookies.isEmpty) {
        cleanCookies = input.replaceAll('\n', ' ').replaceAll('\r', '').trim();
      }

      if (!cleanCookies.contains("SAPISID") &&
          !cleanCookies.contains("__Secure-3PAPISID") &&
          !cleanCookies.contains("LOGIN_INFO") &&
          !cleanCookies.contains("SSID") &&
          !cleanCookies.contains("SID")) {
        return false;
      }

      final box = Hive.box("AppPrefs");
      await box.put("ytm_cookies", cleanCookies);
      await box.put("ytm_is_logged_in", true);
      isLoggedIn.value = true;

      if (directName != null && directName.isNotEmpty) {
        userName.value = directName;
        await box.put("ytm_user_name", directName);
      }
      if (directAvatar != null && directAvatar.isNotEmpty) {
        userAvatar.value = directAvatar;
        await box.put("ytm_user_avatar", directAvatar);
      }
      if (directEmail != null && directEmail.isNotEmpty) {
        userEmail.value = directEmail;
        await box.put("ytm_user_email", directEmail);
      }

      // Clear offline home screen cache to avoid mixing anonymous and authenticated feeds
      try {
        if (Hive.isBoxOpen("homeScreenData")) {
          await Hive.box("homeScreenData").clear();
        } else {
          final hBox = await Hive.openBox("homeScreenData");
          await hBox.clear();
        }
      } catch (_) {}

      // Attempt to fetch full account details from YouTube Music
      await fetchAccountInfo();
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().loadContentFromNetwork();
      }
      // Proactively sync user's Liked Music from YouTube Music in the background
      syncLikedMusicToLocal();
      printINFO("YouTube Music login successful! (User: ${userName.value})");
      return true;
    } catch (e) {
      printERROR("Error setting YTM cookies: $e");
      return false;
    }
  }

  dynamic _findInJson(dynamic node, String key) {
    if (node is Map) {
      if (node.containsKey(key)) return node[key];
      for (final val in node.values) {
        final found = _findInJson(val, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findInJson(item, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> fetchAccountInfo() async {
    try {
      final dio = Dio();
      final headers = getAuthHeaders();
      if (headers.isEmpty) return;

      final res = await dio.post(
        "$_domain/youtubei/v1/account/account_menu?prettyPrint=false",
        options: Options(headers: headers),
        data: {
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20260524.14.00',
            }
          }
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        final accountSection = _findInJson(data, 'activeAccountHeaderRenderer');
        if (accountSection != null && accountSection is Map) {
          final name = accountSection['accountName']?['runs']?[0]?['text'] ??
              accountSection['accountName']?['simpleText'];
          final email = accountSection['email']?['runs']?[0]?['text'] ??
              accountSection['email']?['simpleText'] ??
              accountSection['channelHandle']?['runs']?[0]?['text'] ??
              accountSection['channelHandle']?['simpleText'];
          final avatarList = accountSection['accountPhoto']?['thumbnails'] as List?;
          final avatarUrl = avatarList != null && avatarList.isNotEmpty
              ? avatarList.last['url']
              : null;

          final box = Hive.box("AppPrefs");
          if (name != null && name.toString().trim().isNotEmpty) {
            userName.value = name.toString().trim();
            await box.put("ytm_user_name", userName.value);
          }
          if (email != null && email.toString().trim().isNotEmpty) {
            userEmail.value = email.toString().trim();
            await box.put("ytm_user_email", email.toString().trim());
          }
          if (avatarUrl != null && avatarUrl.toString().trim().isNotEmpty) {
            userAvatar.value = avatarUrl.toString().trim();
            await box.put("ytm_user_avatar", userAvatar.value);
          }
        }
      }
    } catch (e) {
      printINFO("Account info lookup: $e");
    }
    if (userName.value.isEmpty) {
      userName.value = "YouTube Account";
    }
  }

  /// Rate a song on YouTube Music (like: true -> like/like, like: false -> like/removelike)
  Future<bool> rateSong(String videoId, {required bool like}) async {
    if (!isLoggedIn.value || videoId.isEmpty) return false;
    try {
      final dio = Dio();
      final headers = getAuthHeaders(videoId: videoId);
      if (headers.isEmpty) return false;

      final endpoint = like ? "like/like" : "like/removelike";
      final res = await dio.post(
        "$_domain/youtubei/v1/$endpoint?prettyPrint=false",
        options: Options(headers: headers),
        data: {
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20260524.14.00',
            }
          },
          'target': {
            'videoId': videoId,
          }
        },
      );
      printINFO("YouTube Music rating ($endpoint) for $videoId -> HTTP ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      printERROR("YouTube Music rating failed for $videoId: $e");
      return false;
    }
  }

  /// Pull all Liked Music tracks from YouTube Music cloud into local favorites box (LIBFAV)
  Future<int> syncLikedMusicToLocal() async {
    if (!isLoggedIn.value) return 0;
    try {
      if (!Get.isRegistered<MusicServices>()) return 0;
      final musicServices = Get.find<MusicServices>();
      final res = await musicServices.getPlaylistOrAlbumSongs(playlistId: "VLLM", limit: 500);
      final tracks = List<MediaItem>.from(res['tracks'] ?? []);
      if (tracks.isEmpty) return 0;

      final box = await Hive.openBox("LIBFAV");
      int addedCount = 0;
      for (final track in tracks) {
        if (!box.containsKey(track.id)) {
          await box.put(track.id, MediaItemBuilder.toJson(track));
          addedCount++;
        }
      }
      printINFO("Synced $addedCount new Liked Music tracks from YouTube Music (total: ${tracks.length})");
      return tracks.length;
    } catch (e) {
      printERROR("syncLikedMusicToLocal error: $e");
      return 0;
    }
  }

  Future<void> logout() async {
    final box = Hive.box("AppPrefs");
    await box.delete("ytm_cookies");
    await box.delete("ytm_is_logged_in");
    await box.delete("ytm_user_name");
    await box.delete("ytm_user_avatar");
    await box.delete("ytm_user_email");

    isLoggedIn.value = false;
    userName.value = "";
    userAvatar.value = "";
    userEmail.value = "";
    printINFO("Logged out of YouTube Music");

    // Clear offline home screen cache to avoid mixing anonymous and authenticated feeds
    try {
      if (Hive.isBoxOpen("homeScreenData")) {
        await Hive.box("homeScreenData").clear();
      } else {
        final hBox = await Hive.openBox("homeScreenData");
        await hBox.clear();
      }
    } catch (_) {}

    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().loadContentFromNetwork();
    }
  }
}
