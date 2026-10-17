import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/models/lyrics_source_model.dart';
import 'package:harmonymusic/services/synced_lyrics_service.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:harmonymusic/ui/widgets/snackbar.dart';
import 'package:harmonymusic/utils/indic_transliteration.dart';
import 'lyrics_sources_sheet.dart';

import '../../widgets/loader.dart';
import '../player_controller.dart';

class LyricWord {
  final Duration time;
  final String text;
  LyricWord({required this.time, required this.text});
}

class LyricLine {
  final Duration time;
  final Duration endTime;
  final String text;
  final List<LyricWord> words;
  final bool isInstrumental;

  LyricLine({
    required this.time,
    required this.text,
    Duration? endTime,
    this.words = const [],
    this.isInstrumental = false,
  }) : endTime = endTime ?? time;
}

class _RawParsedLine {
  final Duration time;
  final String text;
  final List<LyricWord> words;
  _RawParsedLine({required this.time, required this.text, required this.words});
}

class _LyricsCache {
  static String lastSyncedLrc = '';
  static bool lastRomanize = false;
  static Duration lastOffset = Duration.zero;
  static Duration? lastTotalDuration;
  static List<LyricLine> cachedList = [];

  static List<LyricLine> getOrParse(
    String lrc,
    bool isRomanize,
    Duration sponsorOffset, {
    Duration? totalDuration,
    required List<LyricLine> Function(String, bool, Duration, {Duration? totalDuration}) parseFn,
  }) {
    if (lrc == lastSyncedLrc &&
        isRomanize == lastRomanize &&
        sponsorOffset == lastOffset &&
        totalDuration == lastTotalDuration &&
        cachedList.isNotEmpty) {
      return cachedList;
    }
    lastSyncedLrc = lrc;
    lastRomanize = isRomanize;
    lastOffset = sponsorOffset;
    lastTotalDuration = totalDuration;
    cachedList = parseFn(lrc, isRomanize, sponsorOffset, totalDuration: totalDuration);
    return cachedList;
  }
}

class LyricsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const LyricsWidget({super.key, required this.padding});

  List<LyricLine> _parseLrc(
      String lrc, bool isRomanize, Duration sponsorOffset,
      {Duration? totalDuration}) {
    if (lrc.trim().isEmpty) return [];
    final lines = lrc.split('\n');
    final parsed = <_RawParsedLine>[];
    final lineRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    final wordRegex = RegExp(r'<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*)');

    for (final line in lines) {
      final match = lineRegex.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        var duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
        if (sponsorOffset != Duration.zero) {
          duration += sponsorOffset;
        }
        var rawContent = match.group(4) ?? '';
        final words = <LyricWord>[];

        if (rawContent.contains('<') && rawContent.contains('>')) {
          final wordMatches = wordRegex.allMatches(rawContent);
          for (final wm in wordMatches) {
            final wMin = int.parse(wm.group(1)!);
            final wSec = int.parse(wm.group(2)!);
            final wMsStr = wm.group(3)!;
            final wMs = int.parse(wMsStr.padRight(3, '0').substring(0, 3));
            var wDuration =
                Duration(minutes: wMin, seconds: wSec, milliseconds: wMs);
            if (sponsorOffset != Duration.zero) {
              wDuration += sponsorOffset;
            }
            var wText = wm.group(4) ?? '';
            if (wText.isNotEmpty) {
              if (isRomanize && wText.trim().isNotEmpty) {
                final hasTrailingSpace = wText.endsWith(' ');
                wText = IndicTransliteration.transliterateLine(wText.trim()) +
                    (hasTrailingSpace ? ' ' : '');
              }
              words.add(LyricWord(time: wDuration, text: wText));
            }
          }
          // Strip word tags for clean line fallback
          rawContent = rawContent.replaceAll(RegExp(r'<.*?>'), '').trim();
          if (isRomanize && rawContent.isNotEmpty) {
            rawContent = words.isNotEmpty
                ? words.map((w) => w.text).join().trim()
                : IndicTransliteration.transliterateLine(rawContent);
          }
        } else {
          rawContent = rawContent.trim();
          if (isRomanize && rawContent.isNotEmpty) {
            rawContent = IndicTransliteration.transliterateLine(rawContent);
          }
        }

        if (rawContent.isNotEmpty) {
          parsed.add(_RawParsedLine(time: duration, text: rawContent, words: words));
        }
      }
    }
    parsed.sort((a, b) => a.time.compareTo(b.time));
    if (parsed.isEmpty) return [];

    final result = <LyricLine>[];

    // 1. Intro Instrumental Break
    if (parsed.first.time >= const Duration(milliseconds: 4500)) {
      result.add(
        LyricLine(
          time: Duration.zero,
          endTime: parsed.first.time,
          text: "♪",
          isInstrumental: true,
        ),
      );
    }

    // 2. Synthesize word progression for line-synced lyrics & detect interlude gaps
    for (int i = 0; i < parsed.length; i++) {
      final current = parsed[i];
      Duration nextTime;
      if (i + 1 < parsed.length) {
        nextTime = parsed[i + 1].time;
      } else if (totalDuration != null && totalDuration > current.time) {
        nextTime = totalDuration;
      } else {
        nextTime = current.time + const Duration(seconds: 4);
      }

      final lineGap = nextTime - current.time;
      List<LyricWord> words;
      Duration lineEndTime;

      if (current.words.isNotEmpty) {
        words = current.words;
        lineEndTime = words.last.time + const Duration(milliseconds: 700);
      } else {
        final tokens = current.text.split(' ');
        final estDurationMs = (tokens.length * 420).clamp(1800, 5500);
        final vocalDurationMs = lineGap.inMilliseconds < estDurationMs
            ? lineGap.inMilliseconds
            : estDurationMs;
        lineEndTime = current.time + Duration(milliseconds: vocalDurationMs);

        words = <LyricWord>[];
        int currentMs = current.time.inMilliseconds;
        final totalChars = current.text.length;
        for (int w = 0; w < tokens.length; w++) {
          final token = tokens[w];
          if (token.isEmpty) continue;
          final suffix = (w < tokens.length - 1) ? ' ' : '';
          words.add(LyricWord(
            time: Duration(milliseconds: currentMs),
            text: '$token$suffix',
          ));
          final wordShareMs = totalChars > 0
              ? (vocalDurationMs * (token.length / totalChars)).round()
              : (vocalDurationMs ~/ tokens.length);
          currentMs += wordShareMs.clamp(100, 2000);
        }
      }

      final cleanText = (isRomanize && words.isNotEmpty)
          ? words.map((w) => w.text).join().trim()
          : current.text;

      result.add(
        LyricLine(
          time: current.time,
          endTime: lineEndTime,
          text: cleanText.isNotEmpty ? cleanText : current.text,
          words: words,
          isInstrumental: false,
        ),
      );

      // 3. Interlude Instrumental Break
      if (i + 1 < parsed.length) {
        final nextStart = parsed[i + 1].time;
        final gapMs = (nextStart - lineEndTime).inMilliseconds;
        if (gapMs >= 5000) {
          result.add(
            LyricLine(
              time: lineEndTime,
              endTime: nextStart,
              text: "♪",
              isInstrumental: true,
            ),
          );
        }
      }
    }

    // 4. Outro Instrumental Break
    if (totalDuration != null && result.isNotEmpty) {
      final lastEndTime = result.last.endTime;
      final outroGapMs = (totalDuration - lastEndTime).inMilliseconds;
      if (outroGapMs >= 6000) {
        result.add(
          LyricLine(
            time: lastEndTime,
            endTime: totalDuration,
            text: "♪",
            isInstrumental: true,
          ),
        );
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final settingsController = Get.find<SettingsScreenController>();

    return Obx(() {
      IndicTransliteration.cacheVersion.value;
      if (playerController.isLyricsLoading.isTrue) {
        return const Center(
          child: LoadingIndicator(),
        );
      }

      final isRomanize = settingsController.romanizeLyricsEnabled.value;
      final rawProvider =
          playerController.lyrics["provider"]?.toString() ?? "";

      // Alignment Priority Rule:
      // 1. If lyrics were already aligned with YouTube video vocal subtitles (or provider is direct youtube_captions),
      //    their timestamps are already 100% bound to the YouTube video clock. No extra sponsor offset is needed.
      // 2. If YouTube captions were unavailable (captionAligned is false), sponsorIntroOffset serves as an intelligent
      //    fallback offset to account for intro delays.
      final isCaptionAligned = rawProvider == "youtube_captions" ||
          playerController.lyrics["captionAligned"] == true;
      final effectiveOffset = !isCaptionAligned
          ? playerController.sponsorIntroOffset.value
          : Duration.zero;

      final rawPlain =
          playerController.lyrics["plainLyrics"]?.toString().trim() ?? "";
      final displayPlain =
          (rawPlain.isNotEmpty && rawPlain != "NA" && isRomanize)
              ? IndicTransliteration.transliterateLyrics(rawPlain)
              : rawPlain;

      final rawSynced =
          playerController.lyrics['synced']?.toString().trim() ?? '';
      if (rawSynced.isNotEmpty) {
        IndicTransliteration.prefetchRomanization(rawSynced);
      } else if (rawPlain.isNotEmpty) {
        IndicTransliteration.prefetchRomanization(rawPlain);
      }
      final totalDuration = playerController.currentSong.value?.duration;
      final parsedSynced = _LyricsCache.getOrParse(
        rawSynced,
        isRomanize,
        effectiveOffset,
        totalDuration: totalDuration,
        parseFn: _parseLrc,
      );

      // Automatic Fallback Hierarchy:
      // 1. Synced lyrics (word-by-word or line-by-line)
      if (parsedSynced.isNotEmpty) {
        return YtmSyncedLyricsView(
          lyrics: parsedSynced,
          playerController: playerController,
          padding: padding,
        );
      }

      // 2. Plain lyrics fallback (rendered in same 20pt bold style as synced lyrics)
      if (displayPlain.isNotEmpty && displayPlain != "NA") {
        return LayoutBuilder(
          builder: (context, constraints) {
            final verticalPad = constraints.maxHeight / 3;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: verticalPad > 40.0 ? verticalPad : 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextSelectionTheme(
                    data: Theme.of(context).textSelectionTheme,
                    child: SelectableText(
                      displayPlain,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    onPressed: () =>
                        showLyricsSearchSheet(context, playerController),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      "Wrong lyrics? Search Providers",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      // 3. Fallback: Neither synced nor plain lyrics available
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_note_outlined,
              color: Colors.white54,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              "lyricsNotAvailable".tr,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD54F),
              ),
              onPressed: () => showLyricsSearchSheet(context, playerController),
              icon: const Icon(Icons.search, size: 18),
              label: const Text("Search Lyrics Providers"),
            ),
          ],
        ),
      );
    });
  }
}

