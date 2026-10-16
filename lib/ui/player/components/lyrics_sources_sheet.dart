import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/models/lyrics_source_model.dart';
import 'package:harmonymusic/ui/player/player_controller.dart';

void showLyricsSourcesDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const LyricsSourcesSheet(),
  );
}

class LyricsSourcesSheet extends StatefulWidget {
  const LyricsSourcesSheet({super.key});

  @override
  State<LyricsSourcesSheet> createState() => _LyricsSourcesSheetState();
}

class _LyricsSourcesSheetState extends State<LyricsSourcesSheet> {
  late List<LyricsSourceInfo> _sources;

  @override
  void initState() {
    super.initState();
    _sources = LyricsSourceInfo.loadSavedSources();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sources.removeAt(oldIndex);
      _sources.insert(newIndex, item);
    });
    LyricsSourceInfo.saveSources(_sources);
  }

  void _onToggle(int index, bool val) {
    setState(() {
      _sources[index].enabled = val;
    });
    LyricsSourceInfo.saveSources(_sources);
  }

  void _resetToDefault() {
    setState(() {
      _sources = List.from(LyricsSourceInfo.defaultSources);
    });
    LyricsSourceInfo.saveSources(_sources);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 550,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lyrics Sources",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Drag to set priority • Toggle to enable",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _resetToDefault,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    "Reset",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: _sources.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final source = _sources[index];
                return Material(
                  key: ValueKey(source.id),
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: source.enabled
                          ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03))
                          : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: source.enabled
                            ? (source.wordSynced
                                ? const Color(0xFFFFD54F).withOpacity(0.20)
                                : Colors.white12)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Drag handle
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: Colors.white.withOpacity(0.40),
                              size: 22,
                            ),
                          ),
                        ),

                        // Source details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      source.label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: source.enabled
                                            ? Colors.white
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: source.wordSynced
                                          ? const Color(0xFFFFD54F).withOpacity(0.18)
                                          : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      source.wordSynced
                                          ? "Word-by-word"
                                          : "Line-synced",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: source.wordSynced
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white60,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                source.detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: source.enabled
                                      ? Colors.white60
                                      : Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Switch toggle
                        Switch(
                          value: source.enabled,
                          activeColor: const Color(0xFFFFD54F),
                          onChanged: (val) => _onToggle(index, val),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Close / Refetch Button
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Trigger a fresh lyrics lookup using the newly arranged providers
                  if (Get.isRegistered<PlayerController>()) {
                    final pc = Get.find<PlayerController>();
                    if (pc.currentSong.value != null) {
                      pc.fetchLyrics();
                    }
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  "Apply & Refresh Lyrics",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
