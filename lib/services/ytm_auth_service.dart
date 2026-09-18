import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../ui/screens/Home/home_screen_controller.dart';
import '../utils/helper.dart';

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

  Future<bool> setCookies(String rawCookies) async {
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

      // Attempt to fetch user account details from YouTube Music
      await fetchAccountInfo();
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().loadContentFromNetwork();
      }
      printINFO("YouTube Music login successful!");
      return true;
    } catch (e) {
      printERROR("Error setting YTM cookies: $e");
      return false;
    }
  }

  Future<void> fetchAccountInfo() async {
    try {
      final dio = Dio();
      final headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'accept': '*/*',
        'cookie': cookies ?? '',
        'origin': _domain,
      };
      final auth = getSapisidHash();
      if (auth != null) headers['authorization'] = auth;

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
        // Search for account name and avatar thumbnail
        final actions = data['actions'] as List?;
        if (actions != null && actions.isNotEmpty) {
          final accountSection = actions[0]['openPopupAction']?['popup']?['multiPageMenuRenderer']?['header']?['activeAccountHeaderRenderer'];
          if (accountSection != null) {
            final name = accountSection['accountName']?['runs']?[0]?['text'] ??
                accountSection['accountName']?['simpleText'];
            final email = accountSection['email']?['runs']?[0]?['text'] ??
                accountSection['email']?['simpleText'];
            final avatarList = accountSection['accountPhoto']?['thumbnails'] as List?;
            final avatarUrl = avatarList != null && avatarList.isNotEmpty
                ? avatarList.last['url']
                : null;

            final box = Hive.box("AppPrefs");
            if (name != null) {
              userName.value = name.toString();
              await box.put("ytm_user_name", name.toString());
            }
            if (email != null) {
              userEmail.value = email.toString();
              await box.put("ytm_user_email", email.toString());
            }
            if (avatarUrl != null) {
              userAvatar.value = avatarUrl.toString();
              await box.put("ytm_user_avatar", avatarUrl.toString());
            }
          }
        }
      }
    } catch (e) {
      printINFO("Account info lookup: $e");
      if (userName.value.isEmpty) {
        userName.value = "YouTube Account";
      }
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

    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().loadContentFromNetwork();
    }
  }
}
