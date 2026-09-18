import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';

/// Clean, beautiful Lyric UI without karaoke sweep flickering.
/// Active synced line is highlighted in vibrant gold (#FFD54F),
/// while inactive lines are clear white with opacity.
class HarmonyLyricUI extends LyricUI {
  final double defaultSize;
  final double otherMainSize;
  final double lineGap;
  final double inlineGap;

  HarmonyLyricUI({
    this.defaultSize = 19,
    this.otherMainSize = 15,
    this.lineGap = 22,
    this.inlineGap = 16,
  });

  @override
  TextStyle getPlayingMainTextStyle() => TextStyle(
        color: const Color(0xFFFFD54F), // Elegant gold/yellow for active playing line
        fontSize: defaultSize,
        fontWeight: FontWeight.bold,
        height: 1.5,
      );

  @override
  TextStyle getPlayingExtTextStyle() => TextStyle(
        color: const Color(0xFFFFE082),
        fontSize: otherMainSize,
        fontWeight: FontWeight.w500,
      );

  @override
  TextStyle getOtherMainTextStyle() => TextStyle(
        color: Colors.white.withOpacity(0.55),
        fontSize: otherMainSize,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
        color: Colors.white38,
        fontSize: otherMainSize,
      );

  @override
  double getInlineSpace() => inlineGap;

  @override
  double getLineSpace() => lineGap;

  @override
  double getPlayingLineBias() => 0.5;

  @override
  LyricAlign getLyricHorizontalAlign() => LyricAlign.CENTER;

  @override
  LyricBaseLine getBiasBaseLine() => LyricBaseLine.CENTER;

  @override
  bool enableHighlight() => false; // NO flickering or progressive wipe across letters!

  @override
  bool enableLineAnimation() => true; // Smooth auto-scrolling to active line
}
