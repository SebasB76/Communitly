import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/comunidad.dart';
import '../modelos/evento.dart';

class Api {
  static const String base = 'http://127.0.0.1:8000/api';
  static const int estudianteId = 1;

  static Future<List<Comunidad>> listarComunidades({
    String texto = '',
    String categoria = '',
  }) async {
    final parametros = {'estudiante_id': '$estudianteId'};
    if (texto.isNotEmpty) parametros['q'] = texto;
    if (categoria.isNotEmpty) parametros['categoria'] = categoria;

    final url = Uri.parse('$base/comunidades/').replace(queryParameters: parametros);
    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo cargar el catálogo');
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    final lista = datos['comunidades'] as List;
    return lista.map((json) => Comunidad.desdeJson(json)).toList();
  }

  static Future<Comunidad> detalleComunidad(int id) async {
    final url = Uri.parse('$base/comunidades/$id/')
        .replace(queryParameters: {'estudiante_id': '$estudianteId'});
    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('No se encontró la comunidad');
    }

    return Comunidad.desdeJson(jsonDecode(utf8.decode(respuesta.bodyBytes)));
  }

  static Future<String> seguir(int comunidadId) async {
    final respuesta = await http.post(
      Uri.parse('$base/comunidades/$comunidadId/seguir/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estudiante_id': estudianteId}),
    );

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode != 201) {
      throw Exception(datos['error'] ?? 'No se pudo seguir la comunidad');
    }

    return datos['mensaje'];
  }

  static Future<String> dejarDeSeguir(int comunidadId) async {
    final respuesta = await http.delete(
      Uri.parse('$base/comunidades/$comunidadId/seguir/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estudiante_id': estudianteId}),
    );

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudo dejar de seguir la comunidad');
    }

    return datos['mensaje'];
  }

  static Future<List<Evento>> listarEventos({
    int? comunidadId,
    String fecha = '', 
  }) async {
    final parametros = <String, String>{};
    if (comunidadId != null) parametros['comunidad'] = '$comunidadId';
    if (fecha.isNotEmpty) parametros['fecha'] = fecha;

    final url = Uri.parse('$base/eventos/').replace(queryParameters: parametros);
    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo cargar los eventos');
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    final lista = datos['eventos'] as List;
    return lista.map((json) => Evento.desdeJson(json)).toList();
  }

  static Future<Evento> detalleEvento(int id) async {
    final respuesta = await http.get(Uri.parse('$base/eventos/$id/'));

    if (respuesta.statusCode != 200) {
      throw Exception('No se encontró el evento');
    }

    return Evento.desdeJson(jsonDecode(utf8.decode(respuesta.bodyBytes)));
  }

  static Future<Evento> crearEvento({
    required int comunidadId,
    required String titulo,
    required String descripcion,
    required String fecha,
    required String hora, 
    required String lugar,
    int? cupo,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$base/eventos/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'gestor_id': gestorId,
        'comunidad_id': comunidadId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha,
        'hora': hora,
        'lugar': lugar,
        if (cupo != null) 'cupo': cupo,
      }),
    );

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode != 201) {
      throw Exception(datos['error'] ?? 'No se pudo crear el evento');
    }

    return Evento.desdeJson(datos['evento']);
  }

  static Future<Evento> editarEvento({
    required int id,
    required String titulo,
    required String descripcion,
    required String fecha,
    required String hora,
    required String lugar,
    int? cupo,
  }) async {
    final respuesta = await http.patch(
      Uri.parse('$base/eventos/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'gestor_id': gestorId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha,
        'hora': hora,
        'lugar': lugar,
        'cupo': cupo,
      }),
    );

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudo actualizar el evento');
    }

    return Evento.desdeJson(datos['evento']);
  }

  static Future<String> cancelarEvento(int id) async {
    final respuesta = await http.delete(
      Uri.parse('$base/eventos/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'gestor_id': gestorId}),
    );

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudo cancelar el evento');
    }

    return datos['mensaje'];
  }
}