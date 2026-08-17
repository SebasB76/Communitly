class Evento {
  final int id;
  final String titulo;
  final String descripcion;
  final int comunidadId;
  final String comunidadNombre;
  final String fecha; // formato YYYY-MM-DD (tal como lo entrega Django)
  final String hora; // formato HH:MM
  final String lugar;
  final int? cupo;
  final String estado; // 'activo' | 'cancelado'
  final int? gestorId;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.comunidadId,
    required this.comunidadNombre,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.cupo,
    required this.estado,
    required this.gestorId,
  });

  bool get cancelado => estado == 'cancelado';

  /// Convierte 'YYYY-MM-DD' a DateTime para poder ordenar/formatear en la UI.
  DateTime get fechaComoDateTime => DateTime.parse(fecha);

  factory Evento.desdeJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      comunidadId: json['comunidad'],
      comunidadNombre: json['comunidad_nombre'] ?? '',
      fecha: json['fecha'],
      hora: json['hora'],
      lugar: json['lugar'],
      cupo: json['cupo'],
      estado: json['estado'],
      gestorId: json['gestor'],
    );
  }
}
