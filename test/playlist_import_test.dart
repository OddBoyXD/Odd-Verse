import 'package:flutter_test/flutter_test.dart';
import 'package:harmonymusic/services/playlist_import_service.dart';

void main() {
  group('PlaylistImportService URL Detection & Parsing Tests', () {
    test('Detects Spotify playlist URLs correctly', () {
      expect(
        PlaylistImportService.isSpotifyUrl(
            'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=12345'),
        isTrue,
      );
      expect(
        PlaylistImportService.isSpotifyUrl('spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'),
        isTrue,
      );
      expect(
        PlaylistImportService.isSpotifyUrl(
            'https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy'),
        isTrue,
      );
      expect(
        PlaylistImportService.isSpotifyUrl('https://youtube.com/playlist?list=PL123'),
        isFalse,
      );
    });

    test('Detects YouTube playlist URLs correctly', () {
      expect(
        PlaylistImportService.isYouTubePlaylistUrl(
            'https://music.youtube.com/playlist?list=PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0'),
        isTrue,
      );
      expect(
        PlaylistImportService.isYouTubePlaylistUrl(
            'https://www.youtube.com/playlist?list=PLMC9KNkIncKtPzgY-5rmhvj7fax8fdxoj'),
        isTrue,
      );
      expect(
        PlaylistImportService.isYouTubePlaylistUrl('PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0'),
        isTrue,
      );
      expect(
        PlaylistImportService.isYouTubePlaylistUrl('RDCLAK5uy_k1234567'),
        isTrue,
      );
    });

    test('Extracts YouTube playlist IDs accurately', () {
      expect(
        PlaylistImportService.extractYouTubePlaylistId(
            'https://music.youtube.com/playlist?list=PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0&si=abc'),
        equals('PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0'),
      );
      expect(
        PlaylistImportService.extractYouTubePlaylistId(
            'https://www.youtube.com/playlist?list=PLMC9KNkIncKtPzgY-5rmhvj7fax8fdxoj'),
        equals('PLMC9KNkIncKtPzgY-5rmhvj7fax8fdxoj'),
      );
      expect(
        PlaylistImportService.extractYouTubePlaylistId('PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0'),
        equals('PLrAl6sV99vfqf1E6fS7yV8k0k0vYJ2x0'),
      );
    });

    test('Extracts Spotify entity type and ID correctly', () {
      final playlistInfo = PlaylistImportService.extractSpotifyInfo(
          'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abcdef');
      expect(playlistInfo, isNotNull);
      expect(playlistInfo!['type'], equals('playlist'));
      expect(playlistInfo['id'], equals('37i9dQZF1DXcBWIGoYBM5M'));

      final albumInfo = PlaylistImportService.extractSpotifyInfo(
          'https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy');
      expect(albumInfo, isNotNull);
      expect(albumInfo!['type'], equals('album'));
      expect(albumInfo['id'], equals('4aawyAB9vmqN3uQ7FjRGTy'));
    });
  });
}
