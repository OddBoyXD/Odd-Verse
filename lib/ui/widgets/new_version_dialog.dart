import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../screens/Home/home_screen_controller.dart';
import 'common_dialog_widget.dart';
import 'snackbar.dart';

class NewVersionDialog extends StatefulWidget {
  final bool isTestMode;
  const NewVersionDialog({super.key, this.isTestMode = false});

  @override
  State<NewVersionDialog> createState() => _NewVersionDialogState();
}

class _NewVersionDialogState extends State<NewVersionDialog> {
  static const MethodChannel _channel = MethodChannel("com.oddverse.dc/media_store");
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  String _latestVersion = "v1.0.2";
  String _deviceAbi = "arm64-v8a";
  String _selectedVariant = "arm64-v8a";
  bool _isLoadingInfo = true;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _progressText = "";
  Map<String, String> _assetUrls = {};

  final Map<String, String> _variantLabels = {
    "arm64-v8a": "64-bit ARM (Recommended)",
    "universal": "Universal (All-in-One)",
    "armeabi-v7a": "32-bit ARM (Legacy)",
    "x86_64": "64-bit x86 (Emulators)",
  };

  @override
  void initState() {
    super.initState();
    _fetchUpdateInfo();
  }

  @override
  void dispose() {
    _cancelToken?.cancel("Dialog dismissed");
    super.dispose();
  }

  Future<void> _fetchUpdateInfo() async {
    try {
      // 1. Detect device ABI
      if (Platform.isAndroid) {
        final abi = await _channel.invokeMethod<String>("getDeviceAbi");
        if (abi != null && abi.isNotEmpty) {
          _deviceAbi = abi;
          if (abi.contains("arm64")) {
            _selectedVariant = "arm64-v8a";
          } else if (abi.contains("v7a")) {
            _selectedVariant = "armeabi-v7a";
          } else if (abi.contains("x86_64")) {
            _selectedVariant = "x86_64";
          } else {
            _selectedVariant = "universal";
          }
        }
      }

      // 2. Fetch latest release assets from GitHub
      final response = await _dio.get(
        "https://api.github.com/repos/OddBoyXD/Odd-Verse/releases/latest",
        options: Options(headers: {
          'Accept': 'application/vnd.github.v3+json',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        _latestVersion = data['tag_name'] ?? "v1.0.2";
        final List assets = data['assets'] ?? [];

        for (var asset in assets) {
          final String name = (asset['name'] ?? "").toString().toLowerCase();
          final String downloadUrl = asset['browser_download_url'] ?? "";

          if (name.contains("arm64-v8a")) {
            _assetUrls["arm64-v8a"] = downloadUrl;
          } else if (name.contains("universal")) {
            _assetUrls["universal"] = downloadUrl;
          } else if (name.contains("armeabi-v7a")) {
            _assetUrls["armeabi-v7a"] = downloadUrl;
          } else if (name.contains("x86_64")) {
            _assetUrls["x86_64"] = downloadUrl;
          }
        }
      }
    } catch (_) {
      // Fallback direct release URLs
      _assetUrls["arm64-v8a"] =
          "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-$_latestVersion-arm64-v8a.apk";
      _assetUrls["universal"] =
          "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-$_latestVersion-universal.apk";
      _assetUrls["armeabi-v7a"] =
          "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-$_latestVersion-armeabi-v7a.apk";
      _assetUrls["x86_64"] =
          "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-$_latestVersion-x86_64.apk";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInfo = false;
        });
      }
    }
  }

  Future<void> _startInAppDownloadAndInstall() async {
    final downloadUrl = _assetUrls[_selectedVariant] ??
        "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-$_latestVersion-$_selectedVariant.apk";

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _progressText = "Connecting...";
    });

    _cancelToken = CancelToken();

    try {
      final tempDir = await getTemporaryDirectory();
      final updatesDir = Directory("${tempDir.path}/updates");
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      final apkFile = File("${updatesDir.path}/OddVerse-$_latestVersion-$_selectedVariant.apk");
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      await _dio.download(
        downloadUrl,
        apkFile.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            final percent = received / total;
            final recMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totMB = (total / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _progress = percent;
              _progressText = "${(percent * 100).toInt()}% ($recMB MB / $totMB MB)";
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _progressText = "Download complete! Opening installer...";
        });
      }

      // Launch native Android package installer
      if (Platform.isAndroid && await apkFile.exists()) {
        await _channel.invokeMethod("installApk", {"filePath": apkFile.path});
      }
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackbar(context, "Update download cancelled", size: SanckBarSize.MEDIUM),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackbar(context, "Update download failed. Please try again.", size: SanckBarSize.BIG),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CommonDialog(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    widget.isTestMode ? "In-App Update (Test Mode)" : "New Version Available",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Odd Verse $_latestVersion",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Detected Architecture: $_deviceAbi",
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Variant Selector
            if (!_isDownloading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVariant,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: _variantLabels.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedVariant = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Progress or Action Button
            if (_isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _progressText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text("Cancel Download"),
                onPressed: () {
                  _cancelToken?.cancel();
                },
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: Text(_isLoadingInfo ? "Loading info..." : "Download & Install Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoadingInfo ? null : _startInAppDownloadAndInstall,
                ),
              ),
            ],

            if (!_isDownloading) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.isTestMode)
                    GetX<HomeScreenController>(builder: (controller) {
                      return Row(
                        children: [
                          Checkbox(
                            value: controller.showVersionDialog.isFalse,
                            onChanged: (val) {
                              controller.onChangeVersionVisibility(val ?? false);
                            },
                            shape: const CircleBorder(),
                          ),
                          Text("dontShowInfoAgain".tr, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                      );
                    }),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("dismiss".tr),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
