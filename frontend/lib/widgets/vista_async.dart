import 'package:flutter/material.dart';

import '../estado/estado_async.dart';
import 'mensaje_centrado.dart';

/// Pinta un [Estado] resolviendo los cuatro casos de una lista: cargando,
/// error, vacío y con datos.
///
/// Es el reemplazo del bloque `if (_cargando) ... if (_error) ... if (vacío)`
/// que estaba copiado en el catálogo, en "mis solicitudes" y en la bandeja del
/// gestor, cada uno con detalles distintos y ninguno con botón de reintentar.
class VistaAsync<T> extends StatelessWidget {
  final Estado<T> estado;

  /// Qué pintar cuando hay datos.
  final Widget Function(BuildContext context, T datos) constructor;

  /// Silueta que se muestra mientras carga.
  final Widget cargando;

  /// Se vuelve a llamar desde el botón de reintentar.
  final Future<void> Function() alReintentar;

  /// Decide si los datos que llegaron son un resultado vacío.
  final bool Function(T datos)? estaVacio;

  final String tituloVacio;
  final String? detalleVacio;
  final IconData iconoVacio;

  /// Acción alternativa del estado vacío, como "limpiar filtros".
  final String? textoAccionVacio;
  final VoidCallback? alPulsarAccionVacio;

  const VistaAsync({
    super.key,
    required this.estado,
    required this.constructor,
    required this.cargando,
    required this.alReintentar,
    this.estaVacio,
    this.tituloVacio = 'No hay nada por aquí',
    this.detalleVacio,
    this.iconoVacio = Icons.inbox_outlined,
    this.textoAccionVacio,
    this.alPulsarAccionVacio,
  });

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      Cargando<T>() => cargando,
      ConError<T>(:final mensaje, :final sePuedeReintentar) => MensajeCentrado(
          icono: sePuedeReintentar ? Icons.cloud_off : Icons.lock_outline,
          titulo: sePuedeReintentar
              ? 'No pudimos cargar esta información'
              : 'No puedes ver esto',
          detalle: mensaje,
          esError: true,
          textoAccion: sePuedeReintentar ? 'Reintentar' : null,
          alPulsarAccion: sePuedeReintentar ? alReintentar : null,
        ),
      ConDatos<T>(:final datos) => _conDatos(context, datos),
    };
  }

  Widget _conDatos(BuildContext context, T datos) {
    if (estaVacio?.call(datos) ?? false) {
      return MensajeCentrado(
        icono: iconoVacio,
        titulo: tituloVacio,
        detalle: detalleVacio,
        textoAccion: textoAccionVacio,
        alPulsarAccion: alPulsarAccionVacio,
      );
    }

    return constructor(context, datos);
  }
}
