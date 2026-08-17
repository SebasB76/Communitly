import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/usuario.dart';
import 'almacen_sesion.dart';

/// Sesión activa de la aplicación.
///
/// Infraestructura compartida: cualquier módulo pregunta aquí quién está
/// conectado y qué puede hacer, en vez de repetir la comprobación o volver a
/// fijar un id. RF-04 (gestionar eventos) puede usar `Sesion.gestiona()` igual
/// que lo hace RF-05 y RF-06.
///
/// Ocultar una acción **no** es la validación: el backend vuelve a comprobar
/// cada permiso y responde 403 si no corresponde.
class Sesion {
  /// Notifica a la interfaz cuando alguien entra o sale. Lo escuchan el
  /// `MaterialApp` y el enrutador, que es lo que hace que cerrar sesión desde
  /// cualquier pantalla lleve al login sin navegación manual.
  static final ValueNotifier<UsuarioSesion?> usuario =
      ValueNotifier<UsuarioSesion?>(null);

  /// Los tests la apagan: `shared_preferences` necesita el binding de
  /// plataforma, que en una prueba unitaria no existe.
  static bool persistenciaHabilitada = true;

  static bool get activa => usuario.value != null;

  /// Usuario conectado, o null. Es lo que debe leer la interfaz: durante el
  /// fotograma en que se cierra la sesión una pantalla puede seguir montada.
  static UsuarioSesion? get actualONulo => usuario.value;

  /// Usuario conectado, exigiendo que lo haya. Lo usan los servicios: armar una
  /// petición sin sesión es un error de programación, no un caso a manejar.
  static UsuarioSesion get actual {
    final conectado = usuario.value;
    if (conectado == null) {
      throw StateError('No hay una sesión activa');
    }
    return conectado;
  }

  /// Id del usuario conectado, que es el que viaja en cada petición.
  static int get id => actual.id;

  static bool get esGestor => usuario.value?.esGestor ?? false;

  /// Si el usuario conectado gestiona esa comunidad.
  static bool gestiona(int comunidadId) {
    return usuario.value?.gestionaComunidad(comunidadId) ?? false;
  }

  static void abrir(UsuarioSesion conectado) {
    usuario.value = conectado;
    unawaited(_persistir(conectado));
  }

  static void cerrar() {
    usuario.value = null;
    unawaited(_persistir(null));
  }

  /// Recupera la sesión guardada al arrancar. Se llama antes de `runApp`.
  static Future<void> restaurar() async {
    if (!persistenciaHabilitada) return;

    try {
      usuario.value = await AlmacenSesion.leer();
    } catch (error) {
      // Sin almacenamiento disponible se arranca sin sesión, que es el
      // comportamiento que había antes de persistirla.
      debugPrint('No se pudo restaurar la sesión: $error');
    }
  }

  /// La escritura en disco no debe bloquear ni romper la interfaz: si falla, la
  /// sesión sigue viva en memoria durante esta visita.
  static Future<void> _persistir(UsuarioSesion? conectado) async {
    if (!persistenciaHabilitada) return;

    try {
      if (conectado == null) {
        await AlmacenSesion.borrar();
      } else {
        await AlmacenSesion.guardar(conectado);
      }
    } catch (error) {
      debugPrint('No se pudo guardar la sesión: $error');
    }
  }
}
