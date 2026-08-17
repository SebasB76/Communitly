import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formato de fechas en español.
///
/// Antes se armaba a mano un `dd/mm/aaaa`. En una bandeja de solicitudes lo que
/// importa casi siempre es "cuándo, respecto de hoy", así que lo reciente se
/// muestra en relativo y lo viejo con la fecha completa.
class Fechas {
  const Fechas._();

  static const String _locale = 'es';
  static bool _iniciado = false;

  /// Carga los símbolos del locale. `initializeDateFormatting` de
  /// `date_symbol_data_local` resuelve de forma síncrona (los datos van
  /// compilados en el paquete), por eso se puede llamar de forma perezosa
  /// desde cualquier formateo sin esperar el Future.
  static void iniciar() {
    if (_iniciado) return;
    initializeDateFormatting(_locale);
    _iniciado = true;
  }

  /// "14 ago 2026"
  static String corta(DateTime fecha) {
    iniciar();
    return DateFormat('d MMM y', _locale).format(fecha.toLocal());
  }

  /// "14 ago 2026, 15:30"
  static String conHora(DateTime fecha) {
    iniciar();
    return DateFormat('d MMM y, HH:mm', _locale).format(fecha.toLocal());
  }

  /// "hoy", "ayer", "hace 3 días" y, a partir de una semana, la fecha corta.
  static String relativa(DateTime fecha, {DateTime? ahora}) {
    final referencia = (ahora ?? DateTime.now()).toLocal();
    final local = fecha.toLocal();

    final hoy = DateTime(referencia.year, referencia.month, referencia.day);
    final dia = DateTime(local.year, local.month, local.day);
    final dias = hoy.difference(dia).inDays;

    return switch (dias) {
      0 => 'hoy',
      1 => 'ayer',
      >= 2 && <= 6 => 'hace $dias días',
      _ => corta(local),
    };
  }
}
