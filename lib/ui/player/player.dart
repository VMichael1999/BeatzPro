import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../services/music_service.dart';
import '../../utils/helper.dart';
import '../screens/Settings/settings_screen_controller.dart';
import '../utils/beatz_design.dart';
import '../utils/theme_controller.dart';
import '../widgets/beatz/beatz_icon.dart';
import '../widgets/beatz/beatz_widgets.dart';
import '../widgets/beatz/eq_bars.dart';
import '../widgets/beatz/wave_progress.dart';
import '../widgets/image_widget.dart';
import '../widgets/loader.dart';
import '../widgets/marqwee_widget.dart';
import '../widgets/sleep_timer_bottom_sheet.dart';
import '../widgets/songinfo_bottom_sheet.dart';
import 'player_controller.dart';

enum _PlayerView { player, queue, lyrics, related }

/// Lets other widgets (e.g. the desktop bar) ask the player to open a view
/// once the panel is open: `'lyrics'`, `'queue'` or `'related'`.
final playerViewRequest = ValueNotifier<String?>(null);

/// Full screen player of the "Onda" redesign: the main view plus the queue,
/// lyrics and related views, reached from the three tabs at the bottom.
class Player extends StatefulWidget {
  const Player({super.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> {
  final _view = _PlayerView.player.obs;
  final _playerController = Get.find<PlayerController>();
  Worker? _panelWorker;

  @override
  void initState() {
    super.initState();
    playerViewRequest.addListener(_onViewRequest);
    // always come back to the main view when the panel is dismissed
    _panelWorker = ever<bool>(_playerController.isPanelGTHOpened, (open) {
      if (!open && _view.value != _PlayerView.player) {
        _setView(_PlayerView.player);
      }
    });
  }

  void _onViewRequest() {
    final request = playerViewRequest.value;
    if (request == null) return;
    playerViewRequest.value = null;
    switch (request) {
      case 'lyrics':
        _setView(_PlayerView.lyrics);
      case 'queue':
        _setView(_PlayerView.queue);
      case 'related':
        _setView(_PlayerView.related);
    }
  }

  @override
  void dispose() {
    playerViewRequest.removeListener(_onViewRequest);
    _panelWorker?.dispose();
    super.dispose();
  }

  void _setView(_PlayerView next) {
    final previous = _view.value;
    if (previous == next) return;
    // lyrics are loaded/toggled by the controller
    if (next == _PlayerView.lyrics && !_playerController.showLyricsflag.value) {
      _playerController.showLyrics();
    } else if (previous == _PlayerView.lyrics &&
        _playerController.showLyricsflag.value) {
      _playerController.showLyrics();
    }
    _view.value = next;
  }

  void _closePlayer() => _playerController.playerPanelController.close();

  @override
  Widget build(BuildContext context) {
    printINFO("player");
    final colors = context.beatz;
    final themeController = Get.find<ThemeController>();
    final settings = Get.find<SettingsScreenController>();
    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // Tint of the cover, only for the dynamic theme.
          Positioned.fill(
            child: Obx(() {
              final dynamicTheme =
                  settings.themeModetype.value == ThemeType.dynamic;
              final base = themeController.primaryColor.value;
              final top = dynamicTheme && base != null
                  ? _tint(base, 0.20)
                  : colors.surface;
              final mid = dynamicTheme && base != null
                  ? _tint(base, 0.10)
                  : colors.bg;
              final reduce = MediaQuery.disableAnimationsOf(context);
              return AnimatedContainer(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, mid, colors.bg],
                    stops: const [0, 0.38, 0.78],
                  ),
                ),
              );
            }),
          ),
          // Invisible image that feeds the palette of the dynamic theme.
          Obx(() {
            final song = _playerController.currentSong.value;
            if (song == null) return const SizedBox.shrink();
            return SizedBox(
              width: 0,
              height: 0,
              child: CachedNetworkImage(
                imageUrl: song.artUri.toString(),
                cacheKey: "${song.id}_song",
                memCacheHeight: 200,
                imageBuilder: (context, imageProvider) {
                  if (settings.themeModetype.value == ThemeType.dynamic) {
                    themeController.setTheme(imageProvider);
                  }
                  return const SizedBox.shrink();
                },
                errorWidget: (context, url, error) {
                  final imgFile = File(
                      "${settings.supportDirPath}/thumbnails/${song.id}.png");
                  if (imgFile.existsSync() &&
                      settings.themeModetype.value == ThemeType.dynamic) {
                    themeController.setTheme(FileImage(imgFile));
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          }),
          SafeArea(
            bottom: false,
            minimum: EdgeInsets.only(bottom: Get.mediaQuery.viewPadding.bottom),
            child: Obx(() {
              switch (_view.value) {
                case _PlayerView.player:
                  return _MainView(
                    onClose: _closePlayer,
                    onOpen: _setView,
                  );
                case _PlayerView.queue:
                  return _QueueView(
                      onClose: () => _setView(_PlayerView.player));
                case _PlayerView.lyrics:
                  return _LyricsView(
                      onClose: () => _setView(_PlayerView.player));
                case _PlayerView.related:
                  return _RelatedView(
                      onClose: () => _setView(_PlayerView.player));
              }
            }),
          ),
        ],
      ),
    );
  }

  /// Dark, contrast-safe tint (text stays ≥ 4.5:1 on it).
  static Color _tint(Color base, double lightness) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(lightness)
        .withSaturation(math.min(hsl.saturation, 0.6))
        .toColor();
  }
}

