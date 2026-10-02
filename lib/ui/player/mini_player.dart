import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/player_controller.dart';
import '../utils/beatz_design.dart';
import '../widgets/beatz/beatz_icon.dart';
import '../widgets/beatz/wave_progress.dart';
import '../widgets/image_widget.dart';
import '../widgets/loader.dart';
import 'player.dart' show playerViewRequest;

/// Mini player (phones) and the fixed player bar (desktop) of the redesign.
/// The waveform is the progress bar in both.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;
    final colors = context.beatz;
    return Obx(() {
      return Visibility(
        visible: playerController.isPlayerpanelTopVisible.value,
        child: Opacity(
          opacity: playerController.playerPaneOpacity.value,
          child: Container(
            height: playerController.playerPanelMinHeight.value,
            width: size.width,
            color: isWideScreen
                ? (colors.isDark ? const Color(0xFF09080C) : colors.surface)
                : colors.bg,
            child: isWideScreen
                ? _DesktopBar(controller: playerController)
                : _PhoneMini(controller: playerController),
          ),
        ),
      );
    });
  }
}

bool _hasNext(PlayerController c) =>
    c.currentQueue.isNotEmpty &&
    c.currentQueue.last.id != c.currentSong.value?.id;

bool _hasPrevious(PlayerController c) =>
    c.currentQueue.isNotEmpty &&
    c.currentQueue.first.id != c.currentSong.value?.id;

