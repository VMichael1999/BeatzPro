import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '../utils/beatz_design.dart';
import '/ui/widgets/content_list_widget_item.dart';
import 'beatz/beatz_widgets.dart';

class ContentListWidget extends StatelessWidget {
  /// ContentListWidget is used to render a section of Content like a list of Albums or Playlists in HomeScreen
  const ContentListWidget({super.key, this.content, this.isHomeContent = true});

  /// content will be of class Type AlbumContent or PlaylistContent
  final dynamic content;
  final bool isHomeContent;

  @override
  Widget build(BuildContext context) {
    final isAlbumContent = content.runtimeType.toString() == "AlbumContent";
    final itemCount =
        isAlbumContent ? content.albumList.length : content.playlistList.length;
    // three tiles per row, like the design
    final tileWidth = (MediaQuery.of(context).size.width - 36 - 20) / 3;
    final colors = context.beatz;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeatzSectionTitle(
            content.title,
            action: isHomeContent ? null : "viewAll".tr,
            onAction: isHomeContent
                ? null
                : () => Get.find<SearchResultScreenController>()
                    .viewAllCallback(content.title),
          ),
          if (itemCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: tileWidth + 62,
              child: ListView.separated(
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final item = isAlbumContent
                      ? content.albumList[index]
                      : content.playlistList[index];
                  return ContentListItem(content: item, width: tileWidth);
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('—', style: TextStyle(color: colors.muted)),
            ),
        ],
      ),
    );
  }
}
