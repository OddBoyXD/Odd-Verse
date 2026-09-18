import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import '../models/media_Item_builder.dart';
import '../models/playlist.dart';
import '../utils/helper.dart';
import 'music_service.dart';

class PlaylistImportTrack {
  final String title;
  final String artist;
  final int? durationMs;

  PlaylistImportTrack({
    required this.title,
    required this.artist,
    this.durationMs,
  });
}

class PlaylistImportData {
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final List<PlaylistImportTrack> tracks;

  PlaylistImportData({
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.tracks,
  });
}

class PlaylistImportResult {
  final bool success;
  final String message;
  final String? playlistId;
  final String? playlistTitle;
  final int songCount;

  PlaylistImportResult({
    required this.success,
    required this.message,
    this.playlistId,
    this.playlistTitle,
    this.songCount = 0,
  });
}

class PlaylistImportService {
  static final _musicServices = Get.find<MusicServices>();

  /// Detects whether the input string is a valid Spotify or YouTube playlist URL/ID
  static bool isSupportedUrl(String input) {
    final trimmed = input.trim();
    if (isSpotifyUrl(trimmed)) return true;
    if (isYouTubePlaylistUrl(trimmed)) return true;
    return false;
  }

  static bool isSpotifyUrl(String input) {
    return input.contains('spotify.com/playlist') ||
        input.contains('spotify.com/album') ||
        input.startsWith('spotify:playlist:') ||
        input.startsWith('spotify:album:');
  }

  static bool isYouTubePlaylistUrl(String input) {
    if (input.contains('list=')) return true;
    if (input.startsWith('PL') ||
        input.startsWith('RDCLAK') ||
        input.startsWith('VLPL') ||
        input.startsWith('OLAK5uy')) {
      return true;
    }
    if (input.contains('youtube.com/playlist') ||
        input.contains('music.youtube.com/playlist')) {
      return true;
    }
    return false;
  }

