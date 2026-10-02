import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/player_controller.dart';
import '../utils/beatz_design.dart';
import 'beatz/beatz_icon.dart';
import 'beatz/beatz_widgets.dart';
import 'snackbar.dart';

/// Sleep timer sheet of the redesign: four big times, the "wait for the song
/// to end" option and a button that names the exact stop time.
class SleepTimerBottomSheet extends StatefulWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  State<SleepTimerBottomSheet> createState() => _SleepTimerBottomSheetState();
}

class _SleepTimerBottomSheetState extends State<SleepTimerBottomSheet> {
  static const _times = [15, 30, 45, 60];
  final _selected = 30.obs;
  final _waitForSong = true.obs;

  String _stopTime(int minutes) {
    final t = DateTime.now().add(Duration(minutes: minutes));
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    final playerController = Get.find<PlayerController>();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1B1822) : colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(() {
          final active = playerController.isSleepTimerActive.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detener la música en',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.ink)),
                  BeatzIconButton(
                      icon: 'x',
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 14),
              if (active) ..._activeBody(context, colors, playerController)
              else ..._pickBody(context, colors, playerController),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _pickBody(
      BuildContext context, BeatzColors colors, PlayerController controller) {
    return [
      Row(
        children: [
          for (var i = 0; i < _times.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Obx(() {
                final on = _selected.value == _times[i];
                return Semantics(
                  button: true,
                  selected: on,
                  label: '${_times[i]} minutos',
                  child: InkWell(
                    onTap: () => _selected.value = _times[i],
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: on ? colors.ink : colors.raised,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${_times[i]}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: on ? colors.bg : colors.ink)),
                          Text('min',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: on
                                      ? colors.bg.withValues(alpha: 0.7)
                                      : colors.muted)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: colors.raised, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Esperar a que termine la canción',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.ink)),
                  Text('Así no se corta a la mitad',
                      style: TextStyle(fontSize: 12, color: colors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => BeatzToggle(
                  value: _waitForSong.value,
                  label: 'Esperar a que termine la canción',
                  onChanged: (v) => _waitForSong.value = v,
                )),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Obx(() => _PrimaryButton(
            label: 'Detener a las ${_stopTime(_selected.value)}',
            onPressed: () {
              final minutes = _selected.value;
              controller.sleepWaitsForSongEnd = _waitForSong.value;
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 200),
                  () => controller.startSleepTimer(minutes));
              ScaffoldMessenger.of(context).showSnackBar(snackbar(
                  context, "sleepTimeSetAlert".tr,
                  size: SanckBarSize.BIG));
            },
          )),
      const SizedBox(height: 6),
      _TextButton(
          label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
    ];
  }

  List<Widget> _activeBody(
      BuildContext context, BeatzColors colors, PlayerController controller) {
    return [
      Obx(() {
        final left = controller.timerDurationLeft.value;
        final h = (left ~/ 3600).toString().padLeft(2, '0');
        final m = ((left % 3600) ~/ 60).toString().padLeft(2, '0');
        final s = ((left % 3600) % 60).toString().padLeft(2, '0');
        return Container(
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: colors.raised, borderRadius: BorderRadius.circular(14)),
          child: Text('$h:$m:$s',
              style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        );
      }),
      const SizedBox(height: 14),
      if (controller.isSleepEndOfSongActive.isFalse)
        _TextButton(label: 'add5Minutes'.tr, onPressed: controller.addFiveMinutes),
      _PrimaryButton(
        label: 'cancelTimer'.tr,
        onPressed: () {
          Future.delayed(const Duration(milliseconds: 200),
              controller.cancelSleepTimer);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(snackbar(
              context, "cancelTimerAlert".tr,
              size: SanckBarSize.BIG));
        },
      ),
    ];
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Material(
      color: colors.ink,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: colors.bg)),
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: colors.muted)),
        ),
      ),
    );
  }
}