String _fmt(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

// ───────────────────────────── main view ─────────────────────────────

class _MainView extends StatefulWidget {
  const _MainView({required this.onClose, required this.onOpen});

  final VoidCallback onClose;
  final ValueChanged<_PlayerView> onOpen;

  @override
  State<_MainView> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  final _controller = Get.find<PlayerController>();

  /// While the waveform is being dragged, the position shown is the dragged one.
  final _dragFraction = RxnDouble();

  void _openInfo() {
    final song = _controller.currentSong.value;
    if (song == null) return;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      isScrollControlled: true,
      context: _controller.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(song, calledFromPlayer: true),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  void _openSleepTimer() {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      isScrollControlled: true,
      context: _controller.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.black54,
      builder: (context) => const SleepTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return LayoutBuilder(builder: (context, constraints) {
      const side = 22.0;
      final width = constraints.maxWidth - side * 2;
      // Heights of everything that is not the cover (+ gaps of 16).
      const fixedHeights = 440.0;
      final cover = math.max(
          150.0, math.min(width, constraints.maxHeight - fixedHeights));
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(side, 4, side, 18),
            child: Column(
              children: [
                _topBar(colors),
                const SizedBox(height: 16),
                _cover(cover),
                const SizedBox(height: 16),
                _titleRow(colors),
                const SizedBox(height: 16),
                _wave(colors),
                const SizedBox(height: 16),
                _controls(colors),
                const SizedBox(height: 16),
                _actions(colors),
                const SizedBox(height: 8),
                _tabs(colors),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _topBar(BeatzColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BeatzIconButton(
            icon: 'down',
            iconSize: 24,
            tooltip: 'Cerrar reproductor',
            onPressed: widget.onClose),
        Expanded(
          child: Obx(() {
            final song = _controller.currentSong.value;
            final album = song?.album;
            final hasAlbum = album != null && album.isNotEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hasAlbum ? 'Sonando desde el álbum' : 'Sonando ahora',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.muted)),
                Text(hasAlbum ? album : (song?.artist ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.ink)),
              ],
            );
          }),
        ),
        BeatzIconButton(
            icon: 'more',
            iconSize: 24,
            tooltip: 'Más opciones',
            onPressed: _openInfo),
      ],
    );
  }

  Widget _cover(double size) {
    return Obx(() {
      final song = _controller.currentSong.value;
      if (song == null) return SizedBox(width: size, height: size);
      final isVideo = _controller.mediaMode.value == PlayerMediaMode.video;
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        child: Container(
          key: ValueKey(song.id),
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x73000000), blurRadius: 50, offset: Offset(0, 24)),
            ],
          ),
          child: isVideo
              ? _videoSurface(size)
              : GestureDetector(
                  onTap: () => widget.onOpen(_PlayerView.lyrics),
                  onLongPress: _openInfo,
                  child: Semantics(
                    label: 'Carátula de ${song.album ?? song.title}',
                    child: ImageWidget(
                      size: size,
                      song: song,
                      isPlayerArtImage: true,
                      radius: 14,
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _videoSurface(double size) {
    return Obx(() {
      final video = _controller.videoController.value;
      final error = _controller.videoError.value;
      Widget child;
      if (_controller.isVideoLoading.isTrue) {
        child = const Center(child: LoadingIndicator());
      } else if (error != null) {
        child = Center(
            child: Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium));
      } else if (video == null || !video.value.isInitialized) {
        child = const Center(child: Icon(Icons.play_circle_outline, size: 54));
      } else {
        child = Center(
          child: AspectRatio(
              aspectRatio: video.value.aspectRatio, child: VideoPlayer(video)),
        );
      }
      return ColoredBox(color: Colors.black, child: child);
    });
  }

  Widget _titleRow(BeatzColors colors) {
    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final song = _controller.currentSong.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarqueeWidget(
                  child: Text(song?.title ?? 'NA',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: colors.ink)),
                ),
                const SizedBox(height: 4),
                MarqueeWidget(
                  child: Text(song?.artist ?? 'NA',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.muted)),
                ),
              ],
            );
          }),
        ),
        const SizedBox(width: 12),
        Obx(() {
          final fav = _controller.isCurrentSongFav.value;
          return BeatzIconButton(
            icon: 'heart',
            iconSize: 24,
            filled: fav,
            color: BeatzColors.heart,
            tooltip: fav ? 'Quitar de me gusta' : 'Agregar a me gusta',
            onPressed: _controller.toggleFavourite,
          );
        }),
      ],
    );
  }

  Widget _wave(BeatzColors colors) {
    return GetX<PlayerController>(builder: (controller) {
      final status = controller.progressBarStatus.value;
      final total = status.total.inMilliseconds;
      final actual = total == 0 ? 0.0 : status.current.inMilliseconds / total;
      final dragging = _dragFraction.value;
      final fraction = (dragging ?? actual).clamp(0.0, 1.0);
      final shown = dragging != null
          ? Duration(milliseconds: (dragging * total).round())
          : status.current;
      final song = controller.currentSong.value;
      return Column(
        children: [
          /*
          // Previous slider progress bar, kept to be reused later.
          CustomProgressBar(
            currentSliderValue: status.current.inSeconds.toDouble() / 60,
            maxValue: status.total.inSeconds.toDouble() / 60,
            onChanged: (value) =>
                controller.seek(Duration(seconds: (value * 60).toInt())),
          ),
          */
          WaveProgress(
            progress: fraction,
            seed: song?.id ?? 'wave',
            height: 44,
            barCount: 60,
            semanticsLabel:
                'Progreso: ${_fmt(status.current)} de ${_fmt(status.total)}',
            onSeekStart: (f) => _dragFraction.value = f,
            onSeek: (f) {
              _dragFraction.value = f;
            },
            onSeekEnd: (f) {
              final target = _dragFraction.value ?? f;
              controller.seek(Duration(milliseconds: (target * total).round()));
              _dragFraction.value = null;
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                    fontSize: dragging != null ? 20 : 12,
                    fontWeight: FontWeight.w700,
                    color: dragging != null ? colors.ink : colors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()]),
                child: Text(_fmt(shown)),
              ),
              Text(_fmt(status.total),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.muted,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ],
      );
    });
  }

  Widget _controls(BeatzColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BeatzIconButton(
          icon: 'shuffle',
          tooltip: 'Aleatorio',
          color: colors.muted,
          onPressed: _controller.shuffleQueue,
        ),
        BeatzIconButton(
          icon: 'prev',
          iconSize: 24,
          filled: true,
          tooltip: 'Anterior',
          onPressed: _controller.prev,
        ),
        _playButton(colors),
        Obx(() {
          final isLast = _controller.currentQueue.isEmpty ||
              (_controller.currentQueue.last.id ==
                  _controller.currentSong.value?.id);
          return BeatzIconButton(
            icon: 'next',
            iconSize: 24,
            filled: true,
            tooltip: 'Siguiente',
            color: isLast ? colors.muted : colors.ink,
            onPressed: isLast ? null : _controller.next,
          );
        }),
        Obx(() {
          final on = _controller.isLoopModeEnabled.value;
          return BeatzIconButton(
            icon: 'repeat',
            tooltip: on ? 'Repetir: activado' : 'Repetir',
            color: on ? colors.ink : colors.muted,
            onPressed: _controller.toggleLoopMode,
          );
        }),
      ],
    );
  }

  Widget _playButton(BeatzColors colors) {
    return GetX<PlayerController>(builder: (controller) {
      final state = controller.buttonState.value;
      final loading = state == PlayButtonState.loading;
      final playing = state == PlayButtonState.playing;
      return Tooltip(
        message: playing ? 'Pausar' : 'Reproducir',
        child: Semantics(
          button: true,
          label: playing ? 'Pausar' : 'Reproducir',
          child: Material(
            color: colors.ink,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: loading
                  ? null
                  : () => playing ? controller.pause() : controller.play(),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: colors.bg))
                      : BeatzIcon(playing ? 'pause' : 'play',
                          size: 28, color: colors.bg, filled: true),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Download, sleep timer and equalizer, as icons with tooltip.
  Widget _actions(BeatzColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BeatzDownloadButton(background: colors.surface),
        const SizedBox(width: 12),
        Obx(() {
          final active = _controller.isSleepTimerActive.value;
          return BeatzIconButton(
            icon: 'moon',
            tooltip: active ? 'Temporizador activo' : 'Temporizador',
            color: active ? BeatzColors.brandCyan : colors.ink,
            background: colors.surface,
            onPressed: _openSleepTimer,
          );
        }),
        const SizedBox(width: 12),
        BeatzIconButton(
          icon: 'eq',
          tooltip: 'Ecualizador',
          background: colors.surface,
          onPressed: () async {
            try {
              await _controller.openEqualizer();
            } catch (e) {
              printERROR(e);
            }
          },
        ),
      ],
    );
  }

  Widget _tabs(BeatzColors colors) {
    Widget tab(String label, _PlayerView view) => Expanded(
          child: InkWell(
            onTap: () => widget.onOpen(view),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.muted)),
            ),
          ),
        );
    return Row(
      children: [
        tab('A continuación', _PlayerView.queue),
        tab('Letra', _PlayerView.lyrics),
        tab('Relacionado', _PlayerView.related),
      ],
    );
  }
}

