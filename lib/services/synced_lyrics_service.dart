import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/music_service.dart';
import 'package:harmonymusic/utils/helper.dart';
import 'package:hive/hive.dart';

class SyncedLyricsService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  static Future<Box> _getLyricsBox() async {
    return Hive.isBoxOpen("lyrics")
        ? Hive.box("lyrics")
        : await Hive.openBox("lyrics");
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String cleanTrackTitle(String title, {String? artist}) {
    String clean = title;

    // 1. Split by pipe '|', ' / ', ' // ' and take first part (common in YouTube music video titles)
    if (clean.contains('|')) {
      clean = clean.split('|')[0];
    }
    if (clean.contains(' / ')) {
      clean = clean.split(' / ')[0];
    }
    if (clean.contains(' // ')) {
      clean = clean.split(' // ')[0];
    }

    // 2. Handle "Artist - Title" vs "Title - Subtitle"
    final cleanArtist = cleanArtistName(artist);
    if (clean.contains(' - ') || clean.contains(' – ')) {
      final sep = clean.contains(' – ') ? ' – ' : ' - ';
      final parts = clean.split(sep);
      if (parts.length >= 2) {
        final p0 = _normalize(parts[0]);
        final p1 = _normalize(parts[1]);
        final a = _normalize(cleanArtist);
        if (a.isNotEmpty && (p0 == a || p0.contains(a) || a.contains(p0))) {
          // "Artist - Title" -> Take title (parts[1..])
          clean = parts.sublist(1).join(sep);
        } else if (a.isNotEmpty &&
            (p1 == a || p1.contains(a) || a.contains(p1))) {
          // "Title - Artist" -> Take title (parts[0])
          clean = parts[0];
        } else if (cleanArtist.isEmpty) {
          // If no artist given, parts[0] is often artist, parts[1] is title
          clean = parts.sublist(1).join(sep);
        }
      }
    }

    // 3. Remove (From "Movie Name") or [From 'Movie Name']
    clean = clean.replaceAll(
      RegExp(
        r'\s*[\(\[\{]\s*from\s+["\x27]?[^\)\]\}]+["\x27]?\s*[\)\]\}]',
        caseSensitive: false,
      ),
      '',
    );

    // 4. Remove metadata tags inside brackets/parentheses
    clean = clean.replaceAll(
      RegExp(
        r'\s*[\(\[\{][^\)\]\}]*(?:official|video|audio|lyrics|lyric|visualizer|remaster|hd|4k|extended|clean|explicit|live|mv|feat|ft\.|ost|soundtrack|full song|full audio|telemovie|promo|coke studio|teaser|trailer|slowed|reverb|sped up)[^\)\]\}]*[\)\]\}]',
        caseSensitive: false,
      ),
      '',
    );

    // 5. Remove (feat. ...), (ft. ...), [feat. ...]
    clean = clean.replaceAll(
      RegExp(
        r'\s*[\(\[\{]\s*(?:feat\.|ft\.|featuring)\s+[^\)\]\}]+[\)\]\}]',
        caseSensitive: false,
      ),
      '',
    );

    // 6. Remove trailing feat. / ft.
    clean = clean.replaceAll(
      RegExp(r'\s*(?:feat\.|ft\.|featuring)\s+.*$', caseSensitive: false),
      '',
    );

    // 7. Remove hashtags and promotional markers
    clean = clean.replaceAll(RegExp(r'#\w+'), '');

    // 8. Remove trailing dashes/punctuation
    clean = clean.replaceAll(RegExp(r'[\s\-_|:]+$'), '').trim();
    return clean.isEmpty ? title.trim() : clean;
  }

