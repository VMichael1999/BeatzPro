import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Stores the YouTube session cookies obtained from the in-app Google login.
///
/// YouTube no longer serves full-length audio to anonymous clients; the `tv`
/// client works without a PO token when the request carries a signed-in
/// session, so the cookies are attached to every youtube.com request.
class YtAuth {
  static const _prefKey = 'ytCookies';

  static String? get cookies {
    final value = Hive.box('AppPrefs').get(_prefKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  static bool get isLoggedIn => cookies != null;

  static Future<void> saveCookies(String cookies) async {
    await Hive.box('AppPrefs').put(_prefKey, cookies);
    // Cached stream urls were generated for an anonymous session.
    await Hive.box('SongsUrlCache').clear();
  }

  static Future<void> clear() async {
    await Hive.box('AppPrefs').delete(_prefKey);
    await Hive.box('SongsUrlCache').clear();
  }

  /// Value of the `Authorization` header for the given cookie string.
  static String? sapisidHash(String cookies, {String origin = _origin}) {
    final sapisid = RegExp(r'(?:^|;\s*)(?:__Secure-3PAPISID|SAPISID)=([^;]+)')
        .firstMatch(cookies)
        ?.group(1);
    if (sapisid == null) return null;
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hash = sha1.convert(utf8.encode('$ts $sapisid $origin')).toString();
    return 'SAPISIDHASH ${ts}_$hash';
  }

  static const _origin = 'https://www.youtube.com';
}

/// [YoutubeHttpClient] that sends the signed-in session with every request
/// made to youtube.com.
class AuthYoutubeHttpClient extends YoutubeHttpClient {
  final String cookies;

  AuthYoutubeHttpClient(this.cookies);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host.endsWith('youtube.com')) {
      request.headers['cookie'] = cookies;
      final auth = YtAuth.sapisidHash(cookies);
      if (auth != null) {
        request.headers['authorization'] = auth;
        request.headers['x-goog-authuser'] = '0';
        request.headers['x-origin'] = 'https://www.youtube.com';
      }
    }
    return super.send(request);
  }
}