// ───────────────────────────── queue ─────────────────────────────

class _QueueView extends StatelessWidget {
  const _QueueView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    final controller = Get.find<PlayerController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Obx(() {
        final queue = controller.currentQueue;
        final currentIndex = controller.currentSongIndex.value;
        final current = (currentIndex >= 0 && currentIndex < queue.length)
            ? queue[currentIndex]
            : null;
        // songs after the current one are the ones that can be reordered
        final offset = currentIndex + 1;
        final upcoming = offset < queue.length
            ? queue.sublist(offset)
            : <MediaItem>[];
        final totalMinutes = queue.fold<int>(
                0, (sum, s) => sum + (s.duration?.inSeconds ?? 0)) ~/
            60;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('A continuación',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colors.ink)),
                BeatzIconButton(
                    icon: 'down',
                    tooltip: 'Cerrar',
                    background: colors.surface,
                    onPressed: onClose),
              ],
            ),
            const SizedBox(height: 12),
            if (current != null) _currentCard(context, current, controller),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.muted),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${queue.length} canciones · $totalMinutes min'),
                  const Text('Arrastra para ordenar'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                itemCount: upcoming.length,
                onReorder: (oldIndex, newIndex) =>
                    controller.onReorder(oldIndex + offset, newIndex + offset),
                onReorderStart: controller.onReorderStart,
                onReorderEnd: controller.onReorderEnd,
                proxyDecorator: (child, index, animation) => Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final song = upcoming[index];
                  return Material(
                    key: ValueKey('${song.id}_$index'),
                    color: Colors.transparent,
                    child: BeatzSongRow(
                      cover: ImageWidget(size: 44, song: song, radius: 8),
                      title: song.title,
                      subtitle:
                          '${song.artist ?? ''} · ${song.extras?['length'] ?? ''}',
                      onTap: () => controller.seekByIndex(index + offset),
                      onLongPress: () => showModalBottomSheet(
                        constraints: const BoxConstraints(maxWidth: 500),
                        isScrollControlled: true,
                        context:
                            controller.homeScaffoldkey.currentState!.context,
                        barrierColor: Colors.transparent.withAlpha(100),
                        builder: (context) => SongInfoBottomSheet(
                          song,
                          calledFromQueue: true,
                        ),
                      ).whenComplete(() => Get.delete<SongInfoController>()),
                      end: ReorderableDragStartListener(
                        index: index,
                        enabled: !GetPlatform.isDesktop,
                        child: Tooltip(
                          message: 'Mover',
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: BeatzIcon('grip', color: colors.muted),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _RadioOption(controller: controller, artist: current?.artist),
          ],
        );
      }),
    );
  }

  Widget _currentCard(
      BuildContext context, MediaItem song, PlayerController controller) {
    final colors = context.beatz;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ImageWidget(size: 44, song: song, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(() => EqBars(
                        animate: controller.buttonState.value ==
                            PlayButtonState.playing)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: colors.ink)),
                    ),
                  ],
                ),
                Text(song.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: colors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final status = controller.progressBarStatus.value;
            return Text('${_fmt(status.current)} / ${_fmt(status.total)}',
                style: TextStyle(
                    fontSize: 12.5,
                    color: colors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()]));
          }),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.controller, this.artist});

  final PlayerController controller;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    final on = controller.isRadioModeOn.obs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seguir con radio',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.ink)),
                Text(
                    artist == null
                        ? 'Al terminar la cola, agrega canciones parecidas'
                        : 'Al terminar la cola, agrega canciones parecidas a $artist',
                    style: TextStyle(fontSize: 12, color: colors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Obx(() => BeatzToggle(
                value: on.value,
                label: 'Seguir con radio',
                onChanged: (v) {
                  on.value = v;
                  controller.isRadioModeOn = v;
                  if (v) {
                    controller.radioInitiatorItem ??=
                        controller.currentSong.value;
                  }
                },
              )),
        ],
      ),
    );
  }
}

