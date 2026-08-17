import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'rutas/rutas.dart';
import 'servicios/preferencias.dart';
import 'servicios/sesion.dart';
import 'tema/tema.dart';
import 'utilidades/estrategia_url.dart';
import 'utilidades/fechas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Antes de crear el enrutador: si no, la ruta de la URL no se ve y todo
  // enlace profundo termina en el catálogo.
  usarRutasSinNumeral();
  Fechas.iniciar();
  // La sesión y el tema se recuperan antes del primer fotograma, para no
  // mostrar el login durante un instante a alguien que ya había entrado.
  await Sesion.restaurar();
  await PreferenciasUi.restaurar();

  runApp(AppCommunitly(enrutador: crearEnrutador()));
}

class AppCommunitly extends StatelessWidget {
  final GoRouter enrutador;

  const AppCommunitly({super.key, required this.enrutador});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PreferenciasUi.modoTema,
      builder: (context, modo, _) {
        return MaterialApp.router(
          title: 'ESPOL Communities',
          debugShowCheckedModeBanner: false,
          theme: AppTema.claro,
          darkTheme: AppTema.oscuro,
          themeMode: modo,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: enrutador,
        );
      },
    );
  }
}
