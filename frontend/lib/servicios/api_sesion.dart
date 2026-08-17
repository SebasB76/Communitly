import '../modelos/usuario.dart';
import 'cliente_api.dart';

/// Llamadas de autenticación. La validación de las credenciales la hace
/// Django; aquí solo se envían y se guarda la identidad que responde.
class ApiSesion {
  const ApiSesion._();

  /// Inicia sesión con usuario y contraseña institucionales.
  static Future<UsuarioSesion> iniciar({
    required String usuario,
    required String contrasena,
  }) async {
    final datos = await ClienteApi.publicar(
      '/sesion/',
      cuerpo: {'usuario': usuario, 'contrasena': contrasena},
      errorPorDefecto: 'No se pudo iniciar sesión',
    );

    return UsuarioSesion.desdeJson(datos['usuario'] as Map<String, dynamic>);
  }

  /// Vuelve a pedir los permisos del usuario, por si cambiaron sus comunidades.
  /// Se usa al restaurar una sesión guardada, que puede estar desactualizada.
  static Future<UsuarioSesion> refrescarPermisos(int usuarioId) async {
    final datos = await ClienteApi.obtener(
      '/sesion/',
      parametros: {'usuario_id': '$usuarioId'},
      errorPorDefecto: 'No se pudieron cargar los permisos',
    );

    return UsuarioSesion.desdeJson(datos['usuario'] as Map<String, dynamic>);
  }
}
