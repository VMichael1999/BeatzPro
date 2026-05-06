import 'package:beatzpro/services/stream_service.dart' show Audio;

class HMStreamingData {
  final bool playable;
  final String statusMSG;
  final Audio? lowQualityAudio;
  final Audio? highQualityAudio;
  int qualityIndex = 1;

  HMStreamingData({
    required this.playable,
    required this.statusMSG,
    this.lowQualityAudio,
    this.highQualityAudio,
  });

  setQualityIndex(int index) {
    qualityIndex = index;
  }

  Audio? get audio => qualityIndex == 0 ? lowQualityAudio : highQualityAudio;

  factory HMStreamingData.fromJson(json) {
    if (json is! Map || json['playable'] != true) {
      return HMStreamingData(
        playable: false,
        statusMSG: json is Map
            ? json['statusMSG'] ?? "Stream is not playable"
            : "Invalid stream data",
      );
    }
    if (json['lowQualityAudio'] == null || json['highQualityAudio'] == null) {
      return HMStreamingData(
        playable: false,
        statusMSG: json['statusMSG'] ?? "Stream data is incomplete",
      );
    }
    final lowQualityAudio = Audio.fromJson(json['lowQualityAudio']);
    final highQualityAudio = Audio.fromJson(json['highQualityAudio']);
    return HMStreamingData(
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
