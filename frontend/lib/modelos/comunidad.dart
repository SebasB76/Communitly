import 'lectura_json.dart';

class Comunidad {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String contacto;
  final String logo;
  final int seguidores;
  final bool siguiendo;

  /// Estado de la solicitud del usuario conectado en esta comunidad
  /// ('pendiente', 'aprobada', ...). Queda vacío cuando el backend no lo
  /// incluye, y en ese caso la interfaz lo averigua con una petición aparte.
  final String estadoMiSolicitud;

  const Comunidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.contacto,
    this.logo = '',
    required this.seguidores,
    required this.siguiendo,
    this.estadoMiSolicitud = '',
  });

  /// Si el detalle ya trae el estado, no hace falta pedir todas las solicitudes
  /// del estudiante solo para saber qué botón mostrar.
  bool get conoceMiSolicitud => estadoMiSolicitud.isNotEmpty;

  factory Comunidad.desdeJson(Map<String, dynamic> json) {
    final miSolicitud = json['mi_solicitud'];

    return Comunidad(
      id: json.entero('id'),
      nombre: json.texto('nombre'),
      descripcion: json.texto('descripcion'),
      categoria: json.texto('categoria'),
      contacto: json.texto('contacto'),
      logo: json.texto('logo'),
      seguidores: json.entero('seguidores'),
      siguiendo: json.booleano('siguiendo'),
      // El backend puede mandarlo como objeto o como texto suelto; los dos se
      // aceptan, y si no viene queda vacío.
      estadoMiSolicitud: switch (miSolicitud) {
        final Map<String, dynamic> objeto => objeto.texto('estado'),
        final String texto => texto,
        _ => '',
      },
    );
  }
}
