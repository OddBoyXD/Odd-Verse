import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/services/piped_service.dart';
import '/services/playlist_import_service.dart';
import '../screens/Library/library_controller.dart';
import '/ui/widgets/snackbar.dart';
import '../../models/playlist.dart';
import 'common_dialog_widget.dart';
import 'modified_text_field.dart';

class CreateNRenamePlaylistPopup extends StatefulWidget {
  const CreateNRenamePlaylistPopup({
    super.key,
    this.isCreateNadd = false,
    this.songItems,
    this.renamePlaylist = false,
    this.playlist,
  });

  final bool isCreateNadd;
  final bool renamePlaylist;
  final List<MediaItem>? songItems;
  final Playlist? playlist;

  @override
  State<CreateNRenamePlaylistPopup> createState() =>
      _CreateNRenamePlaylistPopupState();
}

class _CreateNRenamePlaylistPopupState
    extends State<CreateNRenamePlaylistPopup> {
  int _selectedTab = 0; // 0: Import Link, 1: Create Blank
  final TextEditingController _importUrlController = TextEditingController();
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _importStatus = '';

  @override
  void initState() {
    super.initState();
    final librPlstCntrller = Get.find<LibraryPlaylistsController>();
    librPlstCntrller.changeCreationMode("local");
    librPlstCntrller.textInputController.text = "";
    if (widget.isCreateNadd || widget.renamePlaylist) {
      _selectedTab = 1;
    }
  }

  @override
  void dispose() {
    _importUrlController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    final text = _importUrlController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackbar(context, "Please paste a Spotify or YouTube playlist URL",
            size: SanckBarSize.MEDIUM),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 0.05;
      _importStatus = 'Connecting...';
    });

    final result = await PlaylistImportService.importPlaylist(
      url: text,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _importProgress = progress;
            _importStatus = status;
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
    final librPlstCntrller = Get.find<LibraryPlaylistsController>();
    final isPipedLinked = Get.find<PipedServices>().isLoggedIn;
    final theme = Theme.of(context);

    if (widget.renamePlaylist) {
      return CommonDialog(
        child: Container(
          height: 200,
          padding:
              const EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Marquee(
                    delay: const Duration(milliseconds: 300),
                    id: "renamePlaylist",
                    child: Text(
                      "renamePlaylist".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              ModifiedTextField(
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                cursorColor: theme.textTheme.titleSmall!.color,
                controller: librPlstCntrller.textInputController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(left: 5),
                  focusColor: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text("cancel".tr),
                      ),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: theme.textTheme.titleLarge!.color,
                          borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10),
                          child: Text(
                            "rename".tr,
                            style: TextStyle(color: theme.canvasColor),
                          ),
                        ),
                        onTap: () async {
                          final res = await librPlstCntrller
                              .renamePlaylist(widget.playlist!);
                          if (res && context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              snackbar(context, "playlistRenameAlert".tr,
                                  size: SanckBarSize.MEDIUM),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }

    return CommonDialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector Tabs (Import Link vs Create Blank)
            if (!widget.isCreateNadd)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _selectedTab == 0
                                ? Border.all(
                                    color: theme.colorScheme.primary, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_rounded,
                                  size: 18,
                                  color: _selectedTab == 0
                                      ? theme.colorScheme.primary
                                      : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                "Import Link",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _selectedTab == 1
                                ? Border.all(
                                    color: theme.colorScheme.primary, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_box_outlined,
                                  size: 18,
                                  color: _selectedTab == 1
                                      ? theme.colorScheme.primary
                                      : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                "Create Blank",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 1
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab 0: Import Spotify / YouTube Link
            if (_selectedTab == 0 && !widget.isCreateNadd) ...[
              if (!_isImporting) ...[
                Text(
                  "Import Spotify / YouTube Playlist",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Paste any public Spotify or YouTube playlist link to directly match and save tracks into your library.",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _importUrlController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "https://open.spotify.com/playlist/... or YouTube link",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded),
                      tooltip: "Paste from clipboard",
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _importUrlController.text = data!.text!.trim();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                      onPressed: _startImport,
                      child: const Text("Import Playlist"),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  "Importing Playlist...",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _importProgress > 0 ? _importProgress : null,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  "${(_importProgress * 100).toInt()}% - $_importStatus",
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
                    "Please keep Odd Verse open...",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],

            // Tab 1: Create Blank Local / Piped Playlist
            if (_selectedTab == 1 || widget.isCreateNadd) ...[
              Text(
                "Create Blank Playlist",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (isPipedLinked && !widget.renamePlaylist)
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio(
                            value: "piped",
                            groupValue:
                                librPlstCntrller.playlistCreationMode.value,
                            onChanged: librPlstCntrller.changeCreationMode,
                          ),
                          Text("Piped".tr),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Row(
                        children: [
                          Radio(
                            value: "local",
                            groupValue:
                                librPlstCntrller.playlistCreationMode.value,
                            onChanged: librPlstCntrller.changeCreationMode,
                          ),
                          Text("local".tr),
                        ],
                      )
                    ],
                  ),
                ),
              ModifiedTextField(
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                cursorColor: theme.textTheme.titleSmall!.color,
                controller: librPlstCntrller.textInputController,
                decoration: const InputDecoration(
                  hintText: "Playlist Title",
                  contentPadding: EdgeInsets.only(left: 5),
                  focusColor: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text("cancel".tr),
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () async {
                        final value = await librPlstCntrller.createNewPlaylist(
                          createPlaylistNaddSong: widget.isCreateNadd,
                          songItems: widget.songItems,
                        );
                        if (!context.mounted) return;
                        if (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            snackbar(
                              context,
                              widget.isCreateNadd
                                  ? "playlistCreatednsongAddedAlert".tr
                                  : "playlistCreatedAlert".tr,
                              size: SanckBarSize.MEDIUM,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            snackbar(context, "errorOccuredAlert".tr,
                                size: SanckBarSize.MEDIUM),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        widget.isCreateNadd ? "createnAdd".tr : "create".tr,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
