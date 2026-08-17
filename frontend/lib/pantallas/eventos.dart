import 'package:flutter/material.dart';

import '../modelos/evento.dart';
import '../servicios/api.dart';
import 'evento_detalle.dart';
import 'evento_formulario.dart';

class PantallaEventos extends StatefulWidget {
  final int? comunidadId;
  final String? comunidadNombre;

  const PantallaEventos({super.key, this.comunidadId, this.comunidadNombre});

  @override
  State<PantallaEventos> createState() => _PantallaEventosState();
}

class _PantallaEventosState extends State<PantallaEventos> {
  List<Evento> _eventos = [];
  DateTime? _fechaFiltro;
  bool _cargando = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final lista = await Api.listarEventos(
        comunidadId: widget.comunidadId,
        fecha: _fechaFiltro == null ? '' : _formatearFecha(_fechaFiltro!),
      );
      setState(() {
        _eventos = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar con el servidor. ¿Está corriendo Django?';
        _cargando = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  Future<void> _elegirFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (seleccionada != null) {
      setState(() => _fechaFiltro = seleccionada);
      _cargar();
    }
  }

  void _limpiarFecha() {
    setState(() => _fechaFiltro = null);
    _cargar();
  }

  Future<void> _abrirDetalle(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantallaEventoDetalle(eventoId: id)),
    );
    _cargar();
  }

  Future<void> _crearEvento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaEventoFormulario(
          comunidadId: widget.comunidadId,
          comunidadNombre: widget.comunidadNombre,
        ),
      ),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.comunidadNombre != null
              ? 'Eventos · ${widget.comunidadNombre}'
              : 'Eventos',
        ),
        backgroundColor: const Color(0xFF123B63),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEvento,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próximos eventos',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _filtroFecha(),
              const SizedBox(height: 24),
              _resultados(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtroFecha() {
    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _elegirFecha,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            _fechaFiltro == null
                ? 'Filtrar por fecha'
                : _formatearFecha(_fechaFiltro!),
          ),
        ),
        if (_fechaFiltro != null)
          TextButton(
            onPressed: _limpiarFecha,
            child: const Text('Quitar filtro'),
          ),
      ],
    );
  }

  Widget _resultados() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(_error)),
      );
    }

    if (_eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('No hay eventos próximos')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_eventos.length} eventos encontrados',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ..._eventos.map(_tarjeta),
      ],
    );
  }

  Widget _tarjeta(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _abrirDetalle(evento.id),
        title: Text(
          evento.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${evento.fecha} · ${evento.hora}  ·  ${evento.lugar}\n'
            '${evento.comunidadNombre}'
            '${evento.cupo != null ? ' · Cupo: ${evento.cupo}' : ''}',
          ),
        ),
        isThreeLine: true,
        trailing: evento.cancelado
            ? const Chip(
                label: Text('Cancelado'),
                backgroundColor: Color(0xFFFCE4E4),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
