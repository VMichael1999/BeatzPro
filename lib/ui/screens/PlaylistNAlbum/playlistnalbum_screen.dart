import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/services/downloader.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/playlist.dart';
import '../../player/player_controller.dart';
import '../../utils/beatz_design.dart';
import '../../widgets/beatz/beatz_icon.dart';
import '../../widgets/beatz/cover_tint.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/loader.dart';
import '../../widgets/modification_list.dart';
import '../Library/library_controller.dart';
import '/ui/navigator.dart';
import 'playlistnalbum_screen_controller.dart';
import '/ui/widgets/create_playlist_dialog.dart';
import '/ui/widgets/list_widget.dart';
import '/ui/widgets/shimmer_widgets/song_list_shimmer.dart';
import '/ui/widgets/snackbar.dart';
import '/ui/widgets/sort_widget.dart';

class PlaylistNAlbumScreen extends StatelessWidget {
  ///PlaylistScreen renders playlist content
  ///
  ///Playlist title,image,songs
  const PlaylistNAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final PlayListNAlbumScreenController controller =
        (Get.isRegistered<PlayListNAlbumScreenController>(tag: tag))
            ? Get.find<PlayListNAlbumScreenController>(tag: tag)
            : Get.put(PlayListNAlbumScreenController(), tag: tag);
    final colors = context.beatz;

    return Obx(() {
      if (controller.isContentFetched.isFalse) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(controller: controller, content: null),
                const Expanded(child: Center(child: LoadingIndicator())),
              ],
            ),
          ),
        );
      }
      final content = controller.contentRenderer;
      final coverUrl = controller.isAlbum
          ? content.thumbnailUrl
          : (content.isCloudPlaylist ? content.thumbnailUrl : "") as String;
      return Scaffold(
        backgroundColor: colors.bg,
        body: CoverTint(
          imageUrl: coverUrl,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(controller: controller, content: content),
                Expanded(
                    child: _Body(controller: controller, content: content)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.content});

  final PlayListNAlbumScreenController controller;
  final dynamic content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BeatzIconButton(
            icon: 'back',
            iconSize: 24,
            tooltip: 'Volver',
            onPressed: () =>
                Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop(),
          ),
          if (content != null)
            BeatzIconButton(
              icon: 'more',
              iconSize: 24,
              tooltip: 'Más opciones',
              onPressed: () => _openMore(context, controller, content),
            ),
        ],
      ),
    );
  }
}

String _minutesLabel(Iterable<dynamic> songs) {
  var seconds = 0;
  for (final s in songs) {
    final d = s.duration as Duration?;
    if (d != null) {
      seconds += d.inSeconds;
    } else {
      final length = (s.extras?['length'] ?? '').toString();
      final parts = length.split(':').map(int.tryParse).toList();
      if (parts.length == 2 && parts.every((e) => e != null)) {
        seconds += parts[0]! * 60 + parts[1]!;
      }
    }
  }
  return seconds == 0 ? '' : '${(seconds / 60).round()} min';
}

