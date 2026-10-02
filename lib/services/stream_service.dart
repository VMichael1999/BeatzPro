import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'visionos_stream.dart';
import 'yt_auth.dart';

bool get _usesAppleAudioBackend => Platform.isIOS || Platform.isMacOS;

/// Clients tried in order; YouTube blocks some of them depending on the video.
/// androidVr goes first: it is the only one of these that does not need a
/// PO token for full-length audio (the others are cut with 403 after ~1 MiB).
const playerClients = [
  YoutubeApiClient.androidVr,
  YoutubeApiClient.androidSdkless,
  YoutubeApiClient.android,
];

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final String statusMSG;

  StreamProvider({
    required this.playable,
    this.audioFormats,
    this.statusMSG = "",
  });

  /// [cookies] is the signed-in YouTube session (see [YtAuth]); it has to be
  /// passed in explicitly because this also runs inside isolates.
  static Future<StreamProvider> fetch(String videoId, {String? cookies}) async {
    final visionOs = await VisionOsStream.fetch(videoId);
    if (visionOs != null) return visionOs;

    final signedIn = cookies != null && cookies.isNotEmpty;
    final yt = signedIn
        ? YoutubeExplode(httpClient: AuthYoutubeHttpClient(cookies))
        : YoutubeExplode();

    try {
      final res = await yt.videos.streamsClient.getManifest(videoId,
          ytClients: signedIn
              ? [YoutubeApiClient.tv, ...playerClients]
              : playerClients);
      final audio = res.audioOnly;
      if (audio.isEmpty) {
        return StreamProvider(
          playable: false,
          statusMSG: "No audio stream available",
        );
      }
      return StreamProvider(
        playable: true,
        statusMSG: "OK",
        audioFormats: audio
            .map((e) => Audio(
                  itag: e.tag,
                  audioCodec:
                      e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
                  bitrate: e.bitrate.bitsPerSecond,
                  duration: 0,
                  loudnessDb: 0,
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
            playable: false, statusMSG: "Song is unplayable");
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

  Audio? get highestQualityAudio =>
      audioFormats == null || audioFormats!.isEmpty
          ? null
          : _usesAppleAudioBackend
              ? highestBitrateMp4aAudio
              : audioFormats!.lastWhere(
                  (item) => item.itag == 251 || item.itag == 140,
                  orElse: () => audioFormats!.first,
                );

  Audio? get highestBitrateMp4aAudio =>
      audioFormats == null || audioFormats!.isEmpty
          ? null
          : audioFormats!.lastWhere(
              (item) => item.itag == 140 || item.itag == 139,
              orElse: () => audioFormats!.first,
            );

  Audio? get highestBitrateOpusAudio =>
      audioFormats == null || audioFormats!.isEmpty
          ? null
          : audioFormats!.lastWhere(
              (item) => item.itag == 251 || item.itag == 250,
              orElse: () => audioFormats!.first,
            );

  Audio? get lowQualityAudio => audioFormats == null || audioFormats!.isEmpty
      ? null
      : _usesAppleAudioBackend
          ? audioFormats!.lastWhere(
              (item) => item.itag == 139,
              orElse: () => highestBitrateMp4aAudio ?? audioFormats!.first,
            )
          : audioFormats!.lastWhere(
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

  Map<String, dynamic> get streamingData {
    final lowQuality = lowQualityAudio;
    final highQuality = highestQualityAudio;
    final hasAudio = lowQuality != null && highQuality != null;
    return {
      "playable": playable && hasAudio,
      "statusMSG": hasAudio ? statusMSG : "No audio stream available",
      "lowQualityAudio": lowQuality?.toJson(),
      "highQualityAudio": highQuality?.toJson(),
    };
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

  Map<String, dynamic> toJson() => {
        "itag": itag,
        "audioCodec": audioCodec.toString(),
        "bitrate": bitrate,
        "loudnessDb": loudnessDb,
        "url": url,
        "approxDurationMs": duration,
        "size": size,
      };

  factory Audio.fromJson(json) => Audio(
        audioCodec: (json["audioCodec"] as String).contains("mp4a")
            ? Codec.mp4a
            : Codec.opus,
        itag: json['itag'],
        duration: json["approxDurationMs"] ?? 0,
        bitrate: json["bitrate"] ?? 0,
        loudnessDb: (json['loudnessDb'])?.toDouble() ?? 0.0,
        url: json['url'],
        size: json["size"] ?? 0,
      );
}

enum Codec { mp4a, opus }
