import 'package:flutter/material.dart';

import '../tema/tema.dart';
import 'rejilla_responsiva.dart';

/// Bloque gris animado que ocupa el sitio de un contenido que todavía no
/// llegó.
///
/// Se percibe bastante más rápido que un `CircularProgressIndicator` centrado,
/// porque anticipa la forma de lo que va a aparecer en lugar de dejar la
/// pantalla en blanco.
class Esqueleto extends StatefulWidget {
  final double? ancho;
  final double alto;
  final BorderRadius? radio;

  const Esqueleto({
    super.key,
    this.ancho,
    this.alto = 14,
    this.radio,
  });

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colores.surfaceContainerHighest;
    final brillante = context.colores.surfaceContainerLow;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controlador,
        builder: (context, _) {
          return Container(
            width: widget.ancho,
            height: widget.alto,
            decoration: BoxDecoration(
              color: Color.lerp(base, brillante, _controlador.value),
              borderRadius: widget.radio ?? BorderRadius.circular(6),
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta fantasma con la silueta de las del catálogo y las de solicitudes.
class EsqueletoTarjeta extends StatelessWidget {
  const EsqueletoTarjeta({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Esqueleto(ancho: 170, alto: 18),
            SizedBox(height: 10),
            Esqueleto(ancho: 110, alto: 12),
            SizedBox(height: 16),
            Esqueleto(alto: 12),
            SizedBox(height: 8),
            Esqueleto(alto: 12),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Esqueleto(alto: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rejilla de tarjetas fantasma, con el mismo reparto de columnas que la
/// rejilla real para que no haya salto cuando llegan los datos.
class EsqueletoRejilla extends StatelessWidget {
  final int cantidad;
  final double anchoMinimo;
  final Widget plantilla;

  const EsqueletoRejilla({
    super.key,
    this.cantidad = 6,
    this.anchoMinimo = 320,
    this.plantilla = const EsqueletoTarjeta(),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando contenido',
      child: RejillaResponsiva(
        anchoMinimo: anchoMinimo,
        hijos: List.generate(cantidad, (_) => plantilla),
      ),
    );
  }
}

class EsqueletoEvento extends StatelessWidget {
  const EsqueletoEvento({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Esqueleto(
              ancho: 60,
              alto: 68,
              radio: BorderRadius.all(Radius.circular(12)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Esqueleto(ancho: 170, alto: 18),
                  SizedBox(height: 10),
                  Esqueleto(ancho: 90, alto: 12),
                  SizedBox(height: 14),
                  Esqueleto(alto: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
