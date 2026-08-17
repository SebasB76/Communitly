// Pruebas de las piezas compartidas: la rejilla responsiva, el bloque de
// mensaje con salida, y el formato de fechas.

import 'package:communitly_frontend/estado/estado_async.dart';
import 'package:communitly_frontend/tema/tema.dart';
import 'package:communitly_frontend/utilidades/fechas.dart';
import 'package:communitly_frontend/widgets/mensaje_centrado.dart';
import 'package:communitly_frontend/widgets/rejilla_responsiva.dart';
import 'package:communitly_frontend/widgets/vista_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda.dart';

void main() {
  group('RejillaResponsiva', () {
    Future<double> anchoDeTarjeta(WidgetTester tester, double anchoTotal) async {
      // La superficie de prueba mide 800x600: un SizedBox más ancho quedaría
      // recortado por las restricciones del padre y la rejilla vería otro
      // ancho del que se quiere probar.
      await tester.binding.setSurfaceSize(Size(anchoTotal, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await montar(
        tester,
        const Scaffold(
          body: RejillaResponsiva(
            hijos: [
              Card(child: Text('a')),
              Card(child: Text('b')),
              Card(child: Text('c')),
              Card(child: Text('d')),
              Card(child: Text('e')),
              Card(child: Text('f')),
            ],
          ),
        ),
      );

      // Se mide la tarjeta ya renderizada, no la restricción que se le pasó.
      return tester.getSize(find.byType(Card).first).width;
    }

    testWidgets('en un teléfono usa una sola columna a ancho completo',
        (tester) async {
      expect(await anchoDeTarjeta(tester, 360), 360);
    });

    testWidgets('en escritorio reparte varias columnas', (tester) async {
      // 1000 px con tarjetas de 320 mínimo y 16 de separación caben 3.
      expect(await anchoDeTarjeta(tester, 1000), closeTo(322.6, 0.1));
    });

    testWidgets('nunca hace tarjetas más angostas que el mínimo',
        (tester) async {
      final ancho = await anchoDeTarjeta(tester, 500);
      expect(ancho, greaterThanOrEqualTo(320));
    });
  });

  group('VistaAsync', () {
    testWidgets('un error de red ofrece reintentar', (tester) async {
      var reintentos = 0;

      await montar(
        tester,
        Scaffold(
          body: VistaAsync<List<String>>(
            estado: const ConError('Sin conexión'),
            cargando: const CircularProgressIndicator(),
            alReintentar: () async => reintentos++,
            constructor: (context, datos) => const Text('datos'),
          ),
        ),
      );

      expect(find.text('Sin conexión'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(reintentos, 1);
    });

    testWidgets('un 403 no ofrece reintentar porque no serviría',
        (tester) async {
      await montar(
        tester,
        Scaffold(
          body: VistaAsync<List<String>>(
            estado: const ConError(
              'No gestionas esta comunidad',
              sePuedeReintentar: false,
            ),
            cargando: const CircularProgressIndicator(),
            alReintentar: () async {},
            constructor: (context, datos) => const Text('datos'),
          ),
        ),
      );

      expect(find.text('No puedes ver esto'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('el estado vacío puede llevar su propia acción',
        (tester) async {
      var limpiezas = 0;

      await montar(
        tester,
        Scaffold(
          body: VistaAsync<List<String>>(
            estado: const ConDatos([]),
            cargando: const CircularProgressIndicator(),
            alReintentar: () async {},
            estaVacio: (datos) => datos.isEmpty,
            tituloVacio: 'Sin resultados',
            textoAccionVacio: 'Limpiar filtros',
            alPulsarAccionVacio: () => limpiezas++,
            constructor: (context, datos) => const Text('datos'),
          ),
        ),
      );

      expect(find.text('Sin resultados'), findsOneWidget);
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pump();

      expect(limpiezas, 1);
    });
  });

  group('MensajeCentrado', () {
    testWidgets('sin acción no pinta ningún botón', (tester) async {
      await montar(
        tester,
        const Scaffold(
          body: MensajeCentrado(
            icono: Icons.inbox_outlined,
            titulo: 'Nada por aquí',
          ),
        ),
      );

      expect(find.text('Nada por aquí'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('Fechas', () {
    final ahora = DateTime(2026, 8, 16, 12);

    test('hoy y ayer se dicen con palabras', () {
      expect(Fechas.relativa(DateTime(2026, 8, 16, 9), ahora: ahora), 'hoy');
      expect(Fechas.relativa(DateTime(2026, 8, 15, 23), ahora: ahora), 'ayer');
    });

    test('dentro de la semana se cuenta en días', () {
      expect(
        Fechas.relativa(DateTime(2026, 8, 13), ahora: ahora),
        'hace 3 días',
      );
    });

    test('más de una semana atrás muestra la fecha', () {
      final texto = Fechas.relativa(DateTime(2026, 7, 20), ahora: ahora);

      expect(texto, contains('20'));
      expect(texto, contains('2026'));
    });

    test('la fecha corta va en español', () {
      expect(Fechas.corta(DateTime(2026, 8, 14)), '14 ago 2026');
    });
  });

  group('Tema', () {
    testWidgets('cada estado tiene su color en claro y en oscuro',
        (tester) async {
      for (final tema in [AppTema.claro, AppTema.oscuro]) {
        final colores = tema.extension<ColoresEstado>();

        expect(colores, isNotNull);
        expect(colores!.porEstado('pendiente'), isNot(colores.aprobada));
        // Un estado desconocido no debe romper la etiqueta.
        expect(colores.porEstado('inventado'), colores.retirada);
      }
    });
  });
}
