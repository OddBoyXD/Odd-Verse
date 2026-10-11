import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/screens/Settings/settings_screen_controller.dart';
import '/ui/widgets/piped_sync_widget.dart';
import '../../widgets/create_playlist_dialog.dart';
import '../../widgets/playlist_import_dialog.dart';
import 'library.dart';

class CombinedLibrary extends StatelessWidget {
  const CombinedLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final tabCon = Get.put(CombinedLibraryController());
    final settingscrnController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        actions: [
          Obx(() => (settingscrnController.isLinkedWithPiped.isTrue)
              ? const PipedSyncWidget(
                  padding: EdgeInsets.only(right: 10, top: 50))
              : const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.only(top: 50.0, right: 8),
            child: SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                tooltip: "Import Playlist (Spotify/YouTube/File)",
                icon: const Icon(Icons.cloud_download_outlined, size: 24),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const PlaylistImportDialog(),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50.0, right: 18),
            child: SizedBox(
              height: 40,
              width: 50,
              child: FittedBox(
                child: FloatingActionButton.extended(
                    elevation: 0,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              const CreateNRenamePlaylistPopup());
                    },
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.add,
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor.withOpacity(0.55)
                    : Theme.of(context).cardColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  width: 1.0,
                ),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                physics: const BouncingScrollPhysics(),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.secondary.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12.5,
                ),
                padding: const EdgeInsets.all(3),
                controller: tabCon.tabController,
                tabs: [
                  Tab(text: "songs".tr),
                  Tab(text: "localSongs".tr),
                  Tab(text: "playlists".tr),
                  Tab(text: "albums".tr),
                  Tab(text: "artists".tr),
                ],
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 60.0, left: 5),
          child:
              Text('library'.tr, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
      body: TabBarView(
        controller: tabCon.tabController,
        children: const [
          SongsLibraryWidget(
            isBottomNavActive: true,
          ),
          LocalSongsLibraryWidget(
            isBottomNavActive: true,
          ),
          PlaylistNAlbumLibraryWidget(
              isAlbumContent: false, isBottomNavActive: true),
          PlaylistNAlbumLibraryWidget(isBottomNavActive: true),
          LibraryArtistWidget(isBottomNavActive: true),
        ],
      ),
    );
  }
}

class CombinedLibraryController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(vsync: this, length: 5);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
