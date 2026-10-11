import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A professional audio wave progress bar.
/// Features a sleek baseline track and a smooth, continuous flowing audio wave
/// strictly rendered above the active/played portion of the track.
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
    this.barHeight = 36.0,
  });

  @override
  State<DynamicWaveformProgressBar> createState() =>
      _DynamicWaveformProgressBarState();
}

class _DynamicWaveformProgressBarState
    extends State<DynamicWaveformProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveAnimCtrl;
  bool _isDragging = false;
  double _dragFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveAnimCtrl.dispose();
    super.dispose();
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
    final int targetMs = (widget.total.inMilliseconds * fraction).round();
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
          // Current Time
          SizedBox(
            width: 44,
            child: Text(
              _formatDuration(displayCurrent),
              textAlign: TextAlign.start,
              style: widget.timeLabelTextStyle,
            ),
          ),
          const SizedBox(width: 6),

          // Interactive Track & Wave
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
                  child: AnimatedBuilder(
                    animation: _waveAnimCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(width, widget.barHeight),
                        painter: _ProfessionalWavePainter(
                          progressFraction: progressFraction,
                          bufferedFraction: bufferedFraction,
                          animationPhase: _waveAnimCtrl.value * 2 * math.pi,
                          activeColor: widget.activeColor,
                          inactiveColor: widget.inactiveColor,
                          bufferedColor: widget.bufferedColor,
                          thumbColor: widget.thumbColor ?? widget.activeColor,
                          isDragging: _isDragging,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 6),
          // Total Time
          SizedBox(
            width: 44,
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

class _ProfessionalWavePainter extends CustomPainter {
  final double progressFraction;
  final double bufferedFraction;
  final double animationPhase;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferedColor;
  final Color thumbColor;
  final bool isDragging;

  _ProfessionalWavePainter({
    required this.progressFraction,
    required this.bufferedFraction,
    required this.animationPhase,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.thumbColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final double baselineY = size.height * 0.72;
    final double trackHeight = 4.0;
    final double totalWidth = size.width;
    final double activeWidth = (totalWidth * progressFraction).clamp(0.0, totalWidth);
    final double bufferedWidth = (totalWidth * bufferedFraction).clamp(0.0, totalWidth);

    // 1. Inactive Baseline Track (Full Width)
    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
    final RRect inactiveTrack = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, baselineY - trackHeight / 2, totalWidth, trackHeight),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(inactiveTrack, inactivePaint);

    // 2. Buffered Baseline Track (Up to buffered position)
    if (bufferedWidth > 0) {
      final Paint bufferedPaint = Paint()
        ..color = bufferedColor
        ..style = PaintingStyle.fill;
      final RRect bufferedTrack = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, baselineY - trackHeight / 2, bufferedWidth, trackHeight),
        Radius.circular(trackHeight / 2),
      );
      canvas.drawRRect(bufferedTrack, bufferedPaint);
    }

    // 3. Smooth Moving Audio Wave Above The Line (ONLY up to active playing position)
    if (activeWidth > 6.0) {
      final double maxAmplitude = (size.height * 0.44).clamp(8.0, 16.0);
      final double waveW = activeWidth;

      // Primary Flowing Wave Path
      final Path wavePath = Path();
      final Path backWavePath = Path();
      final Path fillPath = Path();

      const int samplePoints = 56;
      for (int i = 0; i <= samplePoints; i++) {
        final double t = i / samplePoints;
        final double x = t * waveW;

        // Envelope smooth window (0 at start and end)
        final double envelope = math.sin(t * math.pi);

        // Integer phase multipliers ensure 100% mathematically seamless infinite looping!
        final double wave1 = math.sin((t * 4.0 * math.pi) - animationPhase);
        final double wave2 = math.sin((t * 8.0 * math.pi) + (animationPhase * 2.0));

        // Full up-and-down oscillation around buoyant wave center
        final double displacement = wave1 * 0.70 + wave2 * 0.30;
        final double waveLift = maxAmplitude * 0.55 * envelope;
        final double y = baselineY - waveLift - (maxAmplitude * 0.45 * envelope * displacement);

        // Secondary subtle counter-wave for rich depth
        final double backDisplacement = math.sin((t * 4.0 * math.pi) + animationPhase);
        final double backY = baselineY - waveLift - (maxAmplitude * 0.35 * envelope * backDisplacement);

        if (i == 0) {
          wavePath.moveTo(x, baselineY);
          backWavePath.moveTo(x, baselineY);
          fillPath.moveTo(x, baselineY);
        } else {
          wavePath.lineTo(x, y);
          backWavePath.lineTo(x, backY);
          fillPath.lineTo(x, y);
        }
      }

      fillPath.lineTo(activeWidth, baselineY);
      fillPath.close();

      // Soft glow fill between wave and baseline
      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            activeColor.withOpacity(0.25),
            activeColor.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, baselineY - maxAmplitude * 1.1, activeWidth, maxAmplitude * 1.1))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Secondary depth wave stroke
      final Paint backWaveStroke = Paint()
        ..color = activeColor.withOpacity(0.35)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(backWavePath, backWaveStroke);

      // Primary crisp glowing wave crest line
      final Paint waveStroke = Paint()
        ..color = activeColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(wavePath, waveStroke);
    }

    // 4. Active Baseline Track (Up to current position)
    if (activeWidth > 0) {
      final Paint activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      final RRect activeTrack = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, baselineY - trackHeight / 2, activeWidth, trackHeight),
        Radius.circular(trackHeight / 2),
      );
      canvas.drawRRect(activeTrack, activePaint);
    }

    // 5. Thumb & Playhead Glow Indicator (Directly at current playing position)
    final double thumbRadius = isDragging ? 7.0 : 5.5;

    // Glowing halo behind thumb
    final Paint glowPaint = Paint()
      ..color = activeColor.withOpacity(isDragging ? 0.40 : 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(activeWidth, baselineY), thumbRadius + 5.0, glowPaint);

    // Solid Thumb Cap
    final Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(activeWidth, baselineY), thumbRadius, thumbPaint);

    // Inner bright pip
    final Paint innerPip = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(activeWidth, baselineY), thumbRadius * 0.45, innerPip);
  }

  @override
  bool shouldRepaint(covariant _ProfessionalWavePainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.bufferedFraction != bufferedFraction ||
        oldDelegate.animationPhase != animationPhase ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.bufferedColor != bufferedColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.isDragging != isDragging;
  }
}
