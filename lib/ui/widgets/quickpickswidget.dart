import 'package:carousel_animations/carousel_animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/models/quick_picks.dart';
import '../player/player_controller.dart';
import 'glass_widgets.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget({super.key, required this.content});
  final QuickPicks content;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    if (content.songList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 20.0),
      height: 390,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizedTitle(content.title),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                final song = content.songList[index];
                return GestureDetector(
                  onTap: () {
                    playerController.pushSongToQueue(song);
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      constraints: const BoxConstraints(maxWidth: 500),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20.0)),
                      ),
                      isScrollControlled: true,
                      context: playerController
                          .homeScaffoldkey.currentState!.context,
                      barrierColor: Colors.black.withValues(alpha: 0.6),
                      builder: (context) => SongInfoBottomSheet(song),
                    ).whenComplete(() => Get.delete<SongInfoController>());
                  },
                  child: GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    borderRadius: 28,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: "quick-pick-${song.id}",
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: ImageWidget(
                              song: song,
                              size: 150,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          song.title,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist.toString(),
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: content.songList.length,
              autoplay: true,
              autoplayDelay: 3000,
              autoplayDisableOnInteraction: true,
              loop: true,
              viewportFraction: 0.75,
              scale: 0.86,
              fade: 0.35,
            ),
          ),
        ],
      ),
    );
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
