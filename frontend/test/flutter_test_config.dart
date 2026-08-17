import 'dart:async';

import 'package:communitly_frontend/servicios/sesion.dart';

/// Configuración que Flutter aplica a todos los tests de esta carpeta.
///
/// La sesión se guarda en `shared_preferences`, que necesita el binding de
/// plataforma. En las pruebas unitarias no lo hay, así que la escritura se
/// desactiva: se prueba la lógica de la sesión, no el almacenamiento.
Future<void> testExecutable(FutureOr<void> Function() main) async {
  Sesion.persistenciaHabilitada = false;
  await main();
}
