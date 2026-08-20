import 'package:flutter/material.dart';

import '../modelos/evento.dart';
import '../tema/tema.dart';
import '../utilidades/fechas.dart';

class BloqueFecha extends StatelessWidget {
  final DateTime? fecha;
  final bool atenuado;

  const BloqueFecha({super.key, required this.fecha, this.atenuado = false});

  @override
  Widget build(BuildContext context) {
    final fondo = atenuado
        ? context.colores.surfaceContainerHighest
        : context.colores.secondaryContainer;
    final color = atenuado
        ? context.textoSecundario
        : context.colores.onSecondaryContainer;
    final dia = fecha;

    return Container(
      width: 60,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: dia == null
          ? Icon(Icons.event_outlined, size: 24, color: color)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Fechas.diaSemanaCorto(dia),
                  style: context.textos.labelSmall?.copyWith(color: color),
                ),
                Text(
                  dia.day.toString().padLeft(2, '0'),
                  style: context.textos.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  Fechas.mesCorto(dia),
                  style: context.textos.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
    );
  }
}

class EtiquetaCancelado extends StatelessWidget {
  const EtiquetaCancelado({super.key});

  @override
  Widget build(BuildContext context) {
    final colores = context.coloresEstado.cancelado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colores.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, size: 13, color: colores.texto),
          const SizedBox(width: 5),
          Text(
            'Cancelado',
            style: TextStyle(
              color: colores.texto,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DatoEvento extends StatelessWidget {
  final IconData icono;
  final String texto;

  const DatoEvento({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: context.colores.outline),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: context.textos.bodyMedium
                ?.copyWith(color: context.textoSecundario),
          ),
        ),
      ],
    );
  }
}

class TarjetaEvento extends StatelessWidget {
  final Evento evento;
  final VoidCallback alPulsar;

  const TarjetaEvento({
    super.key,
    required this.evento,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final cancelado = evento.cancelado;

    return Card(
      child: InkWell(
        onTap: alPulsar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloqueFecha(
                fecha: evento.fechaComoDateTime,
                atenuado: cancelado,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: context.textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cancelado ? context.textoSecundario : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      evento.comunidadNombre,
                      style: context.textos.bodySmall
                          ?.copyWith(color: context.textoSecundario),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        DatoEvento(icono: Icons.schedule, texto: evento.hora),
                        DatoEvento(
                          icono: Icons.place_outlined,
                          texto: evento.lugar,
                        ),
                        if (evento.cupo != null)
                          DatoEvento(
                            icono: Icons.groups_outlined,
                            texto: 'Cupo ${evento.cupo}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 68,
                child: Center(
                  child: cancelado
                      ? const EtiquetaCancelado()
                      : Icon(
                          Icons.chevron_right,
                          color: context.colores.outline,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
