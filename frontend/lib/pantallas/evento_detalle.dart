import 'package:flutter/material.dart';

import '../estado/estado_async.dart';
import '../modelos/evento.dart';
import '../servicios/api.dart';
import '../servicios/sesion.dart';
import '../tema/tema.dart';
import '../utilidades/fechas.dart';
import '../widgets/aviso.dart';
import '../widgets/esqueletos.dart';
import '../widgets/vista_async.dart';
import 'evento_formulario.dart';
import 'eventos_widgets.dart';

class PantallaEventoDetalle extends StatefulWidget {
  final int eventoId;

  const PantallaEventoDetalle({super.key, required this.eventoId});

  @override
  State<PantallaEventoDetalle> createState() => _PantallaEventoDetalleState();
}

class _PantallaEventoDetalleState extends State<PantallaEventoDetalle> {
  Estado<Evento> _estado = const Cargando();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _estado = const Cargando());

    try {
      final evento = await Api.detalleEvento(widget.eventoId);
      if (!mounted) return;
      setState(() => _estado = ConDatos(evento));
    } catch (error) {
      if (!mounted) return;
      setState(() => _estado = ConError.desde(error));
    }
  }

  Future<void> _editar(Evento evento) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PantallaEventoFormulario(eventoExistente: evento),
      ),
    );
    if (mounted) await _cargar();
  }

  Future<void> _cancelar(Evento evento) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: Text('¿Seguro que deseas cancelar "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colores.error,
              foregroundColor: context.colores.onError,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _procesando = true);

    try {
      final mensaje = await Api.cancelarEvento(evento.id);
      await _cargar();
      if (mounted) mostrarAviso(context, mensaje);
    } catch (error) {
      if (mounted) {
        mostrarAviso(context, mensajeDeFalla(error), esError: true);
      }
    }

    if (!mounted) return;
    setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    final evento = _estado.datosONulo;

    return Scaffold(
      appBar: AppBar(
        title: Text(evento?.titulo ?? 'Detalle del evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: VistaAsync<Evento>(
              estado: _estado,
              cargando: const _EsqueletoDetalle(),
              alReintentar: _cargar,
              constructor: _contenido,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, Evento evento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    evento.titulo,
                    style: context.textos.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    evento.comunidadNombre,
                    style: context.textos.bodyLarge
                        ?.copyWith(color: context.textoSecundario),
                  ),
                ],
              ),
              if (evento.cancelado) const EtiquetaCancelado(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _dato(Icons.calendar_month, _cuando(evento)),
        _dato(Icons.place_outlined, evento.lugar),
        if (evento.cupo != null)
          _dato(Icons.groups_outlined, 'Cupo ${evento.cupo}'),
        const SizedBox(height: 36),
        Text('Descripción', style: context.textos.titleLarge),
        const SizedBox(height: 8),
        Text(evento.descripcion, style: const TextStyle(height: 1.5)),
        if (!evento.cancelado && Sesion.gestiona(evento.comunidadId)) ...[
          const SizedBox(height: 36),
          _acciones(evento),
        ],
      ],
    );
  }

  String _cuando(Evento evento) {
    final fecha = evento.fechaComoDateTime;
    if (fecha == null) return '${evento.fecha} · ${evento.hora}';

    return '${Fechas.conDiaSemana(fecha)} · ${evento.hora}';
  }

  Widget _dato(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: context.textoSecundario),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: context.textos.bodyLarge)),
        ],
      ),
    );
  }

  Widget _acciones(Evento evento) {
    if (_procesando) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editar(evento),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar evento'),
        ),
        OutlinedButton.icon(
          onPressed: () => _cancelar(evento),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar evento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colores.error,
            side: BorderSide(color: context.colores.error),
          ),
        ),
      ],
    );
  }
}

class _EsqueletoDetalle extends StatelessWidget {
  const _EsqueletoDetalle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Esqueleto(ancho: 280, alto: 30),
        SizedBox(height: 12),
        Esqueleto(ancho: 150, alto: 16),
        SizedBox(height: 32),
        Esqueleto(ancho: 230, alto: 14),
        SizedBox(height: 12),
        Esqueleto(ancho: 190, alto: 14),
        SizedBox(height: 40),
        Esqueleto(alto: 14),
        SizedBox(height: 10),
        Esqueleto(ancho: 260, alto: 14),
      ],
    );
  }
}
