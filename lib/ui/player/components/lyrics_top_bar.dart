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
            // Close / Minimize Lyrics Button
            IconButton(
              tooltip: "Close Lyrics",
              splashRadius: 20,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                playerController.showLyricsflag.value = false;
              },
            ),

          // Center: Synced / Plain mode toggle
          Obx(() {
            final isPlain = playerController.lyricsMode.value == 1;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                playerController.changeLyricsMode(isPlain ? 0 : 1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlain ? Icons.text_snippet_outlined : Icons.music_note_rounded,
                      size: 14,
                      color: const Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPlain ? "Plain" : "Synced",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

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
