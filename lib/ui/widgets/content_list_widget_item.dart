import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigator.dart';
import '../utils/beatz_design.dart';
import 'beatz/beatz_icon.dart';
import 'image_widget.dart';

/// Album / playlist tile (`.tile` in the design): square cover, title and a
/// muted line below.
class ContentListItem extends StatelessWidget {
  const ContentListItem(
      {super.key,
      required this.content,
      this.isLibraryItem = false,
      this.width = 120});

  ///content will be of Type class Album or Playlist
  final dynamic content;
  final bool isLibraryItem;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    final isAlbum = content.runtimeType.toString() == "Album";
    final subtitle = isAlbum
        ? isLibraryItem
            ? ""
            : "${content.artists[0]['name'] ?? ""} · ${content.year ?? ""}"
        : isLibraryItem
            ? ""
            : content.description ?? "";
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Get.toNamed(ScreenNavigationSetup.playlistNAlbumScreen,
            id: ScreenNavigationSetup.id, arguments: [isAlbum, content, false]);
      },
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cover(context, colors, isAlbum),
            const SizedBox(height: 6),
            Text(
              content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.25,
                  color: colors.ink),
            ),
            if (subtitle.toString().isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, height: 1.25, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cover(BuildContext context, BeatzColors colors, bool isAlbum) {
    if (isAlbum) {
      return ImageWidget(size: width, album: content);
    }
    if (content.isCloudPlaylist) {
      return SizedBox.square(
        dimension: width,
        child: Stack(
          children: [
            ImageWidget(size: width, playlist: content),
            if (content.isPipedPlaylist)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 18,
                    width: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: colors.raised,
                    ),
                    child: Center(
                        child: Text("P",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.ink))),
                  ),
                ),
              )
          ],
        ),
      );
    }
    final id = content.playlistId;
    final icon = id == 'LIBRP'
        ? 'radio'
        : id == 'LIBFAV'
            ? 'heart'
            : id == 'SongsCache'
                ? 'db'
                : id == 'SongDownloads'
                    ? 'dl'
                    : 'queue';
    return Container(
      height: width,
      width: width,
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: BeatzIcon(icon,
            size: 32,
            color: id == 'LIBFAV' ? BeatzColors.heart : colors.ink,
            filled: id == 'LIBFAV'),
      ),
    );
  }
}
