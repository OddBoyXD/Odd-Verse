import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/player/components/lyrics_sources_sheet.dart';
import 'package:harmonymusic/ui/player/components/lyrics_widget.dart';
import 'package:harmonymusic/ui/player/player_controller.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';

class LyricsTopBar extends StatelessWidget {
  const LyricsTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final settingsController = Get.find<SettingsScreenController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Lyrics Badge / Label
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lyrics_rounded,
                    size: 16,
                    color: Color(0xFFFFD54F),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "lyrics".tr.isNotEmpty ? "lyrics".tr : "Lyrics",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Right action buttons: Romanize, Sources, Search
            Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Universal Romanize / English toggle
              Obx(() {
                final isRoman = settingsController.romanizeLyricsEnabled.value;
                return IconButton(
                  tooltip: "Universal Romanize (English)",
                  splashRadius: 20,
                  icon: Icon(
                    Icons.translate_rounded,
                    color: isRoman ? const Color(0xFFFFD54F) : Colors.white60,
                    size: 20,
                  ),
                  onPressed: () {
                    settingsController.toggleRomanizeLyrics(!isRoman);
                  },
                );
              }),

              // Manual Lyrics search across providers
              IconButton(
                tooltip: "Search Across Providers",
                splashRadius: 20,
                icon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  showLyricsSearchSheet(context, playerController);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
