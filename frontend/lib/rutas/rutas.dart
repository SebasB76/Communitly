import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pantallas/bandeja_gestor.dart';
import '../pantallas/catalogo.dart';
import '../pantallas/detalle.dart';
import '../pantallas/login.dart';
import '../pantallas/mis_solicitudes.dart';
import '../servicios/sesion.dart';
import '../widgets/mensaje_centrado.dart';

/// Direcciones de la aplicación, en un solo sitio.
class Rutas {
  const Rutas._();

  static const String login = '/login';
  static const String catalogo = '/catalogo';
  static const String solicitudes = '/solicitudes';

  static String comunidad(int id) => '/comunidad/$id';

  static String bandeja(int id) => '/comunidad/$id/bandeja';
}

/// Enrutador de la aplicación.
///
/// Antes toda la navegación era `Navigator.push(MaterialPageRoute(...))`. En
/// una app que corre en el navegador eso significa que la URL nunca cambia: F5
/// devolvía al login, no se podía compartir el enlace de una comunidad y el
/// botón "atrás" del navegador salía de la aplicación.
///
/// El `refreshListenable` es lo que hace que la sesión sea de verdad reactiva:
/// al cerrarla, el `redirect` manda al login desde donde sea que estuviera el
/// usuario, sin navegación manual.
GoRouter crearEnrutador() {
  return GoRouter(
    initialLocation: Rutas.catalogo,
    refreshListenable: Sesion.usuario,
    redirect: (BuildContext context, GoRouterState estado) {
      final enLogin = estado.matchedLocation == Rutas.login;

      if (!Sesion.activa) {
        // Se recuerda a dónde quería ir para volver ahí tras entrar.
        if (enLogin) return null;
        final destino = estado.uri.toString();
        return Uri(
          path: Rutas.login,
          queryParameters: destino == Rutas.catalogo ? null : {'destino': destino},
        ).toString();
      }

      if (enLogin) return Rutas.catalogo;
      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState estado) => Scaffold(
      appBar: AppBar(title: const Text('ESPOL Communities')),
      body: MensajeCentrado(
        icono: Icons.explore_off_outlined,
        titulo: 'Esta página no existe',
        detalle: estado.uri.toString(),
        textoAccion: 'Ir al catálogo',
        alPulsarAccion: () => context.go(Rutas.catalogo),
      ),
    ),
    routes: [
      GoRoute(
        path: Rutas.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState estado) => PantallaLogin(
          destino: estado.uri.queryParameters['destino'],
        ),
      ),
      GoRoute(
        path: Rutas.catalogo,
        name: 'catalogo',
        builder: (BuildContext context, GoRouterState estado) =>
            const PantallaCatalogo(),
      ),
      GoRoute(
        path: Rutas.solicitudes,
        name: 'solicitudes',
        builder: (BuildContext context, GoRouterState estado) =>
            const PantallaMisSolicitudes(),
      ),
      GoRoute(
        path: '/comunidad/:id',
        name: 'comunidad',
        redirect: (BuildContext context, GoRouterState estado) =>
            _idValido(estado.pathParameters['id']) ? null : Rutas.catalogo,
        builder: (BuildContext context, GoRouterState estado) => PantallaDetalle(
          comunidadId: int.parse(estado.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'bandeja',
            name: 'bandeja',
            builder: (BuildContext context, GoRouterState estado) =>
                PantallaBandejaGestor(
              comunidadId: int.parse(estado.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Una URL escrita a mano con `/comunidad/abc` no debe romper la aplicación.
bool _idValido(String? valor) =>
    valor != null && int.tryParse(valor) != null;