class _InstrumentalLineWidget extends StatelessWidget {
  final bool isActive;
  final LyricLine line;
  final ValueNotifier<Duration> animatedPosition;

  const _InstrumentalLineWidget({
    required this.isActive,
    required this.line,
    required this.animatedPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, color: Colors.white.withOpacity(0.25), size: 18),
          const SizedBox(width: 8),
          Text(
            "•  •  •",
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(
      child: ValueListenableBuilder<Duration>(
        valueListenable: animatedPosition,
        builder: (context, pos, _) {
        final totalSpanMs = (line.endTime - line.time).inMilliseconds;
        final elapsedMs = (pos - line.time).inMilliseconds;
        final through = totalSpanMs > 0
            ? (elapsedMs / totalSpanMs).clamp(0.0, 1.0)
            : 1.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 22,
              shadows: [
                Shadow(
                  color: Color(0x99FFFFFF),
                  blurRadius: 14.0,
                ),
                Shadow(
                  color: Color(0x44FFFFFF),
                  blurRadius: 24.0,
                ),
              ],
            ),
            const SizedBox(width: 12),
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Builder(
                builder: (context) {
                  final dotProgress = (through * 3.0 - i).clamp(0.0, 1.0);
                  final isLit = dotProgress >= 1.0;
                  final isFilling = dotProgress > 0.0 && dotProgress < 1.0;

                  return Container(
                    width: isFilling ? 10 : 8,
                    height: isFilling ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLit
                          ? Colors.white
                          : isFilling
                              ? Color.lerp(
                                  Colors.white38,
                                  Colors.white,
                                  dotProgress,
                                )
                              : Colors.white.withOpacity(0.25),
                      boxShadow: (isLit || isFilling)
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                    isLit ? 0.8 : 0.4 * dotProgress),
                                blurRadius: isLit ? 10.0 : 6.0,
                                spreadRadius: isLit ? 2.0 : 1.0,
                              ),
                            ]
                          : const [],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    ),
  );
  }
}

class _SweptLyricLineWidget extends StatelessWidget {
  final LyricLine line;
  final ValueNotifier<Duration> animatedPosition;
  final TextStyle activeStyle;
  final bool isActive;

