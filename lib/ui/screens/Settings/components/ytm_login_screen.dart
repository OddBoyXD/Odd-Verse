import 'package:flutter/material.dart';
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

  static const String _loginUrl =
      "https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&passive=true&continue=https%3A%2F%2Fmusic.youtube.com%2F";

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
            _checkCookies(url);
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkCookies(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  Future<void> _checkCookies(String currentUrl) async {
    if (_loginCaptured) return;
    try {
      final cookieResult =
          await _controller.runJavaScriptReturningResult("document.cookie");
      final cookieStr = cookieResult.toString();

      if (cookieStr.contains("SAPISID") ||
          cookieStr.contains("__Secure-3PAPISID") ||
          cookieStr.contains("LOGIN_INFO") ||
          cookieStr.contains("SSID")) {
        _loginCaptured = true;
        final authService = Get.find<YtmAuthService>();
        final success = await authService.setCookies(cookieStr);

        if (success && mounted) {
          if (Get.isRegistered<HomeScreenController>()) {
            Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
          }
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            snackbar(
              Get.context!,
              "Connected to YouTube Music successfully!",
              size: SanckBarSize.BIG,
            ),
          );
        }
      }
    } catch (_) {}
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
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Check Login",
            onPressed: () async {
              final url = await _controller.currentUrl();
              if (url != null) {
                await _checkCookies(url);
              }
              if (!_loginCaptured && mounted) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  snackbar(
                    Get.context!,
                    "Please finish signing in on the page.",
                    size: SanckBarSize.MEDIUM,
                  ),
                );
              }
            },
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
      body: WebViewWidget(controller: _controller),
    );
  }
}
