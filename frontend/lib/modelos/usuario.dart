// Identidad y permisos del usuario conectado. Es infraestructura compartida:
// la usan todos los módulos, no solo el de solicitudes.

import 'lectura_json.dart';

class ComunidadGestionada {
  final int id;
  final String nombre;

  const ComunidadGestionada({required this.id, required this.nombre});

  factory ComunidadGestionada.desdeJson(Map<String, dynamic> json) {
    return ComunidadGestionada(
      id: json.entero('id'),
      nombre: json.texto('nombre'),
    );
  }

  Map<String, dynamic> aJson() => {'id': id, 'nombre': nombre};
}

class UsuarioSesion {
  final int id;
  final String usuario;
  final String nombre;
  final bool esGestor;
  final List<ComunidadGestionada> comunidadesGestionadas;

  const UsuarioSesion({
    required this.id,
    required this.usuario,
    required this.nombre,
    required this.esGestor,
    required this.comunidadesGestionadas,
  });

  /// Permiso sobre una comunidad concreta. El backend vuelve a comprobarlo en
  /// cada operación; esto solo decide qué se le ofrece al usuario.
  bool gestionaComunidad(int comunidadId) {
    return comunidadesGestionadas.any((c) => c.id == comunidadId);
  }

  factory UsuarioSesion.desdeJson(Map<String, dynamic> json) {
    final usuario = json.texto('usuario');

    return UsuarioSesion(
      id: json.entero('id'),
      usuario: usuario,
      nombre: json.texto('nombre', porDefecto: usuario),
      esGestor: json.booleano('es_gestor'),
      comunidadesGestionadas: json
          .objetos('comunidades_gestionadas')
          .map(ComunidadGestionada.desdeJson)
          .toList(),
    );
  }

  /// Serializa con las mismas claves que usa el backend, para que la sesión
  /// guardada en el navegador se pueda releer con [UsuarioSesion.desdeJson].
  Map<String, dynamic> aJson() => {
        'id': id,
        'usuario': usuario,
        'nombre': nombre,
        'es_gestor': esGestor,
        'comunidades_gestionadas':
            comunidadesGestionadas.map((c) => c.aJson()).toList(),
      };
}
