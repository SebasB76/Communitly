// Pruebas de la sesión y los permisos. Es infraestructura compartida, así que
// se verifica aparte del módulo de solicitudes.

import 'package:communitly_frontend/modelos/usuario.dart';
import 'package:communitly_frontend/servicios/api.dart';
import 'package:communitly_frontend/servicios/api_solicitudes.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Respuesta real de `POST /api/sesion/` para un estudiante.
Map<String, dynamic> estudianteJson() => {
      'id': 1,
      'usuario': 'estudiante1',
      'nombre': 'estudiante1',
      'es_gestor': false,
      'comunidades_gestionadas': <Map<String, dynamic>>[],
    };

Map<String, dynamic> gestorJson() => {
      'id': 3,
      'usuario': 'gestor_ciap',
      'nombre': 'gestor_ciap',
      'es_gestor': true,
      'comunidades_gestionadas': [
        {'id': 1, 'nombre': 'CIAP'},
      ],
    };

void main() {
  tearDown(Sesion.cerrar);

  group('UsuarioSesion', () {
    test('convierte a un estudiante sin comunidades', () {
      final usuario = UsuarioSesion.desdeJson(estudianteJson());

      expect(usuario.id, 1);
      expect(usuario.usuario, 'estudiante1');
      expect(usuario.esGestor, isFalse);
      expect(usuario.comunidadesGestionadas, isEmpty);
    });

    test('convierte a un gestor con su comunidad', () {
      final usuario = UsuarioSesion.desdeJson(gestorJson());

      expect(usuario.esGestor, isTrue);
      expect(usuario.comunidadesGestionadas.single.nombre, 'CIAP');
    });

    test('el permiso es por comunidad, no general', () {
      final usuario = UsuarioSesion.desdeJson(gestorJson());

      expect(usuario.gestionaComunidad(1), isTrue);
      expect(usuario.gestionaComunidad(6), isFalse);
    });

    test('un estudiante no gestiona ninguna comunidad', () {
      final usuario = UsuarioSesion.desdeJson(estudianteJson());

      expect(usuario.gestionaComunidad(1), isFalse);
    });
  });

  group('Sesion', () {
    test('sin sesión no hay usuario activo', () {
      expect(Sesion.activa, isFalse);
      expect(Sesion.esGestor, isFalse);
      expect(Sesion.gestiona(1), isFalse);
      expect(() => Sesion.actual, throwsStateError);
    });

    test('abrir deja disponible al usuario conectado', () {
      Sesion.abrir(UsuarioSesion.desdeJson(gestorJson()));

      expect(Sesion.activa, isTrue);
      expect(Sesion.id, 3);
      expect(Sesion.esGestor, isTrue);
      expect(Sesion.gestiona(1), isTrue);
      expect(Sesion.gestiona(6), isFalse);
    });

    test('cerrar borra los permisos', () {
      Sesion.abrir(UsuarioSesion.desdeJson(gestorJson()));
      Sesion.cerrar();

      expect(Sesion.activa, isFalse);
      expect(Sesion.gestiona(1), isFalse);
    });

    test('avisa a la interfaz cuando cambia', () {
      var avisos = 0;
      void escuchar() => avisos++;
      Sesion.usuario.addListener(escuchar);

      Sesion.abrir(UsuarioSesion.desdeJson(estudianteJson()));
      Sesion.cerrar();
      Sesion.usuario.removeListener(escuchar);

      expect(avisos, 2);
    });
  });

  group('Identidad que viaja en las peticiones', () {
    test('el estudiante y el gestor salen de la sesión, no de una constante',
        () {
      Sesion.abrir(UsuarioSesion.desdeJson(gestorJson()));

      expect(Api.estudianteId, 3);
      expect(ApiSolicitudes.gestorId, 3);
    });

    test('cambia al entrar con otra cuenta', () {
      Sesion.abrir(UsuarioSesion.desdeJson(gestorJson()));
      Sesion.abrir(UsuarioSesion.desdeJson(estudianteJson()));

      expect(Api.estudianteId, 1);
      expect(ApiSolicitudes.gestorId, 1);
    });

    test('sin sesión no se puede armar una petición', () {
      expect(() => Api.estudianteId, throwsStateError);
    });
  });
}
