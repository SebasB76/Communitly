import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../estado/estado_async.dart';
import '../modelos/comunidad.dart';
import '../rutas/rutas.dart';
import '../servicios/api.dart';
import '../servicios/preferencias.dart';
import '../servicios/sesion.dart';
import '../tema/tema.dart';
import '../widgets/esqueletos.dart';
import '../widgets/rejilla_responsiva.dart';
import '../widgets/vista_async.dart';

/// RF-01 a RF-03: catálogo de comunidades con búsqueda y filtro por categoría.
class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({super.key});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final _buscador = TextEditingController();

  Estado<List<Comunidad>> _estado = const Cargando();
  List<String> _categorias = const [];
  String _categoriaActiva = '';
  Timer? _retrasoBusqueda;

  /// Contador de peticiones. Sin él, filtrar rápido podía pintar el resultado
  /// de una búsqueda anterior encima de la actual, porque nada garantiza que
  /// las respuestas lleguen en el orden en que se pidieron.
  int _ultimaPeticion = 0;

  bool get _hayFiltros =>
      _buscador.text.trim().isNotEmpty || _categoriaActiva.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _retrasoBusqueda?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final peticion = ++_ultimaPeticion;
    final texto = _buscador.text.trim();

    setState(() => _estado = const Cargando());

    try {
      final lista = await Api.listarComunidades(
        texto: texto,
        categoria: _categoriaActiva,
      );
      if (!mounted || peticion != _ultimaPeticion) return;

      setState(() {
        _estado = ConDatos(lista);
        // Las categorías solo se deducen de un listado sin filtrar; con filtros
        // la lista sería incompleta.
        if (_categorias.isEmpty && !_hayFiltros) {
          _categorias = lista.map((c) => c.categoria).toSet().toList()..sort();
        }
      });
    } catch (error) {
      if (!mounted || peticion != _ultimaPeticion) return;
      setState(() => _estado = ConError.desde(error));
    }
  }

  /// La búsqueda se dispara sola mientras se escribe, con una pausa para no
  /// lanzar una petición por tecla.
  void _buscarConRetraso() {
    _retrasoBusqueda?.cancel();
    _retrasoBusqueda = Timer(const Duration(milliseconds: 350), _cargar);
  }

  void _filtrarPor(String categoria) {
    setState(() => _categoriaActiva = categoria);
    _cargar();
  }

  void _limpiarFiltros() {
    _retrasoBusqueda?.cancel();
    _buscador.clear();
    setState(() => _categoriaActiva = '');
    _cargar();
  }

  Future<void> _abrirDetalle(int id) async {
    // Al volver del detalle se recarga: el estudiante pudo seguir la comunidad
    // o enviar una solicitud desde allí.
    await context.push<void>(Rutas.comunidad(id));
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Sesion.actualONulo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESPOL Communities'),
        actions: [
          IconButton(
            onPressed: () =>
                PreferenciasUi.alternar(Theme.of(context).brightness),
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: 'Cambiar el tema',
          ),
          IconButton(
            onPressed: () => context.push(Rutas.solicitudes),
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Mis solicitudes',
          ),
          IconButton(
            onPressed: Sesion.cerrar,
            icon: const Icon(Icons.logout),
            tooltip: usuario == null
                ? 'Cerrar sesión'
                : 'Cerrar sesión (${usuario.usuario})',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descubre tu próxima comunidad',
                    style: context.textos.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    usuario == null
                        ? ''
                        : usuario.esGestor
                            ? 'Conectado como ${usuario.usuario} · gestor'
                            : 'Conectado como ${usuario.usuario}',
                    style: context.textos.bodyMedium
                        ?.copyWith(color: context.textoSecundario),
                  ),
                  const SizedBox(height: 20),
                  _campoBusqueda(),
                  const SizedBox(height: 16),
                  _filtros(),
                  const SizedBox(height: 24),
                  _resultados(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      controller: _buscador,
      // El setState es para que aparezca o desaparezca la "x" de limpiar.
      onChanged: (_) {
        setState(() {});
        _buscarConRetraso();
      },
      onSubmitted: (_) => _cargar(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, categoría o interés...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _buscador.text.isEmpty
            ? null
            : IconButton(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.close),
                tooltip: 'Limpiar la búsqueda',
              ),
      ),
    );
  }

  Widget _filtros() {
    if (_categorias.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Todas'),
          selected: _categoriaActiva.isEmpty,
          onSelected: (_) => _filtrarPor(''),
        ),
        for (final categoria in _categorias)
          FilterChip(
            label: Text(categoria),
            selected: _categoriaActiva == categoria,
            onSelected: (_) => _filtrarPor(categoria),
          ),
      ],
    );
  }

  Widget _resultados() {
    return VistaAsync<List<Comunidad>>(
      estado: _estado,
      cargando: const EsqueletoRejilla(),
      alReintentar: _cargar,
      estaVacio: (lista) => lista.isEmpty,
      iconoVacio: Icons.search_off,
      tituloVacio: 'No encontramos comunidades',
      detalleVacio: _hayFiltros
          ? 'Prueba con otras palabras o quita los filtros.'
          : 'Todavía no hay comunidades publicadas.',
      textoAccionVacio: _hayFiltros ? 'Limpiar filtros' : null,
      alPulsarAccionVacio: _hayFiltros ? _limpiarFiltros : null,
      constructor: (context, lista) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lista.length == 1
                ? '1 comunidad encontrada'
                : '${lista.length} comunidades encontradas',
            style: context.textos.bodyMedium
                ?.copyWith(color: context.textoSecundario),
          ),
          const SizedBox(height: 12),
          RejillaResponsiva(
            hijos: [for (final comunidad in lista) _tarjeta(comunidad)],
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Comunidad comunidad) {
    return Card(
      child: InkWell(
        onTap: () => _abrirDetalle(comunidad.id),
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
                      comunidad.nombre,
                      style: context.textos.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (comunidad.siguiendo)
                    const Tooltip(
                      message: 'Ya sigues esta comunidad',
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColores.turquesa,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${comunidad.categoria} · ${comunidad.seguidores} seguidores',
                style: context.textos.bodySmall
                    ?.copyWith(color: context.textoSecundario),
              ),
              const SizedBox(height: 8),
              Text(
                comunidad.descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
