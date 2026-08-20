import 'lectura_json.dart';

class Evento {
  final int id;
  final String titulo;
  final String descripcion;
  final int comunidadId;
  final String comunidadNombre;
  final String fecha; 
  final String hora; 
  final String lugar;
  final int? cupo;
  final String estado;
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

  DateTime? get fechaComoDateTime => DateTime.tryParse(fecha);

  factory Evento.desdeJson(Map<String, dynamic> json) {
    return Evento(
      id: json.entero('id'),
      titulo: json.texto('titulo'),
      descripcion: json.texto('descripcion'),
      comunidadId: json.entero('comunidad'),
      comunidadNombre: json.texto('comunidad_nombre'),
      fecha: json.texto('fecha'),
      hora: json.texto('hora'),
      lugar: json.texto('lugar'),
      cupo: json.enteroONulo('cupo'),
      estado: json.texto('estado'),
      gestorId: json.enteroONulo('gestor'),
    );
  }
}
