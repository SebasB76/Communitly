import 'package:flutter/material.dart';

import '../modelos/comunidad.dart';
import '../servicios/api.dart';
import 'eventos.dart';

class PantallaDetalle extends StatefulWidget {
  final int comunidadId;

  const PantallaDetalle({super.key, required this.comunidadId});

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  Comunidad? _comunidad;
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
      final comunidad = await Api.detalleComunidad(widget.comunidadId);
      if (!mounted) return;
      setState(() {
        _comunidad = comunidad;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la comunidad';
        _cargando = false;
      });
    }
  }

  Future<void> _alternarSeguimiento() async {
    final comunidad = _comunidad!;
    setState(() => _procesando = true);

    try {
      final mensaje = comunidad.siguiendo
          ? await Api.dejarDeSeguir(comunidad.id)
          : await Api.seguir(comunidad.id);
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
        title: const Text('ESPOL Communities'),
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

    final comunidad = _comunidad!;

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
                      comunidad.nombre,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${comunidad.categoria} · ${comunidad.seguidores} seguidores',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              _botonSeguir(comunidad),
            ],
          ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaEventos(
                    comunidadId: comunidad.id,
                    comunidadNombre: comunidad.nombre,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.event),
            label: const Text('Ver eventos de esta comunidad'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Acerca de la comunidad',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(comunidad.descripcion, style: const TextStyle(height: 1.5)),
          if (comunidad.contacto.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Contacto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(comunidad.contacto),
          ],
        ],
      ),
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
        onPressed: _alternarSeguimiento,
        icon: const Icon(Icons.check),
        label: const Text('Siguiendo'),
      );
    }

    return FilledButton.icon(
      onPressed: _alternarSeguimiento,
      icon: const Icon(Icons.add),
      label: const Text('Seguir'),
    );
  }
}
