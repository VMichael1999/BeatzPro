import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player/player_controller.dart';
import '../screens/Search/search_result_screen_controller.dart';
import '../utils/beatz_design.dart';
import '/models/album.dart';
import '/models/artist.dart';
import '/models/playlist.dart';
import '/ui/widgets/content_list_widget.dart';
import 'beatz/beatz_icon.dart';
import 'image_widget.dart';
import 'separate_tab_item_widget.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, this.isv2Used = false});
  final bool isv2Used;

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    return Obx(
      () => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 120, top: isv2Used ? 8 : 70),
        child: searchResScrController.isResultContentFetced.value
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!isv2Used)
                  Text(
                    "searchRes".tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (!isv2Used)
                  Text(
                    "${"for1".tr} \"${searchResScrController.queryString.value}\"",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 6),
                _topResult(context, searchResScrController),
                ...generateWidgetList(searchResScrController),
              ])
            : const SizedBox.shrink(),
      ),
    );
  }

  /// The first song of the results, big, with a play button.
  Widget _topResult(BuildContext context, SearchResultScreenController c) {
    final songs = c.resultContent["Songs"];
    if (songs is! List || songs.isEmpty || songs.first is! MediaItem) {
      return const SizedBox.shrink();
    }
    final song = songs.first as MediaItem;
    final colors = context.beatz;
    final player = Get.find<PlayerController>();
    final details = [
      song.artist,
      if (song.album != null && song.album!.isNotEmpty) song.album,
      song.extras?['length'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => player.pushSongToQueue(song),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ImageWidget(size: 84, song: song),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resultado principal · Canción',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.muted)),
                      Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: colors.ink)),
                      Text(details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 13, color: colors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Reproducir ${song.title}',
                  child: Material(
                    color: colors.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => player.pushSongToQueue(song),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: BeatzIcon('play',
                              filled: true, color: colors.bg),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
