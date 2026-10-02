import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../utils/beatz_design.dart';

final _tintCache = <String, Color>{};

/// Vertical gradient that starts with the dominant colour of a cover and
/// fades into the app background (album / artist headers).
class CoverTint extends StatefulWidget {
  const CoverTint({
    super.key,
    required this.imageUrl,
    required this.child,
    this.fadeAt = 0.45,
  });

  final String imageUrl;
  final Widget child;

  /// Where the tint has fully faded into the background (0..1).
  final double fadeAt;

  @override
  State<CoverTint> createState() => _CoverTintState();
}

class _CoverTintState extends State<CoverTint> {
  Color? _tint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CoverTint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _load();
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    if (url.isEmpty) return;
    final cached = _tintCache[url];
    if (cached != null) {
      _tint = cached;
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(80, 80),
        maximumColorCount: 6,
      );
      final base = palette.dominantColor?.color ??
          palette.darkMutedColor?.color ??
          palette.vibrantColor?.color;
      if (base == null) return;
      final hsl = HSLColor.fromColor(base);
      // dark enough for white text, never washed out
      final tint = hsl
          .withLightness(0.20)
          .withSaturation(hsl.saturation.clamp(0.0, 0.6))
          .toColor();
      _tintCache[url] = tint;
      if (mounted) setState(() => _tint = tint);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.isDark ? (_tint ?? colors.surface) : colors.surface,
            colors.bg,
          ],
          stops: [0, widget.fadeAt],
        ),
      ),
      child: widget.child,
    );
  }
}
