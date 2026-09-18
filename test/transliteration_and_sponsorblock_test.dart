import 'package:flutter_test/flutter_test.dart';
import 'package:harmonymusic/utils/indic_transliteration.dart';
import 'package:harmonymusic/services/sponsorblock_service.dart';
import 'package:harmonymusic/services/synced_lyrics_service.dart';

void main() {
  group('Indic Transliteration Tests', () {
    test('Transliterates Gurmukhi / Punjabi lyrics cleanly without leftover characters', () {
      const punjabiText = "ਕੱਚੀ ਕਲੀ, ਸਾਡਾ ਮਾਸੂਮ ਚਿਹਰਾ\nਨੀਅਤ ਨੂਰਾਨੀ, ਸਾਡਾ ਦਿਲ ਹੈ ਸੁਨਹਿਰਾ\nਪਰਦੇ ਦੇ ਪਿੱਛੇ ਕੀ ਐ, ਕਿਸ ਨੂੰ ਪਤਾ";
      final transliterated = IndicTransliteration.transliterateLyrics(punjabiText);
      expect(IndicTransliteration.containsIndic(transliterated), isFalse);
      expect(transliterated.contains('ਸ'), isFalse);
      expect(transliterated.contains('ਹ'), isFalse);
      expect(transliterated.contains('ਕ'), isFalse);
      expect(transliterated.contains('ਚ'), isFalse);
      expect(transliterated, contains('kachee kalee, saadaa maasoom chiharaa'));
      expect(transliterated, contains('neeat nooraanee, saadaa dil hai sunahiraa'));
    });

    test('Transliterates Hindi lyrics cleanly', () {
      const hindiText = "तूने पर्दा उठाया, क्या बात हो गई";
      final transliterated = IndicTransliteration.transliterateLyrics(hindiText);
      expect(IndicTransliteration.containsIndic(transliterated), isFalse);
      expect(transliterated, contains('toone pardaa uthaayaa, kyaa baat ho gaee'));
    });
  });

  group('SponsorBlock Tests', () {
    test('Parses intro and sponsor segments correctly', () {
      final json = {
        'category': 'intro',
        'segment': [0.0, 4.5],
        'UUID': 'uuid-123'
      };
      final seg = SponsorSegment.fromJson(json);
      expect(seg.category, equals('intro'));
      expect(seg.start, equals(0.0));
      expect(seg.end, equals(4.5));
      expect(seg.uuid, equals('uuid-123'));
    });

    test('Computes exact intro watermark offset compensation for synced lyrics (e.g. 3.69s)', () {
      final segments = [
        SponsorSegment(category: 'intro', start: 0.0, end: 3.69, uuid: 'u1'),
        SponsorSegment(category: 'sponsor', start: 60.0, end: 75.0, uuid: 'u2'),
      ];

      double totalIntroSec = 0.0;
      for (final seg in segments) {
        if (seg.category == 'intro' && seg.start <= 1.5) {
          totalIntroSec += (seg.end - seg.start);
        }
      }

      final offset = Duration(milliseconds: (totalIntroSec * 1000).round());
      expect(offset.inMilliseconds, equals(3690));

      const rawLyricMs = 1950; // 00:01.95
      final compensatedLyricMs = rawLyricMs + offset.inMilliseconds;
      expect(compensatedLyricMs, equals(5640)); // Exactly 5.64s
    });
  });

  group('Synced Lyrics Cleaner Tests', () {
    test('Cleans movie and official video tags from track title', () {
      expect(
        SyncedLyricsService.cleanTrackTitle('Shararat (From "Dhurandhar") [Official Music Video]'),
        equals('Shararat'),
      );
      expect(
        SyncedLyricsService.cleanTrackTitle('Chaleya | Jawan | Shah Rukh Khan | Nayanthara'),
        equals('Chaleya'),
      );
    });

    test('Cleans artist name topic and featured tags', () {
      expect(
        SyncedLyricsService.cleanArtistName('Shashwat Sachdev - Topic'),
        equals('Shashwat Sachdev'),
      );
      expect(
        SyncedLyricsService.cleanArtistName('Arijit Singh, Shilpa Rao'),
        equals('Arijit Singh'),
      );
    });
  });
}
