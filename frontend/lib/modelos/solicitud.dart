// Modelos del RF-05 y RF-06. Convierten el JSON que devuelve Python en
// objetos tipados, para que el resto del frontend no manipule mapas sueltos.

import 'lectura_json.dart';

class Solicitud {
  final int id;
  final String estado;
  final String estadoTexto;
  final String mensaje;
  final String observacion;
  final int comunidadId;
  final String comunidadNombre;
  final int estudianteId;
  final String estudianteUsuario;
  final DateTime creadaEn;
  final DateTime? resueltaEn;
  final String resueltaPor;

  Solicitud({
    required this.id,
    required this.estado,
    required this.estadoTexto,
    required this.mensaje,
    required this.observacion,
    required this.comunidadId,
    required this.comunidadNombre,
    required this.estudianteId,
    required this.estudianteUsuario,
    required this.creadaEn,
    required this.resueltaEn,
    required this.resueltaPor,
  });

  bool get pendiente => estado == 'pendiente';
  bool get aprobada => estado == 'aprobada';
  bool get resuelta => resueltaEn != null;

  factory Solicitud.desdeJson(Map<String, dynamic> json) {
    final comunidad = json.objeto('comunidad');
    final estudiante = json.objeto('estudiante');

    return Solicitud(
      id: json.entero('id'),
      estado: json.texto('estado'),
      estadoTexto: json.texto('estado_texto'),
      mensaje: json.texto('mensaje'),
      observacion: json.texto('observacion'),
      comunidadId: comunidad.entero('id'),
      comunidadNombre: comunidad.texto('nombre'),
      estudianteId: estudiante.entero('id'),
      estudianteUsuario: estudiante.texto('usuario'),
      // Una fecha de creación ilegible no debe tumbar la pantalla entera; se
      // cae a "ahora" y la solicitud se sigue mostrando.
      creadaEn: json.fechaONula('creada_en') ?? DateTime.now(),
      resueltaEn: json.fechaONula('resuelta_en'),
      resueltaPor: json.texto('resuelta_por'),
    );
  }
}

/// Conteo por estado que acompaña a cada listado. No cambia con el filtro
/// activo, por eso sirve para rotular los chips sin volver a pedir todo.
class ResumenSolicitudes {
  final int pendiente;
  final int aprobada;
  final int rechazada;
  final int retirada;

  const ResumenSolicitudes({
    required this.pendiente,
    required this.aprobada,
    required this.rechazada,
    required this.retirada,
  });

  int get total => pendiente + aprobada + rechazada + retirada;

  int porEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return pendiente;
      case 'aprobada':
        return aprobada;
      case 'rechazada':
        return rechazada;
      case 'retirada':
        return retirada;
      default:
        return total;
    }
  }

  factory ResumenSolicitudes.desdeJson(Map<String, dynamic> json) {
    return ResumenSolicitudes(
      pendiente: json.entero('pendiente'),
      aprobada: json.entero('aprobada'),
      rechazada: json.entero('rechazada'),
      retirada: json.entero('retirada'),
    );
  }
}

/// Respuesta de los dos listados del RF-05. `comunidadNombre` solo llega en la
/// bandeja del gestor; en la lista del estudiante queda vacío.
class ListaSolicitudes {
  final String comunidadNombre;
  final int total;
  final ResumenSolicitudes resumen;
  final List<Solicitud> solicitudes;

  ListaSolicitudes({
    required this.comunidadNombre,
    required this.total,
    required this.resumen,
    required this.solicitudes,
  });

  factory ListaSolicitudes.desdeJson(Map<String, dynamic> json) {
    return ListaSolicitudes(
      comunidadNombre: json.objeto('comunidad').texto('nombre'),
      total: json.entero('total'),
      resumen: ResumenSolicitudes.desdeJson(json.objeto('resumen')),
      solicitudes: json.objetos('solicitudes').map(Solicitud.desdeJson).toList(),
    );
  }
}
