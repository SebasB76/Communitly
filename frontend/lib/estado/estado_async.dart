import '../servicios/cliente_api.dart';

/// Estado de una carga asíncrona.
///
/// Las cinco pantallas repetían los mismos tres campos (`_cargando`, `_error` y
/// los datos) y el mismo encadenado de `if` para decidir qué pintar. Con un
/// tipo sellado el compilador obliga a cubrir los tres casos y el widget
/// [VistaAsync] se encarga del resto.
sealed class Estado<T> {
  const Estado();

  /// Datos ya disponibles, o null si todavía no llegaron. Sirve para pintar
  /// partes de la pantalla (los filtros, por ejemplo) mientras se recarga.
  T? get datosONulo => switch (this) {
        ConDatos<T>(:final datos) => datos,
        _ => null,
      };
}

class Cargando<T> extends Estado<T> {
  const Cargando();
}

class ConError<T> extends Estado<T> {
  final String mensaje;

  /// El servidor no respondió, así que reintentar puede funcionar.
  final bool sePuedeReintentar;

  const ConError(this.mensaje, {this.sePuedeReintentar = true});

  /// Traduce cualquier excepción al estado de error correspondiente.
  factory ConError.desde(Object error) {
    if (error is ErrorApi) {
      // Un 403 o un error de validación no se arregla reintentando.
      return ConError(error.mensaje, sePuedeReintentar: error.esDeRed);
    }
    return ConError(mensajeDeFalla(error));
  }
}

class ConDatos<T> extends Estado<T> {
  final T datos;

  const ConDatos(this.datos);
}

/// Texto que se le muestra al usuario ante una falla cualquiera.
///
/// Los mensajes de validación que arma el backend llegan como [ErrorApi] y se
/// muestran tal cual; el resto se reporta como problema de conexión.
String mensajeDeFalla(Object error) {
  if (error is ErrorApi) return error.mensaje;

  const prefijo = 'Exception: ';
  final texto = error.toString();
  if (texto.startsWith(prefijo)) return texto.substring(prefijo.length);

  return 'No pudimos conectarnos con el servidor. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
