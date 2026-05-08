import 'package:beatzpro/ui/utils/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/ui/widgets/content_list_widget_item.dart';
import 'glass_widgets.dart';

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

    return GlassContainer(
      margin: const EdgeInsets.only(right: 12, bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      borderRadius: 28,
      opacity: 0.06,
      blur: 10,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  !isHomeContent && content.title.length > 12
                      ? "${content.title.substring(0, 12)}..."
                      : content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
              ),
              if (!isHomeContent)
                TextButton(
                  onPressed: () {
                    final scrresController =
                        Get.find<SearchResultScreenController>();
                    scrresController.viewAllCallback(content.title);
                  },
                  child: Text(
                    "viewAll".tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).primaryColor.withLightness(0.7),
                        ),
                  ),
                ),
            ],
          ),
          if (itemCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 218,
              child: ListView.separated(
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(width: 15),
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final item = isAlbumContent
                      ? content.albumList[index]
                      : content.playlistList[index];
                  return ContentListItem(content: item);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