  static String cleanArtistName(String? artist) {
    if (artist == null || artist.trim().isEmpty) return '';
    String clean = artist.trim();
    // Remove " - Topic" from auto-generated channels
    clean =
        clean.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'\s*VEVO$', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'\s*Official$', caseSensitive: false), '');
    // Take primary artist before comma, &, x, X, feat, ft
    clean = clean.split(',')[0].split('&')[0].split(
      RegExp(r'\s+[xX]\s+'),
    )[0].split(
      RegExp(r'\s+(?:feat\.|ft\.|featuring)\s+', caseSensitive: false),
    )[0].trim();
    return clean;
  }

  /// Verifies that candidate from LRCLIB genuinely matches the target track
  static bool _isStrictMatch(
    Map item,
    String cleanTitle,
    String cleanArtist,
    int expectedDurationSec,
  ) {
    final candidateTrack = _normalize(
      (item["trackName"] ?? item["name"] ?? "").toString(),
    );
    final targetTrack = _normalize(cleanTitle);

    if (candidateTrack.isEmpty || targetTrack.isEmpty) return false;

    // Direct equality or substring containment
    bool titleMatches = (candidateTrack == targetTrack) ||
        candidateTrack.startsWith(targetTrack) ||
        targetTrack.startsWith(candidateTrack) ||
        candidateTrack.contains(targetTrack) ||
        targetTrack.contains(candidateTrack);

    if (!titleMatches) {
      // Word overlap check: at least 60% of target track words must be present
      final cWords =
          candidateTrack.split(' ').where((w) => w.length > 1).toSet();
      final tWords =
          targetTrack.split(' ').where((w) => w.length > 1).toSet();
      if (tWords.isNotEmpty && cWords.isNotEmpty) {
        final common = tWords.intersection(cWords);
        if (common.length / tWords.length >= 0.6) {
          titleMatches = true;
        }
      }
    }

    if (!titleMatches) return false;

    // Check duration tolerance
    final candidateArtist = _normalize((item["artistName"] ?? "").toString());
    final targetArtist = _normalize(cleanArtist);
    bool artistMatches = false;
    if (targetArtist.isNotEmpty && candidateArtist.isNotEmpty) {
      artistMatches = candidateArtist == targetArtist ||
          candidateArtist.contains(targetArtist) ||
          targetArtist.contains(candidateArtist);
    }

    final itemDur = (item["duration"] is num)
        ? (item["duration"] as num).toInt()
        : 0;
    if (expectedDurationSec > 0 && itemDur > 0) {
      final diff = (itemDur - expectedDurationSec).abs();
      if (artistMatches) {
        return diff <= 50; // generous tolerance when artist is confirmed
      } else {
        return diff <= 25; // stricter tolerance when artist is not confirmed
      }
    }

    return true;
  }

  static Future<Map<String, dynamic>?> getSyncedLyrics(
      MediaItem song, int durInSec) async {
    final lyricsBox = await _getLyricsBox();

    // 1. Check local cache
    if (lyricsBox.containsKey(song.id)) {
      try {
        final cached = lyricsBox.get(song.id);
        if (cached is Map) {
          return Map<String, dynamic>.from(cached);
        }
      } catch (_) {}
    }

    final cleanTitle = cleanTrackTitle(song.title, artist: song.artist);
    final cleanArtist = cleanArtistName(song.artist);
    final dur = song.duration?.inSeconds ?? durInSec;
    String? fallbackPlain;

    // 2. Tier 1: LRCLIB Exact Lookup
    if (cleanArtist.isNotEmpty && cleanTitle.isNotEmpty) {
      try {
        final url =
            'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(cleanArtist)}&track_name=${Uri.encodeComponent(cleanTitle)}&duration=$dur';
        final response = (await _dio.get(url)).data;
        if (response != null && response is Map) {
          if (_isStrictMatch(response, cleanTitle, cleanArtist, dur)) {
            final synced = response["syncedLyrics"]?.toString();
            final plain = response["plainLyrics"]?.toString() ?? "";
            if (synced != null && synced.trim().isNotEmpty) {
              printINFO("Synced Lyrics found via LRCLIB exact match for $cleanTitle");
              final lyricsData = {
                "synced": synced,
                "plainLyrics": plain,
              };
              await lyricsBox.put(song.id, lyricsData);
              return lyricsData;
            }
            if (plain.trim().isNotEmpty) {
              fallbackPlain = plain;
            }
          }
        }
      } catch (_) {}
    }

    // 3. Tier 2: LRCLIB Search with Track & Artist (tolerating duration variance)
    if (cleanTitle.isNotEmpty) {
      try {
        final searchUrl = cleanArtist.isNotEmpty
            ? 'https://lrclib.net/api/search?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}'
            : 'https://lrclib.net/api/search?track_name=${Uri.encodeComponent(cleanTitle)}';
        final response = (await _dio.get(searchUrl)).data;
        if (response != null && response is List && response.isNotEmpty) {
          Map? bestMatch;
          int minDurDiff = 999999;
          for (final item in response) {
            if (item is Map &&
                _isStrictMatch(item, cleanTitle, cleanArtist, dur)) {
              final synced = item["syncedLyrics"]?.toString();
              if (synced != null && synced.trim().isNotEmpty) {
                final itemDur = (item["duration"] is num)
                    ? (item["duration"] as num).toInt()
                    : 0;
                final diff = (itemDur - dur).abs();
                if (diff < minDurDiff) {
                  minDurDiff = diff;
                  bestMatch = item;
                }
              } else if (fallbackPlain == null &&
                  item["plainLyrics"] != null &&
                  item["plainLyrics"].toString().trim().isNotEmpty) {
                fallbackPlain = item["plainLyrics"].toString();
              }
            }
          }
          if (bestMatch != null) {
            printINFO("Synced Lyrics found via LRCLIB track search for $cleanTitle");
            final lyricsData = {
              "synced": bestMatch["syncedLyrics"],
              "plainLyrics": bestMatch["plainLyrics"] ?? fallbackPlain ?? "",
            };
            await lyricsBox.put(song.id, lyricsData);
            return lyricsData;
          }
        }
      } catch (_) {}
    }

    // 4. Tier 3: LRCLIB General Query Search with Cleaned Title & Artist
    try {
      final q = Uri.encodeComponent('$cleanTitle $cleanArtist'.trim());
      final qUrl = 'https://lrclib.net/api/search?q=$q';
      final response = (await _dio.get(qUrl)).data;
      if (response != null && response is List && response.isNotEmpty) {
        Map? bestMatch;
        int minDurDiff = 999999;
        for (final item in response) {
          if (item is Map &&
              _isStrictMatch(item, cleanTitle, cleanArtist, dur)) {
            final synced = item["syncedLyrics"]?.toString();
            if (synced != null && synced.trim().isNotEmpty) {
              final itemDur = (item["duration"] is num)
                  ? (item["duration"] as num).toInt()
                  : 0;
              final diff = (itemDur - dur).abs();
              if (diff < minDurDiff) {
                minDurDiff = diff;
                bestMatch = item;
              }
            } else if (fallbackPlain == null &&
                item["plainLyrics"] != null &&
                item["plainLyrics"].toString().trim().isNotEmpty) {
              fallbackPlain = item["plainLyrics"].toString();
            }
          }
        }
        if (bestMatch != null) {
          printINFO("Synced Lyrics found via LRCLIB general search for $cleanTitle");
          final lyricsData = {
            "synced": bestMatch["syncedLyrics"],
            "plainLyrics": bestMatch["plainLyrics"] ?? fallbackPlain ?? "",
          };
          await lyricsBox.put(song.id, lyricsData);
          return lyricsData;
        }
      }
    } catch (_) {}

    // 5. Tier 4: YouTube Music Official Lyrics Fallback
    try {
      if (Get.isRegistered<MusicServices>()) {
        final musicServices = Get.find<MusicServices>();
        final related = await musicServices.getWatchPlaylist(
          videoId: song.id,
          onlyRelated: true,
        );
        final lyricsId = related['lyrics'];
        if (lyricsId != null) {
          final ytLyrics = await musicServices.getLyrics(lyricsId);
          if (ytLyrics != null && ytLyrics.toString().trim().isNotEmpty) {
            printINFO("Official YouTube Music Lyrics retrieved for ${song.title}");
            final lyricsData = {
              "synced": "",
              "plainLyrics": ytLyrics.toString().trim(),
            };
            await lyricsBox.put(song.id, lyricsData);
            return lyricsData;
          }
        }
      }
    } catch (e) {
      printERROR("YTMusic Lyrics fetch error: $e");
    }

    // 6. Tier 5: Return fallback plain lyrics if available
    if (fallbackPlain != null && fallbackPlain.trim().isNotEmpty) {
      final lyricsData = {
        "synced": "",
        "plainLyrics": fallbackPlain,
      };
      await lyricsBox.put(song.id, lyricsData);
      return lyricsData;
    }

    return null;
  }
}
