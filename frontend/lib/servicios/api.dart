import '../modelos/comunidad.dart';
import '../modelos/evento.dart';
import 'cliente_api.dart';
import 'sesion.dart';

/// Catálogo de comunidades y eventos (RF-01 a RF-04).
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

  /// El gestor que crea, edita o cancela un evento es el usuario conectado.
  /// El backend comprueba que gestione esa comunidad y responde 403 si no.
  static int get gestorId => Sesion.id;

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

  // --- RF-03 y RF-04: eventos -----------------------------------------------

  static Future<List<Evento>> listarEventos({
    int? comunidadId,
    String fecha = '',
  }) async {
    final parametros = <String, String>{};
    if (comunidadId != null) parametros['comunidad'] = '$comunidadId';
    if (fecha.isNotEmpty) parametros['fecha'] = fecha;

    final datos = await ClienteApi.obtener(
      '/eventos/',
      parametros: parametros,
      errorPorDefecto: 'No se pudieron cargar los eventos',
    );

    final lista = datos['eventos'] as List? ?? const [];
    return lista
        .map((json) => Evento.desdeJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Evento> detalleEvento(int id) async {
    final datos = await ClienteApi.obtener(
      '/eventos/$id/',
      errorPorDefecto: 'No se encontró el evento',
    );

    return Evento.desdeJson(datos);
  }

  static Future<Evento> crearEvento({
    required int comunidadId,
    required String titulo,
    required String descripcion,
    required String fecha,
    required String hora,
    required String lugar,
    int? cupo,
  }) async {
    final datos = await ClienteApi.publicar(
      '/eventos/',
      cuerpo: {
        'gestor_id': gestorId,
        'comunidad_id': comunidadId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha,
        'hora': hora,
        'lugar': lugar,
        'cupo': ?cupo,
      },
      esperado: 201,
      errorPorDefecto: 'No se pudo crear el evento',
    );

    return Evento.desdeJson(datos['evento'] as Map<String, dynamic>);
  }

  static Future<Evento> editarEvento({
    required int id,
    required String titulo,
    required String descripcion,
    required String fecha,
    required String hora,
    required String lugar,
    int? cupo,
  }) async {
    final datos = await ClienteApi.parchear(
      '/eventos/$id/',
      cuerpo: {
        'gestor_id': gestorId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha,
        'hora': hora,
        'lugar': lugar,
        'cupo': cupo,
      },
      errorPorDefecto: 'No se pudo actualizar el evento',
    );

    return Evento.desdeJson(datos['evento'] as Map<String, dynamic>);
  }

  static Future<String> cancelarEvento(int id) async {
    final datos = await ClienteApi.eliminar(
      '/eventos/$id/',
      cuerpo: {'gestor_id': gestorId},
      errorPorDefecto: 'No se pudo cancelar el evento',
    );

    return datos['mensaje'] as String? ?? 'Evento cancelado';
  }
}
