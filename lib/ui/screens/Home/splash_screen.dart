// splash_screen.dart
import 'package:beatzpro/ui/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simula una carga de 3 segundos (3000 ms)
    await Future.delayed(const Duration(seconds: 3));
    // Navega a la pantalla principal
    Get.offAll(() => const Home());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/ico.png', // Ruta de la imagen
                  fit: BoxFit.cover,
                  width: 260,
                  height: 260,
                ),
                const SizedBox(height: 20), // Espacio entre la imagen y el texto
                const Text(
                  'BeatzPro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
