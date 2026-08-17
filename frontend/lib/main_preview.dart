// TEMPORAL — entrada solo para capturar pantallas durante la revisión.
// Abre una sesión de demostración sin pasar por el login. Este archivo se
// borra al terminar; no forma parte de la aplicación.

import 'package:flutter/material.dart';

import 'main.dart';
import 'rutas/rutas.dart';
import 'servicios/api_sesion.dart';
import 'servicios/sesion.dart';
import 'utilidades/estrategia_url.dart';
import 'utilidades/fechas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usarRutasSinNumeral();
  Fechas.iniciar();
  Sesion.persistenciaHabilitada = false;

  final demo = Uri.base.queryParameters['demo'] ?? 'estudiante';
  final id = demo == 'gestor' ? 3 : 1;

  try {
    Sesion.abrir(await ApiSesion.refrescarPermisos(id));
  } catch (error) {
    debugPrint('No se pudo abrir la sesión de demostración: $error');
  }

  runApp(AppCommunitly(enrutador: crearEnrutador()));
}
