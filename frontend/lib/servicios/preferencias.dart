import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de interfaz que sobreviven a la recarga de la página.
class PreferenciasUi {
  const PreferenciasUi._();

  static const String _claveTema = 'communitly.tema';

  /// Modo de tema elegido. Por defecto sigue al sistema operativo.
  static final ValueNotifier<ThemeMode> modoTema =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> restaurar() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      modoTema.value = switch (preferencias.getString(_claveTema)) {
        'claro' => ThemeMode.light,
        'oscuro' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (error) {
      debugPrint('No se pudieron leer las preferencias: $error');
    }
  }

  /// Alterna entre claro y oscuro tomando como punto de partida el brillo que
  /// se está viendo, para que el primer toque siempre haga algo visible.
  static void alternar(Brightness brilloActual) {
    cambiar(
      brilloActual == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  static void cambiar(ThemeMode modo) {
    modoTema.value = modo;
    unawaited(_persistir(modo));
  }

  static Future<void> _persistir(ThemeMode modo) async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(_claveTema, switch (modo) {
        ThemeMode.light => 'claro',
        ThemeMode.dark => 'oscuro',
        ThemeMode.system => 'sistema',
      });
    } catch (error) {
      debugPrint('No se pudo guardar el tema: $error');
    }
  }
}
