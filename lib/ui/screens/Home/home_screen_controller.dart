import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/media_Item_builder.dart';
import '/ui/player/player_controller.dart';
import '../../../utils/update_check_flag_file.dart';
import '../../../utils/helper.dart';
import '/models/album.dart';
import '/models/playlist.dart';
import '/models/quick_picks.dart';
import '/services/music_service.dart';
import '/services/ytm_auth_service.dart';
import '../Settings/settings_screen_controller.dart';
import '/ui/widgets/new_version_dialog.dart';

class HomeScreenController extends GetxController {
  final MusicServices _musicServices = Get.find<MusicServices>();
  final isContentFetched = false.obs;
  final tabIndex = 0.obs;
  final networkError = false.obs;
  final quickPicks = QuickPicks([]).obs;
  final middleContent = [].obs;
  final fixedContent = [].obs;
  final showVersionDialog = true.obs;
  //isHomeScreenOnTop var only useful if bottom nav enabled
  final isHomeSreenOnTop = true.obs;
  final List<ScrollController> contentScrollControllers = [];
  bool reverseAnimationtransiton = false;

  @override
  onInit() {
    super.onInit();
    loadContent();
    if (updateCheckFlag) _checkNewVersion();
  }

  Future<void> loadContent() async {
    final box = Hive.box("AppPrefs");
    final isCachedHomeScreenDataEnabled =
        box.get("cacheHomeScreenData") ?? true;
    if (isCachedHomeScreenDataEnabled) {
      final loaded = await loadContentFromDb();
      if (loaded) {
        // Instant display from cache, silently refresh in background
        loadContentFromNetwork(silent: true);
      } else {
        loadContentFromNetwork();
      }
    } else {
      loadContentFromNetwork();
    }
  }

  Future<bool> loadContentFromDb() async {
    final homeScreenData = await Hive.openBox("homeScreenData");
    if (homeScreenData.keys.isNotEmpty) {
      final String quickPicksType = homeScreenData.get("quickPicksType");
      final List quickPicksData = homeScreenData.get("quickPicks");
      final List middleContentData = homeScreenData.get("middleContent") ?? [];
      final List fixedContentData = homeScreenData.get("fixedContent") ?? [];
      quickPicks.value = QuickPicks(
          quickPicksData.map((e) => MediaItemBuilder.fromJson(e)).toList(),
          title: quickPicksType);
      middleContent.value = middleContentData.map((e) {
        if (e["type"] == "Album Content") {
          return AlbumContent.fromJson(e);
        } else if (e["type"] == "QuickPicks") {
          return QuickPicks(
            (e["songList"] as List)
                .map((s) => MediaItemBuilder.fromJson(s))
                .toList(),
            title: e["title"] ?? "Recommended",
          );
        } else {
          return PlaylistContent.fromJson(e);
        }
      }).toList();
      fixedContent.value = fixedContentData.map((e) {
        if (e["type"] == "Album Content") {
          return AlbumContent.fromJson(e);
        } else if (e["type"] == "QuickPicks") {
          return QuickPicks(
            (e["songList"] as List)
                .map((s) => MediaItemBuilder.fromJson(s))
                .toList(),
            title: e["title"] ?? "Recommended",
          );
        } else {
          return PlaylistContent.fromJson(e);
        }
      }).toList();
      isContentFetched.value = true;
      printINFO("Loaded from offline db");
      return true;
    } else {
      return false;
    }
  }

