// Pruebas del cliente HTTP: cómo se traduce cada tipo de falla a algo que la
// interfaz pueda mostrar y saber si vale la pena reintentar.

import 'package:communitly_frontend/estado/estado_async.dart';
import 'package:communitly_frontend/modelos/usuario.dart';
import 'package:communitly_frontend/servicios/api.dart';
import 'package:communitly_frontend/servicios/api_solicitudes.dart';
import 'package:communitly_frontend/servicios/cliente_api.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'ayuda.dart';

void main() {
  setUp(abrirSesionDePrueba);

  tearDown(() {
    Sesion.cerrar();
    ClienteApi.cliente = http.Client();
  });

  group('ErrorApi', () {
    test('un servidor caído se reporta como problema de red', () async {
      responderConFalloDeRed();

      final error = await Api.listarComunidades().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect(error, isA<ErrorApi>());
      expect((error! as ErrorApi).esDeRed, isTrue);
      expect((error as ErrorApi).mensaje, contains('No pudimos conectarnos'));
    });

    test('el mensaje de validación del backend se muestra tal cual', () async {
      responderCon(
        {'error': 'Ya tienes una solicitud pendiente en CIAP'},
        codigo: 400,
      );

      final error = await ApiSolicitudes.solicitarIngreso(1).then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect(error, isA<ErrorApi>());
      expect(
        (error! as ErrorApi).mensaje,
        'Ya tienes una solicitud pendiente en CIAP',
      );
      expect((error as ErrorApi).esDeRed, isFalse);
    });

    test('un 403 no es reintentable', () async {
      responderCon({'error': 'No gestionas esta comunidad'}, codigo: 403);

      final error = await ApiSolicitudes.solicitudesComunidad(9).then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect((error! as ErrorApi).esProhibido, isTrue);
      expect(ConError<void>.desde(error).sePuedeReintentar, isFalse);
    });

    test('una respuesta que no es JSON cae al mensaje por defecto', () async {
      ClienteApi.cliente = _clienteQueDevuelveHtml();

      final error = await Api.detalleComunidad(1).then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect((error! as ErrorApi).mensaje, 'No se encontró la comunidad');
    });
  });

  group('Identidad en la petición', () {
    test('el id del usuario conectado viaja en la URL', () async {
      final contador = responderCon({'comunidades': <Map<String, dynamic>>[]});

      await Api.listarComunidades(texto: 'rob', categoria: 'Tecnología');

      expect(contador.ultimaUrl, contains('estudiante_id=1'));
      expect(contador.ultimaUrl, contains('q=rob'));
      expect(contador.ultimaUrl, contains('categoria=Tecnolog'));
    });

    test('los filtros vacíos no se mandan', () async {
      final contador = responderCon({'comunidades': <Map<String, dynamic>>[]});

      await Api.listarComunidades();

      expect(contador.ultimaUrl, isNot(contains('q=')));
      expect(contador.ultimaUrl, isNot(contains('categoria=')));
    });

    test('el gestor que resuelve es el de la sesión', () async {
      Sesion.abrir(UsuarioSesion.desdeJson({
        'id': 3,
        'usuario': 'gestor_ciap',
        'nombre': 'gestor_ciap',
        'es_gestor': true,
        'comunidades_gestionadas': <Map<String, dynamic>>[],
      }));

      expect(ApiSolicitudes.gestorId, 3);
    });
  });
}

http.Client _clienteQueDevuelveHtml() {
  return _ClienteHtml();
}

class _ClienteHtml extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value('<html><body>Server Error</body></html>'.codeUnits),
      500,
    );
  }
}
