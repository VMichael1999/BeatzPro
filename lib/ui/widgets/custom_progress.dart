import 'package:beatzpro/ui/utils/theme_controller.dart';
import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double currentSliderValue;
  final double maxValue;
  final ValueChanged<double> onChanged;

  CustomProgressBar({
    required this.currentSliderValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context)
                .primaryColor
                .withLightness(0.5), // Color de la barra de progreso
            inactiveTrackColor: Theme.of(context)
                .primaryColor.withLightness(0.3), // Color de la barra sin progreso
            thumbColor: Theme.of(context)
                .primaryColor
                .withLightness(0.7), // Color del "thumb"
            thumbShape: CustomSliderThumbRect(
              thumbHeight: 40.0,
              thumbWidth: 10.0,
              innerColor:  Theme.of(context)
                .primaryColor, // Color adicional en el centro del thumb
              innerWidth: 4.0, // Ancho del color interno
              innerHeight: 35.0, // Altura del color interno
            ),
            trackHeight: 20.0, // Altura de la barra de progreso
          ),
          child: Slider(
            value: currentSliderValue,
            min: 0.0,
            max: maxValue,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentSliderValue),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                _formatDuration(maxValue),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(double value) {
    final minutes = value.floor();
    final seconds = ((value - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class CustomSliderThumbRect extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  final Color innerColor; // Nuevo color central
  final double innerWidth; // Ancho del color central
  final double innerHeight; // Altura del color central

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
      RRect.fromRectAndRadius(
          rect, const Radius.circular(4.0)), // Radio de los bordes
      paint,
    );

    // Pintar el color central adicional
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;

    final innerRect = Rect.fromCenter(
      center: center,
      width: innerWidth,
      height: innerHeight, // Altura del color interno
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2.0)), // Radio de los bordes internos
      innerPaint,
    );
  }
}
