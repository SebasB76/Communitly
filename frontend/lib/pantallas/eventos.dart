import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../estado/estado_async.dart';
import '../modelos/evento.dart';
import '../rutas/rutas.dart';
import '../servicios/api.dart';
import '../servicios/sesion.dart';
import '../tema/tema.dart';
import '../utilidades/fechas.dart';
import '../widgets/encabezado.dart';
import '../widgets/esqueletos.dart';
import '../widgets/rejilla_responsiva.dart';
import '../widgets/vista_async.dart';
import 'evento_formulario.dart';
import 'eventos_widgets.dart';

/// RF-03: eventos de todas las comunidades o de una sola.
class PantallaEventos extends StatefulWidget {
  final int? comunidadId;
  final String? comunidadNombre;

  const PantallaEventos({super.key, this.comunidadId, this.comunidadNombre});

  @override
  State<PantallaEventos> createState() => _PantallaEventosState();
}

class _PantallaEventosState extends State<PantallaEventos> {
  Estado<List<Evento>> _estado = const Cargando();
  DateTime? _fechaFiltro;

  int _ultimaPeticion = 0;

  /// RF-04: crear solo se ofrece a quien gestiona. El backend vuelve a
  /// comprobarlo y responde 403 si no corresponde.
  bool get _puedeCrear => widget.comunidadId == null
      ? Sesion.esGestor
      : Sesion.gestiona(widget.comunidadId!);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final peticion = ++_ultimaPeticion;
    setState(() => _estado = const Cargando());

    try {
      final lista = await Api.listarEventos(
        comunidadId: widget.comunidadId,
        fecha: _fechaFiltro == null ? '' : _comoIso(_fechaFiltro!),
      );
      if (!mounted || peticion != _ultimaPeticion) return;
      setState(() => _estado = ConDatos(lista));
    } catch (error) {
      if (!mounted || peticion != _ultimaPeticion) return;
      setState(() => _estado = ConError.desde(error));
    }
  }

  String _comoIso(DateTime fecha) {
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
    if (seleccionada == null) return;

    setState(() => _fechaFiltro = seleccionada);
    await _cargar();
  }

  void _limpiarFecha() {
    setState(() => _fechaFiltro = null);
    _cargar();
  }

  Future<void> _abrirDetalle(int id) async {
    await context.push<void>(Rutas.evento(id));
    if (mounted) await _cargar();
  }

  Future<void> _crearEvento() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PantallaEventoFormulario(
          comunidadId: widget.comunidadId,
          comunidadNombre: widget.comunidadNombre,
        ),
      ),
    );
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.comunidadNombre;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre == null ? 'Eventos' : 'Eventos · $nombre'),
        actions: [
          IconButton(
            onPressed: _estado is Cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _crearEvento,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo evento'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Encabezado(
                    icono: Icons.event_outlined,
                    titulo: 'Próximos eventos',
                    subtitulo:
                        'Actividades que publican las comunidades de la ESPOL.',
                  ),
                  const SizedBox(height: 24),
                  _filtroFecha(),
                  const SizedBox(height: 24),
                  _resultados(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtroFecha() {
    final fecha = _fechaFiltro;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _elegirFecha,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            fecha == null ? 'Filtrar por fecha' : Fechas.conDiaSemana(fecha),
          ),
        ),
        if (fecha != null)
          TextButton(
            onPressed: _limpiarFecha,
            child: const Text('Quitar filtro'),
          ),
      ],
    );
  }

  Widget _resultados() {
    final hayFiltro = _fechaFiltro != null;

    return VistaAsync<List<Evento>>(
      estado: _estado,
      cargando: const EsqueletoRejilla(
        cantidad: 4,
        anchoMinimo: 420,
        plantilla: EsqueletoEvento(),
      ),
      alReintentar: _cargar,
      estaVacio: (lista) => lista.isEmpty,
      iconoVacio: Icons.event_busy_outlined,
      tituloVacio: hayFiltro
          ? 'No hay eventos ese día'
          : 'No hay eventos próximos',
      detalleVacio: hayFiltro
          ? 'Prueba con otra fecha o quita el filtro.'
          : 'Cuando una comunidad publique uno, aparecerá aquí.',
      textoAccionVacio: hayFiltro ? 'Quitar filtro' : null,
      alPulsarAccionVacio: hayFiltro ? _limpiarFecha : null,
      constructor: (context, lista) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lista.length == 1 ? '1 evento' : '${lista.length} eventos',
            style: context.textos.bodyMedium?.copyWith(
              color: context.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          RejillaResponsiva(
            anchoMinimo: 420,
            hijos: [
              for (final evento in lista)
                TarjetaEvento(
                  evento: evento,
                  alPulsar: () => _abrirDetalle(evento.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
