import 'package:flutter/material.dart';

import '../estado/estado_async.dart';
import '../modelos/solicitud.dart';
import '../servicios/api_solicitudes.dart';
import '../tema/tema.dart';
import '../utilidades/fechas.dart';
import '../widgets/aviso.dart';

export '../widgets/aviso.dart';

/// Piezas compartidas por las pantallas del RF-05 y RF-06.

/// Estados en el orden en que se muestran; el vacío significa "todas".
const List<(String, String)> estadosSolicitud = [
  ('', 'Todas'),
  ('pendiente', 'Pendientes'),
  ('aprobada', 'Aprobadas'),
  ('rechazada', 'Rechazadas'),
  ('retirada', 'Retiradas'),
];

const Map<String, IconData> _iconosEstado = {
  'pendiente': Icons.hourglass_top,
  'aprobada': Icons.check_circle,
  'rechazada': Icons.cancel,
  'retirada': Icons.remove_circle_outline,
};

/// Texto que se le muestra al usuario cuando algo falla.
///
/// Se conserva el nombre por compatibilidad; la lógica vive en
/// [mensajeDeFalla], junto al resto del manejo de estados asíncronos.
String mensajeDeError(Object error) => mensajeDeFalla(error);

/// Etiqueta de color con el estado de la solicitud.
///
/// Además del color lleva un icono: el color por sí solo no comunica nada a
/// quien no lo distingue.
class EtiquetaEstado extends StatelessWidget {
  final Solicitud solicitud;

  const EtiquetaEstado({super.key, required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final colores = context.coloresEstado.porEstado(solicitud.estado);
    final icono = _iconosEstado[solicitud.estado] ?? Icons.help_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colores.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: colores.texto),
          const SizedBox(width: 5),
          Text(
            solicitud.estadoTexto,
            style: TextStyle(
              color: colores.texto,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtro rotulados con el conteo de cada estado. El resumen no
/// depende del filtro activo, así que los números no cambian al filtrar.
class FiltroEstados extends StatelessWidget {
  final String estadoActivo;
  final ResumenSolicitudes resumen;
  final ValueChanged<String> alCambiar;

  const FiltroEstados({
    super.key,
    required this.estadoActivo,
    required this.resumen,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: estadosSolicitud.map((estado) {
        final (valor, etiqueta) = estado;
        final conteo = resumen.porEstado(valor);

        return FilterChip(
          label: Text('$etiqueta ($conteo)'),
          selected: estadoActivo == valor,
          // Un estado sin solicitudes no tiene por qué ser pulsable.
          onSelected: conteo == 0 && valor.isNotEmpty
              ? null
              : (_) => alCambiar(valor),
        );
      }).toList(),
    );
  }
}

/// Tarjeta de una solicitud. El título cambia según quién mira: la comunidad
/// para el estudiante, el estudiante para el gestor.
class TarjetaSolicitud extends StatelessWidget {
  final String titulo;
  final Solicitud solicitud;
  final List<Widget> acciones;

  const TarjetaSolicitud({
    super.key,
    required this.titulo,
    required this.solicitud,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: context.textos.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                EtiquetaEstado(solicitud: solicitud),
              ],
            ),
            const SizedBox(height: 4),
            Tooltip(
              message: Fechas.conHora(solicitud.creadaEn),
              child: Text(
                'Enviada ${Fechas.relativa(solicitud.creadaEn)}',
                style: context.textos.bodySmall
                    ?.copyWith(color: context.textoSecundario),
              ),
            ),
            if (solicitud.mensaje.isNotEmpty)
              _bloque(context, 'Mensaje del estudiante', solicitud.mensaje),
            if (solicitud.observacion.isNotEmpty)
              _bloque(context, 'Observación del gestor', solicitud.observacion),
            if (solicitud.resuelta) ...[
              const SizedBox(height: 12),
              Text(
                'Resuelta por ${solicitud.resueltaPor} '
                '${Fechas.relativa(solicitud.resueltaEn!)}',
                style: context.textos.bodySmall
                    ?.copyWith(color: context.textoSecundario),
              ),
            ],
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 8, children: acciones),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bloque(BuildContext context, String etiqueta, String contenido) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: context.textos.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(contenido, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

/// Diálogo que pide un texto opcional (mensaje u observación).
///
/// Es un widget con estado, y no un `showDialog` con un controlador suelto,
/// porque así el `TextEditingController` se libera al cerrarse. La versión
/// anterior creaba uno nuevo en cada solicitud y no lo liberaba nunca.
class _DialogoTexto extends StatefulWidget {
  final String titulo;
  final String etiqueta;
  final String boton;
  final bool esDestructivo;

  const _DialogoTexto({
    required this.titulo,
    required this.etiqueta,
    required this.boton,
    required this.esDestructivo,
  });

  @override
  State<_DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<_DialogoTexto> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La consigna va arriba y no como `labelText`: son frases de
            // cuarenta caracteres, y flotando dentro del borde se recortaban.
            Text(
              widget.etiqueta,
              style: context.textos.bodyMedium
                  ?.copyWith(color: context.textoSecundario),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controlador,
              autofocus: true,
              maxLength: 500,
              // Alto fijo de tres líneas que crece hasta cinco: así el diálogo
              // no da un salto en cuanto se escribe la segunda línea.
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Escribe aquí…'),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controlador.text),
          style: widget.esDestructivo
              ? FilledButton.styleFrom(
                  backgroundColor: context.colores.error,
                  foregroundColor: context.colores.onError,
                )
              : null,
          child: Text(widget.boton),
        ),
      ],
    );
  }
}

/// Pide un texto opcional. Devuelve null si se cancela.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  required String boton,
  bool esDestructivo = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoTexto(
      titulo: titulo,
      etiqueta: etiqueta,
      boton: boton,
      esDestructivo: esDestructivo,
    ),
  );
}

