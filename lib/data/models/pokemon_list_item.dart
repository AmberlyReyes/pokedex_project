import 'package:hive/hive.dart';

part 'pokemon_list_item.g.dart';

@HiveType(typeId: 0) // Define un ID único para este modelo
class PokemonListItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int id;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final List<String> types;

  PokemonListItem({
    required this.name,
    required this.id,
    required this.imageUrl,
    this.types = const [],
  });

  factory PokemonListItem.fromGraphQL(Map<String, dynamic> data) {
    final typesData = data['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
    final typesList = typesData
        .map((t) => (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String)
        .toList();
    
    return PokemonListItem(
      name: data['name'] as String,
      id: data['id'] as int,
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/${data['id']}.png',
      types: typesList,
    );
  }
}
