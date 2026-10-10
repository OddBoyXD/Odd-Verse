import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/ui/widgets/common_dialog_widget.dart';
import 'image_widget.dart';
import 'snackbar.dart';

class SongInfoDialog extends StatelessWidget {
  final MediaItem song;
  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final streamInfo = _getStreamInfo(song.id);

    final durationSec = song.duration?.inSeconds ??
        ((streamInfo["approxDurationMs"] is int)
            ? (streamInfo["approxDurationMs"] as int) ~/ 1000
            : null);
    final durationStr = durationSec != null
        ? "${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}"
        : "N/A";

    return CommonDialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: Get.mediaQuery.size.height * 0.75,
          maxWidth: 480,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header with Album Art & Title
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ImageWidget(song: song, size: 52),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist ?? "Unknown Artist",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Metadata Grid / List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _infoCard(
                    context,
                    icon: Icons.tag_rounded,
                    title: "Song ID",
                    value: song.id,
                    canCopy: true,
                  ),
                  if (song.album != null && song.album!.isNotEmpty)
                    _infoCard(
                      context,
                      icon: Icons.album_rounded,
                      title: "Album",
                      value: song.album!,
                    ),
                  _infoCard(
                    context,
                    icon: Icons.timer_outlined,
                    title: "Duration",
                    value: durationStr,
                  ),
                  _infoCard(
                    context,
                    icon: Icons.graphic_eq_rounded,
                    title: "Audio Codec",
                    value: streamInfo["audioCodec"]?.toString().toUpperCase() ??
                        "N/A",
                  ),
                  _infoCard(
                    context,
                    icon: Icons.speed_rounded,
                    title: "Bitrate",
                    value: streamInfo["bitrate"] != null
                        ? "${(int.tryParse(streamInfo["bitrate"].toString()) ?? 0) ~/ 1000} kbps"
                        : "N/A",
                  ),
                  if (streamInfo["loudnessDb"] != null)
                    _infoCard(
                      context,
                      icon: Icons.volume_up_rounded,
                      title: "Loudness",
                      value: "${streamInfo["loudnessDb"]} dB",
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "close".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool canCopy = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(snackbar(
                  context,
                  "Copied to clipboard!",
                  size: SanckBarSize.SMALL,
                ));
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<dynamic, dynamic> _getStreamInfo(String id) {
    Map<dynamic, dynamic> tempstreamInfo;
    final nullVal = {
      "audioCodec": null,
      "bitrate": null,
      "loudnessDb": null,
      "approxDurationMs": null
    };
    if (Hive.box("SongDownloads").containsKey(id)) {
      final song = Hive.box("SongDownloads").get(id);

      tempstreamInfo =
          song["streamInfo"] == null ? nullVal : song["streamInfo"][1];
    } else {
      final dbStreamData = Hive.box("SongsUrlCache").get(id);
      tempstreamInfo = dbStreamData != null &&
              dbStreamData.runtimeType.toString().contains("Map")
          ? dbStreamData[Hive.box('AppPrefs').get('streamingQuality') == 0
              ? 'lowQualityAudio'
              : "highQualityAudio"]
          : nullVal;
    }
    return tempstreamInfo;
  }
}