  const _SweptLyricLineWidget({
    required this.line,
    required this.animatedPosition,
    required this.activeStyle,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<Duration>(
        valueListenable: animatedPosition,
        builder: (context, pos, _) {
          return Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: List.generate(line.words.length, (k) {
              final w = line.words[k];
              Duration wEndTime;
              if (k + 1 < line.words.length) {
                wEndTime = line.words[k + 1].time;
              } else {
                wEndTime = line.endTime;
              }

              final wDurationMs = (wEndTime - w.time).inMilliseconds;
              double progress = 0.0;
              if (pos >= wEndTime) {
                progress = 1.0;
              } else if (pos < w.time) {
                progress = 0.0;
              } else if (wDurationMs > 0) {
                progress =
                    ((pos - w.time).inMilliseconds / wDurationMs).clamp(0.0, 1.0);
              } else {
                progress = 1.0;
              }

              // Unsung: dimmed text
              if (progress <= 0.0) {
                return Text(
                  w.text,
                  style: activeStyle.copyWith(
                    color: Colors.white.withOpacity(0.40),
                    shadows: const [],
                  ),
                );
              }

              // Fully sung: radiant white text
              if (progress >= 1.0) {
                return Text(
                  w.text,
                  style: activeStyle.copyWith(
                    color: Colors.white,
                    shadows: const [],
                  ),
                );
              }

              // Currently singing: smooth letter-by-letter gradient sweep
              return ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [
                      progress,
                      (progress + 0.05).clamp(0.0, 1.0),
                    ],
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.40),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  w.text,
                  style: activeStyle.copyWith(
                    color: Colors.white,
                    shadows: const [],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class YtmSyncedLyricsView extends StatefulWidget {
  final List<LyricLine> lyrics;
  final PlayerController playerController;
  final EdgeInsetsGeometry padding;

  const YtmSyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.playerController,
    required this.padding,
  });

  @override
  State<YtmSyncedLyricsView> createState() => _YtmSyncedLyricsViewState();
}

class _YtmSyncedLyricsViewState extends State<YtmSyncedLyricsView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [];
  int _lastActiveIndex = -1;
  bool _userInteracting = false;
  bool _isPointerDown = false;
  Timer? _resumeTimer;
  Ticker? _ticker;
  Duration _lastReportedPosition = Duration.zero;
  DateTime _lastReportedTime = DateTime.now();
  late final ValueNotifier<Duration> _animatedPosition;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _initKeys();
    final currentPos =
        widget.playerController.progressBarStatus.value.current;
    final isPlaying =
        widget.playerController.buttonState.value == PlayButtonState.playing;
    _lastReportedPosition = currentPos;
    _lastReportedTime = DateTime.now();
    _wasPlaying = isPlaying;
    _animatedPosition = ValueNotifier<Duration>(currentPos);

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      final currentButtonState = widget.playerController.buttonState.value;
      if (currentButtonState != PlayButtonState.playing) {
        if (_wasPlaying) {
          _wasPlaying = false;
        }
        return;
      }

      final currentPos =
          widget.playerController.progressBarStatus.value.current;

      if (!_wasPlaying) {
        _wasPlaying = true;
        _lastReportedPosition = currentPos;
        _lastReportedTime = DateTime.now();
        _animatedPosition.value = currentPos;
        return;
      }

      final now = DateTime.now();
      final delta = now.difference(_lastReportedTime);
      final interpolated = _lastReportedPosition + delta;

      // Keep position strictly monotonic during normal continuous playback
      if (interpolated >= _animatedPosition.value) {
        _animatedPosition.value = interpolated;
      }

      final activeIndex = _findActiveIndex(_animatedPosition.value);
      if (activeIndex != _lastActiveIndex) {
        _lastActiveIndex = activeIndex;
        if (mounted) setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_userInteracting && !_isPointerDown) {
            _scrollToActive(activeIndex);
          }
        });
      }
    });
    _ticker?.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final activeIndex = _findActiveIndex(currentPos);
        if (activeIndex >= 0) {
          _lastActiveIndex = activeIndex;
          _scrollToActive(activeIndex, jump: true);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant YtmSyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lyrics, widget.lyrics)) {
      final isDifferentContent = oldWidget.lyrics.length != widget.lyrics.length ||
          (oldWidget.lyrics.isNotEmpty &&
              widget.lyrics.isNotEmpty &&
              oldWidget.lyrics.first.text != widget.lyrics.first.text);
      if (isDifferentContent) {
        _initKeys();
        _lastActiveIndex = -1;
        _userInteracting = false;
        _resumeTimer?.cancel();
        final curPos = widget.playerController.progressBarStatus.value.current;
        _lastReportedPosition = curPos;
        _lastReportedTime = DateTime.now();
        _animatedPosition.value = curPos;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final activeIndex = _findActiveIndex(curPos);
            if (activeIndex >= 0) {
              _lastActiveIndex = activeIndex;
              _scrollToActive(activeIndex, jump: true);
              setState(() {});
            }
          }
        });
      }
    }
  }

  void _initKeys() {
    _itemKeys.clear();
    for (int i = 0; i < widget.lyrics.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _animatedPosition.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive(int index, {bool jump = false}) {
    if (_userInteracting || _isPointerDown || index < 0 || index >= _itemKeys.length) return;
    if (!_scrollController.hasClients) return;

    final itemContext = _itemKeys[index].currentContext;
    if (itemContext == null) return;

    Scrollable.ensureVisible(
      itemContext,
      alignment: 0.5,
      duration: jump ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _startResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _userInteracting = false;
        _scrollToActive(_lastActiveIndex);
      }
    });
  }

  int _findActiveIndex(Duration currentPosition) {
    int active = -1;
    for (int i = 0; i < widget.lyrics.length; i++) {
      if (currentPosition >= widget.lyrics[i].time) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentPos =
          widget.playerController.progressBarStatus.value.current;
      final isPlaying =
          widget.playerController.buttonState.value == PlayButtonState.playing;

      if (!isPlaying) {
        _wasPlaying = false;
        _lastReportedPosition = currentPos;
        _lastReportedTime = DateTime.now();
        _animatedPosition.value = currentPos;
        final activeIndex = _findActiveIndex(currentPos);
        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userInteracting && !_isPointerDown) {
              _scrollToActive(activeIndex);
            }
          });
        }
      } else {
        if (!_wasPlaying) {
          _wasPlaying = true;
          _lastReportedPosition = currentPos;
          _lastReportedTime = DateTime.now();
          _animatedPosition.value = currentPos;
        } else {
          final diffMs = (currentPos - _animatedPosition.value).inMilliseconds;
          // Reconcile when user seeks (>500ms jump) or when audio stream is ahead
          if (diffMs.abs() > 500) {
            _lastReportedPosition = currentPos;
            _lastReportedTime = DateTime.now();
            _animatedPosition.value = currentPos;
          } else if (currentPos > _animatedPosition.value) {
            _lastReportedPosition = currentPos;
            _lastReportedTime = DateTime.now();
            _animatedPosition.value = currentPos;
          }
        }
      }
      final activeIndex = _findActiveIndex(_animatedPosition.value);

      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final verticalPad = (viewportHeight / 2) - 24.0;
          final scrollPadding = EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: verticalPad > 20.0 ? verticalPad : 40.0,
          );

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) {
                if (notification.direction != ScrollDirection.idle) {
                  _userInteracting = true;
                  _resumeTimer?.cancel();
                } else if (!_isPointerDown) {
                  _startResumeTimer();
                }
              } else if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  _userInteracting = true;
                  _resumeTimer?.cancel();
                }
              } else if (notification is ScrollUpdateNotification) {
                if (notification.dragDetails != null) {
                  _userInteracting = true;
                  _resumeTimer?.cancel();
                }
              } else if (notification is ScrollEndNotification) {
                if (_userInteracting && !_isPointerDown) {
                  _startResumeTimer();
                }
              }
              return false;
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                _isPointerDown = true;
                _userInteracting = true;
                _resumeTimer?.cancel();
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.offset);
                }
              },
              onPointerMove: (_) {
                _isPointerDown = true;
                _userInteracting = true;
                _resumeTimer?.cancel();
              },
              onPointerUp: (_) {
                _isPointerDown = false;
                if (_userInteracting) {
                  _startResumeTimer();
                }
              },
              onPointerCancel: (_) {
                _isPointerDown = false;
                if (_userInteracting) {
                  _startResumeTimer();
                }
              },
              child: SingleChildScrollView(
                key: _viewportKey,
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: scrollPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(widget.lyrics.length, (index) {
                      final line = widget.lyrics[index];
                      final isActive = index == activeIndex;

                      return RepaintBoundary(
                        key: _itemKeys[index],
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: const Color(0x22FFFFFF),
                              highlightColor: const Color(0x11FFFFFF),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.playerController.seek(line.time);
                                _lastReportedPosition = line.time;
                                _lastReportedTime = DateTime.now();
                                _animatedPosition.value = line.time;
                                _lastActiveIndex = index;
                                _userInteracting = false;
                                _resumeTimer?.cancel();
                                if (mounted) setState(() {});
                                _scrollToActive(index);
                              },
                              child: AnimatedScale(
                                scale: isActive ? 1.05 : 0.95,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                child: AnimatedOpacity(
                                  opacity: isActive ? 1.0 : 0.38,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: line.isInstrumental
                                        ? _InstrumentalLineWidget(
                                            isActive: isActive,
                                            line: line,
                                            animatedPosition: _animatedPosition,
                                          )
                                        : (isActive && line.words.isNotEmpty)
                                            ? _SweptLyricLineWidget(
                                                line: line,
                                                animatedPosition:
                                                    _animatedPosition,
                                                isActive: isActive,
                                                activeStyle: const TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                  height: 1.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                line.words.isNotEmpty
                                                    ? line.words
                                                        .map((w) => w.text)
                                                        .join()
                                                    : line.text,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                  height: 1.5,
                                                  color: Colors.white,
                                                  shadows: const [],
                                                ),
                                              ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(top: 28.0, bottom: 20.0),
                      child: Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white54,
                          ),
                          onPressed: () => showLyricsSearchSheet(
                              context, widget.playerController),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text(
                            "Wrong lyrics? Search Providers",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

void showLyricsSearchSheet(
    BuildContext context, PlayerController playerController) {
  final current = playerController.currentSong.value;
  String initArtist = current != null
      ? SyncedLyricsService.cleanArtistName(current.artist)
      : "";

  // If artist was "Song" or empty, try recovering artist from track title
  if (initArtist.isEmpty && current != null) {
    if (current.title.contains(' - ') || current.title.contains(' – ')) {
      final sep = current.title.contains(' – ') ? ' – ' : ' - ';
      final possibleArtist = SyncedLyricsService.cleanArtistName(current.title.split(sep)[0]);
      if (possibleArtist.isNotEmpty) {
        initArtist = possibleArtist;
      }
    } else if (current.title.contains('[') && current.title.contains(']')) {
      final match = RegExp(r'\[(.*?)\]').firstMatch(current.title);
      if (match != null) {
        final possibleArtist = SyncedLyricsService.cleanArtistName(match.group(1)!);
        if (possibleArtist.isNotEmpty) {
          initArtist = possibleArtist;
        }
      }
    }
  }

  final titleController = TextEditingController(
      text: current != null
          ? SyncedLyricsService.cleanTrackTitle(current.title,
              artist: initArtist.isNotEmpty ? initArtist : current.artist)
          : "");
  final artistController = TextEditingController(text: initArtist);

  final allSources = LyricsSourceInfo.loadSavedSources();

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      bool isSearching = false;
      String selectedProviderId = 'all';
      List<Map<String, dynamic>> searchResults = [];

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentLyrics = playerController.lyrics;
          final currentProviderId = currentLyrics['provider']?.toString() ?? '';
          final currentSourceName = currentLyrics['sourceName']?.toString() ?? '';
          LyricsSourceInfo? activeSource;
          try {
            activeSource = allSources.firstWhere(
              (s) =>
                  s.id.toLowerCase() == currentProviderId.toLowerCase() ||
                  s.label.toLowerCase() == currentProviderId.toLowerCase(),
            );
          } catch (_) {}

          final activeLabel = activeSource?.label ??
              (currentSourceName.isNotEmpty
                  ? currentSourceName
                  : (currentProviderId.isNotEmpty ? currentProviderId : "Default / Auto"));
          final isCurrentWordSynced = currentLyrics['wordSynced'] == true ||
              (currentLyrics['synced']?.toString().contains('<') ?? false);

          Future<void> doSearch(String providerId) async {
            setSheetState(() {
              isSearching = true;
              selectedProviderId = providerId;
            });
            final dur =
                playerController.progressBarStatus.value.total.inSeconds;
            final list = await SyncedLyricsService.searchProvider(
              providerId,
              titleController.text.trim(),
              artistController.text.trim(),
              durationSec: dur,
              videoId: current?.id ?? "",
            );
            if (context.mounted) {
              setSheetState(() {
                searchResults = list;
                isSearching = false;
              });
            }
          }

          Future<void> applyLyrics(Map<String, dynamic> item) async {
            final sourceName = item['sourceName'] ?? item['provider'] ?? 'Source';
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }
            await playerController.manualSetLyrics(item);
            playerController.showLyricsflag.value = true;
            Future.delayed(const Duration(milliseconds: 150), () {
              if (playerController.playerPanelController.isAttached) {
                playerController.playerPanelController.open();
              }
            });
            ScaffoldMessenger.of(Get.context!).showSnackBar(
              snackbar(
                Get.context!,
                "Applied lyrics from $sourceName!",
                size: SanckBarSize.MEDIUM,
              ),
            );
          }

          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final systemBottomPadding = MediaQuery.of(context).padding.bottom;
          final effectiveBottomPadding = bottomInset > 0
              ? (bottomInset + 16)
              : (systemBottomPadding + 20);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: effectiveBottomPadding,
                left: 16,
                right: 16,
                top: 12,
              ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Search Lyrics by Provider",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                            Navigator.of(ctx, rootNavigator: true).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  // Current Active Provider Banner
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentWordSynced
                            ? const Color(0x66FFD54F)
                            : const Color(0x22FFFFFF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentWordSynced
                              ? Icons.apple
                              : Icons.music_note,
                          color: isCurrentWordSynced
                              ? const Color(0xFFFFD54F)
                              : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "CURRENT ACTIVE PROVIDER",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      activeLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCurrentWordSynced
                                          ? const Color(0x33FFD54F)
                                          : Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCurrentWordSynced
                                          ? "Apple Word-Synced 🍎"
                                          : "Line-Synced ⏱️",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isCurrentWordSynced
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Provider selection chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text("All Providers"),
                            selected: selectedProviderId == 'all',
                            selectedColor: const Color(0xFFFFD54F),
                            backgroundColor: const Color(0xFF1E1E1E),
                            labelStyle: TextStyle(
                              color: selectedProviderId == 'all'
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected && !isSearching) {
                                doSearch('all');
                              }
                            },
                          ),
                        ),
                        ...allSources.map((source) {
                          final isSel = selectedProviderId == source.id;
                          final labelText =
                              "${source.label}${source.wordSynced ? " 🍎" : ""}";
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(labelText),
                              selected: isSel,
                              selectedColor: const Color(0xFFFFD54F),
                              backgroundColor: const Color(0xFF1E1E1E),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected && !isSearching) {
                                  doSearch(source.id);
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Track Title",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: artistController,
                    decoration: InputDecoration(
                      labelText: "Artist Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSearching
                        ? null
                        : () => doSearch(selectedProviderId),
                    icon: isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(isSearching
                        ? "Searching..."
                        : (selectedProviderId == 'all'
                            ? "Search All Providers"
                            : "Search Selected Provider")),
                  ),
                  const SizedBox(height: 12),
                  if (searchResults.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          final isWord = item['wordSynced'] == true;
                          final sourceName = item['sourceName'] ??
                              item['provider'] ??
                              'Source';
                          final rawTitle = item['title']?.toString().trim() ?? '';
                          final rawArtist = item['artist']?.toString().trim() ?? '';

                          final fallbackTitle = titleController.text.trim().isNotEmpty
                              ? titleController.text.trim()
                              : ((current?.title != null && current!.title.trim().isNotEmpty)
                                  ? SyncedLyricsService.cleanTrackTitle(current!.title, artist: current!.artist)
                                  : '');
                          final fallbackArtist = artistController.text.trim().isNotEmpty
                              ? artistController.text.trim()
                              : ((current?.artist != null && current!.artist!.trim().isNotEmpty)
                                  ? SyncedLyricsService.cleanArtistName(current!.artist)
                                  : '');

                          final isGenericTitle = rawTitle.isEmpty || rawTitle.toLowerCase() == 'song';
                          final displayTitle = isGenericTitle ? fallbackTitle : rawTitle;

                          final isGenericArtist = rawArtist.isEmpty ||
                              rawArtist.toLowerCase() == 'song' ||
                              rawArtist.toLowerCase() == 'unknown' ||
                              rawArtist.toLowerCase() == 'unknown artist';
                          final displayArtist = isGenericArtist ? fallbackArtist : rawArtist;

                          final titleDisplay = displayTitle.isNotEmpty
                              ? (displayArtist.isNotEmpty ? "$displayTitle - $displayArtist" : displayTitle)
                              : sourceName;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWord
                                    ? const Color(0x44FFD54F)
                                    : Colors.white12,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              title: Text(
                                titleDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isWord
                                            ? const Color(0x33FFD54F)
                                            : Colors.white12,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isWord
                                            ? "Apple Word-Synced 🍎"
                                            : "Line-Synced ⏱️",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isWord
                                              ? const Color(0xFFFFD54F)
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sourceName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD54F),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(64, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => applyLyrics(item),
                                child: const Text(
                                  "Apply",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => applyLyrics(item),
                            ),
                          );
                        },
                      ),
                    )
                  else if (!isSearching &&
                      searchResults.isEmpty &&
                      titleController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        selectedProviderId == 'all'
                            ? "Select a provider above or search to fetch lyrics."
                            : "No lyrics found from selected provider. Tap another provider above to try.",
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
}
