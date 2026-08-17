import 'package:flutter/material.dart';

import '../tema/tema.dart';

/// Bloque que ocupa el hueco de una lista cuando no hay nada que mostrar:
/// un error, un resultado vacío o un filtro sin coincidencias.
///
/// Siempre ofrece una salida. Un error sin botón de reintentar es un callejón
/// sin salida, que es justo lo que pasaba antes en las tres listas.
class MensajeCentrado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final String? textoAccion;
  final VoidCallback? alPulsarAccion;

  /// Tiñe el icono con el color de error del tema.
  final bool esError;

  const MensajeCentrado({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.textoAccion,
    this.alPulsarAccion,
    this.esError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorIcono = esError ? context.colores.error : context.textoSecundario;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 44, color: colorIcono),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: context.textos.titleMedium,
                ),
                if (detalle != null && detalle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detalle!,
                    textAlign: TextAlign.center,
                    style: context.textos.bodyMedium
                        ?.copyWith(color: context.textoSecundario),
                  ),
                ],
                if (textoAccion != null && alPulsarAccion != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: alPulsarAccion,
                    icon: const Icon(Icons.refresh),
                    label: Text(textoAccion!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
