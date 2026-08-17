import 'package:flutter/material.dart';

import '../estado/estado_async.dart';
import '../modelos/solicitud.dart';
import '../servicios/api_solicitudes.dart';
import '../tema/tema.dart';
import '../widgets/esqueletos.dart';
import '../widgets/rejilla_responsiva.dart';
import '../widgets/vista_async.dart';
import 'solicitudes_widgets.dart';

/// RF-05 (vista del estudiante): estado de las solicitudes que envió.
/// Incorpora también el retiro de una solicitud pendiente, que es RF-06.
class PantallaMisSolicitudes extends StatefulWidget {
  const PantallaMisSolicitudes({super.key});

  @override
  State<PantallaMisSolicitudes> createState() => _PantallaMisSolicitudesState();
}

class _PantallaMisSolicitudesState extends State<PantallaMisSolicitudes> {
  Estado<ListaSolicitudes> _estado = const Cargando();
  String _estadoActivo = '';

  /// Ids en curso, en vez de un único booleano: antes retirar una solicitud
  /// deshabilitaba los botones de todas las tarjetas a la vez.
  final Set<int> _enCurso = {};

  int _ultimaPeticion = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final peticion = ++_ultimaPeticion;
    setState(() => _estado = const Cargando());

    try {
      final lista = await ApiSolicitudes.misSolicitudes(estado: _estadoActivo);
      if (!mounted || peticion != _ultimaPeticion) return;
      setState(() => _estado = ConDatos(lista));
    } catch (error) {
      if (!mounted || peticion != _ultimaPeticion) return;
      setState(() => _estado = ConError.desde(error));
    }
  }

  void _filtrar(String estado) {
    setState(() => _estadoActivo = estado);
    _cargar();
  }

  Future<void> _retirar(Solicitud solicitud) async {
    setState(() => _enCurso.add(solicitud.id));

    try {
      final mensaje =
          await ApiSolicitudes.retirarSolicitud(solicitud.comunidadId);
      await _cargar();
      if (mounted) mostrarAviso(context, mensaje);
    } catch (error) {
      if (mounted) {
        mostrarAviso(context, mensajeDeFalla(error), esError: true);
      }
    }

    if (!mounted) return;
    setState(() => _enCurso.remove(solicitud.id));
  }

  @override
  Widget build(BuildContext context) {
    final lista = _estado.datosONulo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            onPressed: _estado is Cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado de tus solicitudes',
                    style: context.textos.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aquí ves en qué va cada comunidad a la que postulaste.',
                    style: context.textos.bodyMedium
                        ?.copyWith(color: context.textoSecundario),
                  ),
                  const SizedBox(height: 20),
                  // Los filtros siguen visibles mientras recarga: el resumen no
                  // depende del filtro activo.
                  if (lista != null)
                    FiltroEstados(
                      estadoActivo: _estadoActivo,
                      resumen: lista.resumen,
                      alCambiar: _filtrar,
                    ),
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

  Widget _resultados() {
    return VistaAsync<ListaSolicitudes>(
      estado: _estado,
      cargando: const EsqueletoRejilla(cantidad: 3, anchoMinimo: 420),
      alReintentar: _cargar,
      estaVacio: (lista) => lista.solicitudes.isEmpty,
      iconoVacio: Icons.assignment_outlined,
      tituloVacio: _estadoActivo.isEmpty
          ? 'Todavía no has postulado a ninguna comunidad'
          : 'No tienes solicitudes en este estado',
      detalleVacio: _estadoActivo.isEmpty
          ? 'Explora el catálogo y envía tu primera solicitud.'
          : null,
      textoAccionVacio: _estadoActivo.isEmpty ? null : 'Ver todas',
      alPulsarAccionVacio: _estadoActivo.isEmpty ? null : () => _filtrar(''),
      constructor: (context, lista) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lista.solicitudes.length == 1
                ? '1 solicitud'
                : '${lista.solicitudes.length} solicitudes',
            style: context.textos.bodyMedium
                ?.copyWith(color: context.textoSecundario),
          ),
          const SizedBox(height: 12),
          RejillaResponsiva(
            anchoMinimo: 420,
            hijos: [
              for (final solicitud in lista.solicitudes) _tarjeta(solicitud),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Solicitud solicitud) {
    final ocupada = _enCurso.contains(solicitud.id);

    return TarjetaSolicitud(
      titulo: solicitud.comunidadNombre,
      solicitud: solicitud,
      acciones: [
        if (solicitud.pendiente)
          OutlinedButton.icon(
            onPressed: ocupada ? null : () => _retirar(solicitud),
            icon: ocupada
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.close),
            label: const Text('Retirar solicitud'),
          ),
      ],
    );
  }
}
