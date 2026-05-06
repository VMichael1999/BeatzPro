import 'package:carousel_animations/carousel_animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/models/quick_picks.dart';
import '../player/player_controller.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget({super.key, required this.content});
  final QuickPicks content;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 20.0),
      height:
          400, // Aumentar un poco la altura para acomodar la imagen más grande
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title.toLowerCase().removeAllWhitespace.tr,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                      barrierColor: Colors.black.withOpacity(0.6),
                      builder: (context) => SongInfoBottomSheet(song),
                    ).whenComplete(() => Get.delete<SongInfoController>());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Colors.black87
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: ImageWidget(
                            song: song,
                            size:
                                150, // Tamaño más grande para destacar la imagen
                          ),
                        ),
                        const SizedBox(height: 20), // Mayor separación
                        Text(
                          song.title,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10), // Mayor separación
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
              viewportFraction:
                  0.75, // Reducido para dar más espacio a la imagen
              scale: 0.85, // Ligera reducción para destacar la imagen central
              fade: 0.4, // Aumentado para una transición más suave
              // control: const SwiperControl(
              //   color: Colors.white, // Color de las flechas
              //   padding: EdgeInsets.symmetric(horizontal: 20.0), // Espacio alrededor de las flechas
              //   size: 24.0, // Tamaño de las flechas
              // ),
            ),
          ),
        ],
      ),
    );
  }
}
