import '../modelos/comunidad.dart';
import 'cliente_api.dart';
import 'sesion.dart';

/// Catálogo de comunidades (RF-01 a RF-03).
///
/// Toda la mecánica HTTP —URL base, cabeceras, UTF-8, tiempo límite y errores—
/// vive en [ClienteApi]; aquí solo quedan las rutas y la conversión a modelos.
class Api {
  const Api._();

  /// Se mantiene por compatibilidad: la configuración real está en
  /// [ClienteApi.base].
  static String get base => ClienteApi.base;

  /// El estudiante que viaja en cada petición es el que inició sesión.
  static int get estudianteId => Sesion.id;

  static Future<List<Comunidad>> listarComunidades({
    String texto = '',
    String categoria = '',
  }) async {
    final parametros = {'estudiante_id': '$estudianteId'};
    if (texto.isNotEmpty) parametros['q'] = texto;
    if (categoria.isNotEmpty) parametros['categoria'] = categoria;

    final datos = await ClienteApi.obtener(
      '/comunidades/',
      parametros: parametros,
      errorPorDefecto: 'No se pudo cargar el catálogo',
    );

    final lista = datos['comunidades'] as List? ?? const [];
    return lista
        .map((json) => Comunidad.desdeJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Comunidad> detalleComunidad(int id) async {
    final datos = await ClienteApi.obtener(
      '/comunidades/$id/',
      parametros: {'estudiante_id': '$estudianteId'},
      errorPorDefecto: 'No se encontró la comunidad',
    );

    return Comunidad.desdeJson(datos);
  }

  static Future<String> seguir(int comunidadId) async {
    final datos = await ClienteApi.publicar(
      '/comunidades/$comunidadId/seguir/',
      cuerpo: {'estudiante_id': estudianteId},
      esperado: 201,
      errorPorDefecto: 'No se pudo seguir la comunidad',
    );

    return datos['mensaje'] as String? ?? 'Ahora sigues esta comunidad';
  }

  static Future<String> dejarDeSeguir(int comunidadId) async {
    final datos = await ClienteApi.eliminar(
      '/comunidades/$comunidadId/seguir/',
      cuerpo: {'estudiante_id': estudianteId},
      errorPorDefecto: 'No se pudo dejar de seguir la comunidad',
    );

    return datos['mensaje'] as String? ?? 'Dejaste de seguir esta comunidad';
  }
}
