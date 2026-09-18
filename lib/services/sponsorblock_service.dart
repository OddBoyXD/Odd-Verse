import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:harmonymusic/utils/helper.dart';

class SponsorSegment {
  final String category;
  final double start;
  final double end;
  final String uuid;

  SponsorSegment({
    required this.category,
    required this.start,
    required this.end,
    required this.uuid,
  });

  factory SponsorSegment.fromJson(Map<String, dynamic> json) {
    final segmentList = json['segment'] as List? ?? [0.0, 0.0];
    final startVal = (segmentList.isNotEmpty && segmentList[0] is num)
        ? (segmentList[0] as num).toDouble()
        : 0.0;
    final endVal = (segmentList.length > 1 && segmentList[1] is num)
        ? (segmentList[1] as num).toDouble()
        : 0.0;

    return SponsorSegment(
      category: json['category']?.toString() ?? '',
      start: startVal,
      end: endVal,
      uuid: json['UUID']?.toString() ?? json['uuid']?.toString() ?? '',
    );
  }
}

class SponsorBlockService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {
        'User-Agent': 'OddVerse/1.0.0 (Android)',
      },
    ),
  );

  static final Map<String, List<SponsorSegment>> _cache = {};

  /// Fetches intro and sponsor segments for a YouTube video ID.
  /// Strictly filters for 'intro' and 'sponsor' only. Excludes 'music_offtopic' or dialogue.
  static Future<List<SponsorSegment>> getSegments(String videoId) async {
    if (videoId.isEmpty) return [];

    if (_cache.containsKey(videoId)) {
      return _cache[videoId]!;
    }

    try {
      final categoriesParam = jsonEncode(["intro", "sponsor"]);
      final url =
          'https://sponsor.ajay.app/api/skipSegments?videoID=${Uri.encodeComponent(videoId)}&categories=${Uri.encodeComponent(categoriesParam)}';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            (response.data is List) ? response.data : [];
        final segments = <SponsorSegment>[];

        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final seg = SponsorSegment.fromJson(item);
            // Double check category is strictly intro or sponsor
            if ((seg.category == 'intro' || seg.category == 'sponsor') &&
                seg.end > seg.start) {
              segments.add(seg);
            }
          }
        }

        // Sort segments chronologically
        segments.sort((a, b) => a.start.compareTo(b.start));
        _cache[videoId] = segments;
        if (segments.isNotEmpty) {
          printINFO(
              "SponsorBlock: Found ${segments.length} segment(s) for video $videoId");
        }
        return segments;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No segments submitted for this video
        _cache[videoId] = [];
        return [];
      }
      printINFO("SponsorBlock API request error: ${e.message}");
    } catch (e) {
      printINFO("SponsorBlock error: $e");
    }

    _cache[videoId] = [];
    return [];
  }
}
