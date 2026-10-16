import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/synced_lyrics_service.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:harmonymusic/ui/widgets/snackbar.dart';
import 'package:harmonymusic/utils/indic_transliteration.dart';

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

      result.add(
        LyricLine(
          time: current.time,
          endTime: lineEndTime,
          text: current.text,
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
      final parsedSynced = _parseLrc(rawSynced, isRomanize, effectiveOffset,
          totalDuration: playerController.progressBarStatus.value.total);

      // Mode 1: Plain Lyrics
      if (playerController.lyricsMode.toInt() == 1) {
        if (displayPlain.isEmpty || displayPlain == "NA") {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lyrics_outlined,
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
        }

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: padding,
            child: TextSelectionTheme(
              data: Theme.of(context).textSelectionTheme,
              child: SelectableText(
                displayPlain,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      }

      // Mode 0: Synced Lyrics (YouTube Music style tap-on-line seeking)
      if (parsedSynced.isEmpty) {
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
                "syncedLyricsNotAvailable".tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD54F),
                    ),
                    onPressed: () => showLyricsSearchSheet(context, playerController),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text("Search Providers"),
                  ),
                  if (displayPlain.isNotEmpty && displayPlain != "NA") ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      onPressed: () {
                        playerController.changeLyricsMode(1);
                      },
                      icon: const Icon(Icons.text_snippet_outlined, size: 18),
                      label: Text("plain".tr),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }

      return YtmSyncedLyricsView(
        lyrics: parsedSynced,
        playerController: playerController,
        padding: padding,
      );
    });
  }
}

class _InstrumentalLineWidget extends StatefulWidget {
  final bool isActive;
  const _InstrumentalLineWidget({required this.isActive});

  @override
  State<_InstrumentalLineWidget> createState() => _InstrumentalLineWidgetState();
}