// ───────────────────────────── lyrics ─────────────────────────────

class _LyricsView extends StatefulWidget {
  const _LyricsView({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  final _controller = Get.find<PlayerController>();
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _lastLine = -1;
  Worker? _lineWorker;
  List<LyricsLineModel> _lines = const [];
  String _linesSource = '';

  @override
  void dispose() {
    _lineWorker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<LyricsLineModel> _parse(String synced) {
    if (synced == _linesSource) return _lines;
    _linesSource = synced;
    _lastLine = -1;
    _keys.clear();
    try {
      _lines = LyricsModelBuilder.create()
          .bindLyricToMain(synced)
          .getModel()
          .lyrics
          .where((l) => (l.mainText ?? '').trim().isNotEmpty)
          .toList();
    } catch (_) {
      _lines = const [];
    }
    return _lines;
  }

  void _followLine(int line) {
    if (line == _lastLine || line < 0) return;
    _lastLine = line;
    final ctx = _keys[line]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.35,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BeatzIconButton(
                  icon: 'down',
                  iconSize: 24,
                  tooltip: 'Volver al reproductor',
                  onPressed: widget.onClose),
              Text('Letra',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink)),
              BeatzIconButton(
                  icon: 'more',
                  iconSize: 24,
                  tooltip: 'Más opciones',
                  onPressed: () {
                    final song = _controller.currentSong.value;
                    if (song == null) return;
                    showModalBottomSheet(
                      constraints: const BoxConstraints(maxWidth: 500),
                      isScrollControlled: true,
                      context:
                          _controller.homeScaffoldkey.currentState!.context,
                      barrierColor: Colors.transparent.withAlpha(100),
                      builder: (context) =>
                          SongInfoBottomSheet(song, calledFromPlayer: true),
                    ).whenComplete(() => Get.delete<SongInfoController>());
                  }),
            ],
          ),
        ),
        Expanded(child: Obx(_body)),
        _miniRow(colors),
        _thinWave(colors),
      ],
    );
  }

  Widget _body() {
    final colors = context.beatz;
    if (_controller.isLyricsLoading.isTrue) {
      return const Center(child: LoadingIndicator());
    }
    final synced = (_controller.lyrics['synced'] ?? '').toString();
    final plain = (_controller.lyrics['plainLyrics'] ?? '').toString();
    final lines = synced.isEmpty ? const <LyricsLineModel>[] : _parse(synced);
    final lyricStyle = GoogleFonts.acme(fontSize: 23, height: 1.25);

    if (lines.isEmpty) {
      final unavailable = plain.isEmpty || plain == 'NA';
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  unavailable ? 'lyricsNotAvailable'.tr : plain,
                  style: lyricStyle.copyWith(
                      color: unavailable ? colors.muted : colors.ink),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final position =
          _controller.progressBarStatus.value.current.inMilliseconds;
      var current = -1;
      for (var i = 0; i < lines.length; i++) {
        if ((lines[i].startTime ?? 0) <= position) current = i;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _followLine(current));
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
        child: Column(
          children: [
            Expanded(
              // all lines are built so every one can be scrolled into view
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      InkWell(
                        key: _keys.putIfAbsent(i, () => GlobalKey()),
                        onTap: () => _controller.seek(
                            Duration(milliseconds: lines[i].startTime ?? 0)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: lyricStyle.copyWith(
                              fontSize: i == current ? 30 : 23,
                              color: i == current
                                  ? colors.ink
                                  : i < current
                                      ? colors.ink.withValues(alpha: 0.42)
                                      : colors.dim,
                            ),
                            child: Text(lines[i].mainText!.trim()),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _miniRow(BeatzColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Obx(() {
        final song = _controller.currentSong.value;
        final playing = _controller.buttonState.value == PlayButtonState.playing;
        return Row(
          children: [
            if (song != null) ImageWidget(size: 40, song: song, radius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: colors.ink)),
                  Text(song?.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.muted)),
                ],
              ),
            ),
            BeatzIconButton(
              icon: playing ? 'pause' : 'play',
              tooltip: playing ? 'Pausar' : 'Reproducir',
              filled: true,
              color: colors.bg,
              background: colors.ink,
              onPressed: playing ? _controller.pause : _controller.play,
            ),
          ],
        );
      }),
    );
  }

  Widget _thinWave(BeatzColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: GetX<PlayerController>(builder: (controller) {
        final status = controller.progressBarStatus.value;
        final total = status.total.inMilliseconds;
        return WaveProgress(
          progress: total == 0 ? 0 : status.current.inMilliseconds / total,
          seed: controller.currentSong.value?.id ?? 'wave',
          height: 12,
          barCount: 75,
          barWidthFactor: 2.5 / 4,
          semanticsLabel:
              'Progreso: ${_fmt(status.current)} de ${_fmt(status.total)}',
        );
      }),
    );
  }
}

