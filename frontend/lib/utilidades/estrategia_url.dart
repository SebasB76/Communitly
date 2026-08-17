/// Selecciona la implementación según la plataforma: en el navegador se usa la
/// real; al correr los tests en la VM de Dart, la vacía.
library;

export 'estrategia_url_vm.dart'
    if (dart.library.js_interop) 'estrategia_url_web.dart';
