import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:device_equalizer/device_equalizer.dart';

import '../ui/screens/Home/home_screen_controller.dart';
import '/services/background_task.dart';
import '/services/permission_service.dart';
import '../utils/helper.dart';
import '/models/hm_streaming_data.dart';
import '/models/media_Item_builder.dart';
import '/services/stream_service.dart';
import '/services/utils.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '../ui/screens/Library/library_controller.dart';
// ignore: unused_import, implementation_imports, depend_on_referenced_packages
import "package:media_kit/src/player/platform_player.dart" show MPVLogLevel;

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationIcon: 'drawable/ic_stat_beatzpro',
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'BeatzPro Notification',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with GetxServiceMixin {
  // ignore: prefer_typing_uninitialized_variables
  late final _cacheDir;
  late AudioPlayer _player;
  // ignore: prefer_typing_uninitialized_variables
  var currentIndex;
  late String? currentSongUrl;
  bool isPlayingUsingLockCachingSource = false;
  bool loopModeEnabled = false;
  var networkErrorPause = false;
  bool isSongLoading = true;
  int _playerErrorRetries = 0;
  String? _lastPlayerErrorSongId;
  bool _isAutoAdvancing = false;
  DeviceEqualizer? deviceEqualizer;

  final _playList = ConcatenatingAudioSource(
    children: [],
  );
  LibrarySongsController librarySongsController =
      Get.find<LibrarySongsController>();

  MyAudioHandler() {
    if (GetPlatform.isWindows || GetPlatform.isLinux) {
      JustAudioMediaKit.title = 'BeatzPro';
      JustAudioMediaKit.protocolWhitelist = const ['http', 'https', 'file'];
    }
    _player = AudioPlayer();
    _createCacheDir();
    _addEmptyList();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenToPlaybackForNextSong();
    _listenForSequenceStateChanges();
    _player
        .setSkipSilenceEnabled(Hive.box("appPrefs").get("skipSilenceEnabled"));
    loopModeEnabled = Hive.box("appPrefs").get("isLoopModeEnabled") ?? false;
    if (GetPlatform.isAndroid) {
      deviceEqualizer = DeviceEqualizer();
      _listenSessionIdStream();
    }
  }

  Future<void> _createCacheDir() async {
    _cacheDir = (await getTemporaryDirectory()).path;
    if (!Directory("$_cacheDir/cachedSongs/").existsSync()) {
      Directory("$_cacheDir/cachedSongs/").createSync(recursive: true);
    }
  }

  void _addEmptyList() {
    try {
      _player.setAudioSource(_playList);
    } catch (r) {
      printERROR(r.toString());
    }
  }

  void _listenSessionIdStream() {
    _player.androidAudioSessionIdStream.listen((int? id) {
      if (id != null) {
        deviceEqualizer?.initAudioEffect(id);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: isSongLoading
            ? AudioProcessingState.loading
            : const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: currentIndex,
      ));

      //print("set ${playbackState.value.queueIndex},${event.currentIndex}");
    }, onError: (Object e, StackTrace st) async {
      if (e is PlayerException) {
        printERROR('Error code: ${e.code}');
        printERROR('Error message: ${e.message}');
      } else {
        printERROR('An error occurred: $e');
        final box = Hive.box("SongsUrlCache");
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && box.containsKey(currentMediaItem.id)) {
          final cachedInfo = box.get(currentMediaItem.id);
          String? cachedUrl;
          if (cachedInfo is Map) {
            final highQualityAudio = cachedInfo['highQualityAudio'];
            final lowQualityAudio = cachedInfo['lowQualityAudio'];
            cachedUrl = highQualityAudio is Map
                ? highQualityAudio['url']
                : lowQualityAudio is Map
                    ? lowQualityAudio['url']
                    : null;
          } else if (cachedInfo is List && cachedInfo.length > 1) {
            cachedUrl = cachedInfo[1];
          }
          if (isExpired(url: cachedUrl)) {
            await _player.stop();
            await customAction("playByIndex", {'index': currentIndex});
            return;
          }
        }
        if (isPlayingUsingLockCachingSource &&
            e.toString().contains("Connection closed while receiving data")) {
          Duration curPos = _player.position;
          await _player.stop();
          await _player.seek(curPos, index: 0);
          await _player.play();
        }

        final shouldRetry = _shouldRetryPlayerError(e);
        if (!shouldRetry) {
          await _player.stop();
          currentSongUrl = null;
          isSongLoading = false;
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            errorCode: 500,
            errorMessage: e.toString(),
          ));
          return;
        }

        customAction("playByIndex", {'index': currentIndex, 'newUrl': true})
            .whenComplete(() async {
          await _player.stop();
          if (currentSongUrl == null) {
            networkErrorPause = true;
          } else {
            _player.play();
          }
        });
      }
    });
  }

  bool _shouldRetryPlayerError(Object error) {
    final currentMediaItem = mediaItem.value;
    final songId = currentMediaItem?.id;
    if (songId == null) return false;
    if (_lastPlayerErrorSongId != songId) {
      _lastPlayerErrorSongId = songId;
      _playerErrorRetries = 0;
    }
    if (_playerErrorRetries >= 1) return false;

    final message = error.toString();
    final canRefreshUrl = message.contains("Connection closed") ||
        message.contains("403") ||
        message.contains("-11828") ||
        message.contains("Cannot Open");
    if (!canRefreshUrl) return false;

    _playerErrorRetries += 1;
    return true;
  }

  void _listenToPlaybackForNextSong() {
    final playerDurationOffset = _usesAppleDurationGuard
        ? 500
        : GetPlatform.isWindows
            ? 200
            : GetPlatform.isLinux
                ? 700
                : 0;
    _player.positionStream.listen((value) async {
      final duration = _completionDuration;
      if (duration != null && duration.inSeconds != 0) {
        if (value.inMilliseconds >=
            (duration.inMilliseconds - playerDurationOffset)) {
          await _triggerNext();
        }
      }
    });
    _player.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        await _triggerNext();
      }
    });
  }

  Future<void> _triggerNext() async {
    if (_isAutoAdvancing) return;
    _isAutoAdvancing = true;
    try {
      if (loopModeEnabled) {
        await _player.seek(Duration.zero);
        if (!_player.playing) {
          await _player.play();
        }
        return;
      }
      await skipToNext();
    } finally {
      _isAutoAdvancing = false;
    }
  }

  Duration? get _completionDuration {
    if (_usesAppleDurationGuard) {
      final metadataDuration = mediaItem.value?.duration;
      if (metadataDuration != null && metadataDuration > Duration.zero) {
        return metadataDuration;
      }
    }
    return _player.duration;
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) async {
      var index = currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(
        duration: _resolveDisplayDuration(oldMediaItem.duration, duration),
      );
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  Duration? _resolveDisplayDuration(
    Duration? metadataDuration,
    Duration? playerDuration,
  ) {
    if (playerDuration == null || playerDuration <= Duration.zero) {
      return metadataDuration;
    }
    if (metadataDuration == null || metadataDuration <= Duration.zero) {
      return playerDuration;
    }
    if (!_usesAppleDurationGuard) {
      return playerDuration;
    }

    final metadataMs = metadataDuration.inMilliseconds;
    final playerMs = playerDuration.inMilliseconds;
    final toleranceMs = math.max(5000, (metadataMs * 0.05).round());
    if ((metadataMs - playerMs).abs() > toleranceMs) {
      printWarning(
        "Ignoring Apple stream duration $playerDuration; metadata duration is $metadataDuration",
      );
      return metadataDuration;
    }
    return playerDuration;
  }

  bool get _usesAppleDurationGuard => GetPlatform.isIOS || GetPlatform.isMacOS;

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    final newQueue = this.queue.value
      ..replaceRange(0, this.queue.value.length, queue);
    this.queue.add(newQueue);
    final index = currentIndex;
    if (index is int &&
        index >= 0 &&
        index < newQueue.length &&
        mediaItem.value?.id == newQueue[index].id) {
      final currentItem = mediaItem.value;
      final updatedItem = newQueue[index].copyWith(
        duration: newQueue[index].duration ?? currentItem?.duration,
        extras: {
          ...?newQueue[index].extras,
          if (currentItem?.extras?['url'] != null)
            'url': currentItem!.extras!['url'],
        },
      );
      newQueue[index] = updatedItem;
      mediaItem.add(updatedItem);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    final url = mediaItem.extras!['url'] as String;
    if (url.contains('/cache') ||
        (Get.find<SettingsScreenController>().cacheSongs.isTrue &&
            url.contains("http"))) {
      printINFO("Playing Using LockCaching");
      isPlayingUsingLockCachingSource = true;
      return LockCachingAudioSource(
        Uri.parse(url),
        cacheFile: File("$_cacheDir/cachedSongs/${mediaItem.id}.mp3"),
        tag: mediaItem,
      );
    }

    printINFO("Playing Using AudioSource.uri");
    isPlayingUsingLockCachingSource = false;
    return AudioSource.uri(
      Uri.tryParse(url)!,
      tag: mediaItem,
    );
  }

  Future<void> _replaceCurrentAudioSource(MediaItem mediaItem) async {
    final source = _createAudioSource(mediaItem);
    if (GetPlatform.isIOS) {
      await _player.stop();
      await _player.setAudioSource(source);
      return;
    }
    if (_playList.children.isNotEmpty) {
      await _playList.clear();
    }
    await _playList.add(source);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> removeQueueItem(MediaItem mediaItem_) async {
    final currentQueue = queue.value;
    final currentSong = mediaItem.value;
    final itemIndex = currentQueue.indexOf(mediaItem_);
    if (currentIndex > itemIndex) {
      currentIndex -= 1;
    }
    currentQueue.remove(mediaItem_);
    queue.add(currentQueue);
    mediaItem.add(currentSong);
  }

  @override
  Future<void> play() async {
    if (currentSongUrl == null ||
        (GetPlatform.isDesktop &&
            (_player.duration == null ||
                _player.duration?.inMilliseconds == 0))) {
      await customAction("playByIndex", {'index': currentIndex});
      return;
    }
    // Workaround for network error pause in case of PlayingUsingLockCachingSource
    if (isPlayingUsingLockCachingSource && networkErrorPause) {
      await _player.play();
      Future.delayed(const Duration(seconds: 2)).then((value) {
        if (_player.playing) {
          networkErrorPause = false;
        }
      });
      await _player.play();
      return;
    }
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await customAction("playByIndex", {'index': index});
  }

  @override
  Future<void> skipToNext() async {
    if (queue.value.length > currentIndex + 1) {
      _player.seek(Duration.zero);
      await customAction("playByIndex", {'index': currentIndex + 1});
    } else {
      _player.seek(Duration.zero);
      _player.pause();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inMilliseconds > 5000) {
      _player.seek(Duration.zero);
      return;
    }
    _player.seek(Duration.zero);
    if (currentIndex - 1 >= 0) {
      await customAction("playByIndex", {'index': currentIndex - 1});
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (repeatMode == AudioServiceRepeatMode.none) {
      loopModeEnabled = false;
    } else {
      loopModeEnabled = true;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.stop();
    } else if (name == 'playByIndex') {
      final bool restoreSession = extras!['restoreSession'] ?? false;
      isSongLoading = true;
      final songIndex = extras['index'];
      currentIndex = songIndex;
      final isNewUrlReq = extras['newUrl'] ?? false;
      var currentSong = queue.value[currentIndex];
      final streamInfo =
          await checkNGetUrl(currentSong.id, generateNewUrl: isNewUrlReq);
      if (songIndex != currentIndex) {
        return;
      }
      final audio = streamInfo.audio;
      if (!streamInfo.playable || audio == null) {
        currentSongUrl = null;
        isSongLoading = false;
        final errorMessage = audio == null
            ? "No compatible audio stream available"
            : streamInfo.statusMSG;
        printERROR(errorMessage);
        playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            errorCode: 404,
            errorMessage: errorMessage));
        return;
      }
      currentSong = _withStreamDuration(currentSong, audio);
      queue.value[currentIndex] = currentSong;
      queue.add(queue.value);
      mediaItem.add(currentSong);
      if (_lastPlayerErrorSongId != currentSong.id) {
        _playerErrorRetries = 0;
        _lastPlayerErrorSongId = currentSong.id;
      }
      currentSongUrl = currentSong.extras!['url'] = audio.url;
      playbackState.add(playbackState.value.copyWith(queueIndex: currentIndex));
      await _replaceCurrentAudioSource(currentSong);
      isSongLoading = false;

      if (restoreSession) {
        if (!GetPlatform.isDesktop) {
          final position = extras['position'];
          await _player.load();
          await _player.seek(
            Duration(
              milliseconds: position,
            ),
          );
          await _player.seek(
            Duration(
              milliseconds: position,
            ),
          );
        }
      } else {
        await _player.play();
      }
      if (currentIndex == 0) {
        cacheNextSongUrl(offset: 1);
      }
      cacheNextSongUrl();
    } else if (name == "checkWithCacheDb" && isPlayingUsingLockCachingSource) {
      final song = extras!['mediaItem'] as MediaItem;
      final songsCacheBox = Hive.box("SongsCache");
      if (!songsCacheBox.containsKey(song.id) &&
          await File("$_cacheDir/cachedSongs/${song.id}.mp3").exists()) {
        song.extras!['url'] = currentSongUrl;
        song.extras!['date'] = DateTime.now().millisecondsSinceEpoch;
        final jsonData = MediaItemBuilder.toJson(song);
        jsonData['duration'] = _player.duration!.inSeconds;
        songsCacheBox.put(song.id, jsonData);
        if (!librarySongsController.isClosed) {
          librarySongsController.librarySongsList.value =
              librarySongsController.librarySongsList.toList() + [song];
        }
      }
    } else if (name == 'setSourceNPlay') {
      isSongLoading = true;
      var currMed = (extras!['mediaItem'] as MediaItem);
      currentIndex = 0;
      final streamInfo = await checkNGetUrl(currMed.id);
      final audio = streamInfo.audio;
      if (!streamInfo.playable || audio == null) {
        currentSongUrl = null;
        isSongLoading = false;
        final errorMessage = audio == null
            ? "No compatible audio stream available"
            : streamInfo.statusMSG;
        printERROR(errorMessage);
        playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            errorCode: 404,
            errorMessage: errorMessage));
        return;
      }
      currMed = _withStreamDuration(currMed, audio);
      mediaItem.add(currMed);
      queue.add([currMed]);
      if (_lastPlayerErrorSongId != currMed.id) {
        _playerErrorRetries = 0;
        _lastPlayerErrorSongId = currMed.id;
      }
      currentSongUrl = currMed.extras!['url'] = audio.url;
      await _replaceCurrentAudioSource(currMed);
      isSongLoading = false;
      await _player.play();
      cacheNextSongUrl(offset: 1);
      cacheNextSongUrl(offset: 2);
    } else if (name == 'toggleSkipSilence') {
      final enable = (extras!['enable'] as bool);
      await _player.setSkipSilenceEnabled(enable);
    } else if (name == "shuffleQueue") {
      final currentQueue = queue.value;
      final currentItem = currentQueue[currentIndex];
      currentQueue.remove(currentItem);
      currentQueue.shuffle();
      currentQueue.insert(0, currentItem);
      queue.add(currentQueue);
      mediaItem.add(currentItem);
      currentIndex = 0;
      cacheNextSongUrl();
    } else if (name == "reorderQueue") {
      final oldIndex = extras!['oldIndex'];
      int newIndex = extras['newIndex'];

      if (oldIndex < newIndex) {
        newIndex--;
      }

      final currentQueue = queue.value;
      final currentItem = currentQueue[currentIndex];
      final item = currentQueue.removeAt(
        oldIndex,
      );
      currentQueue.insert(newIndex, item);
      currentIndex = currentQueue.indexOf(currentItem);
      queue.add(currentQueue);
      mediaItem.add(currentItem);
    } else if (name == 'addPlayNextItem') {
      final song = extras!['mediaItem'] as MediaItem;
      final currentQueue = queue.value;
      currentQueue.insert(currentIndex + 1, song);
      queue.add(currentQueue);
    } else if (name == 'openEqualizer') {
      await deviceEqualizer?.open(_player.androidAudioSessionId!);
    } else if (name == "saveSession") {
      await saveSessionData();
    } else if (name == "setVolume") {
      _player.setVolume(extras!['value'] / 100);
    }
  }

  MediaItem _withStreamDuration(MediaItem mediaItem, Audio audio) {
    final streamDuration =
        audio.duration > 0 ? Duration(milliseconds: audio.duration) : null;
    final duration =
        _resolveDisplayDuration(mediaItem.duration, streamDuration);
    if (duration == mediaItem.duration) return mediaItem;

    return mediaItem.copyWith(
      duration: duration,
      extras: {
        ...?mediaItem.extras,
        if (duration != null) 'length': _formatDuration(duration),
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return "$hours:${minutes.padLeft(2, '0')}:$seconds";
    }
    return "$minutes:$seconds";
  }

  Future<void> saveSessionData() async {
    if (Get.find<SettingsScreenController>().restorePlaybackSession.isFalse) {
      return;
    }
    final currQueue = queue.value;
    if (currQueue.isNotEmpty) {
      final queueData =
          currQueue.map((e) => MediaItemBuilder.toJson(e)).toList();
      final currIndex = currentIndex ?? 0;
      final position = _player.position.inMilliseconds;
      final prevSessionData = await Hive.openBox("prevSessionData");
      await prevSessionData.clear();
      await prevSessionData.putAll(
          {"queue": queueData, "position": position, "index": currIndex});
      await prevSessionData.close();
      printINFO("Saved session data");
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    final stopForegroundService =
        Get.find<SettingsScreenController>().stopPlyabackOnSwipeAway.value;
    if (stopForegroundService) {
      await Get.find<HomeScreenController>().cachedHomeScreenData();
      await saveSessionData();
      await stop();
    }
  }

  @override
  Future<void> stop() async {
    await deviceEqualizer?.endAudioEffect(_player.androidAudioSessionId!);
    await _player.stop();
    return super.stop();
  }

  Future<void> cacheNextSongUrl({int offset = 2}) async {
    if (queue.value.length > currentIndex + offset) {
      final songId = (queue.value[currentIndex + offset]).id;
      final streamInfoJson = Hive.box("SongsUrlCache").get(songId);
      final cachedLowQualityAudio =
          streamInfoJson is Map ? streamInfoJson['lowQualityAudio'] : null;
      final cachedLowQualityUrl =
          cachedLowQualityAudio is Map ? cachedLowQualityAudio['url'] : null;
      if (isExpired(url: cachedLowQualityUrl) &&
          !(Hive.box("SongDownloads").containsKey(songId)) &&
          !(Hive.box("SongsCache").containsKey(songId))) {
        final token = RootIsolateToken.instance;
        Future.sync(() => Isolate.run(() => getStreamInfo(songId, token!))
                .then((value) async {
              final streamInfo = HMStreamingData.fromJson(value);
              if (streamInfo.playable) {
                await Hive.box("SongsUrlCache").put(songId, value);
                printWarning("Isolate: Next Song Url Cached song Id $songId");
              }
            }));
      }
    }
  }

// Work around used [useNewInstanceOfExplode = false] to Fix Connection closed before full header was received issue
  Future<HMStreamingData> checkNGetUrl(String songId,
      {bool generateNewUrl = false, bool offlineReplacementUrl = false}) async {
    printINFO("Requested id : $songId");
    final songDownloadsBox = Hive.box("SongDownloads");
    if (!offlineReplacementUrl &&
        (await Hive.openBox("SongsCache")).containsKey(songId)) {
      printINFO("Got Song from cachedbox ($songId)");
      final streamInfo = Hive.box("SongsCache").get(songId)["streamInfo"];
      Audio? cacheAudioPlaceholder;
      if (streamInfo != null && streamInfo.isNotEmpty) {
        streamInfo[1]['url'] = "file://$_cacheDir/cachedSongs/$songId.mp3";
        cacheAudioPlaceholder = Audio.fromJson(streamInfo[1]);
      } else {
        cacheAudioPlaceholder = Audio(
            audioCodec: Codec.mp4a,
            bitrate: 0,
            loudnessDb: 0,
            duration: 0,
            size: 0,
            url: "file://$_cacheDir/cachedSongs/$songId.mp3",
            itag: 0);
      }
      return HMStreamingData(
          playable: true,
          statusMSG: "OK",
          lowQualityAudio: cacheAudioPlaceholder,
          highQualityAudio: cacheAudioPlaceholder);
    } else if (!offlineReplacementUrl && songDownloadsBox.containsKey(songId)) {
      final song = songDownloadsBox.get(songId);
      final streamInfoJson = song["streamInfo"];
      Audio? audio;
      final path = song['url'];
      if (streamInfoJson != null && streamInfoJson.isNotEmpty) {
        audio = Audio.fromJson(streamInfoJson[1]);
      } else {
        audio = Audio(
            itag: 140,
            audioCodec: Codec.mp4a,
            bitrate: 0,
            duration: 0,
            loudnessDb: 0,
            url: path,
            size: 0);
      }
      final streamInfo = HMStreamingData(
          playable: true,
          statusMSG: "OK",
          highQualityAudio: audio,
          lowQualityAudio: audio);

      if (path.contains(
          "${Get.find<SettingsScreenController>().supportDirPath}/Music")) {
        return streamInfo;
      }
      //check file access and if file exist in storage
      final status = await PermissionService.getExtStoragePermission();
      if (status && await File(path).exists()) {
        return streamInfo;
      }
      //in case file doesnot found in storage, song will be played online
      return checkNGetUrl(songId, offlineReplacementUrl: true);
    } else {
      //check if song stream url is cached and allocate url accordingly
      final songsUrlCacheBox = Hive.box("SongsUrlCache");
      final qualityIndex = Hive.box('AppPrefs').get('streamingQuality') ?? 1;
      HMStreamingData? streamInfo;
      if (songsUrlCacheBox.containsKey(songId) && !generateNewUrl) {
        final streamInfoJson = songsUrlCacheBox.get(songId);
        if (streamInfoJson.runtimeType.toString().contains("Map") &&
            !isExpired(url: (streamInfoJson['lowQualityAudio']['url']))) {
          printINFO("Got cached Url ($songId)");
          streamInfo = HMStreamingData.fromJson(streamInfoJson);
          if (streamInfo.audio == null) {
            streamInfo = null;
          }
        }
      }

      if (streamInfo == null) {
        final token = RootIsolateToken.instance;
        final streamInfoJson =
            await Isolate.run(() => getStreamInfo(songId, token));
        streamInfo = HMStreamingData.fromJson(streamInfoJson);
        if (streamInfo.playable) songsUrlCacheBox.put(songId, streamInfoJson);
      }

      streamInfo.setQualityIndex(qualityIndex as int);
      return streamInfo;
    }
  }
}

class UrlError extends Error {
  String message() => 'Unable to fetch url';
}
