import 'package:flutter/material.dart';

/// Rejilla que reparte las tarjetas en las columnas que quepan.
///
/// Sustituye a los `SizedBox(width: 320)` y `SizedBox(width: 420)` fijos que
/// había dentro de un `Wrap`: con un ancho constante, en un teléfono de 360 px
/// la tarjeta se desbordaba. Aquí el ancho sale del espacio disponible, así que
/// en móvil hay una columna a ancho completo y en escritorio las que entren.
class RejillaResponsiva extends StatelessWidget {
  final List<Widget> hijos;

  /// Ancho por debajo del cual se prefiere quitar una columna.
  final double anchoMinimo;

  final double separacion;

  const RejillaResponsiva({
    super.key,
    required this.hijos,
    this.anchoMinimo = 320,
    this.separacion = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (hijos.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, restricciones) {
        final disponible = restricciones.maxWidth;
        final columnas = disponible.isFinite
            ? ((disponible + separacion) ~/ (anchoMinimo + separacion))
                .clamp(1, hijos.length)
            : 1;
        final ancho =
            (disponible - separacion * (columnas - 1)) / columnas;

        // El ancho explícito evita que la rejilla encoja hasta sus hijos y
        // arrastre consigo a la columna que la contiene.
        return SizedBox(
          width: disponible.isFinite ? disponible : null,
          child: Wrap(
            spacing: separacion,
            runSpacing: separacion,
            children: [
              for (final hijo in hijos)
                SizedBox(
                  width: disponible.isFinite ? ancho : anchoMinimo,
                  child: hijo,
                ),
            ],
          ),
        );
      },
    );
  }
}
