import 'dart:io';

import 'package:communitly_frontend/pantallas/eventos.dart';
import 'package:communitly_frontend/servicios/cliente_api.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:communitly_frontend/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'ayuda.dart';

Map<String, dynamic> eventoJson(
  int id,
  String titulo,
  String fecha, {
  String estado = 'activo',
  int? cupo = 30,
}) =>
    {
      'id': id,
      'titulo': titulo,
      'descripcion': 'Descripción de $titulo',
      'comunidad': 1,
      'comunidad_nombre': 'CIAP',
      'fecha': fecha,
      'hora': '15:00',
      'lugar': 'Aula 12, FIEC',
      'cupo': cupo,
      'estado': estado,
      'gestor': 3,
    };

Future<void> montar(WidgetTester tester, {bool oscuro = false}) async {
  await tester.pumpWidget(MaterialApp(
    theme: oscuro ? AppTema.oscuro : AppTema.claro,
    home: const PantallaEventos(),
  ));
}

void main() {
  tearDown(() {
    Sesion.cerrar();
    ClienteApi.cliente = http.Client();
  });

  testWidgets('pinta la lista con fecha formateada', (tester) async {
    abrirSesionDePrueba();
    responderCon({
      'eventos': [
        eventoJson(1, 'Taller de introducción', '2026-08-22'),
        eventoJson(2, 'Charla de proyectos', '2026-09-11',
            estado: 'cancelado', cupo: null),
      ],
    });

    await montar(tester);
    await asentar(tester);

    expect(find.text('2 eventos'), findsOneWidget);
    expect(find.text('Taller de introducción'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('ago'), findsOneWidget);
    expect(find.text('sáb'), findsOneWidget);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text('Cupo 30'), findsOneWidget);
    expect(find.text('2026-08-22'), findsNothing);
  });

  testWidgets('un estudiante no ve el FAB de crear', (tester) async {
    abrirSesionDePrueba();
    responderCon({'eventos': <Map<String, dynamic>>[]});

    await montar(tester);
    await asentar(tester);

    expect(find.text('Nuevo evento'), findsNothing);
    expect(find.text('No hay eventos próximos'), findsOneWidget);
  });

  testWidgets('un gestor sí ve el FAB de crear', (tester) async {
    abrirSesionDePrueba(gestor: true);
    responderCon({'eventos': <Map<String, dynamic>>[]});

    await montar(tester);
    await asentar(tester);

    expect(find.text('Nuevo evento'), findsOneWidget);
  });

  testWidgets('un fallo de red ofrece reintentar', (tester) async {
    abrirSesionDePrueba();
    ClienteApi.cliente = MockClient((_) async => throw const SocketException(
          'sin conexión',
        ));

    await montar(tester);
    await asentar(tester);

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('en oscuro no queda ningún azul fijo en la barra',
      (tester) async {
    abrirSesionDePrueba();
    responderCon({'eventos': <Map<String, dynamic>>[]});

    await montar(tester, oscuro: true);
    await asentar(tester);

    final barra = tester.widget<AppBar>(find.byType(AppBar));
    expect(barra.backgroundColor, isNull);
    final material = tester.widget<Material>(
      find
          .descendant(of: find.byType(AppBar), matching: find.byType(Material))
          .first,
    );
    expect(material.color, isNot(const Color(0xFF123B63)));
  });
}
