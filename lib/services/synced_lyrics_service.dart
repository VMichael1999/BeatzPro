import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:beatzpro/utils/helper.dart';
import 'package:hive/hive.dart';

class SyncedLyricsService {
  static Future<Map<String, dynamic>?> getSyncedLyrics(
      MediaItem song, int durInSec) async {
    final lyricsBox = await Hive.openBox("lyrics");
    // check if lyrics available in local database
    if (lyricsBox.containsKey(song.id)) {
      final cachedLyrics =
          Map<String, dynamic>.from(await lyricsBox.get(song.id));
      if (_hasUsableLyrics(cachedLyrics)) {
        return cachedLyrics;
      }
      await lyricsBox.delete(song.id);
    }

    final dio = Dio(BaseOptions(
      baseUrl: 'https://lrclib.net',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
    final dur = song.duration?.inSeconds ?? durInSec;
    final artist = _cleanArtist(song.artist ?? "");
    final title = _cleanSearchText(song.title);
    final album = _cleanSearchText(song.album ?? "");

    try {
      final exactResponse = await dio.get(
        '/api/get',
        queryParameters: {
          'artist_name': artist,
          'track_name': title,
          if (album.isNotEmpty) 'album_name': album,
          if (dur > 0) 'duration': dur,
        },
      );
      final exactLyrics = _lyricsFromResponse(exactResponse.data);
      if (exactLyrics != null) {
        await lyricsBox.put(song.id, exactLyrics);
        return exactLyrics;
      }
    } on DioException catch (e) {
      printERROR(e.response);
    }

    try {
      final searchQueries = [
        {
          if (artist.isNotEmpty) 'artist_name': artist,
          'track_name': title,
        },
        {'track_name': title},
        {'q': artist.isEmpty ? title : '$title $artist'},
      ];

      for (final query in searchQueries) {
        final searchResponse = await dio.get(
          '/api/search',
          queryParameters: query,
        );
        final lyricsData = _bestLyricsFromSearch(searchResponse.data, dur);
        if (lyricsData != null) {
          await lyricsBox.put(song.id, lyricsData);
          return lyricsData;
        }
      }
    } on DioException catch (e) {
      printERROR(e.response);
    } finally {
      await lyricsBox.close();
    }

    return null;
  }

  static Map<String, dynamic>? _bestLyricsFromSearch(
    dynamic response,
    int durationInSeconds,
  ) {
    if (response is! List || response.isEmpty) return null;

    final candidates = response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _lyricsFromResponse(item) != null)
        .toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aDuration = (a['duration'] as num?)?.toInt() ?? durationInSeconds;
      final bDuration = (b['duration'] as num?)?.toInt() ?? durationInSeconds;
      return (aDuration - durationInSeconds)
          .abs()
          .compareTo((bDuration - durationInSeconds).abs());
    });

    return _lyricsFromResponse(candidates.first);
  }

  static Map<String, dynamic>? _lyricsFromResponse(dynamic response) {
    if (response is! Map) return null;

    final syncedLyrics = response['syncedLyrics']?.toString() ?? "";
    final plainLyrics = response['plainLyrics']?.toString() ?? "";
    if (syncedLyrics.trim().isEmpty && plainLyrics.trim().isEmpty) {
      return null;
    }

    if (syncedLyrics.trim().isNotEmpty) {
      printINFO("Synced lyrics available");
    } else {
      printINFO("Plain lyrics available");
    }

    return {
      "synced": syncedLyrics,
      "plainLyrics": plainLyrics,
    };
  }

  static bool _hasUsableLyrics(Map<String, dynamic> lyrics) {
    final syncedLyrics = lyrics['synced']?.toString().trim() ?? "";
    final plainLyrics = lyrics['plainLyrics']?.toString().trim() ?? "";
    return syncedLyrics.isNotEmpty ||
        (plainLyrics.isNotEmpty && plainLyrics != "NA");
  }

  static String _cleanSearchText(String text) {
    return text
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(
            RegExp(r'\b(official|video|audio|lyrics?|visualizer)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(
            RegExp(r'\b(live|remastered|remaster|version)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanArtist(String artist) {
    final cleanArtist = _cleanSearchText(artist);
    if (!cleanArtist.contains('•')) return cleanArtist;

    final parts = cleanArtist
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return cleanArtist;

    final nonMetadataParts = parts
        .where((part) =>
            !RegExp(r'^(song|video)$', caseSensitive: false).hasMatch(part) &&
            !RegExp(r'\b(views?|visualizaciones|reproducciones)\b',
                    caseSensitive: false)
                .hasMatch(part))
        .toList();

    return nonMetadataParts.isEmpty ? parts.first : nonMetadataParts.last;
  }
}
