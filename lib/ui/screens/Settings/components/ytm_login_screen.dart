import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../services/ytm_auth_service.dart';
import '../../../widgets/snackbar.dart';
import '../../Home/home_screen_controller.dart';

class YtmLoginScreen extends StatefulWidget {
  const YtmLoginScreen({super.key});

  @override
  State<YtmLoginScreen> createState() => _YtmLoginScreenState();
}

class _YtmLoginScreenState extends State<YtmLoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _loginCaptured = false;
  bool _isOnMusicOrigin = false;
  String? _detectedUserName;
  String? _detectedUserAvatar;

  static const String _loginUrl =
      "https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&passive=true&continue=https%3A%2F%2Fmusic.youtube.com%2F";

  static const String _probeScript = r'''
(function () {
  try {
    var cookie = document.cookie || '';
    var get = function (k) {
      if (window.ytcfg && window.ytcfg.get) {
        var v = window.ytcfg.get(k);
        return (v === undefined || v === null) ? '' : String(v);
      }
      return '';
    };
    var name = get('USER_NAME');
    var avatar = get('USER_AVATAR');
    var loggedIn = get('LOGGED_IN');
    if (!name) {
      var el = document.querySelector('button.ytmusic-settings-button img, yt-img-shadow#avatar img, button#avatar-btn img');
      if (el) {
        if (el.alt) name = el.alt;
        if (el.src) avatar = el.src;
      }
    }
    return JSON.stringify({
      cookie: cookie,
      loggedIn: loggedIn,
      name: name,
      avatar: avatar
    });
  } catch(e) {
    return JSON.stringify({ cookie: document.cookie || '', loggedIn: 'false' });
  }
})()
''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            _handleUrlChange(url);
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _handleUrlChange(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  Future<void> _handleUrlChange(String url) async {
    final isMusic = url.contains("music.youtube.com");
    if (mounted && _isOnMusicOrigin != isMusic) {
      setState(() {
        _isOnMusicOrigin = isMusic;
      });
    }

    if (isMusic && !_loginCaptured) {
      await _probeSession(autoComplete: true);
    }
  }

  Future<String?> _getNativeCookies() async {
    try {
      const channel = MethodChannel("com.oddverse.dc/media_store");
      final cookies = await channel.invokeMethod<String>(
          "getCookiesForUrl", {"url": "https://music.youtube.com"});
      if (cookies != null && cookies.isNotEmpty) {
        return cookies;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _probeSession({bool autoComplete = false}) async {
    if (_loginCaptured) return;
    try {
      final nativeCookies = await _getNativeCookies();
      final rawResult =
          await _controller.runJavaScriptReturningResult(_probeScript);
      String resultStr = rawResult.toString().trim();
      if (resultStr.startsWith('"') && resultStr.endsWith('"')) {
        resultStr = jsonDecode(resultStr);
      }
      final parsed = jsonDecode(resultStr);

      if (parsed is Map) {
        final jsCookieStr = parsed['cookie']?.toString() ?? '';
        final effectiveCookies =
            (nativeCookies != null && nativeCookies.isNotEmpty)
                ? nativeCookies
                : jsCookieStr;
        final name = parsed['name']?.toString();
        final avatar = parsed['avatar']?.toString();
        final loggedIn = parsed['loggedIn']?.toString() == 'true';

        final hasApiSid = effectiveCookies.contains("SAPISID") ||
            effectiveCookies.contains("__Secure-3PAPISID") ||
            effectiveCookies.contains("__Secure-1PAPISID");

        if (name != null && name.isNotEmpty && mounted) {
          setState(() {
            _detectedUserName = name;
            _detectedUserAvatar = avatar;
          });
        }

        if (hasApiSid && (loggedIn || !autoComplete)) {
          await _completeLogin(
            effectiveCookies,
            name: name ?? _detectedUserName,
            avatar: avatar ?? _detectedUserAvatar,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _completeLogin(String cookieStr,
      {String? name, String? avatar}) async {
    if (_loginCaptured) return;
    _loginCaptured = true;

    final authService = Get.find<YtmAuthService>();
    final success = await authService.setCookies(
      cookieStr,
      directName: name,
      directAvatar: avatar,
    );

    if (success && mounted) {
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        snackbar(
          Get.context!,
          name != null && name.isNotEmpty
              ? "Signed in as $name!"
              : "Connected to YouTube Music successfully!",
          size: SanckBarSize.BIG,
        ),
      );
    } else {
      _loginCaptured = false;
    }
  }

  void _showPasteCookieDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Paste YouTube Cookies"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paste your exported YouTube Music cookies (Header, Netscape, or JSON format):",
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "SAPISID=...; __Secure-3PAPISID=...; SID=...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                final authService = Get.find<YtmAuthService>();
                final ok = await authService.setCookies(raw);
                if (ok && mounted) {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop(true);
                  if (Get.isRegistered<HomeScreenController>()) {
                    Get.find<HomeScreenController>()
                        .loadContentFromNetwork(silent: true);
                  }
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    snackbar(
                      Get.context!,
                      "Connected to YouTube Music successfully!",
                      size: SanckBarSize.BIG,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    snackbar(
                      ctx,
                      "Invalid cookies. Ensure SAPISID or SID is present.",
                      size: SanckBarSize.MEDIUM,
                    ),
                  );
                }
              }
            },
            child: const Text("Save & Connect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login to YouTube Music",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: "Paste Cookies",
            onPressed: _showPasteCookieDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reload",
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isOnMusicOrigin)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 10,
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0x33FF0000), width: 1.5),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      if (_detectedUserAvatar != null &&
                          _detectedUserAvatar!.isNotEmpty)
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(_detectedUserAvatar!),
                        )
                      else
                        const Icon(Icons.check_circle,
                            color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _detectedUserName != null &&
                                      _detectedUserName!.isNotEmpty
                                  ? _detectedUserName!
                                  : "YouTube Music",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "Signed in • Ready to sync",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _probeSession(autoComplete: false),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