/// Botón del RF-06 que se incrusta en el detalle de una comunidad: envía la
/// solicitud, o la retira si ya hay una pendiente.
class BotonSolicitarIngreso extends StatefulWidget {
  final int comunidadId;

  /// Estado que ya venía en el detalle de la comunidad. Cuando el backend lo
  /// incluye, este botón se pinta sin pedir nada; si no, cae a consultar las
  /// solicitudes del estudiante.
  final String? estadoConocido;

  /// Se llama cuando la solicitud cambia, para que el detalle se refresque.
  final VoidCallback? alCambiar;

  const BotonSolicitarIngreso({
    super.key,
    required this.comunidadId,
    this.estadoConocido,
    this.alCambiar,
  });

  @override
  State<BotonSolicitarIngreso> createState() => _BotonSolicitarIngresoState();
}

class _BotonSolicitarIngresoState extends State<BotonSolicitarIngreso> {
  String _estado = '';
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final conocido = widget.estadoConocido;
    if (conocido != null && conocido.isNotEmpty) {
      setState(() {
        _estado = conocido;
        _cargando = false;
      });
      return;
    }

    try {
      final lista = await ApiSolicitudes.misSolicitudes();
      var estado = '';
      for (final solicitud in lista.solicitudes) {
        if (solicitud.comunidadId != widget.comunidadId) continue;
        if (solicitud.pendiente || solicitud.aprobada) {
          estado = solicitud.estado;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _estado = estado;
        _cargando = false;
      });
    } catch (e) {
      // Sin solicitudes visibles el botón queda en su estado inicial: el
      // backend vuelve a validar cuando el estudiante intente enviarla.
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    final mensaje = await pedirTexto(
      context,
      titulo: 'Solicitar ingreso',
      etiqueta: 'Cuéntale al gestor por qué te interesa (opcional)',
      boton: 'Enviar solicitud',
    );
    if (mensaje == null) return;

    await _ejecutar(
      () => ApiSolicitudes.solicitarIngreso(
        widget.comunidadId,
        mensaje: mensaje,
      ),
    );
  }

  Future<void> _retirar() async {
    await _ejecutar(() => ApiSolicitudes.retirarSolicitud(widget.comunidadId));
  }

  /// Ejecuta la operación, muestra el mensaje que devuelve Python y recarga.
  Future<void> _ejecutar(Future<String> Function() operacion) async {
    setState(() => _procesando = true);

    try {
      final mensaje = await operacion();
      if (!mounted) return;
      // Tras cambiar la solicitud el estado guardado ya no sirve: se relee.
      _estado = '';
      await _cargar();
      widget.alCambiar?.call();
      _avisar(mensaje);
    } catch (e) {
      _avisar(mensajeDeFalla(e), esError: true);
    }

    if (!mounted) return;
    setState(() => _procesando = false);
  }

  void _avisar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    mostrarAviso(context, mensaje, esError: esError);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _procesando) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_estado == 'aprobada') {
      return Chip(
        avatar: Icon(
          Icons.verified,
          size: 18,
          color: context.coloresEstado.aprobada.texto,
        ),
        label: const Text('Ya eres miembro'),
      );
    }

    if (_estado == 'pendiente') {
      return OutlinedButton.icon(
        onPressed: _retirar,
        icon: const Icon(Icons.hourglass_bottom),
        label: const Text('Retirar solicitud'),
      );
    }

    return FilledButton.icon(
      onPressed: _enviar,
      icon: const Icon(Icons.mail_outline),
      label: const Text('Solicitar ingreso'),
    );
  }
}