  /// Extracts the clean YouTube playlist ID from a URL or raw string
  static String extractYouTubePlaylistId(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      return uri.queryParameters['list']!;
    }
    final match = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!;
    }
    return trimmed;
  }

  /// Extracts Spotify entity type ('playlist' or 'album') and ID
  static Map<String, String>? extractSpotifyInfo(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'(playlist|album)[/:]([a-zA-Z0-9]+)').firstMatch(trimmed);
    if (match != null) {
      return {
        'type': match.group(1)!,
        'id': match.group(2)!,
      };
    }
    return null;
  }

  /// Fetches metadata and track list from a public Spotify playlist or album
  static Future<PlaylistImportData> fetchSpotifyPlaylist(String url) async {
    final info = extractSpotifyInfo(url);
    if (info == null) {
      throw const FormatException('Invalid Spotify URL');
    }

    final type = info['type']!;
    final id = info['id']!;
    final embedUrl = 'https://open.spotify.com/embed/$type/$id';

    final response = await http.get(
      Uri.parse(embedUrl),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load Spotify playlist (HTTP ${response.statusCode})');
    }

    final html = response.body;
    final nextDataMatch =
        RegExp(r'<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)<\/script>')
            .firstMatch(html);

    if (nextDataMatch == null) {
      throw const FormatException('Could not extract playlist data from Spotify embed page');
    }

    final jsonData = jsonDecode(nextDataMatch.group(1)!);
    final entity = jsonData['props']?['pageProps']?['state']?['data']?['entity'];

    if (entity == null) {
      throw const FormatException('Spotify playlist entity not found');
    }

    final title = entity['name'] ?? 'Spotify Playlist';
    String? description;
    final attributes = entity['attributes'] as List?;
    if (attributes != null) {
      for (var attr in attributes) {
        if (attr['key'] == 'episode_description' || attr['key'] == 'description') {
          description = attr['value'];
          break;
        }
      }
    }

    String? thumbnailUrl;
    final images = entity['visualIdentity']?['image'] as List?;
    if (images != null && images.isNotEmpty) {
      thumbnailUrl = images.last['url'];
    }

    final rawTracks = entity['trackList'] as List? ?? [];
    final List<PlaylistImportTrack> tracks = [];

    for (var t in rawTracks) {
      final tTitle = t['title'] as String?;
      final tArtist = t['subtitle'] as String?;
      if (tTitle != null && tTitle.isNotEmpty) {
        tracks.add(PlaylistImportTrack(
          title: tTitle,
          artist: tArtist ?? '',
          durationMs: t['duration'] as int?,
        ));
      }
    }

    return PlaylistImportData(
      title: title,
      description: description ?? 'Imported from Spotify',
      thumbnailUrl: thumbnailUrl,
      tracks: tracks,
    );
  }

  /// Main method to import a playlist from Spotify or YouTube URL
  static Future<PlaylistImportResult> importPlaylist({
    required String url,
    required Function(double progress, String status) onProgress,
  }) async {
    final trimmed = url.trim();

    if (isSpotifyUrl(trimmed)) {
      return await _importFromSpotify(trimmed, onProgress);
    } else if (isYouTubePlaylistUrl(trimmed)) {
      return await _importFromYouTube(trimmed, onProgress);
    } else {
      return PlaylistImportResult(
        success: false,
        message: 'Unsupported link. Please provide a public Spotify or YouTube playlist URL.',
      );
    }
  }

  /// Imports and matches a Spotify playlist against YouTube Music
  static Future<PlaylistImportResult> _importFromSpotify(
    String url,
    Function(double progress, String status) onProgress,
  ) async {
    try {
      onProgress(0.05, 'Fetching Spotify playlist metadata...');
      final spotifyData = await fetchSpotifyPlaylist(url);

      if (spotifyData.tracks.isEmpty) {
        return PlaylistImportResult(
          success: false,
          message: 'No tracks found in Spotify playlist.',
        );
      }

      onProgress(0.15, 'Found ${spotifyData.tracks.length} tracks. Matching with YouTube Music...');

      final List<MediaItem> matchedMediaItems = [];
      final total = spotifyData.tracks.length;

      for (int i = 0; i < total; i++) {
        final track = spotifyData.tracks[i];
        final progress = 0.15 + (0.75 * (i / total));
        onProgress(
          progress,
          'Matching (${i + 1}/$total): ${track.title} - ${track.artist}',
        );

        try {
          final query = '${track.title} ${track.artist}'.trim();
          final searchResult = await _musicServices.search(
            query,
            filter: 'songs',
            limit: 3,
          );

          final songs = searchResult['Songs'] as List?;
          if (songs != null && songs.isNotEmpty) {
            final mediaItem = songs.first as MediaItem;
            matchedMediaItems.add(mediaItem);
          } else {
            // Fallback search without filter
            final broadResult = await _musicServices.search(query, limit: 3);
            if (broadResult.containsKey('Songs') && (broadResult['Songs'] as List).isNotEmpty) {
              matchedMediaItems.add((broadResult['Songs'] as List).first as MediaItem);
            }
          }
        } catch (e) {
          printERROR('Error matching Spotify track: ${track.title} - $e');
        }

        // Slight throttle to avoid rapid bursting
        if (i % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }

      if (matchedMediaItems.isEmpty) {
        return PlaylistImportResult(
          success: false,
          message: 'Could not match any tracks on YouTube Music.',
        );
      }

      onProgress(0.92, 'Saving playlist to library...');

      final newPlaylistId = 'LIB${DateTime.now().millisecondsSinceEpoch}';
      final thumbUrl = spotifyData.thumbnailUrl ??
          matchedMediaItems.first.artUri?.toString() ??
          Playlist.thumbPlaceholderUrl;

      final newPlaylist = Playlist(
        title: '${spotifyData.title} (Spotify)',
        playlistId: newPlaylistId,
        thumbnailUrl: thumbUrl,
        description: spotifyData.description ?? 'Imported from Spotify',
        isCloudPlaylist: false,
      );

      // Save playlist metadata
      final libBox = await Hive.openBox('LibraryPlaylists');
      await libBox.put(newPlaylistId, newPlaylist.toJson());
      await libBox.close();

      // Save songs
      final songBox = await Hive.openBox(newPlaylistId);
      for (int i = 0; i < matchedMediaItems.length; i++) {
        await songBox.put(i, MediaItemBuilder.toJson(matchedMediaItems[i]));
      }
      await songBox.close();

      onProgress(1.0, 'Import completed successfully!');

      return PlaylistImportResult(
        success: true,
        message: 'Imported ${matchedMediaItems.length} of ${spotifyData.tracks.length} songs from Spotify!',
        playlistId: newPlaylistId,
        playlistTitle: newPlaylist.title,
        songCount: matchedMediaItems.length,
      );
    } catch (e) {
      printERROR('Spotify import error: $e');
      return PlaylistImportResult(
        success: false,
        message: 'Failed to import Spotify playlist: $e',
      );
    }
  }

  /// Imports a YouTube / YouTube Music playlist directly
  static Future<PlaylistImportResult> _importFromYouTube(
    String url,
    Function(double progress, String status) onProgress,
  ) async {
    try {
      onProgress(0.1, 'Fetching YouTube playlist details...');
      final playlistId = extractYouTubePlaylistId(url);

      final content = await _musicServices.getPlaylistOrAlbumSongs(
        playlistId: playlistId,
      );

      final tracks = (content['tracks'] as List?)?.cast<MediaItem>() ?? [];
      if (tracks.isEmpty) {
        return PlaylistImportResult(
          success: false,
          message: 'No tracks found in YouTube playlist or playlist is private.',
        );
      }

      onProgress(0.5, 'Saving ${tracks.length} tracks to library...');

      final title = content['title'] ?? 'YouTube Playlist';
      final newPlaylistId = 'LIB${DateTime.now().millisecondsSinceEpoch}';

      String thumbUrl = Playlist.thumbPlaceholderUrl;
      final thumbs = content['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbUrl = thumbs.last['url'] ?? Playlist.thumbPlaceholderUrl;
      } else if (tracks.first.artUri != null) {
        thumbUrl = tracks.first.artUri.toString();
      }

      final newPlaylist = Playlist(
        title: '$title (YouTube)',
        playlistId: newPlaylistId,
        thumbnailUrl: thumbUrl,
        description: content['description'] ?? 'Imported from YouTube',
        isCloudPlaylist: false,
      );

      // Save playlist metadata
      final libBox = await Hive.openBox('LibraryPlaylists');
      await libBox.put(newPlaylistId, newPlaylist.toJson());
      await libBox.close();

      // Save songs
      final songBox = await Hive.openBox(newPlaylistId);
      for (int i = 0; i < tracks.length; i++) {
        await songBox.put(i, MediaItemBuilder.toJson(tracks[i]));
      }
      await songBox.close();

      onProgress(1.0, 'Import completed successfully!');

      return PlaylistImportResult(
        success: true,
        message: 'Imported ${tracks.length} songs from YouTube!',
        playlistId: newPlaylistId,
        playlistTitle: newPlaylist.title,
        songCount: tracks.length,
      );
    } catch (e) {
      printERROR('YouTube import error: $e');
      return PlaylistImportResult(
        success: false,
        message: 'Failed to import YouTube playlist: $e',
      );
    }
  }
}
