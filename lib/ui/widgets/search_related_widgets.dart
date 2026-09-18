import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/models/album.dart';
import '/models/artist.dart';
// import '/models/playlist.dart';
import '/ui/widgets/content_list_widget.dart';
import 'separate_tab_item_widget.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, this.isv2Used = false});
  final bool isv2Used;

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Obx(
      () => Center(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: SingleChildScrollView(
            padding:
                EdgeInsets.only(bottom: 200, top: isv2Used ? 0 : topPadding),
            child: searchResScrController.isResultContentFetced.value
                ? Column(children: [
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "searchRes".tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${"for1".tr} \"${searchResScrController.queryString.value}\"",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    ...generateWidgetList(searchResScrController),
                  ])
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  List<Widget> generateWidgetList(
      SearchResultScreenController searchResScrController) {
    List<Widget> list = [];
    final contentMap = searchResScrController.resultContent;
    if (contentMap.isEmpty) return list;

    for (var entry in contentMap.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is! List || val.isEmpty) continue;

      try {
        if (key == "Songs" || key == "Videos") {
          final items = val.whereType<MediaItem>().toList();
          if (items.isNotEmpty) {
            list.add(SeparateTabItemWidget(
              items: items,
              title: key,
              isCompleteList: false,
            ));
          }
        } else if (key == "Albums") {
          final items = val.whereType<Album>().toList();
          if (items.isNotEmpty) {
            list.add(ContentListWidget(
              content: AlbumContent(title: key, albumList: items),
              isHomeContent: false,
            ));
          }
        } else if (key.toString().contains("Artist")) {
          final items = val.whereType<Artist>().toList();
          if (items.isNotEmpty) {
            list.add(SeparateTabItemWidget(
              items: items,
              title: key,
              isCompleteList: false,
            ));
          }
        }
      } catch (e) {
        // Safe fallback
      }
    }

    return list;
  }
}
