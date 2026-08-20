// Pruebas del RF-05 y RF-06 en el frontend. Verifican la conversión del JSON
// que devuelve Python y el estado que muestra la interfaz, sin tocar la red.

import 'package:communitly_frontend/modelos/solicitud.dart';
import 'package:communitly_frontend/pantallas/solicitudes_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda.dart';

/// Copia de una respuesta real de `GET /api/solicitudes/`.
Map<String, dynamic> solicitudAprobada() => {
      'id': 5,
      'estado': 'aprobada',
      'estado_texto': 'Aprobada',
      'mensaje': 'Tengo experiencia con Arduino',
      'observacion': 'Bienvenido, te esperamos el viernes.',
      'comunidad': {'id': 6, 'nombre': 'ROBOTA'},
      'estudiante': {'id': 1, 'usuario': 'estudiante1'},
      'creada_en': '2026-08-11T20:14:49.664198+00:00',
      'resuelta_en': '2026-08-12T01:02:03.000000+00:00',
      'resuelta_por': 'gestor_robota',
    };

Map<String, dynamic> solicitudPendiente() => {
      'id': 9,
      'estado': 'pendiente',
      'estado_texto': 'Pendiente',
      'mensaje': '',
      'observacion': '',
      'comunidad': {'id': 1, 'nombre': 'CIAP'},
      'estudiante': {'id': 1, 'usuario': 'estudiante1'},
      'creada_en': '2026-08-14T15:00:00.000000+00:00',
      'resuelta_en': null,
      'resuelta_por': null,
    };

