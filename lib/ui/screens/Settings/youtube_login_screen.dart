import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '/services/yt_auth.dart';

/// Google sign-in inside a WebView. The credentials are typed by the user on
/// Google's own page; the app only keeps the resulting YouTube cookies.
class YoutubeLoginScreen extends StatefulWidget {
  const YoutubeLoginScreen({super.key});

  @override
  State<YoutubeLoginScreen> createState() => _YoutubeLoginScreenState();
}

class _YoutubeLoginScreenState extends State<YoutubeLoginScreen> {
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-A035M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  bool _saving = false;

  Future<bool> _captureCookies() async {
    final manager = CookieManager.instance();
    final all = <String, String>{};
    for (final url in [
      'https://www.youtube.com',
      'https://music.youtube.com',
      'https://accounts.google.com',
    ]) {
      final cookies = await manager.getCookies(url: WebUri(url));
      for (final c in cookies) {
        all[c.name] = c.value.toString();
      }
    }
    final hasSession = all.containsKey('SAPISID') ||
        all.containsKey('__Secure-3PAPISID');
    if (!hasSession) return false;
    final header = all.entries.map((e) => '${e.key}=${e.value}').join('; ');
    await YtAuth.saveCookies(header);
    return true;
  }

  Future<void> _tryFinish() async {
    if (_saving) return;
    _saving = true;
    final ok = await _captureCookies();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube'),
        actions: [
          TextButton(onPressed: _tryFinish, child: const Text('Listo')),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
              'https://accounts.google.com/ServiceLogin?service=youtube&continue=https%3A%2F%2Fmusic.youtube.com%2F'),
        ),
        initialSettings: InAppWebViewSettings(
          userAgent: _userAgent,
          javaScriptEnabled: true,
          thirdPartyCookiesEnabled: true,
        ),
        onLoadStop: (controller, url) async {
          if (url?.host == 'music.youtube.com') {
            await _tryFinish();
          }
        },
      ),
    );
  }
}
