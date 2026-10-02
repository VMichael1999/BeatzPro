import 'package:flutter/material.dart';

import '../../utils/beatz_design.dart';

/// The three animated "now playing" bars, painted with the brand gradient.
class EqBars extends StatefulWidget {
  const EqBars({super.key, this.animate = true, this.height = 14});

  final bool animate;
  final double height;

  @override
  State<EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<EqBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(EqBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (widget.animate && !reduce) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _base = [8 / 14, 1.0, 10 / 14];
  static const _delay = [0.0, 0.2, 0.4];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sonando',
      child: SizedBox(
        width: 13,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value + 1 - _delay[i]) % 1.0;
              // 0.45 → 1 → 0.45, like the CSS ease-in-out keyframes
              final wave = t < 0.5 ? t * 2 : (1 - t) * 2;
              final scale = 0.45 + 0.55 * Curves.easeInOut.transform(wave);
              return Container(
                width: 3,
                height: widget.height * _base[i] * scale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BeatzColors.brandCyan,
                      BeatzColors.brandViolet,
                      BeatzColors.brandMagenta,
                    ],
                    stops: [0, 0.6, 1],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