void main() {
  group('Solicitud', () {
    test('convierte una solicitud resuelta', () {
      final solicitud = Solicitud.desdeJson(solicitudAprobada());

      expect(solicitud.id, 5);
      expect(solicitud.estado, 'aprobada');
      expect(solicitud.estadoTexto, 'Aprobada');
      expect(solicitud.comunidadNombre, 'ROBOTA');
      expect(solicitud.estudianteUsuario, 'estudiante1');
      expect(solicitud.resueltaPor, 'gestor_robota');
      expect(solicitud.aprobada, isTrue);
      expect(solicitud.pendiente, isFalse);
      expect(solicitud.resuelta, isTrue);
      expect(solicitud.resueltaEn, isNotNull);
    });

    test('una solicitud pendiente no tiene resolución', () {
      final solicitud = Solicitud.desdeJson(solicitudPendiente());

      expect(solicitud.pendiente, isTrue);
      expect(solicitud.resuelta, isFalse);
      expect(solicitud.resueltaEn, isNull);
      expect(solicitud.resueltaPor, '');
    });

    test('los textos ausentes quedan vacíos y no en null', () {
      final json = solicitudPendiente();
      json['mensaje'] = null;
      json['observacion'] = null;

      final solicitud = Solicitud.desdeJson(json);

      expect(solicitud.mensaje, '');
      expect(solicitud.observacion, '');
    });
  });

  group('ResumenSolicitudes', () {
    final resumen = ResumenSolicitudes.desdeJson({
      'pendiente': 4,
      'aprobada': 1,
      'rechazada': 2,
      'retirada': 3,
    });

    test('suma el total de todos los estados', () {
      expect(resumen.total, 10);
    });

    test('devuelve el conteo de cada estado', () {
      expect(resumen.porEstado('pendiente'), 4);
      expect(resumen.porEstado('aprobada'), 1);
      expect(resumen.porEstado('rechazada'), 2);
      expect(resumen.porEstado('retirada'), 3);
    });

    test('el estado vacío representa a todas', () {
      expect(resumen.porEstado(''), 10);
    });

    test('un resumen sin datos queda en cero', () {
      expect(ResumenSolicitudes.desdeJson({}).total, 0);
    });
  });

  group('ListaSolicitudes', () {
    test('la lista del estudiante no trae comunidad', () {
      final lista = ListaSolicitudes.desdeJson({
        'total': 2,
        'resumen': {'pendiente': 1, 'aprobada': 1, 'rechazada': 0, 'retirada': 0},
        'solicitudes': [solicitudAprobada(), solicitudPendiente()],
      });

      expect(lista.comunidadNombre, '');
      expect(lista.total, 2);
      expect(lista.solicitudes, hasLength(2));
      expect(lista.resumen.pendiente, 1);
    });

    test('la bandeja del gestor identifica a la comunidad', () {
      final lista = ListaSolicitudes.desdeJson({
        'comunidad': {'id': 1, 'nombre': 'CIAP'},
        'total': 1,
        'resumen': {'pendiente': 1, 'aprobada': 0, 'rechazada': 0, 'retirada': 0},
        'solicitudes': [solicitudPendiente()],
      });

      expect(lista.comunidadNombre, 'CIAP');
      expect(lista.solicitudes.single.comunidadNombre, 'CIAP');
    });

    test('un listado vacío se convierte sin error', () {
      final lista = ListaSolicitudes.desdeJson({
        'total': 0,
        'resumen': {'pendiente': 0, 'aprobada': 0, 'rechazada': 0, 'retirada': 0},
        'solicitudes': <Map<String, dynamic>>[],
      });

      expect(lista.solicitudes, isEmpty);
      expect(lista.total, 0);
    });
  });

  group('mensajeDeError', () {
    test('muestra tal cual el mensaje de validación del backend', () {
      final error = Exception('Ya tienes una solicitud pendiente en CIAP');

      expect(mensajeDeError(error), 'Ya tienes una solicitud pendiente en CIAP');
    });

    test('cualquier otra falla se reporta como problema de conexión', () {
      expect(mensajeDeError(StateError('socket cerrado')), contains('conectar'));
    });
  });

  group('Interfaz', () {
    testWidgets('la etiqueta muestra el estado de la solicitud',
        (WidgetTester tester) async {
      final solicitud = Solicitud.desdeJson(solicitudAprobada());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EtiquetaEstado(solicitud: solicitud)),
      ));

      expect(find.text('Aprobada'), findsOneWidget);
    });

    testWidgets('los filtros rotulan cada estado con su conteo',
        (WidgetTester tester) async {
      final resumen = ResumenSolicitudes.desdeJson({
        'pendiente': 4,
        'aprobada': 1,
        'rechazada': 0,
        'retirada': 0,
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FiltroEstados(
            estadoActivo: 'pendiente',
            resumen: resumen,
            alCambiar: (_) {},
          ),
        ),
      ));

      expect(find.text('Todas (5)'), findsOneWidget);
      expect(find.text('Pendientes (4)'), findsOneWidget);
      expect(find.text('Aprobadas (1)'), findsOneWidget);
      expect(find.text('Retiradas (0)'), findsOneWidget);
    });

    testWidgets('la tarjeta muestra el mensaje y la observación',
        (WidgetTester tester) async {
      final solicitud = Solicitud.desdeJson(solicitudAprobada());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TarjetaSolicitud(
            titulo: solicitud.comunidadNombre,
            solicitud: solicitud,
          ),
        ),
      ));

      expect(find.text('ROBOTA'), findsOneWidget);
      expect(find.text('Tengo experiencia con Arduino'), findsOneWidget);
      expect(find.text('Bienvenido, te esperamos el viernes.'), findsOneWidget);
      expect(find.textContaining('gestor_robota'), findsOneWidget);
    });

    testWidgets('el diálogo cabe en un teléfono y devuelve lo escrito',
        (WidgetTester tester) async {
      // 360 px es el ancho crítico: la consigna larga y el campo de tres
      // líneas son justo lo que antes se desbordaba.
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? respuesta;

      await montar(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => respuesta = await pedirTexto(
                context,
                titulo: 'Solicitar ingreso',
                etiqueta: 'Cuéntale al gestor por qué te interesa (opcional)',
                boton: 'Enviar solicitud',
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(
        find.text('Cuéntale al gestor por qué te interesa (opcional)'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Me interesa la robótica');
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      expect(respuesta, 'Me interesa la robótica');
    });
  });
}
