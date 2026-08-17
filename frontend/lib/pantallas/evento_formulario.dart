import 'package:flutter/material.dart';

import '../modelos/comunidad.dart';
import '../modelos/evento.dart';
import '../servicios/api.dart';

class PantallaEventoFormulario extends StatefulWidget {
  final int? comunidadId;
  final String? comunidadNombre;
  final Evento? eventoExistente;

  const PantallaEventoFormulario({
    super.key,
    this.comunidadId,
    this.comunidadNombre,
    this.eventoExistente,
  });

  bool get esEdicion => eventoExistente != null;

  @override
  State<PantallaEventoFormulario> createState() =>
      _PantallaEventoFormularioState();
}

class _PantallaEventoFormularioState extends State<PantallaEventoFormulario> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _cupoCtrl = TextEditingController();

  List<Comunidad> _comunidades = [];
  int? _comunidadSeleccionada;
  DateTime? _fecha;
  TimeOfDay? _hora;

  bool _cargandoComunidades = true;
  bool _guardando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _comunidadSeleccionada = widget.comunidadId ?? widget.eventoExistente?.comunidadId;

    if (widget.esEdicion) {
      final e = widget.eventoExistente!;
      _tituloCtrl.text = e.titulo;
      _descripcionCtrl.text = e.descripcion;
      _lugarCtrl.text = e.lugar;
      _cupoCtrl.text = e.cupo?.toString() ?? '';
      _fecha = e.fechaComoDateTime;
      final partes = e.hora.split(':');
      _hora = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
    }

    if (!widget.esEdicion && widget.comunidadId == null) {
      _cargarComunidades();
    } else {
      _cargandoComunidades = false;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    _cupoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarComunidades() async {
    try {
      final lista = await Api.listarComunidades();
      setState(() {
        _comunidades = lista;
        _cargandoComunidades = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las comunidades';
        _cargandoComunidades = false;
      });
    }
  }

  Future<void> _elegirFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (seleccionada != null) setState(() => _fecha = seleccionada);
  }

  Future<void> _elegirHora() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (seleccionada != null) setState(() => _hora = seleccionada);
  }

  String _formatearFecha(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_comunidadSeleccionada == null) {
      _avisar('Selecciona una comunidad');
      return;
    }
    if (_fecha == null) {
      _avisar('Selecciona una fecha');
      return;
    }
    if (_hora == null) {
      _avisar('Selecciona una hora');
      return;
    }

    setState(() => _guardando = true);

    final cupoTexto = _cupoCtrl.text.trim();
    final cupo = cupoTexto.isEmpty ? null : int.tryParse(cupoTexto);

    try {
      if (widget.esEdicion) {
        await Api.editarEvento(
          id: widget.eventoExistente!.id,
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          fecha: _formatearFecha(_fecha!),
          hora: _formatearHora(_hora!),
          lugar: _lugarCtrl.text.trim(),
          cupo: cupo,
        );
        _avisar('Evento actualizado');
      } else {
        await Api.crearEvento(
          comunidadId: _comunidadSeleccionada!,
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          fecha: _formatearFecha(_fecha!),
          hora: _formatearHora(_hora!),
          lugar: _lugarCtrl.text.trim(),
          cupo: cupo,
        );
        _avisar('Evento creado');
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _avisar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar evento' : 'Nuevo evento'),
        backgroundColor: const Color(0xFF123B63),
        foregroundColor: Colors.white,
      ),
      body: _cargandoComunidades
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error, style: const TextStyle(color: Colors.red)),
                      ),
                    _campoComunidad(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lugarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lugar',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _elegirFecha,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _fecha == null ? 'Fecha' : _formatearFecha(_fecha!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _elegirHora,
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              _hora == null ? 'Hora' : _formatearHora(_hora!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cupoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cupo (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.esEdicion ? 'Guardar cambios' : 'Crear evento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _campoComunidad() {
    if (widget.esEdicion) {
      return TextFormField(
        initialValue: widget.eventoExistente!.comunidadNombre,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'Comunidad',
          border: OutlineInputBorder(),
        ),
      );
    }

    if (widget.comunidadId != null) {
      return TextFormField(
        initialValue: widget.comunidadNombre ?? 'Comunidad #${widget.comunidadId}',
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'Comunidad',
          border: OutlineInputBorder(),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _comunidadSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Comunidad',
        border: OutlineInputBorder(),
      ),
      items: _comunidades
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
          .toList(),
      onChanged: (valor) => setState(() => _comunidadSeleccionada = valor),
      validator: (v) => v == null ? 'Selecciona una comunidad' : null,
    );
  }
}
