import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../services/local_music_service.dart';
import '../../../utils/helper.dart';
import '../../widgets/sort_widget.dart';

class LocalSongsController extends GetxController {
  final RxList<MediaItem> localSongsList = <MediaItem>[].obs;
  final isScanning = false.obs;
  final hasScannedOnce = false.obs;
  List<MediaItem> tempListContainer = [];
  SortWidgetController? sortWidgetController;
  final additionalOperationMode = OperationMode.none.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocalSongs();
  }

  Future<void> loadLocalSongs({bool forceRescan = false}) async {
    isScanning.value = true;
    try {
      final songs = await LocalMusicService.getLocalSongs(forceRescan: forceRescan);
      localSongsList.value = songs;
      hasScannedOnce.value = true;
    } catch (e) {
      printINFO("Error loading local songs: $e");
    } finally {
      isScanning.value = false;
    }
  }

  void onSort(SortType sortType, bool isAscending) {
    final songlist = localSongsList.toList();
    sortSongsNVideos(songlist, sortType, isAscending);
    localSongsList.value = songlist;
  }

  void onSearchStart(String? tag) {
    tempListContainer = localSongsList.toList();
  }

  void onSearch(String value, String? tag) {
    if (value.trim().isEmpty) {
      localSongsList.value = tempListContainer.toList();
      return;
    }
    final query = value.toLowerCase();
    final filtered = tempListContainer.where((element) {
      final titleMatches = element.title.toLowerCase().contains(query);
      final artistMatches = element.artist?.toLowerCase().contains(query) ?? false;
      final albumMatches = element.album?.toLowerCase().contains(query) ?? false;
      return titleMatches || artistMatches || albumMatches;
    }).toList();
    localSongsList.value = filtered;
  }

  void onSearchClose(String? tag) {
    localSongsList.value = tempListContainer.toList();
  }

  List<String> getExcludedFolders() {
    final box = Hive.box("AppPrefs");
    return List<String>.from(
        box.get("excluded_local_folders", defaultValue: <String>[]) ?? []);
  }

  Future<void> addExcludedFolder(String path) async {
    final box = Hive.box("AppPrefs");
    final current = getExcludedFolders();
    if (!current.contains(path)) {
      current.add(path);
      await box.put("excluded_local_folders", current);
      // Reload songs filtering out the newly excluded folder
      await loadLocalSongs(forceRescan: true);
    }
  }

  Future<void> removeExcludedFolder(String path) async {
    final box = Hive.box("AppPrefs");
    final current = getExcludedFolders();
    if (current.remove(path)) {
      await box.put("excluded_local_folders", current);
      await loadLocalSongs(forceRescan: true);
    }
  }
}
