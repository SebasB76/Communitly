import 'package:flutter/material.dart';

/// Colores de marca y construcción de los dos temas de la aplicación.
///
/// Antes cada pantalla repetía `Color(0xFF123B63)` y `Colors.black54`. Eso
/// significaba dos fuentes de verdad para el mismo color y hacía imposible el
/// modo oscuro. Ahora todo el color vive aquí y las pantallas lo leen del
/// [Theme].
class AppColores {
  const AppColores._();

  /// Azul institucional de la ESPOL.
  static const Color azulEspol = Color(0xFF123B63);

  /// Acento que marca las comunidades que el estudiante ya sigue.
  static const Color turquesa = Color(0xFF0E9AA7);
}

/// Par de colores (texto sobre fondo) de una etiqueta de estado.
@immutable
class ParEstado {
  final Color texto;
  final Color fondo;

  const ParEstado(this.texto, this.fondo);

  static ParEstado lerp(ParEstado a, ParEstado b, double t) {
    return ParEstado(
      Color.lerp(a.texto, b.texto, t)!,
      Color.lerp(a.fondo, b.fondo, t)!,
    );
  }
}

/// Colores de los estados de una solicitud. Van en el tema, y no como
/// constantes sueltas, para que el modo oscuro tenga su propia paleta sin que
/// las pantallas se enteren.
@immutable
class ColoresEstado extends ThemeExtension<ColoresEstado> {
  final ParEstado pendiente;
  final ParEstado aprobada;
  final ParEstado rechazada;
  final ParEstado retirada;

  const ColoresEstado({
    required this.pendiente,
    required this.aprobada,
    required this.rechazada,
    required this.retirada,
  });

  static const ColoresEstado claro = ColoresEstado(
    pendiente: ParEstado(Color(0xFF7A4E00), Color(0xFFFFF3DC)),
    aprobada: ParEstado(Color(0xFF14653B), Color(0xFFE3F5EA)),
    rechazada: ParEstado(Color(0xFFA3231C), Color(0xFFFBE6E4)),
    retirada: ParEstado(Color(0xFF4A4E52), Color(0xFFECEDEE)),
  );

  static const ColoresEstado oscuro = ColoresEstado(
    pendiente: ParEstado(Color(0xFFFFD08A), Color(0xFF3A2B0E)),
    aprobada: ParEstado(Color(0xFF8FDCB0), Color(0xFF10331F)),
    rechazada: ParEstado(Color(0xFFFFB4AB), Color(0xFF3D1613)),
    retirada: ParEstado(Color(0xFFCBCED1), Color(0xFF2B2E30)),
  );

  ParEstado porEstado(String estado) {
    return switch (estado) {
      'pendiente' => pendiente,
      'aprobada' => aprobada,
      'rechazada' => rechazada,
      _ => retirada,
    };
  }

  @override
  ColoresEstado copyWith({
    ParEstado? pendiente,
    ParEstado? aprobada,
    ParEstado? rechazada,
    ParEstado? retirada,
  }) {
    return ColoresEstado(
      pendiente: pendiente ?? this.pendiente,
      aprobada: aprobada ?? this.aprobada,
      rechazada: rechazada ?? this.rechazada,
      retirada: retirada ?? this.retirada,
    );
  }

  @override
  ColoresEstado lerp(ThemeExtension<ColoresEstado>? otro, double t) {
    if (otro is! ColoresEstado) return this;

    return ColoresEstado(
      pendiente: ParEstado.lerp(pendiente, otro.pendiente, t),
      aprobada: ParEstado.lerp(aprobada, otro.aprobada, t),
      rechazada: ParEstado.lerp(rechazada, otro.rechazada, t),
      retirada: ParEstado.lerp(retirada, otro.retirada, t),
    );
  }
}

/// Atajos de lectura del tema. Evitan repetir `Theme.of(context)` en cada
/// widget y son el reemplazo de los colores que antes estaban a mano.
extension TemaDelContexto on BuildContext {
  ColorScheme get colores => Theme.of(this).colorScheme;

  TextTheme get textos => Theme.of(this).textTheme;

  /// Color de los textos secundarios, el que antes era `Colors.black54`.
  Color get textoSecundario => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Paleta de estados. Si el tema no la declara (por ejemplo en un test que
  /// monta un `MaterialApp` pelado) se usa la que corresponde al brillo.
  ColoresEstado get coloresEstado {
    final tema = Theme.of(this);
    return tema.extension<ColoresEstado>() ??
        (tema.brightness == Brightness.dark
            ? ColoresEstado.oscuro
            : ColoresEstado.claro);
  }
}

class AppTema {
  const AppTema._();

  static ThemeData get claro => _construir(Brightness.light);

  static ThemeData get oscuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esOscuro = brillo == Brightness.dark;
    final colores = ColorScheme.fromSeed(
      seedColor: AppColores.azulEspol,
      brightness: brillo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      scaffoldBackgroundColor: colores.surface,
      extensions: [esOscuro ? ColoresEstado.oscuro : ColoresEstado.claro],
      appBarTheme: AppBarTheme(
        // En claro se mantiene el azul institucional; en oscuro ese azul no
        // tiene contraste suficiente y se usa la superficie del esquema.
        backgroundColor:
            esOscuro ? colores.surfaceContainerHigh : AppColores.azulEspol,
        foregroundColor: esOscuro ? colores.onSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colores.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colores.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colores.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colores.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.all(16),
      ),
      dividerTheme: DividerThemeData(color: colores.outlineVariant),
    );
  }
}
