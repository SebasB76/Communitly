import 'package:flutter/material.dart';

import '../modelos/comunidad.dart';
import '../servicios/api.dart';
import 'detalle.dart';

class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({super.key});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final _buscador = TextEditingController();
  List<Comunidad> _comunidades = [];
  List<String> _categorias = [];
  String _categoriaActiva = '';
  bool _cargando = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final lista = await Api.listarComunidades(
        texto: _buscador.text,
        categoria: _categoriaActiva,
      );
      setState(() {
        _comunidades = lista;
        _cargando = false;
        if (_categorias.isEmpty &&
            _buscador.text.isEmpty &&
            _categoriaActiva.isEmpty) {
          _categorias = lista.map((c) => c.categoria).toSet().toList()..sort();
        }
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar con el servidor. ¿Está corriendo Django?';
        _cargando = false;
      });
    }
  }

   Future<void> _abrirDetalle(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(comunidadId: id)),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESPOL Communities'),
        backgroundColor: const Color(0xFF123B63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descubre tu próxima comunidad',
              style: Theme.of(context).textTheme.headlineMedium,
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
    );
  }

  Widget _campoBusqueda() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _buscador,
            onSubmitted: (_) => _cargar(),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre, categoría o interés...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _cargar,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          ),
          child: const Text('Buscar'),
        ),
      ],
    );
  }

  Widget _filtros() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Todas'),
          selected: _categoriaActiva.isEmpty,
          onSelected: (_) {
            setState(() => _categoriaActiva = '');
            _cargar();
          },
        ),
        ..._categorias.map(
          (categoria) => FilterChip(
            label: Text(categoria),
            selected: _categoriaActiva == categoria,
            onSelected: (_) {
              setState(() => _categoriaActiva = categoria);
              _cargar();
            },
          ),
        ),
      ],
    );
  }

  Widget _resultados() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(_error)),
      );
    }

    if (_comunidades.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('No se encontraron comunidades')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_comunidades.length} comunidades encontradas',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _comunidades.map(_tarjeta).toList(),
        ),
      ],
    );
  }

  Widget _tarjeta(Comunidad comunidad) {
    return SizedBox(
      width: 320,
      child: Card(
        child: InkWell(
          onTap: () => _abrirDetalle(comunidad.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comunidad.nombre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (comunidad.siguiendo)
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFF0E9AA7)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${comunidad.categoria} · ${comunidad.seguidores} seguidores',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
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
      ),
    );
  }
}
