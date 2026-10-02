import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/beatz_design.dart';

/// Waveform used as the progress bar. The listened part is painted with the
/// brand gradient, the remaining part with the muted `dim` colour.
///
/// The bar heights are generated from [seed] (the song id), so each song keeps
/// its own shape without needing to decode the audio.
class WaveProgress extends StatelessWidget {
  const WaveProgress({
    super.key,
    required this.progress,
    required this.seed,
    this.height = 44,
    this.barCount = 60,
    this.barWidthFactor = 3 / 5,
    this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticsLabel,
  });

  /// 0..1
  final double progress;
  final String seed;
  final double height;
  final int barCount;

  /// Bar width as a fraction of the distance between bars.
  final double barWidthFactor;
  final ValueChanged<double>? onSeek;
  final ValueChanged<double>? onSeekStart;
  final ValueChanged<double>? onSeekEnd;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Semantics(
      label: semanticsLabel,
      value: '${(progress * 100).round()}%',
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        double fraction(Offset p) => (p.dx / width).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null
              ? null
              : (d) {
                  final f = fraction(d.localPosition);
                  onSeekStart?.call(f);
                  onSeek!(f);
                  onSeekEnd?.call(f);
                },
          onHorizontalDragStart: onSeek == null
              ? null
              : (d) => onSeekStart?.call(fraction(d.localPosition)),
          onHorizontalDragUpdate:
              onSeek == null ? null : (d) => onSeek!(fraction(d.localPosition)),
          onHorizontalDragEnd: onSeekEnd == null
              ? null
              : (_) => onSeekEnd!(progress.clamp(0.0, 1.0)),
          child: CustomPaint(
            size: Size(width, height),
            painter: _WavePainter(
              progress: progress.clamp(0.0, 1.0),
              heights: _heightsFor(seed, barCount),
              barWidthFactor: barWidthFactor,
              idleColor: colors.dim,
            ),
          ),
        );
      }),
    );
  }
}

final _heightCache = <String, List<double>>{};

List<double> _heightsFor(String seed, int count) {
  final key = '$seed#$count';
  return _heightCache.putIfAbsent(key, () {
    var state = seed.hashCode & 0x7fffffff;
    double next() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state / 0x7fffffff;
    }

    final heights = <double>[];
    var prev = 0.55;
    for (var i = 0; i < count; i++) {
      // random walk so neighbouring bars look related, like a real waveform
      prev = (prev * 0.45 + next() * 0.55).clamp(0.12, 0.96);
      heights.add(prev);
    }
    if (_heightCache.length > 200) _heightCache.remove(_heightCache.keys.first);
    return heights;
  });
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.heights,
    required this.barWidthFactor,
    required this.idleColor,
  });

  final double progress;
  final List<double> heights;
  final double barWidthFactor;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final count = heights.length;
    final step = size.width / count;
    final barWidth = step * barWidthFactor;
    final radius = Radius.circular(math.min(barWidth / 2, 2));
    final gradientPaint = Paint()
      ..shader = BeatzColors.brandGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final idlePaint = Paint()..color = idleColor;
    final playedBars = progress * count;

    for (var i = 0; i < count; i++) {
      final h = math.max(2.0, heights[i] * size.height);
      final left = i * step;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - h) / 2, barWidth, h),
        radius,
      );
      canvas.drawRRect(rect, i < playedBars ? gradientPaint : idlePaint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.heights != heights ||
      old.idleColor != idleColor ||
      old.barWidthFactor != barWidthFactor;
}
