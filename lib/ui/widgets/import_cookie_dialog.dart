import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/ytm_auth_service.dart';
import '../screens/Home/home_screen_controller.dart';
import 'common_dialog_widget.dart';
import 'snackbar.dart';

class ImportCookieDialog extends StatefulWidget {
  const ImportCookieDialog({super.key});

  @override
  State<ImportCookieDialog> createState() => _ImportCookieDialogState();
}

class _ImportCookieDialogState extends State<ImportCookieDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importCookies() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Please paste your YouTube Music cookies.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ytmAuth = Get.find<YtmAuthService>();
    final success = await ytmAuth.setCookies(text);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          snackbar(
            context,
            "YouTube Music connected successfully!",
            size: SanckBarSize.BIG,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage =
            "Invalid cookies! Ensure your cookies contain SAPISID, SSID, or LOGIN_INFO.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      maxWidth: 550,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Import Cookies",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Paste your raw YouTube Music cookies (Header text, Netscape format, or JSON array).",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    "e.g. SID=xxx; __Secure-3PAPISID=yyy; SAPISID=zzz; ...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded),
                  tooltip: "Paste from clipboard",
                  onPressed: () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      setState(() {
                        _controller.text = data!.text!;
                        _errorMessage = null;
                      });
                    }
                  },
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _importCookies,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Import & Login"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
