import 'package:flutter/material.dart';

import '../tema/tema.dart';

class LogoComunidad extends StatelessWidget {
  final String logo;
  final String nombre;
  final double tamano;

  const LogoComunidad({
    super.key,
    required this.logo,
    required this.nombre,
    this.tamano = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tamano * 0.2),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo.isEmpty ? _inicial(context) : _imagen(context),
    );
  }

  Widget _imagen(BuildContext context) {
    return Image.network(
      logo,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _inicial(context),
      loadingBuilder: (_, hijo, progreso) {
        if (progreso == null) return hijo;
        return const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _inicial(BuildContext context) {
    final limpio = nombre.trim();
    final letra = limpio.isEmpty ? '?' : limpio[0].toUpperCase();

    return Center(
      child: Text(
        letra,
        style: TextStyle(
          fontSize: tamano * 0.45,
          fontWeight: FontWeight.bold,
          color: AppColores.azulEspol,
        ),
      ),
    );
  }
}
