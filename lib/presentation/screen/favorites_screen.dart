import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    _favoritesBoxFuture = Hive.openBox<PokemonDetail>('favorites');
  }

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
      body: FutureBuilder<Box<PokemonDetail>>(
        future: _favoritesBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: Text(l10n.loading));
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.error}: ${snapshot.error}'));
          }
          final box = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<PokemonDetail> box, _) {
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

              final favorites = box.values.toList();

              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final pokemon = favorites[index];
                  return ListTile(
                    leading: Image.network(
                      pokemon.spriteUrl,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.catching_pokemon),
                    ),
                    title: Text(pokemon.name),
                    subtitle: Text('#${pokemon.id}'),
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