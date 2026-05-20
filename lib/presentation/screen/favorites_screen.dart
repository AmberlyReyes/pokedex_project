import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';

import '../../data/models/pokemon_detail.dart';
import 'pokemon_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  late Future<Box<PokemonDetail>> _favoritesBoxFuture;

  @override
  void initState() {
    super.initState();
    // abre la caja de favoritos
    _favoritesBoxFuture = Hive.openBox<PokemonDetail>('favorites');
  }

  // Obtiene todos los favoritos como una lista de mapas para mostar, muestra los mas recientes primero.
  List<Map<String, dynamic>> getAllFavorites(Box<PokemonDetail> box) {
    final data = box.keys.map((key) {
      final value = box.get(key);
      return {
        "key": key,
        "id": value?.id,
        "name": value?.name,
        "spriteUrl": value?.spriteUrl,
        "isFavorite": value?.isFavorite,
      };
    }).toList();

    return data.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // espera a que se abra la caja de favoritos
      body: FutureBuilder<Box<PokemonDetail>>(
        future: _favoritesBoxFuture,
        builder: (context, snapshot) {
          // muestra un indicador de carga mientras se abre la caja
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: Text(l10n.loading));
          }
          // maneja errores al abrir la caja
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.error}: ${snapshot.error}'));
          }
          // caja lista para usar
          final box = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<PokemonDetail> box, _) {
              // Si no hay favoritos, muestra un mensaje para agregar favoritos
              if (box.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noFavorites,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.addFavorites,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // convierte la lista de pokemones guardados en una lista
              final favorites = box.values.toList();

              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final pokemon = favorites[index];
                  return ListTile(
                    leading: CachedNetworkImage(
                      // imagen del sprite del pokemon
                      imageUrl: pokemon.spriteUrl,
                      width: 50,
                      height: 50,
                      placeholder: (context, url) => const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.catching_pokemon),
                    ),
                    // nombre del pokemon
                    title: Text(
                      pokemon.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    // id del pokemon
                    subtitle: Text(
                      '#${pokemon.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    // boton para eliminar de favoritos
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        box.delete(pokemon.id);
                      },
                    ),
                    onTap: () {
                      // Navegar a la pantalla de detalles del Pokémon
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PokemonDetailScreen(
                            id: pokemon.id,
                            name: pokemon.name,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}