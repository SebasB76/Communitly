/// Lectores tipados del JSON que devuelve el backend.
///
/// Antes cada modelo hacía `id: json['id']`, que es un `dynamic` colándose en
/// un `int`. Mientras el backend responda lo esperado funciona, pero un campo
/// ausente o con otro tipo reventaba en mitad del árbol de widgets con un error
/// que no decía qué campo era. Aquí la conversión es explícita y tiene un valor
/// por defecto.
extension LecturaJson on Map<String, dynamic> {
  int entero(String clave, {int porDefecto = 0}) {
    final valor = this[clave];
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? porDefecto;
    return porDefecto;
  }

  /// Entero opcional: distingue "no vino" de "vino cero". Lo necesitan los
  /// campos que el backend deja en null, como el cupo de un evento.
  int? enteroONulo(String clave) {
    final valor = this[clave];
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  String texto(String clave, {String porDefecto = ''}) {
    final valor = this[clave];
    if (valor is String) return valor;
    if (valor == null) return porDefecto;
    return valor.toString();
  }

  bool booleano(String clave, {bool porDefecto = false}) {
    final valor = this[clave];
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    return porDefecto;
  }

  /// Fecha ISO-8601. Devuelve null si falta o no se puede interpretar.
  DateTime? fechaONula(String clave) {
    final valor = this[clave];
    if (valor is! String || valor.isEmpty) return null;
    return DateTime.tryParse(valor);
  }

  /// Objeto anidado. Devuelve un mapa vacío si falta, para que el modelo pueda
  /// seguir leyendo con sus valores por defecto.
  Map<String, dynamic> objeto(String clave) {
    final valor = this[clave];
    return valor is Map<String, dynamic> ? valor : const {};
  }

  /// Lista de objetos anidados, saltando las entradas que no lo sean.
  List<Map<String, dynamic>> objetos(String clave) {
    final valor = this[clave];
    if (valor is! List) return const [];
    return valor.whereType<Map<String, dynamic>>().toList();
  }
}
