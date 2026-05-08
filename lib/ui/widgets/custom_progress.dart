import 'package:beatzpro/ui/utils/theme_controller.dart';
import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double currentSliderValue;
  final double maxValue;
  final ValueChanged<double> onChanged;

  const CustomProgressBar({
    super.key,
    required this.currentSliderValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeMaxValue = maxValue.isFinite && maxValue > 0 ? maxValue : 0.0;
    final safeCurrentValue =
        currentSliderValue.clamp(0.0, safeMaxValue).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context)
                .primaryColor
                .withLightness(0.62)
                .withValues(alpha: 0.92),
            inactiveTrackColor: Theme.of(context)
                .primaryColor
                .withLightness(0.3)
                .withValues(alpha: 0.46),
            thumbColor: Theme.of(context).primaryColor.withLightness(0.82),
            thumbShape: CustomSliderThumbRect(
              thumbHeight: 38.0,
              thumbWidth: 8.0,
              innerColor: Theme.of(context)
                  .primaryColor
                  .withLightness(0.28)
                  .withValues(alpha: 0.72),
              innerWidth: 3.0,
              innerHeight: 32.0,
            ),
            trackHeight: 14.0,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: safeCurrentValue,
            min: 0.0,
            max: safeMaxValue,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(safeCurrentValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatDuration(safeMaxValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(double value) {
    final totalSeconds = (value * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class CustomSliderThumbRect extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  final Color innerColor;
  final double innerWidth;
  final double innerHeight;

  const CustomSliderThumbRect({
    required this.thumbWidth,
    required this.thumbHeight,
    required this.innerColor,
    required this.innerWidth,
    required this.innerHeight,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: center,
      width: thumbWidth,
      height: thumbHeight,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8.0)),
      paint,
    );

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;

    final innerRect = Rect.fromCenter(
      center: center,
      width: innerWidth,
      height: innerHeight,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(5.0)),
      innerPaint,
    );
  }
}
