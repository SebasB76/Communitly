import 'package:flutter/material.dart';

import '../estado/estado_async.dart';
import '../modelos/solicitud.dart';
import '../servicios/api_solicitudes.dart';
import '../tema/tema.dart';
import '../widgets/encabezado.dart';
import '../widgets/esqueletos.dart';
import '../widgets/rejilla_responsiva.dart';
import '../widgets/vista_async.dart';
import 'solicitudes_widgets.dart';

/// RF-05 (vista del gestor): solicitudes recibidas por su comunidad.
/// Desde aquí también se resuelven, que es RF-06.
///
/// Si quien abre la pantalla no es gestor de la comunidad, el backend responde
/// 403 y ese mismo mensaje es el que se muestra.
class PantallaBandejaGestor extends StatefulWidget {
  final int comunidadId;

  const PantallaBandejaGestor({super.key, required this.comunidadId});

  @override
  State<PantallaBandejaGestor> createState() => _PantallaBandejaGestorState();
}

class _PantallaBandejaGestorState extends State<PantallaBandejaGestor> {
  Estado<ListaSolicitudes> _estado = const Cargando();
  String _estadoActivo = '';

  /// Una solicitud en curso no debe bloquear las demás tarjetas.
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
      final lista = await ApiSolicitudes.solicitudesComunidad(
        widget.comunidadId,
        estado: _estadoActivo,
      );
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

  /// Pide la observación opcional y resuelve la solicitud.
  Future<void> _resolver(Solicitud solicitud, String accion) async {
    final aprueba = accion == 'aprobar';
    final observacion = await pedirTexto(
      context,
      titulo: aprueba
          ? 'Aprobar la solicitud de ${solicitud.estudianteUsuario}'
          : 'Rechazar la solicitud de ${solicitud.estudianteUsuario}',
      etiqueta: 'Observación para el estudiante (opcional)',
      boton: aprueba ? 'Aprobar' : 'Rechazar',
      esDestructivo: !aprueba,
    );
    if (observacion == null) return;

    setState(() => _enCurso.add(solicitud.id));

    try {
      final mensaje = await ApiSolicitudes.resolverSolicitud(
        solicitud.id,
        accion: accion,
        observacion: observacion,
      );
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
    final titulo = lista == null || lista.comunidadNombre.isEmpty
        ? 'Solicitudes recibidas'
        : 'Solicitudes de ${lista.comunidadNombre}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
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
                  const Encabezado(
                    icono: Icons.inbox_outlined,
                    titulo: 'Bandeja del gestor',
                    subtitulo: 'Revisa cada postulación y respóndela con una observación.',
                  ),
                  const SizedBox(height: 24),
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
      iconoVacio: Icons.inbox_outlined,
      tituloVacio: _estadoActivo.isEmpty
          ? 'Esta comunidad aún no recibe solicitudes'
          : 'No hay solicitudes en este estado',
      textoAccionVacio: _estadoActivo.isEmpty ? null : 'Ver todas',
      alPulsarAccionVacio: _estadoActivo.isEmpty ? null : () => _filtrar(''),
      constructor: (context, lista) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lista.solicitudes.length == 1
                ? '1 solicitud'
                : '${lista.solicitudes.length} solicitudes',
            style: context.textos.bodyMedium?.copyWith(
              color: context.textoSecundario,
            ),
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
      titulo: solicitud.estudianteUsuario,
      solicitud: solicitud,
      acciones: [
        if (solicitud.pendiente) ...[
          FilledButton.icon(
            onPressed: ocupada ? null : () => _resolver(solicitud, 'aprobar'),
            icon: ocupada
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Aprobar'),
          ),
          OutlinedButton.icon(
            onPressed: ocupada ? null : () => _resolver(solicitud, 'rechazar'),
            icon: const Icon(Icons.close),
            label: const Text('Rechazar'),
          ),
        ],
      ],
    );
  }
}
