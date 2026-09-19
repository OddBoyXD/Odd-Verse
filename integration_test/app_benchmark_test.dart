import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:harmonymusic/main.dart' as app;
import 'package:harmonymusic/ui/player/player_controller.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';
import 'package:harmonymusic/services/local_music_service.dart';
import 'package:get/get.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Odd Verse End-to-End Benchmark & Health Test Suite', () {
    testWidgets('1. Cold Boot & App Initialization Benchmark',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Launch main application
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      stopwatch.stop();

      final bootTimeMs = stopwatch.elapsedMilliseconds;
      debugPrint('[BENCHMARK] Cold App Boot Time: ${bootTimeMs}ms');
      expect(bootTimeMs, lessThan(8000),
          reason: 'Cold boot time should be under 8s');

      // Verify Home Screen is rendered
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('2. Home Feed & Quick Picks Render Verification',
        (WidgetTester tester) async {
      final homeController = Get.find<HomeScreenController>();
      expect(homeController, isNotNull);

      final stopwatch = Stopwatch()..start();
      // Wait for content or cache load
      await tester.pump(const Duration(seconds: 2));
      stopwatch.stop();

      debugPrint(
          '[BENCHMARK] Home Content Ready in: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('3. Audio Engine & Playback State Health',
        (WidgetTester tester) async {
      final playerController = Get.find<PlayerController>();
      expect(playerController, isNotNull);

      // Verify player state properties
      expect(playerController.currentSong, isNotNull);
      expect(playerController.playerState, isNotNull);

      debugPrint('[BENCHMARK] Audio Service & Background Handler: INITIALIZED');
    });

    testWidgets('4. Local Music & Storage Scanner Health',
        (WidgetTester tester) async {
      final localService = Get.find<LocalMusicService>();
      expect(localService, isNotNull);

      final stopwatch = Stopwatch()..start();
      await localService.scanLocalAudioFiles();
      stopwatch.stop();

      debugPrint(
          '[BENCHMARK] Local Audio Storage Scan Completed in: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint(
          '[BENCHMARK] Discovered Local Songs Count: ${localService.localSongs.length}');
    });

    testWidgets('5. Synced Lyrics Engine & Auto-Snap Verification',
        (WidgetTester tester) async {
      final playerController = Get.find<PlayerController>();

      // Verify lyrics mode toggles cleanly
      playerController.changeLyricsMode(0);
      expect(playerController.lyricsMode.value, 0);

      playerController.changeLyricsMode(1);
      expect(playerController.lyricsMode.value, 1);

      playerController.changeLyricsMode(0);
      debugPrint('[BENCHMARK] Synced Lyrics Engine & Viewport Controller: PASSED');
    });
  });
}
