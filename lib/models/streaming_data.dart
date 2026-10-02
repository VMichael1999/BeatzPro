import 'dart:io';

import 'package:beatzpro/services/stream_service.dart' show Audio, Codec;

bool get _usesAppleAudioBackend => Platform.isIOS || Platform.isMacOS;

class BeatzStreamingData {
  final bool playable;
  final String statusMSG;
  final Audio? lowQualityAudio;
  final Audio? highQualityAudio;
  int qualityIndex = 1;

  BeatzStreamingData({
    required this.playable,
    required this.statusMSG,
    this.lowQualityAudio,
    this.highQualityAudio,
  });

  setQualityIndex(int index) {
    qualityIndex = index;
  }

  Audio? get audio {
    if (_usesAppleAudioBackend) {
      if (highQualityAudio?.audioCodec == Codec.mp4a) {
        return highQualityAudio;
      }
      if (lowQualityAudio?.audioCodec == Codec.mp4a) {
        return lowQualityAudio;
      }
      return null;
    }
    return qualityIndex == 0 ? lowQualityAudio : highQualityAudio;
  }

  factory BeatzStreamingData.fromJson(json) {
    if (json is! Map || json['playable'] != true) {
      return BeatzStreamingData(
        playable: false,
        statusMSG: json is Map
            ? json['statusMSG'] ?? "Stream is not playable"
            : "Invalid stream data",
      );
    }
    if (json['lowQualityAudio'] == null || json['highQualityAudio'] == null) {
      return BeatzStreamingData(
        playable: false,
        statusMSG: json['statusMSG'] ?? "Stream data is incomplete",
      );
    }
    final lowQualityAudio = Audio.fromJson(json['lowQualityAudio']);
    final highQualityAudio = Audio.fromJson(json['highQualityAudio']);
    return BeatzStreamingData(
      playable: json['playable'],
      statusMSG: json['statusMSG'],
      lowQualityAudio: lowQualityAudio,
      highQualityAudio: highQualityAudio,
    );
  }

  Map<String, dynamic> toJson() => {
        "playable": playable,
        "statusMSG": statusMSG,
        "lowQualityAudio": lowQualityAudio?.toJson(),
        "highQualityAudio": highQualityAudio?.toJson(),
      };
}
