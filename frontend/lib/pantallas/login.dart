import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../estado/estado_async.dart';
import '../rutas/rutas.dart';
import '../servicios/api_sesion.dart';
import '../servicios/sesion.dart';
import '../tema/tema.dart';

/// Entrada a la aplicación. Valida las credenciales contra Django y guarda en
/// [Sesion] la identidad con sus permisos, que es lo que después decide qué
/// acciones se muestran.
class PantallaLogin extends StatefulWidget {
  /// Ruta a la que se quería llegar antes de que el enrutador exigiera la
  /// sesión. Al entrar se continúa hacia allá en vez de caer siempre en el
  /// catálogo.
  final String? destino;

  const PantallaLogin({super.key, this.destino});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _entrando = false;
  bool _contrasenaVisible = false;
  String _error = '';

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    // La validación deja de ser un `if` a mano: el Form marca el campo que
    // falta y anuncia el error a los lectores de pantalla.
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _entrando = true;
      _error = '';
    });

    try {
      final conectado = await ApiSesion.iniciar(
        usuario: _usuario.text.trim(),
        contrasena: _contrasena.text,
      );
      Sesion.abrir(conectado);

      if (!mounted) return;
      TextInput.finishAutofillContext();
      context.go(widget.destino ?? Rutas.catalogo);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeFalla(e);
        _entrando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Degradado en vez de un color plano: los colores salen del esquema, así
      // que funciona igual en claro y en oscuro sin una segunda paleta.
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colores.primaryContainer,
              context.colores.surfaceContainerLow,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                // La tarjeta flota sobre el degradado; sin sombra se pierde.
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: AutofillGroup(
                    child: Form(
                      key: _formulario,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _encabezado(),
                          const SizedBox(height: 28),
                          _campoUsuario(),
                          const SizedBox(height: 16),
                          _campoContrasena(),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _mensajeError(),
                          ],
                          const SizedBox(height: 24),
                          _botonEntrar(),
                          if (kDebugMode) ...[
                            const SizedBox(height: 20),
                            _credencialesDePrueba(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Column(
      children: [
        Icon(Icons.groups_2_outlined, size: 44, color: context.colores.primary),
        const SizedBox(height: 12),
        Text(
          'ESPOL Communities',
          textAlign: TextAlign.center,
          style: context.textos.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colores.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Entra con tu cuenta institucional',
          textAlign: TextAlign.center,
          style: context.textos.bodyMedium?.copyWith(
            color: context.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _campoUsuario() {
    return TextFormField(
      controller: _usuario,
      autofocus: true,
      enabled: !_entrando,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      validator: (valor) => (valor ?? '').trim().isEmpty
          ? 'Escribe tu usuario institucional'
          : null,
      decoration: const InputDecoration(
        labelText: 'Usuario',
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }

  Widget _campoContrasena() {
    return TextFormField(
      controller: _contrasena,
      obscureText: !_contrasenaVisible,
      enabled: !_entrando,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _entrar(),
      validator: (valor) =>
          (valor ?? '').isEmpty ? 'Escribe tu contraseña' : null,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () =>
              setState(() => _contrasenaVisible = !_contrasenaVisible),
          icon: Icon(
            _contrasenaVisible ? Icons.visibility_off : Icons.visibility,
          ),
          tooltip: _contrasenaVisible
              ? 'Ocultar contraseña'
              : 'Mostrar contraseña',
        ),
      ),
    );
  }

  Widget _mensajeError() {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colores.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: context.colores.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error,
                style: TextStyle(color: context.colores.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonEntrar() {
    return FilledButton(
      onPressed: _entrando ? null : _entrar,
      child: _entrando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Entrar'),
    );
  }

  /// Solo en desarrollo: en una compilación de producción estas credenciales no
  /// deben aparecer en pantalla.
  Widget _credencialesDePrueba() {
    return Text(
      'Cuentas de prueba: estudiante1 (estudiante) y gestor_ciap '
      '(gestor de CIAP). Contraseña: espol2026',
      textAlign: TextAlign.center,
      style: context.textos.bodySmall?.copyWith(color: context.textoSecundario),
    );
  }
}
