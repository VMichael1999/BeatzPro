import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../models/playlist.dart';
import '../navigator.dart';
import '../player/player_controller.dart';
import '../utils/beatz_design.dart';
import 'beatz/beatz_icon.dart';
import 'beatz/beatz_widgets.dart';
import 'beatz/eq_bars.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

/// Lists of songs, videos, playlists, albums and artists (search, library,
/// album/playlist and artist screens), drawn with the rows of the redesign.
class ListWidget extends StatelessWidget {
  const ListWidget(this.items, this.title, this.isCompleteList,
      {super.key,
      this.isPlaylist = false,
      this.isArtistSongs = false,
      this.playlist,
      this.scrollController});
  final List<dynamic> items;
  final String title;
  final bool isCompleteList;
  final ScrollController? scrollController;

  /// Valid for songlist
  final bool isArtistSongs;
  final bool isPlaylist;
  final Playlist? playlist;

  static const _songRowHeight = 62.0;
  static const _libraryRowHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "No ${title.toLowerCase().tr}!",
            style: TextStyle(color: context.beatz.muted),
          ),
        ),
      );
    } else if (title == "Videos" || title.contains("Songs")) {
      return isCompleteList
          ? Expanded(
              child: listViewSongVid(items,
                  isPlaylist: isPlaylist,
                  playlist: playlist,
                  sc: scrollController,
                  isArtistSongs: isArtistSongs))
          : SizedBox(
              height: items.length * _songRowHeight,
              child: listViewSongVid(items),
            );
    } else if (title.contains("playlists")) {
      return listViewPlaylists(items, sc: scrollController);
    } else if (title == "Albums" || title == "Singles") {
      return listViewAlbums(items, sc: scrollController);
    } else if (title.contains('Artists')) {
      return isCompleteList
          ? Expanded(child: listViewArtists(items, sc: scrollController))
          : artistGrid(context, items);
    }
    return const SizedBox.shrink();
  }

  void _openInfo(PlayerController controller, MediaItem song) {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      isScrollControlled: true,
      context: controller.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(song, playlist: playlist),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  Widget listViewSongVid(List<dynamic> items,
      {bool isPlaylist = false,
      Playlist? playlist,
      bool isArtistSongs = false,
      ScrollController? sc}) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 0),
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      controller: sc,
      itemCount: items.length,
      physics: isCompleteList
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => songRow(context, items, index),
    );
  }

  /// One song row; also used by screens that scroll the list together with a
  /// header (album / playlist).
  Widget songRow(BuildContext context, List<dynamic> items, int index,
      {bool? isPlaylistOverride}) {
    final playerController = Get.find<PlayerController>();
    final isPlaylist = isPlaylistOverride ?? this.isPlaylist;
    final colors = context.beatz;
    final song = items[index] as MediaItem;
    final downloaded = Hive.box("SongDownloads").containsKey(song.id);
    final length = (song.extras?['length'] ?? "").toString();
    Widget row(bool isCurrent) => BeatzSongRow(
          cover: ImageWidget(size: 44, song: song, radius: 8),
          title: song.title,
          subtitle: "${song.artist ?? ''}",
          subtitleLeading: downloaded ? const DownloadedBadge() : null,
          leadingTitle: isCurrent
              ? EqBars(
                  animate: playerController.buttonState.value ==
                      PlayButtonState.playing)
              : null,
          onTap: () {
            (isPlaylist || isArtistSongs)
                ? playerController.playPlayListSong(
                    List<MediaItem>.from(items), index)
                : playerController.pushSongToQueue(song);
          },
          onLongPress: () => _openInfo(playerController, song),
          end: isPlaylist
              ? Text(length,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                      fontFeatures: const [FontFeature.tabularFigures()]))
              : BeatzIconButton(
                  icon: 'more',
                  tooltip: 'Más opciones',
                  color: colors.muted,
                  onPressed: () => _openInfo(playerController, song),
                ),
        );

    // only lists that mark the playing song observe the player
    if (!isPlaylist) return row(false);
    return Obx(() => row(playerController.currentSong.value?.id == song.id));
  }

  Widget listViewPlaylists(List<dynamic> playlists, {ScrollController? sc}) {
    return Expanded(
      child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 0),
          controller: sc,
          itemCount: playlists.length,
          itemExtent: _libraryRowHeight,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) => libraryRow(context,
              playlist: playlists[index],
              title: playlists[index].title,
              subtitle: playlists[index]?.description ?? "NA")),
    );
  }

  Widget listViewAlbums(List<dynamic> albums, {ScrollController? sc}) {
    return Expanded(
      child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 0),
          controller: sc,
          itemCount: albums.length,
          itemExtent: _libraryRowHeight,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return libraryRow(context,
                album: albums[index],
                title: albums[index].title,
                subtitle:
                    "${(albums[index].artists[0]['name'])} · ${albums[index].year}");
          }),
    );
  }

  Widget listViewArtists(List<dynamic> artists, {ScrollController? sc}) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 5),
      controller: sc,
      itemCount: artists.length,
      itemExtent: _libraryRowHeight,
      physics: isCompleteList
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => libraryRow(context,
          artist: artists[index],
          title: artists[index].name,
          subtitle: "${artists[index].subscribers}"),
    );
  }

  /// Three circular artists in a row (`.art` in the design).
  Widget artistGrid(BuildContext context, List<dynamic> artists) {
    final colors = context.beatz;
    final shown = artists.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: i >= shown.length
                ? const SizedBox.shrink()
                : InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.toNamed(ScreenNavigationSetup.artistScreen,
                        id: ScreenNavigationSetup.id,
                        arguments: [false, shown[i]]),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, c) => ImageWidget(
                              size: c.maxWidth, artist: shown[i]),
                        ),
                        const SizedBox(height: 6),
                        Text(shown[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.ink)),
                        Text('Artista',
                            style: TextStyle(
                                fontSize: 11.5, color: colors.muted)),
                      ],
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  /// Library row (`.li`): 56 px cover, title, detail line and a chevron.
  Widget libraryRow(BuildContext context,
      {dynamic album,
      dynamic playlist,
      dynamic artist,
      required String title,
      required String subtitle}) {
    final colors = context.beatz;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (artist != null) {
          Get.toNamed(ScreenNavigationSetup.artistScreen,
              id: ScreenNavigationSetup.id, arguments: [false, artist]);
        } else if (album != null) {
          Get.toNamed(ScreenNavigationSetup.playlistNAlbumScreen,
              id: ScreenNavigationSetup.id, arguments: [true, album, false]);
        } else {
          Get.toNamed(ScreenNavigationSetup.playlistNAlbumScreen,
              id: ScreenNavigationSetup.id,
              arguments: [false, playlist, false]);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            ImageWidget(
                size: 56, album: album, playlist: playlist, artist: artist),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colors.ink)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: colors.muted)),
                ],
              ),
            ),
            BeatzIcon('chev', color: colors.muted),
          ],
        ),
      ),
    );
  }
}
