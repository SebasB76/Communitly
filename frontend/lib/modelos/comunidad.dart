class Comunidad {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String contacto;
  final int seguidores;
  final bool siguiendo;

    Comunidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.contacto,
    required this.seguidores,
    required this.siguiendo,
  });


  factory Comunidad.desdeJson(Map<String, dynamic> json) {
    return Comunidad(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      categoria: json['categoria'],
      contacto: json['contacto'] ?? '',
      seguidores: json['seguidores'],
      siguiendo: json['siguiendo'] ?? false,
    );
  }
}