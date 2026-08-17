import 'package:flutter/material.dart';

import '../modelos/evento.dart';
import '../servicios/api.dart';
import 'evento_formulario.dart';

class PantallaEventoDetalle extends StatefulWidget {
  final int eventoId;

  const PantallaEventoDetalle({super.key, required this.eventoId});

  @override
  State<PantallaEventoDetalle> createState() => _PantallaEventoDetalleState();
}

class _PantallaEventoDetalleState extends State<PantallaEventoDetalle> {
  Evento? _evento;
  bool _cargando = true;
  bool _procesando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final evento = await Api.detalleEvento(widget.eventoId);
      if (!mounted) return;
      setState(() {
        _evento = evento;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el evento';
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PantallaEventoFormulario(eventoExistente: _evento),
      ),
    );
    await _cargar();
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: Text('¿Seguro que deseas cancelar "${_evento!.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      final mensaje = await Api.cancelarEvento(_evento!.id);
      await _cargar();
      _avisar(mensaje);
    } catch (e) {
      _avisar(e.toString().replaceFirst('Exception: ', ''));
    }
    if (!mounted) return;
    setState(() => _procesando = false);
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del evento'),
        backgroundColor: const Color(0xFF123B63),
        foregroundColor: Colors.white,
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }

    final evento = _evento!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      evento.comunidadNombre,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (evento.cancelado)
                const Chip(
                  label: Text('Cancelado'),
                  backgroundColor: Color(0xFFFCE4E4),
                ),
            ],
          ),
          const SizedBox(height: 28),
          _dato(Icons.calendar_today, '${evento.fecha}  ·  ${evento.hora}'),
          _dato(Icons.place, evento.lugar),
          if (evento.cupo != null)
            _dato(Icons.groups, 'Cupo: ${evento.cupo}'),
          const SizedBox(height: 24),
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(evento.descripcion, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 36),
          if (!evento.cancelado) _accionesGestion(),
        ],
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(texto),
        ],
      ),
    );
  }

  Widget _accionesGestion() {
    if (_procesando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _editar,
          icon: const Icon(Icons.edit),
          label: const Text('Editar evento'),
        ),
        OutlinedButton.icon(
          onPressed: _cancelar,
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Cancelar evento', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
        ),
      ],
    );
  }
}
