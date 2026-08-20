import 'package:flutter/material.dart';

import '../tema/tema.dart';

/// Título y subtítulo de una pantalla de lista, con el icono de la sección.
///
/// El catálogo, los eventos, "mis solicitudes" y la bandeja del gestor
/// repetían el mismo par de `Text` con la misma separación. Estaba en cuatro
/// sitios, así que cualquier retoque había que hacerlo cuatro veces.
class Encabezado extends StatelessWidget {
  final IconData icono;
  final String titulo;

  /// Puede venir vacío: en el catálogo depende de si hay sesión.
  final String subtitulo;

  const Encabezado({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      // Al inicio y no centrado: con un título que se parte en dos líneas (un
      // teléfono de 360 px) el icono debe quedar junto a la primera.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.colores.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icono, color: context.colores.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titulo, style: context.textos.headlineMedium),
              if (subtitulo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: context.textos.bodyMedium?.copyWith(
                    color: context.textoSecundario,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
