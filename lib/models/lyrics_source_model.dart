import 'package:hive/hive.dart';

class LyricsSourceInfo {
  final String id;
  final String label;
  final String detail;
  final bool wordSynced;
  bool enabled;

  LyricsSourceInfo({
    required this.id,
    required this.label,
    required this.detail,
    required this.wordSynced,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'detail': detail,
        'wordSynced': wordSynced,
        'enabled': enabled,
      };

  factory LyricsSourceInfo.fromJson(Map<String, dynamic> json) =>
      LyricsSourceInfo(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        wordSynced: json['wordSynced'] == true,
        enabled: json['enabled'] != false,
      );

  static List<LyricsSourceInfo> get defaultSources => [
        LyricsSourceInfo(
          id: "lrc_red",
          label: "lrc.red",
          detail: "Apple timings by recording, syllable by syllable",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "bini_lyrics",
          label: "BiniLyrics",
          detail: "The same Apple timings, matched on the recording itself",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "better_lyrics",
          label: "BetterLyrics",
          detail: "Apple Music timings, word by word",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "better_lyrics_portato",
          label: "BetterLyrics Portato",
          detail: "QQ Music karaoke timings through BetterLyrics",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "paxsenix",
          label: "PaxSenix",
          detail: "Apple Music timings through the original keyless provider",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "paxsenix_spotify",
          label: "PaxSenix: Spotify",
          detail: "Spotify lyrics with PaxSenix fallback",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "paxsenix_musixmatch",
          label: "PaxSenix: Musixmatch",
          detail: "Musixmatch timings with PaxSenix fallback",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "lyrics_plus",
          label: "LyricsPlus",
          detail: "Syllable by syllable, on community mirrors",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "unison",
          label: "Unison",
          detail: "Contributed by listeners, so it has what nobody licensed",
          wordSynced: true,
        ),
        LyricsSourceInfo(
          id: "youtube_captions",
          label: "YouTube captions",
          detail: "Timed captions matched to the exact playing video",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "ytmusic",
          label: "YouTube Music",
          detail: "Plain lyrics from the playing video's Lyrics tab",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "kugou",
          label: "KuGou",
          detail:
              "Whole lines & syllables, strong outside the English catalogue",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "lrclib",
          label: "LRCLIB",
          detail: "Whole lines only, and always up",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "musixmatch",
          label: "Musixmatch",
          detail: "Whole lines, from the biggest lyrics database there is",
          wordSynced: false,
        ),
        LyricsSourceInfo(
          id: "genius",
          label: "Genius",
          detail: "Plain text fallback, massive web catalogue",
          wordSynced: false,
        ),
      ];

  static List<LyricsSourceInfo> loadSavedSources() {
    try {
      final box = Hive.box("AppPrefs");
      final savedData = box.get("lyrics_sources_config");
      if (savedData is List && savedData.isNotEmpty) {
        final list = <LyricsSourceInfo>[];
        for (final item in savedData) {
          if (item is Map) {
            list.add(LyricsSourceInfo.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        // Slot in any new default providers that weren't in the saved list
        final existingIds = list.map((e) => e.id).toSet();
        for (final def in defaultSources) {
          if (!existingIds.contains(def.id)) {
            list.add(def);
          }
        }
        return list;
      }
    } catch (_) {}
    return List.from(defaultSources);
  }

  static Future<void> saveSources(List<LyricsSourceInfo> list) async {
    try {
      final box = Hive.box("AppPrefs");
      await box.put("lyrics_sources_config", list.map((e) => e.toJson()).toList());
    } catch (_) {}
  }
}
