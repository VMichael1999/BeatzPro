import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../screens/Settings/settings_screen_controller.dart';
import '/models/artist.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';
import 'premium_surface.dart';

class ImageWidget extends StatelessWidget {
  const ImageWidget({
    super.key,
    this.song,
    this.playlist,
    this.album,
    this.artist,
    required this.size,
    this.isPlayerArtImage = false,
  });
  final MediaItem? song;
  final Playlist? playlist;
  final Album? album;
  final bool isPlayerArtImage;
  final Artist? artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    String imageUrl = song != null
        ? song!.artUri.toString()
        : playlist != null
            ? playlist!.thumbnailUrl
            : album != null
                ? album!.thumbnailUrl
                : artist != null
                    ? artist!.thumbnailUrl
                    : "";
    // String cacheKey = song != null
    //     ? "${song!.id}_song"
    //     : playlist != null
    //         ? "${playlist!.playlistId}_playlist"
    //         : album != null
    //             ? "${album!.browseId}_album"
    //             : artist != null
    //                 ? "${artist!.browseId}_artist"
    //                 : "";

    /// only valid for offline songs
    final bool offlineAvailable =
        song != null && (song?.extras?["url"] ?? "").contains("file");

    final radius = isPlayerArtImage ? size / 2 : 8.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: (artist != null || isPlayerArtImage)
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: (artist != null || isPlayerArtImage)
            ? null
            : BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: PremiumColors.violet.withOpacity(0.22),
            blurRadius: isPlayerArtImage ? 38 : 18,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: (artist != null || isPlayerArtImage)
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(radius),
        child: offlineAvailable
            ? Image.file(
                File(
                    "${Get.find<SettingsScreenController>().supportDirPath}/thumbnails/${song!.id}.png"),
                height: size,
                width: size,
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                height: size,
                width: size,
                memCacheHeight:
                    (song != null && !isPlayerArtImage) ? 140 : null,
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: PremiumColors.accentGradient,
                        shape: (artist != null || isPlayerArtImage)
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: (artist != null || isPlayerArtImage)
                            ? null
                            : BorderRadius.circular(radius),
                      ),
                      child: Image.asset(
                          "assets/icons/${song != null ? "song" : artist != null ? "artist" : "album"}.png"));
                },
                progressIndicatorBuilder: ((_, __, ___) => Shimmer.fromColors(
                    baseColor: PremiumColors.graphite,
                    highlightColor: Colors.white24,
                    enabled: true,
                    direction: ShimmerDirection.ltr,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: (artist != null || isPlayerArtImage)
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: (artist != null || isPlayerArtImage)
                            ? null
                            : BorderRadius.circular(radius),
                        color: Colors.white54,
                      ),
                    ))),
              ),
      ),
    );
  }
}
