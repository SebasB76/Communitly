// La sesión guardada es lo que evita que un F5 te devuelva al login. Aquí se
// comprueba el viaje completo: guardar, releer y borrar.

import 'dart:convert';

import 'package:communitly_frontend/modelos/usuario.dart';
import 'package:communitly_frontend/servicios/almacen_sesion.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _clave = 'communitly.sesion';

Map<String, dynamic> gestorJson() => {
      'id': 3,
      'usuario': 'gestor_ciap',
      'nombre': 'Gestor CIAP',
      'es_gestor': true,
      'comunidades_gestionadas': <Map<String, dynamic>>[
        {'id': 1, 'nombre': 'CIAP'},
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // El resto de la suite la deja apagada; estas pruebas son justamente de
    // la persistencia, así que hay que encenderla.
    Sesion.persistenciaHabilitada = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    Sesion.cerrar();
    Sesion.persistenciaHabilitada = false;
  });

  test('la sesión guardada se vuelve a leer con sus permisos', () async {
    await AlmacenSesion.guardar(UsuarioSesion.desdeJson(gestorJson()));

    final leido = await AlmacenSesion.leer();

    expect(leido, isNotNull);
    expect(leido!.id, 3);
    expect(leido.usuario, 'gestor_ciap');
    expect(leido.nombre, 'Gestor CIAP');
    expect(leido.esGestor, isTrue);
    expect(leido.gestionaComunidad(1), isTrue);
  });

  test('restaurar deja la sesión activa como si nunca se hubiera ido',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _clave: jsonEncode(gestorJson()),
    });

    await Sesion.restaurar();

    expect(Sesion.activa, isTrue);
    expect(Sesion.id, 3);
    expect(Sesion.gestiona(1), isTrue);
  });

  test('sin nada guardado se arranca sin sesión', () async {
    await Sesion.restaurar();

    expect(Sesion.activa, isFalse);
  });

  test('un valor corrupto se descarta en vez de romper el arranque', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _clave: 'esto no es json',
    });

    await Sesion.restaurar();

    expect(Sesion.activa, isFalse);
    expect(await AlmacenSesion.leer(), isNull,
        reason: 'la clave corrupta debe quedar borrada');
  });

  test('cerrar sesión borra lo guardado', () async {
    await AlmacenSesion.guardar(UsuarioSesion.desdeJson(gestorJson()));
    await AlmacenSesion.borrar();

    expect(await AlmacenSesion.leer(), isNull);
  });
}
