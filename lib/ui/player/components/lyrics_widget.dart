import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:harmonymusic/utils/indic_transliteration.dart';

import '../../widgets/loader.dart';
import '../player_controller.dart';

class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}

class LyricsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const LyricsWidget({super.key, required this.padding});

  List<LyricLine> _parseLrc(
      String lrc, bool isRomanize, Duration sponsorOffset) {
    if (lrc.trim().isEmpty) return [];
    final lines = lrc.split('\n');
    final result = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        var duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
        if (sponsorOffset != Duration.zero) {
          duration += sponsorOffset;
        }
        var text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          if (isRomanize) {
            text = IndicTransliteration.transliterateLine(text);
          }
          result.add(LyricLine(time: duration, text: text));
        }
      }
    }
    result.sort((a, b) => a.time.compareTo(b.time));
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
      final sponsorOffset = playerController.sponsorIntroOffset.value;
      final rawPlain =
          playerController.lyrics["plainLyrics"]?.toString().trim() ?? "";
      final displayPlain =
          (rawPlain.isNotEmpty && rawPlain != "NA" && isRomanize)
              ? IndicTransliteration.transliterateLyrics(rawPlain)
              : rawPlain;

      final rawSynced =
          playerController.lyrics['synced']?.toString().trim() ?? '';
      final parsedSynced = _parseLrc(rawSynced, isRomanize, sponsorOffset);

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
              if (displayPlain.isNotEmpty && displayPlain != "NA")
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD54F),
                    ),
                    onPressed: () {
                      playerController.changeLyricsMode(1);
                    },
                    icon: const Icon(Icons.text_snippet_outlined, size: 18),
                    label: Text("plain".tr),
                  ),
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

class _YtmSyncedLyricsViewState extends State<YtmSyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [];
  int _lastActiveIndex = -1;
  bool _userInteracting = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _initKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentPos =
            widget.playerController.progressBarStatus.value.current;
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
    _resumeTimer = Timer(const Duration(seconds: 3), () {
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
      final activeIndex = _findActiveIndex(currentPos);

      if (activeIndex != _lastActiveIndex) {
        _lastActiveIndex = activeIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToActive(activeIndex);
        });
      }

      return Listener(
        onPointerDown: (_) {
          _userInteracting = true;
          _resumeTimer?.cancel();
        },
        onPointerMove: (_) {
          _userInteracting = true;
          _resumeTimer?.cancel();
        },
        onPointerUp: (_) {
          _startResumeTimer();
        },
        onPointerCancel: (_) {
          _startResumeTimer();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _userInteracting = true;
              _resumeTimer?.cancel();
            } else if (notification is ScrollUpdateNotification &&
                notification.dragDetails != null) {
              _userInteracting = true;
              _resumeTimer?.cancel();
            } else if (notification is ScrollEndNotification) {
              _startResumeTimer();
            }
            return false;
          },
          child: SingleChildScrollView(
            key: _viewportKey,
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.lyrics.length, (index) {
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
                        _userInteracting = false;
                        _resumeTimer?.cancel();
                        _scrollToActive(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0x26FFD54F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withOpacity(0.50),
                            fontSize: isActive ? 19.5 : 15.5,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
    });
  }
}