class _InstrumentalLineWidgetState extends State<_InstrumentalLineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
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

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final val = _animController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_note,
              color: Color(0xFFFFD54F),
              size: 22,
              shadows: [
                Shadow(
                  color: Color(0xCCFFD54F),
                  blurRadius: 14.0,
                ),
                Shadow(
                  color: Color(0x55FFA000),
                  blurRadius: 24.0,
                ),
              ],
            ),
            const SizedBox(width: 10),
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final dotProgress = ((val * 3) - i).clamp(0.0, 1.0);
                  final pulse = dotProgress == 0.0 || dotProgress == 1.0
                      ? 0.0
                      : (dotProgress * (1.0 - dotProgress) * 4);
                  final scale = 0.8 + 0.45 * pulse;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0x88FFD54F),
                          const Color(0xFFFFD54F),
                          pulse,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xCCFFD54F).withOpacity(0.3 + 0.7 * pulse),
                            blurRadius: 6.0 + 8.0 * pulse,
                            spreadRadius: 1.0 + 2.0 * pulse,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
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
  Timer? _resumeTimer;
  Ticker? _ticker;
  Duration _lastReportedPosition = Duration.zero;
  DateTime _lastReportedTime = DateTime.now();
  late final ValueNotifier<Duration> _animatedPosition;

  @override
  void initState() {
    super.initState();
    _initKeys();
    final currentPos =
        widget.playerController.progressBarStatus.value.current;
    _lastReportedPosition = currentPos;
    _lastReportedTime = DateTime.now();
    _animatedPosition = ValueNotifier<Duration>(currentPos);

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (widget.playerController.buttonState.value == PlayButtonState.playing) {
        final now = DateTime.now();
        final delta = now.difference(_lastReportedTime);
        final interpolated = _lastReportedPosition + delta;
        _animatedPosition.value = interpolated;

        final activeIndex = _findActiveIndex(interpolated);
        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          _scrollToActive(activeIndex);
        }
      }
    });
    _ticker?.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final activeIndex = _findActiveIndex(currentPos);
        if (activeIndex >= 0) {
          _lastActiveIndex = activeIndex;
          _scrollToActive(activeIndex);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant YtmSyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _initKeys();
      _lastActiveIndex = -1;
      _userInteracting = false;
      _resumeTimer?.cancel();
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

  void _scrollToActive(int index) {
    if (_userInteracting || index < 0 || index >= _itemKeys.length) return;
    if (!_scrollController.hasClients) return;

    final itemContext = _itemKeys[index].currentContext;
    final viewportContext = _viewportKey.currentContext;

    if (itemContext != null && viewportContext != null) {
      final itemBox = itemContext.findRenderObject() as RenderBox?;
      final viewportBox = viewportContext.findRenderObject() as RenderBox?;

      if (itemBox != null &&
          viewportBox != null &&
          itemBox.hasSize &&
          viewportBox.hasSize) {
        final itemOffset =
            itemBox.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
        final currentScrollOffset = _scrollController.offset;
        final viewportHeight = viewportBox.size.height;
        final itemHeight = itemBox.size.height;

        final targetOffset = currentScrollOffset +
            itemOffset -
            (viewportHeight / 2) +
            (itemHeight / 2);
        final maxScroll = _scrollController.position.maxScrollExtent;
        final minScroll = _scrollController.position.minScrollExtent;
        final clampedOffset = targetOffset.clamp(minScroll, maxScroll);

        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _startResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _userInteracting = false;
        });
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
      _lastReportedPosition = currentPos;
      _lastReportedTime = DateTime.now();
      if (widget.playerController.buttonState.value != PlayButtonState.playing) {
        _animatedPosition.value = currentPos;
      }
      final activeIndex = _findActiveIndex(_animatedPosition.value);

      if (activeIndex != _lastActiveIndex) {
        _lastActiveIndex = activeIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToActive(activeIndex);
        });
      }

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
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _userInteracting = true;
                _resumeTimer?.cancel();
              } else if (notification is ScrollEndNotification &&
                  _userInteracting) {
                _startResumeTimer();
              }
              return false;
            },
            child: SingleChildScrollView(
              key: _viewportKey,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: scrollPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(widget.lyrics.length, (index) {
                  final line = widget.lyrics[index];
                  final isActive = index == activeIndex;

                  return Center(
                    key: _itemKeys[index],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        splashColor: const Color(0x33FFD54F),
                        highlightColor: const Color(0x1AFFD54F),
                        onTap: () {
                          widget.playerController.seek(line.time);
                          _lastReportedPosition = line.time;
                          _lastReportedTime = DateTime.now();
                          _animatedPosition.value = line.time;
                          _userInteracting = false;
                          _resumeTimer?.cancel();
                          _scrollToActive(index);
                        },
                        child: AnimatedContainer(
                          duration: isActive
                              ? const Duration(milliseconds: 240)
                              : Duration.zero,
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0x18FFD54F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: line.isInstrumental
                              ? _InstrumentalLineWidget(isActive: isActive)
                              : AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFFFFD54F)
                                        : Colors.white.withOpacity(0.40),
                                    fontSize: isActive ? 19.5 : 15.5,
                                    fontWeight:
                                        isActive ? FontWeight.w800 : FontWeight.w500,
                                    letterSpacing: isActive ? 0.2 : 0.0,
                                    height: 1.5,
                                    shadows: (isActive && line.words.isEmpty)
                                        ? const [
                                            Shadow(
                                              color: Color(0xCCFFD54F),
                                              blurRadius: 14.0,
                                            ),
                                            Shadow(
                                              color: Color(0x55FFA000),
                                              blurRadius: 24.0,
                                            ),
                                          ]
                                        : const [],
                                  ),
                                  child: (isActive && line.words.isNotEmpty)
                                      ? ValueListenableBuilder<Duration>(
                                          valueListenable: _animatedPosition,
                                          builder: (context, pos, _) {
                                            return Text.rich(
                                              TextSpan(
                                                children: line.words.map((w) {
                                                  final isSung = pos >= w.time;
                                                  return TextSpan(
                                                    text: w.text,
                                                    style: TextStyle(
                                                      color: isSung
                                                          ? const Color(0xFFFFD54F)
                                                          : Colors.white.withOpacity(0.50),
                                                      fontWeight: isSung
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      shadows: isSung
                                                          ? const [
                                                              Shadow(
                                                                color: Color(0xCCFFD54F),
                                                                blurRadius: 14.0,
                                                              ),
                                                              Shadow(
                                                                color: Color(0x55FFA000),
                                                                blurRadius: 24.0,
                                                              ),
                                                            ]
                                                          : const [],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              textAlign: TextAlign.center,
                                            );
                                          },
                                        )
                                      : Text(
                                          line.text,
                                          textAlign: TextAlign.center,
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
        );
      },
    );
  });
}
}

void showLyricsSearchSheet(
    BuildContext context, PlayerController playerController) {
  final current = playerController.currentSong.value;
  final titleController = TextEditingController(
      text: current != null
          ? SyncedLyricsService.cleanTrackTitle(current.title,
              artist: current.artist)
          : "");
  final artistController = TextEditingController(
      text: current != null
          ? SyncedLyricsService.cleanArtistName(current.artist)
          : "");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF181818),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      bool isSearching = false;
      List<Map<String, dynamic>> searchResults = [];

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Search Lyrics Across Providers",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Track Title",
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      : () async {
                          setSheetState(() => isSearching = true);
                          final dur = playerController
                              .progressBarStatus.value.total.inSeconds;
                          final list =
                              await SyncedLyricsService.searchAllProviders(
                            titleController.text.trim(),
                            artistController.text.trim(),
                            durationSec: dur,
                          );
                          setSheetState(() {
                            searchResults = list;
                            isSearching = false;
                          });
                        },
                  icon: isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.search, size: 18),
                  label:
                      Text(isSearching ? "Searching..." : "Search Providers"),
                ),
                const SizedBox(height: 12),
                if (searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        final isWord = item['wordSynced'] == true;
                        final sourceName = item['sourceName'] ??
                            item['provider'] ??
                            'Source';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "${item['title']} - ${item['artist']}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
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
                                      : "Line-Synced",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isWord
                                        ? const Color(0xFFFFD54F)
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sourceName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.check_circle_outline,
                              color: Color(0xFFFFD54F), size: 20),
                          onTap: () async {
                            await playerController.manualSetLyrics(item);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(Get.context!).showSnackBar(
                                snackbar(
                                  Get.context!,
                                  "Applied lyrics from $sourceName!",
                                  size: SanckBarSize.MEDIUM,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  )
                else if (!isSearching &&
                    searchResults.isEmpty &&
                    titleController.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Search above to fetch lyrics from lrc.red, BetterLyrics, KuGou, LRCLIB & Netease.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
