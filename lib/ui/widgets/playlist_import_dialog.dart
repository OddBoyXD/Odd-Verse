import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/playlist_import_service.dart';
import '../screens/Library/library_controller.dart';
import 'common_dialog_widget.dart';
import 'snackbar.dart';

class PlaylistImportDialog extends StatefulWidget {
  const PlaylistImportDialog({super.key});

  @override
  State<PlaylistImportDialog> createState() => _PlaylistImportDialogState();
}

class _PlaylistImportDialogState extends State<PlaylistImportDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  double _progress = 0.0;
  String _statusMessage = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startUrlImport() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackbar(context, "Please enter a Spotify or YouTube playlist URL",
            size: SanckBarSize.MEDIUM),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _progress = 0.05;
      _statusMessage = 'Connecting...';
    });

    final result = await PlaylistImportService.importPlaylist(
      url: text,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statusMessage = status;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isImporting = false;
    });

    if (result.success) {
      Get.find<LibraryPlaylistsController>().refreshLib();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        snackbar(
          context,
          result.message,
          size: SanckBarSize.BIG,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        snackbar(context, result.message, size: SanckBarSize.BIG),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CommonDialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_download_rounded,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  "Import Playlist",
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Import public Spotify or YouTube playlists directly into your local library, or select a JSON backup file.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isImporting) ...[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Playlist URL",
                  hintText: "Paste Spotify or YouTube link...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded),
                    tooltip: "Paste from clipboard",
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _urlController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text("JSON File"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.find<LibraryPlaylistsController>()
                          .importPlaylistFromJson(context);
                    },
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("cancel".tr),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _startUrlImport,
                        child: const Text("Import Link"),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Text(
                "${(_progress * 100).toInt()}% - $_statusMessage",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Please keep Odd Verse open while importing...",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
