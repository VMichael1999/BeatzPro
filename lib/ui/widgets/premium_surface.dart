import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumColors {
  static const ink = Color(0xFF05060A);
  static const graphite = Color(0xFF12141C);
  static const panel = Color(0xCC191C26);
  static const violet = Color(0xFF8B5CF6);
  static const blue = Color(0xFF22D3EE);
  static const red = Color(0xFFFF3D6E);
  static const muted = Color(0xFF9AA3B2);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, blue, red],
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
        gradient: RadialGradient(
          center: Alignment(-0.75, -0.95),
          radius: 1.2,
          colors: [Color(0x553A1C78), PremiumColors.ink],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: 100,
            child: _Glow(color: PremiumColors.blue.withOpacity(0.18)),
          ),
          Positioned(
            left: -110,
            bottom: 80,
            child: _Glow(color: PremiumColors.red.withOpacity(0.14)),
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
    this.borderRadius = 28,
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
            color: PremiumColors.violet.withOpacity(0.15),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
