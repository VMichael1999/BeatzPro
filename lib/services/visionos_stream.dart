import 'dart:convert';

import 'package:http/http.dart' as http;

import 'stream_service.dart';

/// Stream lookup through YouTube's `VISIONOS` innertube client.
///
/// Anonymous requests to the Android/iOS/web clients are cut off after ~1 MiB
/// (PO token enforcement) or rejected with a bot check. The visionOS client
/// needs neither a PO token nor a JS player, and answers with an HLS manifest
/// that carries audio-only renditions, which just_audio / AVPlayer play natively.
class VisionOsStream {
  static const _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/537.36 (KHTML, like Gecko) Version/26.0 Safari/605.1.15';
  static const _appleUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15';
  static const _clientVersion = '1.02';

  static String? _visitorData;

  static Future<String> _getVisitorData(http.Client client) async {
    if (_visitorData != null) return _visitorData!;
    final res = await client.get(
      Uri.parse('https://www.youtube.com/sw.js_data'),
      headers: {
        'user-agent': _appleUserAgent,
        'content-type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    var body = res.body;
    if (body.startsWith(")]}'")) body = body.substring(4);
    final data = json.decode(body) as List<dynamic>;
    return _visitorData = data[0][2][0][0][13] as String;
  }

  /// Returns null when the client can't provide the stream, so the caller can
  /// fall back to the regular clients.
  static Future<StreamProvider?> fetch(String videoId) async {
    final client = http.Client();
    try {
      final visitorData = await _getVisitorData(client);
      final res = await client
          .post(
            Uri.parse(
                'https://www.youtube.com/youtubei/v1/player?prettyPrint=false'),
            headers: {
              'content-type': 'application/json',
              'user-agent': _appleUserAgent,
              'x-youtube-client-name': '101',
              'x-youtube-client-version': _clientVersion,
              'x-goog-visitor-id': visitorData,
              'origin': 'https://www.youtube.com',
            },
            body: json.encode({
              'context': {
                'client': {
                  'clientName': 'VISIONOS',
                  'clientVersion': _clientVersion,
                  'deviceMake': 'Apple',
                  'deviceModel': 'RealityDevice17,1',
                  'userAgent': _appleUserAgent,
                  'osName': 'visionOS',
                  'osVersion': '26.5.23O471',
                  'hl': 'en',
                  'timeZone': 'UTC',
                  'utcOffsetMinutes': 0,
                },
              },
              'videoId': videoId,
              'contentCheckOk': true,
              'racyCheckOk': true,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final player = json.decode(res.body) as Map<String, dynamic>;
      if (player['playabilityStatus']?['status'] != 'OK') {
        // a stale visitor id is the usual cause, drop it for the next try
        _visitorData = null;
        return null;
      }
      final manifestUrl = player['streamingData']?['hlsManifestUrl'] as String?;
      if (manifestUrl == null) return null;

      final master = (await client
              .get(Uri.parse(manifestUrl), headers: {'user-agent': _userAgent})
              .timeout(const Duration(seconds: 15)))
          .body;
      final renditions = <({String url, int group, double loudness})>[];
      for (final line in master.split('\n')) {
        if (!line.startsWith('#EXT-X-MEDIA') || !line.contains('TYPE=AUDIO')) {
          continue;
        }
        final url = RegExp(r'URI="([^"]+)"').firstMatch(line)?[1];
        final group = int.tryParse(
            RegExp(r'GROUP-ID="(\d+)"').firstMatch(line)?[1] ?? '');
        if (url == null || group == null) continue;
        final loudness = double.tryParse(RegExp(r'YT-EXT-ABSOLUTE-LOUDNESS=(-?[0-9.]+)')
                    .firstMatch(line)?[1] ??
                '') ??
            0.0;
        renditions.add((url: url, group: group, loudness: loudness));
      }
      renditions.sort((a, b) => a.group.compareTo(b.group));
      if (renditions.isEmpty) return null;

      final audio = <Audio>[];
      for (var i = 0; i < renditions.length; i++) {
        final m = renditions[i];
        final isHigh = i == renditions.length - 1;
        final loudness = m.loudness;
        audio.add(Audio(
          // itags are what the quality getters of [StreamProvider] look for
          itag: isHigh ? 140 : 139,
          audioCodec: Codec.mp4a,
          bitrate: isHigh ? 128000 : 48000,
          duration: 0,
          loudnessDb: loudness,
          url: m.url,
          size: 0,
        ));
        if (renditions.length == 1) {
          audio.add(Audio(
            itag: 139,
            audioCodec: Codec.mp4a,
            bitrate: 48000,
            duration: 0,
            loudnessDb: loudness,
            url: m.url,
            size: 0,
          ));
        }
      }
      return StreamProvider(playable: true, statusMSG: "OK", audioFormats: audio);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
