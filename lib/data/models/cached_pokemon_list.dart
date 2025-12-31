import 'package:hive/hive.dart';
import 'pokemon_list_item.dart';

part 'cached_pokemon_list.g.dart';

@HiveType(typeId: 6)
class CachedPokemonList {
  @HiveField(0)
  final List<PokemonListItem> pokemons;

  @HiveField(1)
  final DateTime cachedAt;

  @HiveField(2)
  final int offset;

  @HiveField(3)
  final int limit;

  CachedPokemonList({
    required this.pokemons,
    required this.cachedAt,
    required this.offset,
    required this.limit,
  });

  bool isExpired({Duration maxAge = const Duration(days: 1)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
