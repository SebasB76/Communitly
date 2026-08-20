import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../estado/estado_async.dart';
import '../modelos/comunidad.dart';
import '../rutas/rutas.dart';
import '../servicios/api.dart';
import '../servicios/sesion.dart';
import '../tema/tema.dart';
import '../widgets/esqueletos.dart';
import '../widgets/logo_comunidad.dart';
import '../widgets/vista_async.dart';
import 'solicitudes_widgets.dart';

class PantallaDetalle extends StatefulWidget {
  final int comunidadId;

  const PantallaDetalle({super.key, required this.comunidadId});

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  Estado<Comunidad> _estado = const Cargando();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _estado = const Cargando());

    try {
      final comunidad = await Api.detalleComunidad(widget.comunidadId);
      if (!mounted) return;
      setState(() => _estado = ConDatos(comunidad));
    } catch (error) {
      if (!mounted) return;
      setState(() => _estado = ConError.desde(error));
    }
  }

  Future<void> _alternarSeguimiento(Comunidad comunidad) async {
    setState(() => _procesando = true);

    try {
      final mensaje = comunidad.siguiendo
          ? await Api.dejarDeSeguir(comunidad.id)
          : await Api.seguir(comunidad.id);
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
    final comunidad = _estado.datosONulo;

    return Scaffold(
      appBar: AppBar(
        title: Text(comunidad?.nombre ?? 'Comunidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: VistaAsync<Comunidad>(
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

  Widget _contenido(BuildContext context, Comunidad comunidad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En pantallas estrechas el título y el botón no caben en una fila, así
        // que el Wrap los apila en lugar de desbordarse. El ancho infinito es
        // necesario para que `spaceBetween` tenga espacio que repartir: sin él
        // el Wrap encoge hasta sus hijos y arrastra a toda la columna.
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
                  LogoComunidad(
                    logo: comunidad.logo,
                    nombre: comunidad.nombre,
                    tamano: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    comunidad.nombre,
                    style: context.textos.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${comunidad.categoria} · ${comunidad.seguidores} seguidores',
                    style: context.textos.bodyLarge
                        ?.copyWith(color: context.textoSecundario),
                  ),
                ],
              ),
              _botonSeguir(comunidad),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Las dos acciones de comunidad, en un Wrap para que no se desborden
        // en pantallas estrechas.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _accionesSolicitud(comunidad),
            // RF-03: eventos de esta comunidad. El nombre viaja como `extra`
            // porque no está en la URL; con un enlace directo la pantalla se
            // titula solo "Eventos".
            OutlinedButton.icon(
              onPressed: () => context.push<void>(
                Rutas.eventosDeComunidad(comunidad.id),
                extra: comunidad.nombre,
              ),
              icon: const Icon(Icons.event),
              label: const Text('Ver eventos de esta comunidad'),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Text('Acerca de la comunidad', style: context.textos.titleLarge),
        const SizedBox(height: 8),
        Text(comunidad.descripcion, style: const TextStyle(height: 1.5)),
        if (comunidad.contacto.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Contacto', style: context.textos.titleLarge),
          const SizedBox(height: 8),
          SelectableText(comunidad.contacto),
        ],
      ],
    );
  }

  /// RF-06: la acción depende del rol. El gestor de esta comunidad revisa las
  /// solicitudes recibidas; cualquier otro usuario postula. El backend vuelve a
  /// comprobar el permiso en cada operación.
  Widget _accionesSolicitud(Comunidad comunidad) {
    if (Sesion.gestiona(comunidad.id)) {
      return FilledButton.icon(
        onPressed: () => context.push(Rutas.bandeja(comunidad.id)),
        icon: const Icon(Icons.inbox_outlined),
        label: const Text('Ver solicitudes recibidas'),
      );
    }

    return BotonSolicitarIngreso(
      // La clave fuerza a reconstruir el botón cuando el detalle se recarga con
      // un estado de solicitud distinto.
      key: ValueKey('${comunidad.id}:${comunidad.estadoMiSolicitud}'),
      comunidadId: comunidad.id,
      estadoConocido:
          comunidad.conoceMiSolicitud ? comunidad.estadoMiSolicitud : null,
      alCambiar: _cargar,
    );
  }

  Widget _botonSeguir(Comunidad comunidad) {
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

    if (comunidad.siguiendo) {
      return OutlinedButton.icon(
        onPressed: () => _alternarSeguimiento(comunidad),
        icon: const Icon(Icons.check),
        label: const Text('Siguiendo'),
      );
    }

    return FilledButton.icon(
      onPressed: () => _alternarSeguimiento(comunidad),
      icon: const Icon(Icons.add),
      label: const Text('Seguir'),
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
        Esqueleto(ancho: 260, alto: 30),
        SizedBox(height: 12),
        Esqueleto(ancho: 180, alto: 16),
        SizedBox(height: 32),
        Esqueleto(ancho: 190, alto: 44),
        SizedBox(height: 40),
        Esqueleto(alto: 14),
        SizedBox(height: 10),
        Esqueleto(alto: 14),
        SizedBox(height: 10),
        Esqueleto(ancho: 240, alto: 14),
      ],
    );
  }
}