class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.content});

  final PlayListNAlbumScreenController controller;
  final dynamic content;

  bool get _isLocal => !controller.isAlbum && !content.isCloudPlaylist;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Obx(() {
      final inOperation =
          controller.additionalOperationMode.value != OperationMode.none;
      if (inOperation) {
        return Column(
          children: [
            _title(context, colors),
            _sortBar(),
            ModificationList(
              mode: controller.additionalOperationMode.value,
              playListNAlbumScreenController: controller,
            ),
          ],
        );
      }
      if (!controller.isContentFetched.value) {
        return const SongListShimmer();
      }
      final songs = controller.songList.toList();
      final list = ListWidget(songs, "Songs", true,
          isPlaylist: true,
          playlist: !controller.isAlbum ? content as Playlist : null);
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _header(context, colors, songs);
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _sortBar(),
            );
          }
          if (songs.isEmpty) return null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: list.songRow(context, songs, index - 2),
          );
        },
      );
    });
  }

  Widget _title(BuildContext context, BeatzColors colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.ink)),
        ),
      );

  Widget _sortBar() {
    final id = controller.isAlbum ? content.browseId : content.playlistId;
    return Obx(() => SortWidget(
          tag: id,
          isSearchFeatureRequired: true,
          itemCountTitle: "${controller.songList.length}",
          itemIcon: Icons.music_note_rounded,
          titleLeftPadding: 9,
          requiredSortTypes: buildSortTypeSet(false, true),
          isPlaylistRearrageFeatureRequired: _isLocal &&
              content.playlistId != "LIBRP" &&
              content.playlistId != "SongDownloads" &&
              content.playlistId != "SongsCache",
          isSongDeletetioFeatureRequired: _isLocal,
          onSort: controller.onSort,
          onSearch: controller.onSearch,
          onSearchClose: controller.onSearchClose,
          onSearchStart: controller.onSearchStart,
          startAdditionalOperation: controller.startAdditionalOperation,
          selectAll: controller.selectAll,
          performAdditionalOperation: controller.performAdditionalOperation,
          cancelAdditionalOperation: controller.cancelAdditionalOperation,
        ));
  }

  Widget _header(BuildContext context, BeatzColors colors, List songs) {
    final player = Get.find<PlayerController>();
    final isAlbum = controller.isAlbum;
    final count = songs.length;
    final minutes = _minutesLabel(songs);
    final meta = <String>[
      if (isAlbum) ...[
        (content.artists as List?)
                ?.map((a) => a['name'])
                .where((n) => n != null && n.toString().isNotEmpty)
                .join(', ') ??
            '',
        content.year ?? '',
      ] else if (!_isLocal)
        content.description ?? '',
      '$count ${count == 1 ? 'canción' : 'canciones'}',
      minutes,
    ].where((e) => e.toString().isNotEmpty).join(' · ');
    final id = isAlbum ? content.browseId : content.playlistId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Column(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 40,
                    offset: Offset(0, 18)),
              ],
            ),
            child: _cover(colors),
          ),
          const SizedBox(height: 14),
          Text(content.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.ink)),
          const SizedBox(height: 4),
          Text(meta,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Reproducir',
                  child: Material(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: songs.isEmpty
                          ? null
                          : () => player.playPlayListSong(List.from(songs), 0),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BeatzIcon('play', filled: true, color: colors.bg),
                            const SizedBox(width: 8),
                            Text('Reproducir',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: colors.bg)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BeatzIconButton(
                icon: 'shuffle',
                tooltip: 'Aleatorio',
                background: colors.surface,
                onPressed: songs.isEmpty
                    ? null
                    : () {
                        final shuffled = List.from(songs)..shuffle();
                        player.playPlayListSong(shuffled.cast(), 0);
                      },
              ),
              if (!_isLocal && !(!isAlbum && content.isPipedPlaylist)) ...[
                const SizedBox(width: 10),
                Obx(() {
                  final added = controller.isAddedToLibrary.value;
                  final label = isAlbum
                      ? (added ? 'Quitar álbum' : 'Guardar álbum')
                      : (added ? 'Quitar lista' : 'Guardar lista');
                  return BeatzIconButton(
                    icon: added ? 'check' : 'plus',
                    tooltip: label,
                    background: colors.surface,
                    color: added ? colors.good : colors.ink,
                    onPressed: () => _toggleLibrary(context, added),
                  );
                }),
              ],
            ],
          ),
          _downloadProgress(context, colors, id, count),
        ],
      ),
    );
  }

  Widget _cover(BeatzColors colors) {
    if (controller.isAlbum) {
      return ImageWidget(size: 180, album: content, radius: 12);
    }
    if (content.isCloudPlaylist) {
      return ImageWidget(size: 180, playlist: content, radius: 12);
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
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: BeatzIcon(icon,
            size: 56,
            color: id == 'LIBFAV' ? BeatzColors.heart : colors.ink,
            filled: id == 'LIBFAV'),
      ),
    );
  }

  /// "Descargando 7 de 11" with a thin bar (`.prog` in the design).
  Widget _downloadProgress(
      BuildContext context, BeatzColors colors, String id, int total) {
    final downloader = Get.find<Downloader>();
    return Obx(() {
      final queued = downloader.playlistQueue.containsKey(id);
      final active = queued && downloader.currentPlaylistId.toString() == id;
      final done = controller.isDownloaded.isTrue;
      if (!queued && !done) return const SizedBox.shrink();
      final progress = downloader.playlistDownloadingProgress.value;
      final fraction = done
          ? 1.0
          : (active && total > 0 ? math.min(progress / total, 1.0) : 0.0);
      final label = done
          ? 'Descargada'
          : active
              ? 'Descargando $progress de $total'
              : 'En cola para descargar';
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            BeatzIcon(done ? 'check' : 'dl', size: 16, color: colors.good),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 4,
                  color: colors.good,
                  backgroundColor: colors.line,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _toggleLibrary(BuildContext context, bool added) {
    final add = !added;
    final messenger = ScaffoldMessenger.of(context);
    controller.addNremoveFromLibrary(content, add: add).then((value) {
      messenger.showSnackBar(snackbar(
          Get.context!,
          value
              ? add
                  ? controller.isAlbum
                      ? "albumBookmarkAddAlert".tr
                      : "playlistBookmarkAddAlert".tr
                  : controller.isAlbum
                      ? "albumBookmarkRemoveAlert".tr
                      : "playlistBookmarkRemoveAlert".tr
              : "operationFailed".tr,
          size: SanckBarSize.MEDIUM));
    });
  }
}

/// Bottom sheet with the secondary actions of the album / playlist.
void _openMore(BuildContext context, PlayListNAlbumScreenController controller,
    dynamic content) {
  final colors = context.beatz;
  final player = Get.find<PlayerController>();
  final downloader = Get.find<Downloader>();
  final isAlbum = controller.isAlbum;
  final isLocal = !isAlbum && !content.isCloudPlaylist;
  final isPiped = !isAlbum && content.isPipedPlaylist;
  final canRename = isLocal &&
      content.playlistId != "LIBFAV" &&
      content.playlistId != "SongsCache" &&
      content.playlistId != "LIBRP" &&
      content.playlistId != "SongDownloads";
  final id = isAlbum ? content.browseId : content.playlistId;

  Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: colors.muted),
        title: Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink)),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      );

  showModalBottomSheet(
    constraints: const BoxConstraints(maxWidth: 500),
    context: player.homeScaffoldkey.currentState!.context,
    barrierColor: Colors.black54,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: colors.line, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 6),
          tile(Icons.queue_music_rounded, 'enqueueAll'.tr, () {
            player.enqueueSongList(controller.songList.toList()).whenComplete(
                () => ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                    Get.context!, "songEnqueueAlert".tr,
                    size: SanckBarSize.MEDIUM)));
          }),
          if (!isLocal || canRename)
            tile(
                controller.isDownloaded.isTrue
                    ? Icons.download_done_rounded
                    : Icons.download_rounded,
                controller.isDownloaded.isTrue ? 'Descargada' : 'Descargar',
                () {
              if (controller.isDownloaded.isTrue) return;
              downloader.downloadPlaylist(id, controller.songList.toList());
            }),
          if (!isLocal)
            tile(Icons.share_rounded, 'Compartir', () {
              if (isAlbum) {
                Share.share(
                    "https://youtube.com/playlist?list=${content.audioPlaylistId}");
              } else if (isPiped) {
                Share.share(
                    "https://piped.video/playlist?list=${content.playlistId}");
              } else {
                final hasPrefix = content.playlistId.substring(0, 2) == "VL";
                Share.share(
                    "https://youtube.com/playlist?list=${hasPrefix ? content.playlistId.substring(2) : content.playlistId}");
              }
            }),
          if (controller.isAddedToLibrary.isTrue)
            tile(Icons.cloud_sync_rounded, 'Sincronizar',
                controller.syncPlaylistNAlbumSong),
          if (isPiped)
            tile(Icons.block_rounded, 'Ocultar lista', () {
              Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
              Get.find<LibraryPlaylistsController>()
                  .blacklistPipedPlaylist(content as Playlist);
              ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                  Get.context!, "playlistBlacklistAlert".tr,
                  size: SanckBarSize.MEDIUM));
            }),
          if (canRename) ...[
            tile(Icons.edit_rounded, "renamePlaylist".tr, () {
              showDialog(
                context: Get.context!,
                builder: (context) => CreateNRenamePlaylistPopup(
                    renamePlaylist: true, playlist: content),
              );
            }),
            tile(Icons.delete_rounded, "removePlaylist".tr, () {
              controller.addNremoveFromLibrary(content, add: false).then((v) {
                Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
                ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                    Get.context!,
                    v ? "playlistRemovedAlert".tr : "operationFailed".tr,
                    size: SanckBarSize.MEDIUM));
              });
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
