import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A dynamic audio waveform progress bar with interactive seek gesture support,
/// live time labels, and song-specific wave silhouettes.
class DynamicWaveformProgressBar extends StatefulWidget {
  final Duration progress;
  final Duration total;
  final Duration? buffered;
  final ValueChanged<Duration> onSeek;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferedColor;
  final Color? thumbColor;
  final String seedKey;
  final TextStyle? timeLabelTextStyle;
  final double barHeight;

  const DynamicWaveformProgressBar({
    super.key,
    required this.progress,
    required this.total,
    this.buffered,
    required this.onSeek,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    this.thumbColor,
    required this.seedKey,
    this.timeLabelTextStyle,
    this.barHeight = 32.0,
  });

  @override
  State<DynamicWaveformProgressBar> createState() =>
      _DynamicWaveformProgressBarState();
}

class _DynamicWaveformProgressBarState
    extends State<DynamicWaveformProgressBar> {
  bool _isDragging = false;
  double _dragFraction = 0.0;
  List<double> _cachedHeights = const [];
  String _cachedSeedKey = "";

  @override
  void initState() {
    super.initState();
    _updateWaveform();
  }

  @override
  void didUpdateWidget(covariant DynamicWaveformProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedKey != widget.seedKey || _cachedHeights.isEmpty) {
      _updateWaveform();
    }
  }

  void _updateWaveform() {
    _cachedSeedKey = widget.seedKey;
    _cachedHeights = _generateWaveform(widget.seedKey, 42);
  }

  /// Generates a deterministic sound wave silhouette based on a seed key (e.g. song ID).
  List<double> _generateWaveform(String seed, int count) {
    final int hash = seed.hashCode;
    final List<double> heights = [];
    for (int i = 0; i < count; i++) {
      final double x = i / count;
      final double sine1 = math.sin(x * math.pi); // natural arch
      final double sine2 = math.sin(x * math.pi * 3.5);
      final double sine3 = math.cos(x * math.pi * 7.0);

      // Pseudo-random deterministic noise
      final int n = (hash ^ (i * 397)) & 0x7FFFFFFF;
      final double pseudo = (n % 1000) / 1000.0;

      double h = 0.22 +
          0.38 * sine1.abs() +
          0.18 * (sine2 * 0.5 + 0.5) +
          0.10 * (sine3 * 0.5 + 0.5) +
          0.18 * pseudo;

      heights.add(h.clamp(0.18, 1.0));
    }
    return heights;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "0:00";
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _handleSeek(double localDx, double totalWidth) {
    if (totalWidth <= 0 || widget.total <= Duration.zero) return;
    final double fraction = (localDx / totalWidth).clamp(0.0, 1.0);
    final targetMs = (widget.total.inMilliseconds * fraction).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final double totalMs = widget.total.inMilliseconds.toDouble();
    final double currentMs = _isDragging
        ? (totalMs * _dragFraction)
        : widget.progress.inMilliseconds.toDouble();

    final double progressFraction =
        totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    final double bufferedFraction = totalMs > 0 && widget.buffered != null
        ? (widget.buffered!.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    final Duration displayCurrent = _isDragging
        ? Duration(milliseconds: (totalMs * _dragFraction).round())
        : widget.progress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Time Label
          SizedBox(
            width: 42,
            child: Text(
              _formatDuration(displayCurrent),
              textAlign: TextAlign.start,
              style: widget.timeLabelTextStyle,
            ),
          ),
          const SizedBox(width: 6),

          // Waveform Canvas with interactive drag & tap
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragFraction = (details.localPosition.dx / width)
                          .clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragFraction = (details.localPosition.dx / width)
                          .clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    _handleSeek(details.localPosition.dx, width);
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  onHorizontalDragCancel: () {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  onTapDown: (details) {
                    _handleSeek(details.localPosition.dx, width);
                  },
                  child: SizedBox(
                    height: widget.barHeight + 10,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        heights: _cachedHeights,
                        progressFraction: progressFraction,
                        bufferedFraction: bufferedFraction,
                        activeColor: widget.activeColor,
                        inactiveColor: widget.inactiveColor,
                        bufferedColor: widget.bufferedColor,
                        thumbColor: widget.thumbColor ?? widget.activeColor,
                        isDragging: _isDragging,
                      ),
                      size: Size(width, widget.barHeight + 10),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 6),
          // Total Time Label
          SizedBox(
            width: 42,
            child: Text(
              _formatDuration(widget.total),
              textAlign: TextAlign.end,
              style: widget.timeLabelTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> heights;
  final double progressFraction;
  final double bufferedFraction;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferedColor;
  final Color thumbColor;
  final bool isDragging;

  _WaveformPainter({
    required this.heights,
    required this.progressFraction,
    required this.bufferedFraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.thumbColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty || size.width <= 0) return;

    final int count = heights.length;
    final double spacing = 2.4;
    final double availableWidthForBars = size.width - (spacing * (count - 1));
    final double barWidth = (availableWidthForBars / count).clamp(1.5, 6.0);
    final double totalW = (count * barWidth) + ((count - 1) * spacing);
    final double startX = (size.width - totalW) / 2.0;
    final double maxH = size.height - 8.0;

    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final Paint bufferedPaint = Paint()
      ..color = bufferedColor
      ..style = PaintingStyle.fill;

    double playheadX = startX;

    for (int i = 0; i < count; i++) {
      final double x = startX + i * (barWidth + spacing);
      final double h = (heights[i] * maxH).clamp(4.0, maxH);
      final double y = (size.height - h) / 2.0;

      final double barCenterFraction = (x + barWidth / 2.0 - startX) / totalW;

      Paint paintToUse;
      if (barCenterFraction <= progressFraction) {
        paintToUse = activePaint;
        playheadX = x + barWidth;
      } else if (barCenterFraction <= bufferedFraction) {
        paintToUse = bufferedPaint;
      } else {
        paintToUse = inactivePaint;
      }

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        Radius.circular(barWidth / 2.0),
      );

      canvas.drawRRect(rrect, paintToUse);
    }

    // Playhead indicator
    final double targetX = (startX + (totalW * progressFraction)).clamp(startX, startX + totalW);
    final double playheadRadius = isDragging ? 5.5 : 4.0;

    // Subtle glow behind the playhead
    final Paint glowPaint = Paint()
      ..color = activeColor.withOpacity(isDragging ? 0.45 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(targetX, size.height / 2.0), playheadRadius + 3.0, glowPaint);

    // Playhead thumb dot
    final Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(targetX, size.height / 2.0), playheadRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.bufferedFraction != bufferedFraction ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.bufferedColor != bufferedColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.heights != heights;
  }
}
