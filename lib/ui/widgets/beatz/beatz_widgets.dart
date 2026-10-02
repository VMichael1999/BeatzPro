import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/services/downloader.dart';
import '/ui/player/player_controller.dart';
import '../snackbar.dart';
import '../../utils/beatz_design.dart';
import 'beatz_icon.dart';

/// Small green check shown on downloaded songs (`.dl` in the design).
class DownloadedBadge extends StatelessWidget {
  const DownloadedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Semantics(
      label: 'Descargada',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: colors.good, shape: BoxShape.circle),
        child: Center(
          child: BeatzIcon('check',
              size: 10, color: colors.bg, strokeWidth: 3),
        ),
      ),
    );
  }
}

/// Section title with an optional action link (`.sec h4` in the design).
class BeatzSectionTitle extends StatelessWidget {
  const BeatzSectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.17,
                color: colors.ink),
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(action!,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.muted)),
            ),
          ),
      ],
    );
  }
}

/// Song row of lists (`.sg` in the design): 44 px cover, title, artist and an
/// end widget.
class BeatzSongRow extends StatelessWidget {
  const BeatzSongRow({
    super.key,
    required this.cover,
    required this.title,
    required this.subtitle,
    this.end,
    this.onTap,
    this.onLongPress,
    this.leadingTitle,
    this.subtitleLeading,
    this.coverSize = 44,
    this.titleSize = 14.5,
    this.padding = const EdgeInsets.symmetric(vertical: 7),
  });

  final Widget cover;
  final String title;
  final String subtitle;
  final Widget? end;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? leadingTitle;
  final Widget? subtitleLeading;
  final double coverSize;
  final double titleSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            SizedBox(width: coverSize, height: coverSize, child: cover),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (leadingTitle != null) ...[
                        leadingTitle!,
                        const SizedBox(width: 7),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: titleSize,
                              color: colors.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      if (subtitleLeading != null) ...[
                        subtitleLeading!,
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: colors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (end != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: colors.muted),
                child: DefaultTextStyle(
                  style: TextStyle(color: colors.muted, fontSize: 12.5),
                  child: end!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Download state of a song as a single icon button: download, progress or the
/// green "downloaded" check. Same rules as the old `SongDownloadButton`.
class BeatzDownloadButton extends StatelessWidget {
  const BeatzDownloadButton({
    super.key,
    this.song,
    this.calledFromPlayer = true,
    this.background,
  });

  final MediaItem? song;
  final bool calledFromPlayer;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final downloader = Get.find<Downloader>();
    final playerController = Get.find<PlayerController>();
    final colors = context.beatz;
    return Obx(() {
      final item = calledFromPlayer ? playerController.currentSong.value : song;
      if (item == null) {
        return BeatzIconButton(
            icon: 'dl',
            tooltip: 'Descargar',
            onPressed: null,
            color: colors.muted,
            background: background);
      }
      final isDone = (downloader.songQueue.contains(item) &&
              downloader.currentSong == item &&
              downloader.songDownloadingProgress.value == 100) ||
          Hive.box("SongDownloads").containsKey(item.id);
      if (isDone) {
        return BeatzIconButton(
            icon: 'check',
            tooltip: 'Descargada',
            onPressed: null,
            color: colors.good,
            background: background);
      }
      final inQueue = downloader.songQueue.contains(item);
      if (inQueue &&
          downloader.isJobRunning.isTrue &&
          downloader.currentSong == item) {
        final progress = downloader.songDownloadingProgress.value;
        return Tooltip(
          message: 'Descargando $progress%',
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 3,
                      color: colors.good,
                      backgroundColor: colors.line,
                    ),
                  ),
                  Text('$progress',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.ink)),
                ],
              ),
            ),
          ),
        );
      }
      if (inQueue) {
        return SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: colors.muted),
            ),
          ),
        );
      }
      return BeatzIconButton(
        icon: 'dl',
        tooltip: 'Descargar',
        color: colors.ink,
        background: background,
        onPressed: () {
          final messenger = ScaffoldMessenger.of(context);
          final alert = snackbar(context, "songAlreadyOfflineAlert".tr,
              size: SanckBarSize.BIG);
          Hive.openBox("SongsCache").then((box) {
            if (box.containsKey(item.id)) {
              messenger.showSnackBar(alert);
            } else {
              downloader.download(item);
            }
          });
        },
      );
    });
  }
}

/// Switch drawn like `.tog` in the design.
class BeatzToggle extends StatelessWidget {
  const BeatzToggle(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 26,
            decoration: BoxDecoration(
              color: value ? colors.ink : colors.line,
              borderRadius: BorderRadius.circular(26),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? colors.bg : colors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Horizontal pill filters (`.chips` / `.seg` in the design).
class BeatzChips extends StatelessWidget {
  const BeatzChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.bordered = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  /// `.seg` variant: chips carry a thin border.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final on = i == selected;
          return Semantics(
            button: true,
            selected: on,
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(BeatzTokens.radiusPill),
                onTap: () => onSelected(i),
                child: Container(
                  height: 34,
                  padding: EdgeInsets.symmetric(horizontal: bordered ? 13 : 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? colors.ink : colors.surface,
                    borderRadius: BorderRadius.circular(BeatzTokens.radiusPill),
                    border: bordered
                        ? Border.all(color: on ? colors.ink : colors.line)
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                      color: on ? colors.bg : colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Search field of the design (`.search`): 48 px, rounded, with a clear button.
class BeatzSearchField extends StatelessWidget {
  const BeatzSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          BeatzIcon('search', color: colors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: colors.ink,
              style: TextStyle(fontSize: 15, color: colors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 15, color: colors.muted),
              ),
            ),
          ),
          BeatzIconButton(
              icon: 'x',
              tooltip: 'Borrar búsqueda',
              color: colors.muted,
              onPressed: onClear),
        ],
      ),
    );
  }
}
