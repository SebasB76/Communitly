import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Falla de la capa HTTP, ya traducida a algo que se le puede mostrar a una
/// persona.
///
/// [esDeRed] distingue las dos situaciones que la interfaz trata distinto: si
/// el servidor no respondió, ofrecer reintentar tiene sentido; si respondió con
/// un error de validación, el mensaje ya es la explicación.
class ErrorApi implements Exception {
  final String mensaje;
  final int? codigo;
  final bool esDeRed;

  const ErrorApi(this.mensaje, {this.codigo, this.esDeRed = false});

  /// Falta de permiso: el backend rechazó la operación para este usuario.
  bool get esProhibido => codigo == 403;

  @override
  String toString() => mensaje;
}

/// Único punto por el que salen las peticiones de la aplicación.
///
/// Concentra lo que antes estaba repetido en los tres servicios: la URL base,
/// las cabeceras, la decodificación en UTF-8, la comprobación del código de
/// respuesta y —lo que no existía— un tiempo límite.
class ClienteApi {
  const ClienteApi._();

  /// Se puede cambiar al compilar con --dart-define=API_BASE=...
  static const String base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const Duration tiempoLimite = Duration(seconds: 12);

  static const Map<String, String> _cabecerasJson = {
    'Content-Type': 'application/json',
  };

  /// Cliente HTTP en uso. Los tests lo sustituyen por uno falso para no tocar
  /// la red.
  static http.Client cliente = http.Client();

  static Uri _uri(String ruta, Map<String, String> parametros) {
    final uri = Uri.parse('$base$ruta');
    if (parametros.isEmpty) return uri;
    return uri.replace(queryParameters: parametros);
  }

  static Future<Map<String, dynamic>> obtener(
    String ruta, {
    Map<String, String> parametros = const {},
    int esperado = 200,
    required String errorPorDefecto,
  }) {
    return _enviar(
      () => cliente.get(_uri(ruta, parametros)),
      esperado: esperado,
      errorPorDefecto: errorPorDefecto,
    );
  }

  static Future<Map<String, dynamic>> publicar(
    String ruta, {
    Map<String, dynamic> cuerpo = const {},
    int esperado = 200,
    required String errorPorDefecto,
  }) {
    return _enviar(
      () => cliente.post(
        _uri(ruta, const {}),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      ),
      esperado: esperado,
      errorPorDefecto: errorPorDefecto,
    );
  }

  static Future<Map<String, dynamic>> parchear(
    String ruta, {
    Map<String, dynamic> cuerpo = const {},
    int esperado = 200,
    required String errorPorDefecto,
  }) {
    return _enviar(
      () => cliente.patch(
        _uri(ruta, const {}),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      ),
      esperado: esperado,
      errorPorDefecto: errorPorDefecto,
    );
  }

  static Future<Map<String, dynamic>> eliminar(
    String ruta, {
    Map<String, dynamic> cuerpo = const {},
    int esperado = 200,
    required String errorPorDefecto,
  }) {
    return _enviar(
      () => cliente.delete(
        _uri(ruta, const {}),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      ),
      esperado: esperado,
      errorPorDefecto: errorPorDefecto,
    );
  }

  static Future<Map<String, dynamic>> _enviar(
    Future<http.Response> Function() peticion, {
    required int esperado,
    required String errorPorDefecto,
  }) async {
    final respuesta = await _conTiempoLimite(peticion);

    var datos = const <String, dynamic>{};
    try {
      final decodificado = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (decodificado is Map<String, dynamic>) datos = decodificado;
    } catch (_) {
      // Una respuesta que no es JSON (un 500 con HTML, por ejemplo) no debe
      // romper el parseo: se cae al mensaje por defecto de más abajo.
    }

    if (respuesta.statusCode != esperado) {
      final delBackend = datos['error'];
      throw ErrorApi(
        delBackend is String && delBackend.isNotEmpty
            ? delBackend
            : errorPorDefecto,
        codigo: respuesta.statusCode,
      );
    }

    return datos;
  }

  /// Toda petición tiene tiempo límite. Sin él, un servidor que se cuelga —que
  /// no es lo mismo que uno que falla— dejaba el spinner girando para siempre.
  static Future<http.Response> _conTiempoLimite(
    Future<http.Response> Function() peticion,
  ) async {
    try {
      return await peticion().timeout(tiempoLimite);
    } on TimeoutException {
      throw ErrorApi(
        _conDetalle(
          'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
          'timeout tras ${tiempoLimite.inSeconds}s',
        ),
        esDeRed: true,
      );
    } catch (causa) {
      throw ErrorApi(
        _conDetalle(
          'No pudimos conectarnos con el servidor. '
          'Revisa tu conexión e inténtalo de nuevo.',
          '$causa',
        ),
        esDeRed: true,
      );
    }
  }

  /// El detalle técnico solo se muestra en desarrollo. En producción un
  /// estudiante no tiene por qué leer "¿está corriendo Django?".
  static String _conDetalle(String amable, String tecnico) {
    return kDebugMode ? '$amable\n($tecnico)' : amable;
  }
}
