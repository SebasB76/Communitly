// Pruebas de pantalla del catálogo. Cubren los caminos que antes fallaban en
// silencio: el error sin salida, el vacío sin acción y la búsqueda que pedía
// al servidor en cada tecla.

import 'package:communitly_frontend/pantallas/catalogo.dart';
import 'package:communitly_frontend/servicios/cliente_api.dart';
import 'package:communitly_frontend/servicios/sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'ayuda.dart';

Map<String, dynamic> comunidadJson(int id, String nombre, String categoria) => {
      'id': id,
      'nombre': nombre,
      'descripcion': 'Descripción de $nombre',
      'categoria': categoria,
      'contacto': '$nombre@espol.edu.ec',
      'seguidores': 12,
      'siguiendo': false,
    };

Map<String, dynamic> catalogoCon(List<Map<String, dynamic>> comunidades) => {
      'comunidades': comunidades,
    };

void main() {
  setUp(abrirSesionDePrueba);

  tearDown(() {
    Sesion.cerrar();
    ClienteApi.cliente = http.Client();
  });

  testWidgets('muestra las comunidades que devuelve el backend',
      (tester) async {
    responderCon(catalogoCon([
      comunidadJson(1, 'CIAP', 'Académica'),
      comunidadJson(6, 'ROBOTA', 'Tecnología'),
    ]));

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);

    expect(find.text('CIAP'), findsOneWidget);
    expect(find.text('ROBOTA'), findsOneWidget);
    expect(find.text('2 comunidades encontradas'), findsOneWidget);
  });

  testWidgets('el singular del contador está bien escrito', (tester) async {
    responderCon(catalogoCon([comunidadJson(1, 'CIAP', 'Académica')]));

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);

    expect(find.text('1 comunidad encontrada'), findsOneWidget);
  });

  testWidgets('un fallo de red ofrece reintentar y vuelve a pedir',
      (tester) async {
    final contador = responderConFalloDeRed();

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);

    expect(find.text('No pudimos cargar esta información'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(contador.total, 1);

    await tester.tap(find.text('Reintentar'));
    await asentar(tester);

    expect(contador.total, 2);
  });

  testWidgets('sin resultados y con filtros ofrece limpiarlos',
      (tester) async {
    // Primera carga con datos: de ahí salen las categorías de los filtros.
    responderCon(catalogoCon([comunidadJson(1, 'CIAP', 'Académica')]));

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);

    // La búsqueda siguiente no encuentra nada.
    responderCon(catalogoCon([]));
    await tester.enterText(find.byType(TextField), 'algo que no existe');
    await tester.pump(const Duration(milliseconds: 400));
    await asentar(tester);

    expect(find.text('No encontramos comunidades'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);

    // Al limpiar se vuelve a pedir sin el texto de búsqueda.
    final contador = responderCon(
      catalogoCon([comunidadJson(1, 'CIAP', 'Académica')]),
    );
    await tester.tap(find.text('Limpiar filtros'));
    await asentar(tester);

    expect(contador.ultimaUrl, isNot(contains('q=')));
    expect(find.text('CIAP'), findsOneWidget);
  });

  testWidgets('la búsqueda espera a que dejes de escribir', (tester) async {
    final contador = responderCon(catalogoCon([]));

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);
    expect(contador.total, 1, reason: 'la carga inicial');

    await tester.enterText(find.byType(TextField), 'rob');
    await tester.pump(const Duration(milliseconds: 100));
    expect(contador.total, 1, reason: 'todavía no pasó la pausa');

    await tester.pump(const Duration(milliseconds: 400));
    await asentar(tester);
    expect(contador.total, 2, reason: 'una sola petición, no una por tecla');
    expect(contador.ultimaUrl, contains('q=rob'));
  });

  testWidgets('las tarjetas se reparten según el ancho disponible',
      (tester) async {
    responderCon(catalogoCon([
      for (var i = 1; i <= 4; i++) comunidadJson(i, 'C$i', 'Académica'),
    ]));

    // Ancho de teléfono: una sola columna, sin desbordarse.
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await montar(tester, const PantallaCatalogo());
    await asentar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('C1'), findsOneWidget);
  });
}