  Future<void> loadContentFromNetwork({bool silent = false}) async {
    final box = Hive.box("AppPrefs");
    String contentType = box.get("discoverContentType") ?? "QP";

    bool isYtmLoggedIn = false;
    if (Get.isRegistered<YtmAuthService>()) {
      isYtmLoggedIn = Get.find<YtmAuthService>().isLoggedIn.value;
    }

    networkError.value = false;
    try {
      List middleContentTemp = [];
      final homeContentListMap = await _musicServices.getHome(
          limit: isYtmLoggedIn ? 25 : 15);

      if (!isYtmLoggedIn && contentType == "TR") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Trending");
        if (index != -1 && index != 0) {
          quickPicks.value = QuickPicks(
              List<MediaItem>.from(homeContentListMap[index]["contents"]),
              title: "Trending");
        } else if (index == -1) {
          List charts = await _musicServices.getCharts(contentType);
          final index = charts.indexWhere((element) =>
              element['title'] == "Trending");
          if (index != -1) {
            quickPicks.value = QuickPicks(
                List<MediaItem>.from(charts[index]["contents"]),
                title: charts[index]['title']);
            middleContentTemp.addAll(charts);
          }
        }
      } else if (contentType == "TMV") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Top music videos");
        if (index != -1 && index != 0) {
          final con = homeContentListMap.removeAt(index);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: con["title"]);
        } else if (index == -1) {
          List charts = await _musicServices.getCharts(contentType);
          final index = charts.indexWhere((element) =>
              element['title'] == "Top Music Videos");
          if (index != -1) {
            quickPicks.value = QuickPicks(
                List<MediaItem>.from(charts[index]["contents"]),
                title: charts[index]["title"]);
            middleContentTemp.addAll(charts);
          }
        }
      } else if (contentType == "BOLI") {
        try {
          final songId = box.get("recentSongId");
          if (songId != null) {
            final rel = (await _musicServices.getContentRelatedToSong(
                songId, getContentHlCode()));
            if (rel.isNotEmpty &&
                rel[0]["contents"] != null &&
                (rel[0]["contents"] as List).isNotEmpty &&
                rel[0]["contents"][0] is MediaItem) {
              final con = rel.removeAt(0);
              quickPicks.value = QuickPicks(
                  List<MediaItem>.from(con["contents"]),
                  title: con["title"] ?? "Recommended");
              middleContentTemp.addAll(rel);
            }
          }
        } catch (e) {
          printERROR(
              "Seems Based on last interaction content currently not available!");
        }
      } else {
        // Smart Default / Personalized Mode ("QP"):
        // Dynamic top song shelf detection (works seamlessly for both YTM logged-in and anonymous users)
        int songShelfIndex = -1;
        final candidateTitles = [
          "Quick picks",
          "Listen again",
          "Mixed for you",
          "From your library",
          "Speed dial",
          "Forgotten favorites",
        ];
        for (final candidate in candidateTitles) {
          songShelfIndex = homeContentListMap.indexWhere((element) =>
              element['title']?.toString().toLowerCase() == candidate.toLowerCase() &&
              element['contents'] != null &&
              (element['contents'] as List).isNotEmpty &&
              element['contents'][0] is MediaItem);
          if (songShelfIndex != -1) break;
        }

        // Fallback: first shelf containing MediaItems
        if (songShelfIndex == -1) {
          songShelfIndex = homeContentListMap.indexWhere((element) =>
              element['contents'] != null &&
              (element['contents'] as List).isNotEmpty &&
              element['contents'][0] is MediaItem);
        }

        if (songShelfIndex != -1) {
          final con = homeContentListMap.removeAt(songShelfIndex);
          final songs = (con["contents"] as List).whereType<MediaItem>().toList();
          if (songs.isNotEmpty) {
            quickPicks.value =
                QuickPicks(songs, title: con["title"] ?? "Quick picks");
          }
        }

        // In anonymous mode: enrich feed with recommendations based on user's recent listening (governed by 5s rule)
        if (!isYtmLoggedIn) {
          final recentSongId = box.get("recentSongId");
          if (recentSongId != null && recentSongId.isNotEmpty) {
            try {
              final related = await _musicServices.getContentRelatedToSong(
                  recentSongId, getContentHlCode());
              if (related.isNotEmpty) {
                middleContentTemp.addAll(related);
              }
            } catch (_) {}
          }
        }
      }

      // If quickPicks is still empty (fallback for any mode):
      if (quickPicks.value.songList.isEmpty) {
        final fallbackIndex = homeContentListMap.indexWhere((element) =>
            element['contents'] != null &&
            (element['contents'] as List).isNotEmpty &&
            element['contents'][0] is MediaItem);
        if (fallbackIndex >= 0) {
          final con = homeContentListMap.removeAt(fallbackIndex);
          final songs = (con["contents"] as List).whereType<MediaItem>().toList();
          if (songs.isNotEmpty) {
            quickPicks.value = QuickPicks(songs, title: con["title"] ?? "Quick picks");
          }
        }
      }

      middleContent.value = _setContentList(middleContentTemp);

      // Deduplicate fixedContent so shelves already in middleContent or quickPicks never repeat
      final existingTitles = <String>{};
      if (quickPicks.value.title.isNotEmpty) {
        existingTitles.add(quickPicks.value.title.toLowerCase());
      }
      for (final item in middleContent) {
        if (item is AlbumContent) existingTitles.add(item.title.toLowerCase());
        if (item is PlaylistContent) existingTitles.add(item.title.toLowerCase());
      }
      final deduplicatedFixed = homeContentListMap.where((element) {
        final title = (element['title'] ?? '').toString().toLowerCase();
        return !existingTitles.contains(title);
      }).toList();

      fixedContent.value = _setContentList(deduplicatedFixed);

      isContentFetched.value = true;

      // set home content last update time
      cachedHomeScreenData(updateAll: true);
      await Hive.box("AppPrefs")
          .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);
      // ignore: unused_catch_stack
    } on NetworkError catch (r, e) {
      printERROR("Home Content not loaded due to ${r.message}");
      await Future.delayed(const Duration(seconds: 1));
      networkError.value = !silent;
    }
  }

  List _setContentList(
    List<dynamic> contents,
  ) {
    List contentTemp = [];
    for (var content in contents) {
      if ((content["contents"]).isEmpty) continue;
      final first = content["contents"][0];
      if (first is Playlist) {
        final tmp = PlaylistContent(
            playlistList: (content["contents"]).whereType<Playlist>().toList(),
            title: content["title"]);
        if (tmp.playlistList.length >= 2) {
          contentTemp.add(tmp);
        }
      } else if (first is Album) {
        final tmp = AlbumContent(
            albumList: (content["contents"]).whereType<Album>().toList(),
            title: content["title"]);
        if (tmp.albumList.length >= 2) {
          contentTemp.add(tmp);
        }
      } else if (first is MediaItem) {
        final songs = (content["contents"]).whereType<MediaItem>().toList();
        if (songs.isNotEmpty) {
          contentTemp.add(
              QuickPicks(songs, title: content["title"] ?? "Recommended"));
        }
      }
    }
    return contentTemp;
  }

  Future<void> changeDiscoverContent(dynamic val, {String? songId}) async {
    QuickPicks? quickPicks_;
    if (val == 'QP') {
      final homeContentListMap = await _musicServices.getHome(limit: 3);
      quickPicks_ = QuickPicks(
          List<MediaItem>.from(homeContentListMap[0]["contents"]),
          title: homeContentListMap[0]["title"]);
    } else if (val == "TMV" || val == 'TR') {
      try {
        final charts = await _musicServices.getCharts(val);
        final index = charts.indexWhere((element) =>
            element['title'] ==
            (val == "TMV" ? "Top Music Videos" : "Trending"));
        quickPicks_ = QuickPicks(
            List<MediaItem>.from(charts[index]["contents"]),
            title: charts[index]["title"]);
      } catch (e) {
        printERROR(
            "Seems ${val == "TMV" ? "Top music videos" : "Trending songs"} currently not available!");
      }
    } else {
      songId ??= Hive.box("AppPrefs").get("recentSongId");
      if (songId != null) {
        try {
          final value = await _musicServices.getContentRelatedToSong(
              songId, getContentHlCode());
          middleContent.value = _setContentList(value);
          if (value.isNotEmpty &&
              value[0]['contents'] != null &&
              (value[0]['contents'] as List).isNotEmpty &&
              value[0]['contents'][0] is MediaItem) {
            quickPicks_ =
                QuickPicks(List<MediaItem>.from(value[0]["contents"]),
                    title: value[0]["title"] ?? "Recommended");
            Hive.box("AppPrefs").put("recentSongId", songId);
          }
          // ignore: empty_catches
        } catch (e) {}
      }
    }
    if (quickPicks_ == null) return;

    quickPicks.value = quickPicks_;

    // set home content last update time
    cachedHomeScreenData(updateQuickPicksNMiddleContent: true);
    await Hive.box("AppPrefs")
        .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);
  }

  String getContentHlCode() {
    const List<String> unsupportedLangIds = ["ia", "ga", "fj", "eo"];
    final userLangId =
        Get.find<SettingsScreenController>().currentAppLanguageCode.value;
    return unsupportedLangIds.contains(userLangId) ? "en" : userLangId;
  }

  void onSideBarTabSelected(int index) {
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void onBottonBarTabSelected(int index) {
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void _checkNewVersion() {
    final isAutoUpdateCheckEnabled =
        Hive.box("AppPrefs").get("isAutoUpdateCheckEnabled") ?? true;
    if (!isAutoUpdateCheckEnabled) return;

    showVersionDialog.value =
        Hive.box("AppPrefs").get("newVersionVisibility") ?? true;
    if (showVersionDialog.isTrue) {
      newVersionCheck(Get.find<SettingsScreenController>().currentVersion)
          .then((value) {
        if (value) {
          showDialog(
              context: Get.context!,
              builder: (context) => const NewVersionDialog());
        }
      });
    }
  }

  void onChangeVersionVisibility(bool val) {
    Hive.box("AppPrefs").put("newVersionVisibility", !val);
    showVersionDialog.value = !val;
  }

  ///This is used to minimized bottom navigation bar by setting [isHomeSreenOnTop.value] to `true` and set mini player height.
  ///
  ///and applicable/useful if bottom nav enabled
  void whenHomeScreenOnTop() {
    if (Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue) {
      final currentRoute = getCurrentRouteName();
      final isHomeOnTop = currentRoute == '/homeScreen';
      final isResultScreenOnTop = currentRoute == '/searchResultScreen';
      final playerCon = Get.find<PlayerController>();

      isHomeSreenOnTop.value = isHomeOnTop;

      // Set miniplayer height accordingly
      if (!playerCon.initFlagForPlayer) {
        if (isHomeOnTop) {
          playerCon.playerPanelMinHeight.value = 75.0;
        } else {
          Future.delayed(
              isResultScreenOnTop
                  ? const Duration(milliseconds: 300)
                  : Duration.zero, () {
            playerCon.playerPanelMinHeight.value =
                75.0 + Get.mediaQuery.viewPadding.bottom;
          });
        }
      }
    }
  }

  Future<void> cachedHomeScreenData({
    bool updateAll = false,
    bool updateQuickPicksNMiddleContent = false,
  }) async {
    if (Get.find<SettingsScreenController>().cacheHomeScreenData.isFalse ||
        quickPicks.value.songList.isEmpty) {
      return;
    }

    final homeScreenData = Hive.box("homeScreenData");

    if (updateQuickPicksNMiddleContent) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
      });
    } else if (updateAll) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
        "fixedContent": _getContentDataInJson(fixedContent.toList())
      });
    }

    printINFO("Saved Homescreen data data");
  }

  List<Map<String, dynamic>> _getContentDataInJson(List content,
      {bool isQuickPicks = false}) {
    if (isQuickPicks) {
      return content.toList().map((e) => MediaItemBuilder.toJson(e)).toList();
    } else {
      return content.map((e) {
        if (e is AlbumContent) {
          return e.toJson();
        } else if (e is QuickPicks) {
          return {
            "type": "QuickPicks",
            "title": e.title,
            "songList":
                e.songList.map((s) => MediaItemBuilder.toJson(s)).toList(),
          };
        } else {
          return (e as PlaylistContent).toJson();
        }
      }).toList();
    }
  }

  void disposeDetachedScrollControllers({bool disposeAll = false}) {
    final scrollControllersCopy = contentScrollControllers.toList();
    for (final contoller in scrollControllersCopy) {
      if (!contoller.hasClients || disposeAll) {
        contentScrollControllers.remove(contoller);
        contoller.dispose();
      }
    }
  }

  @override
  void dispose() {
    disposeDetachedScrollControllers(disposeAll: true);
    super.dispose();
  }
}
