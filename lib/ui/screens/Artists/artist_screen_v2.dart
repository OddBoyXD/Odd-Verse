import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/screens/Artists/artist_screen.dart' show AboutArtist;
import '../../navigator.dart';
import '../../widgets/loader.dart';
import '../../widgets/separate_tab_item_widget.dart';
import 'artist_screen_controller.dart';

class ArtistScreenBN extends StatelessWidget {
  const ArtistScreenBN(
      {super.key, required this.artistScreenController, required this.tag});
  final ArtistScreenController artistScreenController;
  final String tag;
  @override
  Widget build(BuildContext context) {
    final separatedContent = artistScreenController.sepataredContent;
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 85,
          backgroundColor: Theme.of(context).canvasColor,
          leading: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: IconButton(
                onPressed: () {
                  Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
                },
                icon: const Icon(Icons.arrow_back_ios_new)),
          ),
          elevation: 0,
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
                  enableFeedback: true,
                  controller: artistScreenController.tabController!,
                  onTap: artistScreenController.onDestinationSelected,
                  tabs:
                      ["about".tr, "songs".tr, "videos".tr, "albums".tr, "singles".tr]
                          .map((e) => Tab(
                                text: e,
                              ))
                          .toList(),
                ),
              ),
            ),
          ),
          title: Obx(
            () => artistScreenController.isArtistContentFetced.isTrue
                ? Padding(
                    padding: const EdgeInsets.only(top: 25.0),
                    child: Text(artistScreenController.artist_.name,
                        style: Theme.of(context).textTheme.titleLarge),
                  )
                : const SizedBox.shrink(),
          )),
      body: Obx(
        () => TabBarView(
          controller: artistScreenController.tabController,
          children: artistScreenController.isArtistContentFetced.isFalse
              ? List.generate(
                  5,
                  (index) => const Center(
                        child: LoadingIndicator(),
                      ))
              : [
                  AboutArtist(
                    artistScreenController: artistScreenController,
                    padding: const EdgeInsets.only(
                        top: 10, left: 15, right: 5, bottom: 200),
                  ),
                  ...["Songs", "Videos", "Albums", "Singles"].map(
                    (item) {
                      if (artistScreenController
                              .isSeparatedArtistContentFetced.isFalse &&
                          artistScreenController
                                  .navigationRailCurrentIndex.value !=
                              0) {
                        return const Center(child: LoadingIndicator());
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 15.0, right: 5),
                        child: SeparateTabItemWidget(
                          artistControllerTag: tag,
                          hideTitle: true,
                          isResultWidget: false,
                          items: separatedContent.containsKey(item)
                              ? separatedContent[item]['results']
                              : [],
                          title: item,
                          scrollController: item == "Songs"
                              ? artistScreenController.songScrollController
                              : item == "Videos"
                                  ? artistScreenController.videoScrollController
                                  : item == "Albums"
                                      ? artistScreenController
                                          .albumScrollController
                                      : item == "Singles"
                                          ? artistScreenController
                                              .singlesScrollController
                                          : null,
                        ),
                      );
                    },
                  )
                ],
        ),
      ),
    );
  }
}
