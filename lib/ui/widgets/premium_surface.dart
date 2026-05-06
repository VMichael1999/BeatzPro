import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumColors {
  static const ink = Color(0xFF12071F);
  static const graphite = Color(0xFF1C0E2B);
  static const panel = Color(0xFF241333);
  static const violet = Color(0xFF7A2CFF);
  static const blue = Color(0xFF1C7CFF);
  static const red = Color(0xFFFF007A);
  static const muted = Color(0xFFB8A8CC);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, violet, blue],
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
          colors: [
            Color(0xFF4A2D63),
            Color(0xFF1D0E2F),
            Color(0xFF0B0614),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: 100,
            child: _Glow(color: PremiumColors.blue.withOpacity(0.16)),
          ),
          Positioned(
            left: -110,
            bottom: 80,
            child: _Glow(color: PremiumColors.red.withOpacity(0.18)),
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
            color: PremiumColors.red.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
              border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                  PremiumColors.red,
                  PremiumColors.violet,
                  PremiumColors.blue,
                  PremiumColors.red,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumColors.red.withOpacity(0.35),
                  blurRadius: 28,
                ),
                BoxShadow(
                  color: PremiumColors.blue.withOpacity(0.22),
                  blurRadius: 36,
                ),
              ],
            ),
          ),
          Container(
            height: size - 10,
            width: size - 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PremiumColors.ink,
            ),
          ),
          SizedBox(
            height: size - 46,
            width: size - 46,
            child: child,
          ),
          Positioned(
            right: 5,
            top: size * 0.35,
            child: Container(
              height: 11,
              width: 11,
              decoration: BoxDecoration(
                color: PremiumColors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PremiumColors.blue.withOpacity(0.85),
                    blurRadius: 12,
                  )
                ],
              ),
            ),
          ),
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
