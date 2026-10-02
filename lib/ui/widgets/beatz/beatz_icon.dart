import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/beatz_icon_data.dart';

/// Icon of the redesign, drawn from the same SVG paths as the design file.
///
/// [filled] mirrors the `.ic.f` class of the design (solid glyph, no stroke).
class BeatzIcon extends StatelessWidget {
  const BeatzIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.filled = false,
    this.strokeWidth = 1.9,
  });

  final String name;
  final double size;
  final Color? color;
  final bool filled;
  final double strokeWidth;

  static String _hex(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.white;
    final hex = _hex(resolved);
    final body = (kBeatzIconMarkup[name] ?? '').replaceAll('currentColor', hex);
    final attrs = filled
        ? 'fill="$hex" stroke="none"'
        : 'fill="none" stroke="$hex" stroke-width="$strokeWidth" '
            'stroke-linecap="round" stroke-linejoin="round"';
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        '$attrs>$body</svg>';
    Widget icon = SvgPicture.string(svg, width: size, height: size);
    if (resolved.a < 1) {
      icon = Opacity(opacity: resolved.a, child: icon);
    }
    return ExcludeSemantics(child: icon);
  }
}

/// Round 44 dp tap target holding a [BeatzIcon], like `.icb` in the design.
class BeatzIconButton extends StatelessWidget {
  const BeatzIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.color,
    this.background,
    this.filled = false,
  });

  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size < 48 ? 48 : size,
              height: size < 48 ? 48 : size,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                      color: background, shape: BoxShape.circle),
                  child: Center(
                    child: BeatzIcon(icon,
                        size: iconSize, color: fg, filled: filled),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
