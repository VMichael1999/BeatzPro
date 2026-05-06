import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/models/album.dart';
import '/models/artist.dart';
import '/models/playlist.dart';
import '/ui/widgets/content_list_widget.dart';
import 'separate_tab_item_widget.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, this.isv2Used = false});
  final bool isv2Used;

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    return Obx(
      () => Center(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 200, top: isv2Used ? 0 : 70),
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
    final orderedEntries = searchResScrController.resultContent.entries.toList()
      ..sort((a, b) =>
          _contentSortIndex(a.key).compareTo(_contentSortIndex(b.key)));
    for (dynamic item in orderedEntries) {
      final key = item.key.toString();
      if (key == "Songs" || key == "Videos") {
        list.add(SeparateTabItemWidget(
          items: List<MediaItem>.from(item.value),
          title: key,
          isCompleteList: false,
        ));
      } else if (key == "Albums") {
        list.add(ContentListWidget(
          content:
              AlbumContent(title: key, albumList: List<Album>.from(item.value)),
          isHomeContent: false,
        ));
      } else if (key.toLowerCase().contains("playlist")) {
        list.add(ContentListWidget(
          content: PlaylistContent(
            title: key,
            playlistList: List<Playlist>.from(item.value),
          ),
          isHomeContent: false,
        ));
      } else if (key.contains("Artist")) {
        list.add(SeparateTabItemWidget(
          items: List<Artist>.from(item.value),
          title: key,
          isCompleteList: false,
        ));
      }
    }

    return list;
  }

  int _contentSortIndex(String key) {
    if (key == "Songs") return 0;
    if (key == "Videos") return 1;
    if (key == "Albums") return 2;
    if (key.toLowerCase().contains("playlist")) return 3;
    if (key.contains("Artist")) return 4;
    return 5;
  }
}