String _fmt(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

// ───────────────────────────── phone ─────────────────────────────

class _PhoneMini extends StatelessWidget {
  const _PhoneMini({required this.controller});

  final PlayerController controller;

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250 || controller.currentSong.value == null) return;
    if (velocity < 0 && _hasNext(controller)) {
      controller.next();
    } else if (velocity > 0 && _hasPrevious(controller)) {
      controller.prev();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: BorderRadius.circular(14),
          border: colors.isDark ? null : Border.all(color: colors.line),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _swipe,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    Obx(() {
                      final song = controller.currentSong.value;
                      return song == null
                          ? const SizedBox(width: 44, height: 44)
                          : ImageWidget(size: 44, song: song, radius: 8);
                    }),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        final song = controller.currentSong.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song?.title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: colors.ink)),
                            Text(song?.artist ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: colors.muted)),
                          ],
                        );
                      }),
                    ),
                    _playPause(colors),
                    Obx(() {
                      final enabled = _hasNext(controller);
                      return BeatzIconButton(
                        icon: 'next',
                        size: 40,
                        filled: true,
                        tooltip: 'Siguiente',
                        color: enabled ? colors.ink : colors.muted,
                        onPressed: enabled ? controller.next : null,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playPause(BeatzColors colors) {
    return GetX<PlayerController>(builder: (c) {
      final state = c.buttonState.value;
      if (state == PlayButtonState.loading) {
        return const SizedBox(
            width: 48, height: 48, child: Center(child: LoadingIndicator(dimension: 20)));
      }
      final playing = state == PlayButtonState.playing;
      return BeatzIconButton(
        icon: playing ? 'pause' : 'play',
        size: 40,
        iconSize: 24,
        filled: true,
        tooltip: playing ? 'Pausar' : 'Reproducir',
        onPressed: playing ? c.pause : c.play,
      );
    });
  }
}

// ───────────────────────────── desktop ─────────────────────────────

class _DesktopBar extends StatelessWidget {
  const _DesktopBar({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Container(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 280, child: _now(colors)),
          const SizedBox(width: 24),
          Expanded(child: _middle(context, colors)),
          const SizedBox(width: 24),
          SizedBox(width: 240, child: _right(context, colors)),
        ],
      ),
    );
  }

  Widget _now(BeatzColors colors) {
    return Obx(() {
      final song = controller.currentSong.value;
      return Row(
        children: [
          song == null
              ? const SizedBox(width: 52, height: 52)
              : ImageWidget(size: 52, song: song, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: colors.ink)),
                Text(song?.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: colors.muted)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _middle(BuildContext context, BeatzColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BeatzIconButton(
                icon: 'shuffle',
                tooltip: 'Aleatorio',
                color: colors.muted,
                onPressed: controller.shuffleQueue),
            const SizedBox(width: 6),
            Obx(() {
              final enabled = _hasPrevious(controller);
              return BeatzIconButton(
                  icon: 'prev',
                  filled: true,
                  tooltip: 'Anterior',
                  color: enabled ? colors.ink : colors.muted,
                  onPressed: enabled ? controller.prev : null);
            }),
            const SizedBox(width: 6),
            GetX<PlayerController>(builder: (c) {
              final playing = c.buttonState.value == PlayButtonState.playing;
              return Tooltip(
                message: playing ? 'Pausar' : 'Reproducir',
                child: Material(
                  color: colors.ink,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: playing ? c.pause : c.play,
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Center(
                        child: BeatzIcon(playing ? 'pause' : 'play',
                            filled: true, color: colors.bg),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 6),
            Obx(() {
              final enabled = _hasNext(controller);
              return BeatzIconButton(
                  icon: 'next',
                  filled: true,
                  tooltip: 'Siguiente',
                  color: enabled ? colors.ink : colors.muted,
                  onPressed: enabled ? controller.next : null);
            }),
            const SizedBox(width: 6),
            Obx(() {
              final on = controller.isLoopModeEnabled.value;
              return BeatzIconButton(
                  icon: 'repeat',
                  tooltip: on ? 'Repetir: activado' : 'Repetir',
                  color: on ? colors.ink : colors.muted,
                  onPressed: controller.toggleLoopMode);
            }),
          ],
        ),
        GetX<PlayerController>(builder: (c) {
          final status = c.progressBarStatus.value;
          final total = status.total.inMilliseconds;
          final labelStyle = TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.muted,
              fontFeatures: const [FontFeature.tabularFigures()]);
          return Row(
            children: [
              SizedBox(
                  width: 40,
                  child: Text(_fmt(status.current),
                      textAlign: TextAlign.right, style: labelStyle)),
              const SizedBox(width: 10),
              Expanded(
                child: WaveProgress(
                  progress:
                      total == 0 ? 0 : status.current.inMilliseconds / total,
                  seed: c.currentSong.value?.id ?? 'wave',
                  height: 26,
                  barCount: 90,
                  barWidthFactor: 2.1 / 3.33,
                  semanticsLabel:
                      'Progreso: ${_fmt(status.current)} de ${_fmt(status.total)}',
                  onSeek: (f) => c.seek(
                      Duration(milliseconds: (f * total).round())),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 40, child: Text(_fmt(status.total), style: labelStyle)),
            ],
          );
        }),
      ],
    );
  }

  Widget _right(BuildContext context, BeatzColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BeatzIconButton(
          icon: 'mic',
          tooltip: 'Letra',
          color: colors.muted,
          onPressed: () {
            playerViewRequest.value = 'lyrics';
            controller.playerPanelController.open();
          },
        ),
        BeatzIconButton(
          icon: 'queue',
          tooltip: 'A continuación',
          color: colors.muted,
          onPressed: () =>
              controller.homeScaffoldkey.currentState?.openEndDrawer(),
        ),
        Obx(() => BeatzIconButton(
              icon: 'vol',
              tooltip: controller.volume.value == 0 ? 'Activar sonido' : 'Silenciar',
              color: colors.muted,
              onPressed: controller.mute,
            )),
        const SizedBox(width: 4),
        SizedBox(
          width: 90,
          child: Obx(() => SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: colors.ink,
                  inactiveTrackColor: colors.line,
                  thumbColor: colors.ink,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: controller.volume.value / 100,
                  onChanged: (v) => controller.setVolume((v * 100).toInt()),
                ),
              )),
        ),
      ],
    );
  }
}
