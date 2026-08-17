import 'package:flutter_web_plugins/url_strategy.dart';

/// Quita el `#` de las URLs.
///
/// Flutter web usa por defecto la estrategia de fragmento: la ruta viaja detrás
/// de un `#`, así que para el navegador toda la aplicación vive en `/`. Con eso
/// `GoRouter` nunca ve el enlace profundo —recargar `/comunidad/6` devolvía al
/// catálogo— y las URLs quedan feas para compartir.
///
/// Requiere que el servidor devuelva `index.html` para cualquier ruta, que es
/// lo que ya hace el `try_files` de `nginx.conf`.
void usarRutasSinNumeral() => usePathUrlStrategy();
