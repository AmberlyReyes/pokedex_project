// lib/screens/pokearth_map_screen.dart

import 'package:flutter/material.dart';
import '../../data/mapa/pokearth_map_parser.dart';
import '../../data/providers/pokemon_providers.dart';
import '../../data/helpers/error_formatter.dart';
import '../widgets/error_widget.dart';
import 'pokemon_list_screen.dart';
import 'favorites_screen.dart';

class PokearthMapScreen extends StatefulWidget {
  const PokearthMapScreen({super.key});
  @override State<PokearthMapScreen> createState() => _PokearthMapScreenState();
}

class _PokearthMapScreenState extends State<PokearthMapScreen> {
  late Future<List<PokearthArea>> _areas;
  late TransformationController _transformationController;
  double _currentScale = 1.0;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _areas = PokearthMap.loadAreas();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onImageTap(TapDownDetails details, List<PokearthArea> areas) {
    // PASO 0: Obtener la posición global del toque
    final globalPosition = details.globalPosition;
    
    // Obtener el RenderBox de la imagen para calcular su posición
    final renderBox = _imageKey.currentContext?.findRenderObject();
    if (renderBox is! RenderBox) return;
    
    // PASO 1: Convertir de global a local (relativo a la imagen)
    final localPosition = renderBox.globalToLocal(globalPosition);
    
    // Obtener el tamaño renderizado de la imagen en el widget
    final renderedSize = renderBox.size;
    
    // Tamaño original de la imagen (según el HTML)
    const double originalWidth = 1100.0;
    const double originalHeight = 850.0;
    
    // PASO 2: Transformación a coordenadas originales (1100 x 850)
    // Calcular el factor de escala (tamaño original / tamaño renderizado)
    final scaleX = originalWidth / renderedSize.width;
    final scaleY = originalHeight / renderedSize.height;
    
    // Convertir las coordenadas locales a las coordenadas originales de la imagen
    final scaledPosition = Offset(
      localPosition.dx * scaleX,
      localPosition.dy * scaleY,
    );
    
    // Buscar si el toque cae dentro de algún área
    PokearthArea? foundArea;
    for (final area in areas) {
      if (area.coordinates.contains(scaledPosition)) {
        foundArea = area;
        break;
      }
    }

    if (foundArea != null) {
      // Obtener los pokémon de esta ubicación
      _showLocationPokemonDialog(context, foundArea.title);
    }
  }

  void _showLocationPokemonDialog(BuildContext context, String locationName) {
    print('DEBUG: locationName recibido: $locationName');
    print('DEBUG: locationName en minúsculas: ${locationName.toLowerCase()}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locationName),
        content: FutureBuilder(
          future: _fetchLocationPokemon(locationName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final errorData = ErrorFormatter.format(snapshot.error, showDetails: false);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorData.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorData.message,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final pokemon = snapshot.data ?? [];

            if (pokemon.isEmpty) {
              return const Center(child: Text('No se encontraron Pokémon'));
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pokemon
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila con imagen, ID y nombre
                              Row(
                                children: [
                                  Image.network(
                                    p.imageUrl,
                                    width: 50,
                                    height: 50,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${p.id} - ${p.name[0].toUpperCase()}${p.name.substring(1)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lvl ${p.minLevel}-${p.maxLevel}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Información detallada
                              Padding(
                                padding: const EdgeInsets.only(left: 62.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Método: ${p.method[0].toUpperCase()}${p.method.substring(1)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      'Probabilidad: ${p.chance}%',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      'Versión: ${p.version[0].toUpperCase()}${p.version.substring(1)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchLocationPokemon(String locationName) async {
    try {
      final notifier = PokemonListNotifier();
      return await notifier.fetchPokemonByLocation(locationName);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + 1).clamp(1.0, 4.0);
      _transformationController.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 2).clamp(1.0, 4.0);
      _transformationController.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokéarth')),
      body: FutureBuilder<List<PokearthArea>>(
        future: _areas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorData = ErrorFormatter.format(snapshot.error, showDetails: false);
            return ErrorMessageWidget(
              title: errorData.title,
              message: errorData.message,
              onRetry: () {
                setState(() {
                  _areas = PokearthMap.loadAreas();
                });
              },
            );
          }

          final areas = snapshot.data ?? [];

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: _currentScale > 1.0, // Solo permitir pan si hay zoom
                scaleEnabled: false, // Desabilitar zoom por gesto
                child: GestureDetector(
                  onTapDown: (details) => _onImageTap(details, areas),
                  child: Center(
                    child: Image.asset(
                      'assets/images/pokearth.png',
                      fit: BoxFit.contain,
                      key: _imageKey,
                    ),
                  ),
                ),
              ),
              // Botón de zoom in (abajo a la derecha)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _zoomIn,
                  mini: true,
                  child: const Icon(Icons.zoom_in),
                ),
              ),
              // Botón de zoom out (arriba del anterior)
              Positioned(
                bottom: 20,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _zoomOut,
                  mini: true,
                  child: const Icon(Icons.zoom_out),
                ),
              ),
              // Botón de reset zoom
              if (_currentScale > 1.0)
                Positioned(
                  bottom: 140,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _resetZoom,
                    mini: true,
                    child: const Icon(Icons.restart_alt),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}