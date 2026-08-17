import 'package:flutter/material.dart';

import 'pantallas/catalogo.dart';

void main() {
  runApp(const AppCommunitly());
}

class AppCommunitly extends StatelessWidget {
  const AppCommunitly({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESPOL Communities',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF123B63)),
        useMaterial3: true,
      ),
      home: const PantallaCatalogo(),
    );
  }
}
