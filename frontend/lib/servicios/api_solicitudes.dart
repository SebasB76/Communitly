import '../modelos/solicitud.dart';
import 'api.dart';
import 'cliente_api.dart';
import 'sesion.dart';

/// Llamadas HTTP del RF-05 (consultar) y RF-06 (gestionar).
class ApiSolicitudes {
  const ApiSolicitudes._();

  /// El gestor que resuelve es el usuario conectado. El backend comprueba que
  /// realmente gestione la comunidad y responde 403 si no.
  static int get gestorId => Sesion.id;

  // --- RF-05: consultar solicitudes -----------------------------------------

  /// Solicitudes que envió el estudiante. `estado` vacío trae todas.
  static Future<ListaSolicitudes> misSolicitudes({String estado = ''}) async {
    final parametros = {'estudiante_id': '${Api.estudianteId}'};
    if (estado.isNotEmpty) parametros['estado'] = estado;

    final datos = await ClienteApi.obtener(
      '/solicitudes/',
      parametros: parametros,
      errorPorDefecto: 'No se pudieron cargar tus solicitudes',
    );

    return ListaSolicitudes.desdeJson(datos);
  }

  /// Bandeja del gestor: solicitudes recibidas por una comunidad.
  static Future<ListaSolicitudes> solicitudesComunidad(
    int comunidadId, {
    String estado = '',
  }) async {
    final parametros = {'gestor_id': '$gestorId'};
    if (estado.isNotEmpty) parametros['estado'] = estado;

    final datos = await ClienteApi.obtener(
      '/comunidades/$comunidadId/solicitudes/',
      parametros: parametros,
      errorPorDefecto: 'No se pudieron cargar las solicitudes',
    );

    return ListaSolicitudes.desdeJson(datos);
  }

  /// Detalle de una solicitud propia del estudiante.
  static Future<Solicitud> detalleSolicitud(int solicitudId) async {
    final datos = await ClienteApi.obtener(
      '/solicitudes/$solicitudId/',
      parametros: {'estudiante_id': '${Api.estudianteId}'},
      errorPorDefecto: 'No se encontró la solicitud',
    );

    return Solicitud.desdeJson(datos);
  }

  // --- RF-06: gestionar solicitudes de ingreso ------------------------------

  /// Envía la solicitud del estudiante. El mensaje es opcional.
  static Future<String> solicitarIngreso(
    int comunidadId, {
    String mensaje = '',
  }) async {
    final datos = await ClienteApi.publicar(
      '/comunidades/$comunidadId/solicitar/',
      cuerpo: {'estudiante_id': Api.estudianteId, 'mensaje': mensaje},
      esperado: 201,
      errorPorDefecto: 'No se pudo enviar la solicitud',
    );

    return datos['mensaje'] as String? ?? 'Solicitud enviada';
  }

  /// Retira la solicitud pendiente. El registro queda en el historial.
  static Future<String> retirarSolicitud(int comunidadId) async {
    final datos = await ClienteApi.eliminar(
      '/comunidades/$comunidadId/solicitar/',
      cuerpo: {'estudiante_id': Api.estudianteId},
      errorPorDefecto: 'No se pudo retirar la solicitud',
    );

    return datos['mensaje'] as String? ?? 'Solicitud retirada';
  }

  /// El gestor aprueba o rechaza. `accion` es 'aprobar' o 'rechazar'.
  static Future<String> resolverSolicitud(
    int solicitudId, {
    required String accion,
    String observacion = '',
  }) async {
    final datos = await ClienteApi.publicar(
      '/solicitudes/$solicitudId/resolver/',
      cuerpo: {
        'gestor_id': gestorId,
        'accion': accion,
        'observacion': observacion,
      },
      errorPorDefecto: 'No se pudo resolver la solicitud',
    );

    return datos['mensaje'] as String? ?? 'Solicitud resuelta';
  }
}
