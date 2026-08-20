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

  ParEstado get cancelado => rechazada;

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

  /// Ajustes de tipografía sobre la escala de Material. Solo se declara lo que
  /// cambia: `ThemeData` los mezcla con los tamaños por defecto, así que no hay
  /// que repetir `fontSize` en cada estilo.
  ///
  /// Los titulares por defecto vienen con espaciado positivo, pensado para
  /// textos pequeños; a 28 px eso se lee suelto y desalineado. Se ciñen, y los
  /// párrafos ganan altura de línea para que un texto largo respire.
  static const TextTheme _textos = TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.7),
    headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(height: 1.45),
    bodyMedium: TextStyle(height: 1.45),
  );

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
      textTheme: _textos,
      appBarTheme: AppBarTheme(
        // En claro se mantiene el azul institucional; en oscuro ese azul no
        // tiene contraste suficiente y se usa la superficie del esquema.
        backgroundColor: esOscuro
            ? colores.surfaceContainerHigh
            : AppColores.azulEspol,
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
          borderRadius: BorderRadius.circular(20),
          // El borde a media opacidad separa la tarjeta del fondo sin dibujar
          // una caja: a opacidad completa la rejilla parecía una tabla.
          side: BorderSide(
            color: colores.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colores.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colores.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colores.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colores.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colores.outlineVariant),
        selectedColor: colores.primaryContainer,
        checkmarkColor: colores.onPrimaryContainer,
        // Sin `labelStyle` a propósito: el del tema no completa al de Material,
        // lo reemplaza. Uno sin color deja el texto en negro sobre el chip
        // oscuro, y uno con color fijo ignora los estados (seleccionado,
        // deshabilitado). El color del texto lo resuelve Material.
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: const StadiumBorder(),
          side: BorderSide(color: colores.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: colores.outlineVariant),
    );
  }
}