// ───────────────────────────── related ─────────────────────────────

class _RelatedView extends StatefulWidget {
  const _RelatedView({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_RelatedView> createState() => _RelatedViewState();
}

class _RelatedViewState extends State<_RelatedView> {
  final _controller = Get.find<PlayerController>();
  late Future<List<MediaItem>> _future = _load();

  Future<List<MediaItem>> _load() async {
    final song = _controller.currentSong.value;
    if (song == null) return [];
    final sections = await Get.find<MusicServices>()
        .getContentRelatedToSong(song.id) as List;
    final songs = <MediaItem>[];
    for (final section in sections) {
      final contents = section['contents'];
      if (contents is List) songs.addAll(contents.whereType<MediaItem>());
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relacionado',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: colors.ink)),
              BeatzIconButton(
                  icon: 'down',
                  tooltip: 'Cerrar',
                  background: colors.surface,
                  onPressed: widget.onClose),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<MediaItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: LoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('networkError1'.tr,
                            style: TextStyle(color: colors.muted)),
                        TextButton(
                            onPressed: () =>
                                setState(() => _future = _load()),
                            child: Text('retry'.tr,
                                style: TextStyle(color: colors.ink))),
                      ],
                    ),
                  );
                }
                final songs = snapshot.data ?? [];
                if (songs.isEmpty) {
                  return Center(
                      child: Text('Sin canciones relacionadas',
                          style: TextStyle(color: colors.muted)));
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: songs.length,
                  itemBuilder: (context, i) => BeatzSongRow(
                    cover: ImageWidget(size: 44, song: songs[i], radius: 8),
                    title: songs[i].title,
                    subtitle: songs[i].artist ?? '',
                    onTap: () => _controller.playPlayListSong(songs, i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
