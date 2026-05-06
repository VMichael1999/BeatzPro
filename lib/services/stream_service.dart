import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final String statusMSG;

  StreamProvider({
    required this.playable,
    this.audioFormats,
    this.statusMSG = "",
  });

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode();

    try {
      final res = await yt.videos.streamsClient.getManifest(videoId);
      final audio = res.audioOnly;
      return StreamProvider(
        playable: true,
        statusMSG: "OK",
        audioFormats: audio
            .map((e) => Audio(
                  itag: e.tag,
                  audioCodec:
                      e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
                  bitrate: e.bitrate.bitsPerSecond,
                  duration: e.duration ?? 0,
                  loudnessDb: e.loudnessDb,
                  url: e.url.toString(),
                  size: e.size.totalBytes,
                ))
            .toList(),
      );
    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(playable: false, statusMSG: "networkError");
      } else if (e is VideoUnplayableException) {
        return StreamProvider(
            playable: false, statusMSG: e.reason ?? "Song is unplayable");
      } else if (e is VideoRequiresPurchaseException) {
        return StreamProvider(
            playable: false, statusMSG: "Song requires purchase");
      } else if (e is VideoUnavailableException) {
        return StreamProvider(
            playable: false, statusMSG: "Song is unavailable");
      } else if (e is YoutubeExplodeException) {
        return StreamProvider(playable: false, statusMSG: e.message);
      } else {
        return StreamProvider(
            playable: false, statusMSG: "Unknown error occurred");
      }
    } finally {
      yt.close();
    }
  }

  Audio? get highestQualityAudio => audioFormats?.lastWhere(
        (item) => item.itag == 251 || item.itag == 140,
        orElse: () => audioFormats!.first,
      );

  Audio? get lowQualityAudio => audioFormats?.lastWhere(
        (item) => item.itag == 249 || item.itag == 139,
        orElse: () => audioFormats!.first,
      );

  List<String>? get legacyUrlList {
    if (!playable || audioFormats == null || audioFormats!.isEmpty) {
      return null;
    }
    return [
      lowQualityAudio?.url ?? audioFormats!.first.url,
      highestQualityAudio?.url ?? audioFormats!.last.url,
    ];
  }
}

class Audio {
  final int itag;
  final Codec audioCodec;
  final int bitrate;
  final int duration;
  final int size;
  final double loudnessDb;
  final String url;

  Audio({
    required this.itag,
    required this.audioCodec,
    required this.bitrate,
    required this.duration,
    required this.loudnessDb,
    required this.url,
    required this.size,
  });
}

enum Codec { mp4a, opus }
