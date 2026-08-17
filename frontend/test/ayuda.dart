// Utilidades compartidas por los tests de interfaz.

import 'dart:convert';

import 'package:communitly_frontend/modelos/usuario.dart';
import 'package:communitly_frontend/rutas/rutas.dart';
import 'package:communitly_frontend/servicios/cliente_api.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:communitly_frontend/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Estudiante conectado por defecto en los tests de pantalla: sin sesión los
/// servicios se niegan a armar la petición.
void abrirSesionDePrueba({bool gestor = false}) {
  Sesion.abrir(UsuarioSesion.desdeJson({
    'id': gestor ? 3 : 1,
    'usuario': gestor ? 'gestor_ciap' : 'estudiante1',
    'nombre': gestor ? 'gestor_ciap' : 'estudiante1',
    'es_gestor': gestor,
    'comunidades_gestionadas': gestor
        ? <Map<String, dynamic>>[
            {'id': 1, 'nombre': 'CIAP'},
          ]
        : <Map<String, dynamic>>[],
  }));
}

/// Sustituye el cliente HTTP por uno que responde con [json] sin tocar la red.
/// Devuelve un contador de peticiones, para comprobar cuántas se hicieron.
ContadorPeticiones responderCon(
  Map<String, dynamic> json, {
  int codigo = 200,
}) {
  final contador = ContadorPeticiones();

  ClienteApi.cliente = MockClient((peticion) async {
    contador.total++;
    contador.ultimaUrl = peticion.url.toString();
    return http.Response(
      jsonEncode(json),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  return contador;
}

/// Responde distinto según la ruta pedida, para las pruebas que atraviesan más
/// de una pantalla.
ContadorPeticiones responderPorRuta(List<(String, Map<String, dynamic>)> reglas) {
  final contador = ContadorPeticiones();

  ClienteApi.cliente = MockClient((peticion) async {
    contador.total++;
    contador.ultimaUrl = peticion.url.toString();

    for (final (fragmento, json) in reglas) {
      if (peticion.url.path.contains(fragmento)) {
        return http.Response(
          jsonEncode(json),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }

    return http.Response(
      jsonEncode({'error': 'ruta no simulada: ${peticion.url.path}'}),
      404,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  return contador;
}

/// Cliente que falla como lo haría un servidor apagado.
ContadorPeticiones responderConFalloDeRed() {
  final contador = ContadorPeticiones();

  ClienteApi.cliente = MockClient((peticion) async {
    contador.total++;
    throw const SocketExceptionFalsa();
  });

  return contador;
}

class ContadorPeticiones {
  int total = 0;
  String ultimaUrl = '';
}

/// `dart:io` no existe en web, así que los tests no pueden usar
/// `SocketException`. Cualquier excepción sirve: [ClienteApi] las trata todas
/// igual y las convierte en un error de red.
class SocketExceptionFalsa implements Exception {
  const SocketExceptionFalsa();

  @override
  String toString() => 'Connection refused';
}

/// Monta un widget con el tema real de la aplicación.
Future<void> montar(WidgetTester tester, Widget pantalla) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTema.claro,
    home: pantalla,
  ));
}

/// Monta la aplicación entera con su enrutador, para las pruebas de flujo.
Future<void> montarApp(WidgetTester tester) async {
  final enrutador = crearEnrutador();
  addTearDown(enrutador.dispose);

  await tester.pumpWidget(MaterialApp.router(
    theme: AppTema.claro,
    routerConfig: enrutador,
  ));
}

/// Deja que se resuelvan las peticiones simuladas.
///
/// No se puede usar `pumpAndSettle`: los esqueletos de carga tienen una
/// animación que se repite para siempre y nunca se asentaría.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
