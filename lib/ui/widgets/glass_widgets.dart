import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class GlassColors {
  const GlassColors._();

  static Color surface(BuildContext context, {double alpha = 0.12}) {
    final brightness = Theme.of(context).brightness;
    return (brightness == Brightness.dark ? Colors.white : Colors.black)
        .withValues(alpha: alpha);
  }

  static Color tint(BuildContext context, {double alpha = 0.20}) {
    return Theme.of(context).primaryColor.withValues(alpha: alpha);
  }

  static Color border(BuildContext context, {double alpha = 0.22}) {
    return Colors.white.withValues(alpha: alpha);
  }

  static Color glow(BuildContext context, {double alpha = 0.20}) {
    return Theme.of(context).colorScheme.secondary.withValues(alpha: alpha);
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.margin,
    this.padding,
    this.borderRadius = 28,
    this.blur = 18,
    this.opacity = 0.12,
    this.borderOpacity = 0.22,
    this.gradient,
    this.color,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.shadows = const [],
    this.useLiquidGlass = true,
    this.fakeLiquidGlass = true,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final Gradient? gradient;
  final Color? color;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final List<BoxShadow> shadows;
  final bool useLiquidGlass;
  final bool fakeLiquidGlass;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final glassTint = color ??
        Colors.white.withValues(
          alpha: (opacity + 0.04).clamp(0.04, 0.22),
        );
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: useLiquidGlass
            ? Colors.white.withValues(alpha: opacity * 0.35)
            : color ?? GlassColors.surface(context, alpha: opacity),
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(
          color: GlassColors.border(context, alpha: borderOpacity),
          width: 1,
        ),
      ),
      child: child,
    );

    return RepaintBoundary(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows.isEmpty
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ]
              : shadows,
        ),
        child: useLiquidGlass
            ? LiquidGlassLayer(
                fake: fakeLiquidGlass,
                useBackdropGroup: true,
                settings: LiquidGlassSettings(
                  blur: blur.clamp(4, 18),
                  thickness: fakeLiquidGlass ? 12 : 20,
                  glassColor: glassTint,
                  lightAngle: 0.5 * math.pi,
                  lightIntensity: 0.62,
                  ambientStrength: 0.10,
                  saturation: 1.35,
                  chromaticAberration: fakeLiquidGlass ? 0 : 1,
                ),
                child: LiquidGlassBlendGroup(
                  blend: fakeLiquidGlass ? 0 : 8,
                  child: LiquidGlass(
                    shape: LiquidRoundedSuperellipse(
                      borderRadius: borderRadius,
                    ),
                    clipBehavior: clipBehavior,
                    child: GlassGlow(
                      glowColor: Colors.white.withValues(alpha: 0.18),
                      glowRadius: 0.8,
                      child: content,
                    ),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: radius,
                clipBehavior: clipBehavior,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: content,
                ),
              ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      opacity: 0.10,
      blur: 16,
      fakeLiquidGlass: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Theme.of(context).primaryColor.withValues(alpha: 0.08),
          Colors.black.withValues(alpha: 0.18),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    this.isPrimary = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool isPrimary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).textTheme.titleMedium?.color;
    return GlassContainer(
      height: size,
      width: size,
      padding: EdgeInsets.zero,
      borderRadius: size / 2,
      opacity: isPrimary ? 0.86 : 0.12,
      blur: isPrimary ? 8 : 18,
      fakeLiquidGlass: !isPrimary,
      color: isPrimary ? Colors.white.withValues(alpha: 0.92) : null,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isPrimary ? 0.28 : 0.18),
          blurRadius: isPrimary ? 24 : 18,
          offset: const Offset(0, 10),
        ),
      ],
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        icon: Icon(
          icon,
          size: iconSize,
          color: isPrimary ? Theme.of(context).primaryColor : foreground,
        ),
      ),
    );
  }
}

class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassBottomBarItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: GlassContainer(
        margin: EdgeInsets.fromLTRB(14, 0, 14, 8 + bottomPadding * 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        borderRadius: 30,
        opacity: 0.11,
        blur: 22,
        fakeLiquidGlass: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = selectedIndex == index;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _GlassBottomBarTile(
                  item: item,
                  selected: selected,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class GlassBottomBarItem {
  const GlassBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _GlassBottomBarTile extends StatelessWidget {
  const _GlassBottomBarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassBottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : Theme.of(context)
            .textTheme
            .titleMedium
            ?.color
            ?.withValues(alpha: 0.62);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: selected
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
        border: selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.18))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 11,
                      letterSpacing: 0,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassPlayerControls extends StatelessWidget {
  const GlassPlayerControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onFavorite,
    required this.onLoop,
    required this.isFavorite,
    required this.isLoopEnabled,
    this.nextEnabled = true,
    this.previousEnabled = true,
    this.compact = false,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onFavorite;
  final VoidCallback onLoop;
  final bool isFavorite;
  final bool isLoopEnabled;
  final bool nextEnabled;
  final bool previousEnabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return GlassContainer(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      borderRadius: 32,
      opacity: 0.10,
      blur: 18,
      fakeLiquidGlass: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GlassButton(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
            size: compact ? 42 : 46,
            iconSize: compact ? 21 : 23,
            color: isFavorite ? accent : null,
            onPressed: onFavorite,
          ),
          GlassButton(
            icon: Icons.skip_previous_rounded,
            size: compact ? 44 : 48,
            iconSize: compact ? 27 : 31,
            onPressed: previousEnabled ? onPrevious : null,
          ),
          GlassButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: compact ? 64 : 72,
            iconSize: compact ? 38 : 44,
            isPrimary: true,
            onPressed: onPlayPause,
          ),
          GlassButton(
            icon: Icons.skip_next_rounded,
            size: compact ? 44 : 48,
            iconSize: compact ? 27 : 31,
            onPressed: nextEnabled ? onNext : null,
          ),
          GlassButton(
            icon: Icons.all_inclusive_rounded,
            size: compact ? 42 : 46,
            iconSize: compact ? 21 : 23,
            color: isLoopEnabled ? accent : null,
            onPressed: onLoop,
          ),
        ],
      ),
    );
  }
}
