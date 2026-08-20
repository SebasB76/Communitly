// Pruebas de la pantalla de entrada: validación del formulario y el mensaje
// que llega del backend cuando las credenciales no sirven.

import 'package:communitly_frontend/pantallas/login.dart';
import 'package:communitly_frontend/servicios/cliente_api.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'ayuda.dart';

void main() {
  tearDown(() {
    Sesion.cerrar();
    ClienteApi.cliente = http.Client();
  });

  testWidgets('no envía nada con los campos vacíos', (tester) async {
    final contador = responderCon({'usuario': <String, dynamic>{}});

    await montar(tester, const PantallaLogin());
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Escribe tu usuario institucional'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(contador.total, 0, reason: 'no debe llegar a llamar al backend');
  });

  testWidgets('muestra tal cual el mensaje de error del backend',
      (tester) async {
    responderCon(
      {'error': 'Usuario o contraseña incorrectos'},
      codigo: 401,
    );

    await montar(tester, const PantallaLogin());
    await tester.enterText(find.byType(TextFormField).first, 'estudiante1');
    await tester.enterText(find.byType(TextFormField).last, 'mala');
    await tester.tap(find.text('Entrar'));
    await asentar(tester);

    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(Sesion.activa, isFalse);
  });

  testWidgets('un servidor caído no muestra el detalle técnico como título',
      (tester) async {
    responderConFalloDeRed();

    await montar(tester, const PantallaLogin());
    await tester.enterText(find.byType(TextFormField).first, 'estudiante1');
    await tester.enterText(find.byType(TextFormField).last, 'espol2026');
    await tester.tap(find.text('Entrar'));
    await asentar(tester);

    expect(find.textContaining('No pudimos conectarnos'), findsOneWidget);
    expect(find.textContaining('Django'), findsNothing);
  });

  testWidgets('la contraseña se puede mostrar y volver a ocultar',
      (tester) async {
    await montar(tester, const PantallaLogin());

    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('sin sesión el enrutador manda al login', (tester) async {
    responderPorRuta(const []);

    await montarApp(tester);
    await asentar(tester);

    expect(find.text('Entra con tu cuenta institucional'), findsOneWidget);
  });

  testWidgets('al entrar se abre la sesión y se llega al catálogo',
      (tester) async {
    responderPorRuta([
      (
        '/sesion/',
        {
          'usuario': {
            'id': 1,
            'usuario': 'estudiante1',
            'nombre': 'estudiante1',
            'es_gestor': false,
            'comunidades_gestionadas': <Map<String, dynamic>>[],
          },
        }
      ),
      (
        '/comunidades/',
        {
          'comunidades': [
            {
              'id': 1,
              'nombre': 'CIAP',
              'descripcion': 'Centro de investigación',
              'categoria': 'Académica',
              'contacto': 'ciap@espol.edu.ec',
              'seguidores': 30,
              'siguiendo': false,
            },
          ],
        }
      ),
    ]);

    await montarApp(tester);
    await asentar(tester);

    await tester.enterText(find.byType(TextFormField).first, 'estudiante1');
    await tester.enterText(find.byType(TextFormField).last, 'espol2026');
    await tester.tap(find.text('Entrar'));
    await asentar(tester);
    await asentar(tester);

    expect(Sesion.activa, isTrue);
    expect(find.text('Descubre tu próxima comunidad'), findsOneWidget);
    expect(find.text('CIAP'), findsOneWidget);
  });

  testWidgets('cerrar sesión devuelve al login desde cualquier pantalla',
      (tester) async {
    abrirSesionDePrueba();
    responderPorRuta([
      ('/comunidades/', {'comunidades': <Map<String, dynamic>>[]}),
    ]);

    await montarApp(tester);
    await asentar(tester);
    expect(find.text('Descubre tu próxima comunidad'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.logout));
    await asentar(tester);
    await asentar(tester);

    expect(find.text('Entra con tu cuenta institucional'), findsOneWidget);
  });
}
