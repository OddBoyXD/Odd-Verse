import 'package:harmonymusic/services/stream_service.dart'show Audio;

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
    if (json == null || json['playable'] == false) {
      return HMStreamingData(
        playable: false,
        statusMSG: json?['statusMSG'] ?? 'Unplayable track',
      );
    }
    final lowQualityAudio = json['lowQualityAudio'] != null
        ? Audio.fromJson(json['lowQualityAudio'])
        : (json['highQualityAudio'] != null
            ? Audio.fromJson(json['highQualityAudio'])
            : null);
    final highQualityAudio = json['highQualityAudio'] != null
        ? Audio.fromJson(json['highQualityAudio'])
        : lowQualityAudio;
    return HMStreamingData(
        playable: json['playable'] ?? false,
        statusMSG: json['statusMSG'] ?? '',
        lowQualityAudio: lowQualityAudio,
        highQualityAudio: highQualityAudio);
  }

  Map<String, dynamic> toJson() => {
        "playable": playable,
        "statusMSG": statusMSG,
        "lowQualityAudio": lowQualityAudio?.toJson(),
        "highQualityAudio": highQualityAudio?.toJson(),
      };
}
