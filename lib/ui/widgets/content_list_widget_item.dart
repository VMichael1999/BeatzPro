import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigator.dart';
import 'glass_widgets.dart';
import 'image_widget.dart';

class ContentListItem extends StatelessWidget {
  const ContentListItem(
      {super.key, required this.content, this.isLibraryItem = false});

  ///content will be of Type class Album or Playlist
  final dynamic content;
  final bool isLibraryItem;

  @override
  Widget build(BuildContext context) {
    final isAlbum = content.runtimeType.toString() == "Album";
    return GlassCard(
      width: 134,
      padding: const EdgeInsets.all(8),
      borderRadius: 24,
      onTap: () {
        Get.toNamed(ScreenNavigationSetup.playlistNAlbumScreen,
            id: ScreenNavigationSetup.id, arguments: [isAlbum, content, false]);
      },
      child: SizedBox(
        width: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag:
                  "content-art-${isAlbum ? content.browseId : content.playlistId}",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: isAlbum
                    ? ImageWidget(
                        size: 118,
                        album: content,
                      )
                    : content.isCloudPlaylist
                        ? SizedBox.square(
                            dimension: 118,
                            child: Stack(
                              children: [
                                ImageWidget(
                                  size: 118,
                                  playlist: content,
                                ),
                                if (content.isPipedPlaylist)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        height: 18,
                                        width: 18,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "P",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          )
                        : Container(
                            height: 118,
                            width: 118,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.75),
                                  Colors.white.withValues(alpha: 0.12),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Icon(
                                content.playlistId == 'LIBRP'
                                    ? Icons.history_rounded
                                    : content.playlistId == 'LIBFAV'
                                        ? Icons.favorite_rounded
                                        : content.playlistId == 'SongsCache'
                                            ? Icons.flight_rounded
                                            : content.playlistId ==
                                                    'SongDownloads'
                                                ? Icons.download
                                                : Icons.playlist_play_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              isAlbum
                  ? isLibraryItem
                      ? ""
                      : "${content.artists[0]['name'] ?? ""} | ${content.year ?? ""}"
                  : isLibraryItem
                      ? ""
                      : content.description ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.color
                        ?.withValues(alpha: 0.72),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
