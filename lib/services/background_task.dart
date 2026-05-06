import 'dart:core';
import 'package:flutter/services.dart';

import '/services/stream_service.dart';

//Not in use for now
// Future<List<String>?> getSongUrlFromPiped(String songId,
//     {String defaultUrl = "https://pipedapi.kavin.rocks"}) async {
//   try {
//     if (songId.substring(0, 4) == "MPED") {
//       songId = songId.substring(4);
//     }
//     final response = await Dio().get("$defaultUrl/streams/$songId");
//     if (response.statusCode == 200) {
//       final audioStream = response.data["audioStreams"] as List;
//       final x =
//           audioStream.firstWhere((item) => (item['itag'].toString() == "251"));

//       final y =
//           audioStream.firstWhere((item) => (item['itag'].toString() == "251"));

//       return [y['url'], x['url']];
//     } else {
//       return null;
//     }
//   } catch (e) {
//     return null;
//   }
// }

Future<List<String>?> getSongUrlFromExplode(String songId) async {
  if (songId.substring(0, 4) == "MPED") {
    songId = songId.substring(4);
  }
  final streamProvider = await StreamProvider.fetch(songId);
  return streamProvider.legacyUrlList;
}

Future<List<String>?> getSongUrlFromExplodeIsolate(
    String songId, RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  return getSongUrlFromExplode(songId);
}
