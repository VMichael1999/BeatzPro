import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/quick_picks.dart';
import '../player/player_controller.dart';
import '../utils/beatz_design.dart';
import 'beatz/beatz_icon.dart';
import 'beatz/beatz_widgets.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

/// "Selección rápida": the quick picks as song rows, with a link that plays
/// the whole list.
class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget({super.key, required this.content});
  final QuickPicks content;

  static const _maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    if (content.songList.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.beatz;
    final songs = content.songList.take(_maxRows).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeatzSectionTitle(
            _localizedTitle(content.title),
            action: 'Reproducir todo',
            onAction: () =>
                playerController.playPlayListSong(content.songList, 0),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < songs.length; i++)
            BeatzSongRow(
              cover: ImageWidget(size: 44, song: songs[i], radius: 8),
              title: songs[i].title,
              subtitle: songs[i].artist ?? '',
              onTap: () => playerController.pushSongToQueue(songs[i]),
              onLongPress: () => _openInfo(playerController, songs[i]),
              end: _end(context, playerController, songs[i], colors),
            ),
        ],
      ),
    );
  }

  Widget _end(BuildContext context, PlayerController controller,
      dynamic song, BeatzColors colors) {
    final downloaded = Hive.box("SongDownloads").containsKey(song.id);
    if (downloaded) return const DownloadedBadge();
    return BeatzIconButton(
      icon: 'more',
      tooltip: 'Más opciones',
      color: colors.muted,
      onPressed: () => _openInfo(controller, song),
    );
  }

  void _openInfo(PlayerController controller, dynamic song) {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      isScrollControlled: true,
      context: controller.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => SongInfoBottomSheet(song),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  String _localizedTitle(String title) {
    final key = title.toLowerCase().removeAllWhitespace;
    final translated = key.tr;
    if (translated != key) {
      return translated;
    }
    return title;
  }
}
