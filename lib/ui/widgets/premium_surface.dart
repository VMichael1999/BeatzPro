import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumColors {
  static const ink = Color(0xFF050507);
  static const graphite = Color(0xFF111015);
  static const panel = Color(0xEE15121D);
  static const violet = Color(0xFFB58AF7);
  static const blue = Color(0xFF8DA2FF);
  static const red = Color(0xFFE8A7D8);
  static const muted = Color(0xFFC9BDD5);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF1B6E7), Color(0xFFBCA4FF), Color(0xFF8AA3FF)],
  );
}

class PremiumBackdrop extends StatelessWidget {
  const PremiumBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PremiumColors.ink,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7F588B), Color(0xFF291E34), Color(0xFF050507)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: 100,
            child: _Glow(color: PremiumColors.blue.withOpacity(0.10)),
          ),
          Positioned(
            left: -110,
            bottom: 80,
            child: _Glow(color: PremiumColors.red.withOpacity(0.12)),
          ),
          child,
        ],
      ),
    );
  }
}

class PremiumGlass extends StatelessWidget {
  const PremiumGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 10,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: PremiumColors.panel,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class NeonDiscFrame extends StatelessWidget {
  const NeonDiscFrame({
    super.key,
    required this.child,
    required this.size,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0x66FFFFFF),
                  Color(0x22FFFFFF),
                  Color(0x77D9B8FF),
                  Color(0x66FFFFFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumColors.violet.withOpacity(0.22),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
          Container(
            height: size - 10,
            width: size - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
          ),
          SizedBox(
            height: size - 82,
            width: size - 82,
            child: child,
          ),
        ],
      ),
    );
  }
}

class FrostedTabBar extends StatelessWidget {
  const FrostedTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      borderRadius: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home_outlined, size: 18),
          Icon(Icons.queue_music_rounded, size: 18),
          CircleAvatar(
            radius: 13,
            backgroundColor: PremiumColors.violet,
            child: Icon(Icons.music_note, size: 15, color: Colors.white),
          ),
          Icon(Icons.equalizer_rounded, size: 18),
          Icon(Icons.person_outline_rounded, size: 18),
        ],
      ),
    );
  }
}

class GradientIconButton extends StatelessWidget {
  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onPressed,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          gradient: PremiumColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: PremiumColors.violet.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 34.0, 24.0, 46.0, 28.0, 40.0, 20.0, 32.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final height in heights)
          Container(
            width: 5,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: PremiumColors.accentGradient,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: PremiumColors.blue.withOpacity(0.35),
                  blurRadius: 10,
                )
              ],
            ),
          )
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 120)],
        ),
      ),
    );
  }
}
