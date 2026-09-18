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
      "https://accounts.google.com/ServiceLogin?service=youtube&passive=true&continue=https%3A%2F%2Fmusic.youtube.com%2F";

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
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
