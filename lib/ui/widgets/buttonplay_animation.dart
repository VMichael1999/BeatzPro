import 'package:beatzpro/ui/utils/theme_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math' show pi;

class PlayButton extends StatefulWidget {
  final bool isPlaying; // Estado actual de reproducción
  final Icon playIcon;
  final Icon pauseIcon;
  final VoidCallback onPressed;

  const PlayButton({
    Key? key,
    required this.onPressed,
    required this.isPlaying, // Se pasa el estado actual de reproducción
    this.playIcon = const Icon(Icons.play_arrow),
    this.pauseIcon = const Icon(Icons.pause),
  }) : super(key: key);

  @override
  _PlayButtonState createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with TickerProviderStateMixin {
  static const _kToggleDuration = Duration(milliseconds: 300);
  static const _kRotationDuration = Duration(seconds: 5);

  late AnimationController _rotationController;
  late AnimationController _scaleController;
  double _rotation = 0;
  double _scale = 0.85;

  bool get _showWaves => !_scaleController.isDismissed;

  void _updateRotation() => _rotation = _rotationController.value * pi * 2;
  void _updateScale() => _scale = (_scaleController.value * 0.2) + 0.85;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _rotationController = AnimationController(
      vsync: this,
      duration: _kRotationDuration,
    )..addListener(() => setState(_updateRotation));

    _scaleController = AnimationController(
      vsync: this,
      duration: _kToggleDuration,
    )..addListener(() => setState(_updateScale));

    // Si está reproduciéndose, empezar la animación
    if (widget.isPlaying) {
      _rotationController.repeat(); // Repetir animación de rotación
      _scaleController.forward();   // Mostrar animación de escala
    }
  }

  @override
  void didUpdateWidget(covariant PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying && !_rotationController.isAnimating) {
      // Si empieza a reproducirse y la animación no está activa, comenzarla
      _rotationController.repeat();
      _scaleController.forward();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      // Si se detiene la música y la animación está activa, detenerla
      _rotationController.stop();
      _scaleController.reverse();
    }
  }

  Widget _buildIcon(bool isPlaying) {
    return SizedBox.expand(
      key: ValueKey<bool>(isPlaying),
      child: IconButton(
        icon: isPlaying ? widget.pauseIcon : widget.playIcon,
        onPressed: widget.onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_showWaves) ...[
            Blob(color: const Color.fromARGB(255, 46, 46, 46), scale: _scale, rotation: _rotation),
            Blob(color: Theme.of(context).primaryColor.withLightness(0.5), scale: _scale, rotation: _rotation * 2 - 30),
            Blob(color: Theme.of(context).primaryColor.withLightness(0.2), scale: _scale, rotation: _rotation * 3 - 45),
          ],
          Container(
            constraints: const BoxConstraints.expand(),
            child: AnimatedSwitcher(
              duration: _kToggleDuration,
              child: _buildIcon(widget.isPlaying),
            ),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class Blob extends StatelessWidget {
  final double rotation;
  final double scale;
  final Color color;

  const Blob({
    Key? key,
    required this.color,
    this.rotation = 0,
    this.scale = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(150),
              topRight: Radius.circular(240),
              bottomLeft: Radius.circular(220),
              bottomRight: Radius.circular(180),
            ),
          ),
        ),
      ),
    );
  }
}