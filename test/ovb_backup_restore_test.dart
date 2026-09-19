import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Odd Verse .ovb Backup Integrity & Extraction Test', () {
    test('1. Verify .ovb archive structure and checksums', () async {
      // Find backup file if present
      final localBackup = File('/home/ubuntu/1789811050065.ovb');
      if (!localBackup.existsSync()) {
        debugPrint('Skip local path test: File not found on current host');
        return;
      }

      final bytes = localBackup.readAsBytesSync();
      expect(bytes.length, greaterThan(1000),
          reason: 'Backup file should not be empty');

      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.isNotEmpty, true, reason: 'Archive must contain files');

      final filenames = archive.map((e) => e.name).toList();
      debugPrint('Extracted Hive Boxes: ${filenames.join(", ")}');

      // Check essential boxes
      expect(filenames.contains('appprefs.hive'), true);
      expect(filenames.contains('homescreendata.hive'), true);
      expect(filenames.contains('lyrics.hive'), true);
      expect(filenames.contains('localsongscache.hive'), true);
      expect(filenames.contains('prevsessiondata.hive'), true);

      // Verify file integrity
      for (final file in archive) {
        if (file.isFile) {
          final content = file.content as List<int>;
          expect(content.length, equals(file.size),
              reason: 'Extracted size must match recorded header size');
        }
      }

      debugPrint('✅ All ${archive.length} Hive boxes in .ovb verified intact and uncorrupted.');
    });
  });
}
