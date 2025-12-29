import 'package:hive/hive.dart';

part 'pokemon_variant.g.dart';

@HiveType(typeId: 5)
class PokemonVariant {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name; // Ej: "mega", "mega-x", "mega-y", "gigantamax"

  @HiveField(2)
  final String formName; // Ej: "mega-charizard-x", "gigantamax"

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String variantType; // "mega", "gigantamax", "alola", "galar", "paldea"

  @HiveField(5)
  final List<String> types;

  PokemonVariant({
    required this.id,
    required this.name,
    required this.formName,
    required this.imageUrl,
    required this.variantType,
    required this.types,
  });

  factory PokemonVariant.fromGraphQL(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['pokemon']?['name'] as String? ?? json['name'] as String;
    final formName = json['form_name'] as String? ?? '';

    // Determine variant type
    String variantType = 'other';
    if (formName.contains('mega')) {
      variantType = 'mega';
    } else if (formName.contains('gigantamax')) {
      variantType = 'gigantamax';
    } else if (formName.contains('alola')) {
      variantType = 'alola';
    } else if (formName.contains('galar')) {
      variantType = 'galar';
    } else if (formName.contains('paldea')) {
      variantType = 'paldea';
    }

    final imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png';

    // Parse types
    final typesList = <String>[];
    final types = json['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
    for (final t in types) {
      final typeName = (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String;
      typesList.add(typeName);
    }

    return PokemonVariant(
      id: id,
      name: name,
      formName: formName,
      imageUrl: imageUrl,
      variantType: variantType,
      types: typesList.isNotEmpty ? typesList : ['unknown'],
    );
  }

  String getDisplayName() {
    switch (variantType) {
      case 'mega':
        return formName.contains('x') ? 'Mega X' : formName.contains('y') ? 'Mega Y' : 'Mega';
      case 'gigantamax':
        return 'Gigantamax';
      case 'alola':
        return 'Alola';
      case 'galar':
        return 'Galar';
      case 'paldea':
        return 'Paldea';
      default:
        return formName.replaceAll('-', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
}
