import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/usuario.dart';

/// Guarda la sesión en el almacenamiento del navegador.
///
/// Sin esto, recargar la página (F5, que en una app web pasa todo el tiempo)
/// devolvía al login aunque el usuario acabara de entrar.
///
/// Solo se guarda la identidad y los permisos que ya devuelve el backend: no
/// hay credenciales aquí. Los permisos se vuelven a comprobar en el servidor en
/// cada operación, así que lo peor que puede pasar con un dato viejo es que se
/// ofrezca una acción que luego responda 403.
class AlmacenSesion {
  const AlmacenSesion._();

  static const String _clave = 'communitly.sesion';

  static Future<void> guardar(UsuarioSesion usuario) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_clave, jsonEncode(usuario.aJson()));
  }

  static Future<UsuarioSesion?> leer() async {
    final preferencias = await SharedPreferences.getInstance();
    final guardado = preferencias.getString(_clave);
    if (guardado == null || guardado.isEmpty) return null;

    try {
      final json = jsonDecode(guardado) as Map<String, dynamic>;
      return UsuarioSesion.desdeJson(json);
    } catch (_) {
      // Formato viejo o corrupto: se descarta y se vuelve al login.
      await preferencias.remove(_clave);
      return null;
    }
  }

  static Future<void> borrar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_clave);
  }
}
