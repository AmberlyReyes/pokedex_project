import 'package:hive/hive.dart';
import 'pokemon_ability.dart';
import 'pokemon_move.dart';
import 'pokemon_evolution.dart';
import 'pokemon_variant.dart';

part 'pokemon_detail.g.dart';

@HiveType(typeId: 1)
class PokemonDetail {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int height;

  @HiveField(3)
  final int weight;

  @HiveField(4)
  final List<String> types;

  @HiveField(5)
  final List<PokemonAbility> abilities;

  @HiveField(6)
  final Map<String, int> stats;

  @HiveField(7)
  final String spriteUrl;

  @HiveField(8)
  final List<PokemonMove> moves;

  @HiveField(9)
  final List<String> eggGroups;

  @HiveField(10)
  final Map<String, double> typeMatchups;

  @HiveField(11)
  bool isFavorite = false; // Campo para marcar si el Pokémon es favorito

  @HiveField(12)
  final List<PokemonEvolution> evolutions;

  @HiveField(13)
  final List<PokemonVariant> variants;

  @HiveField(14)
  final String flavorText; // Descripción de la Pokédex

  PokemonDetail({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.spriteUrl,
    required this.moves,
    required this.eggGroups,
    required this.typeMatchups,
    this.isFavorite = false, // Inicializar como no favorito por defecto
    required this.evolutions,
    required this.variants,
    this.flavorText = '',
  });

  /// Parse PokemonDetail from GraphQL response
  factory PokemonDetail.fromGraphQL(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final height = json['height'] as int;
    final weight = json['weight'] as int;

    // Parse types from GraphQL format
    final typesList = <String>[];
    final types = json['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
    for (final t in types) {
      final typeName = (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String;
      typesList.add(typeName);
    }

    // Parse abilities from GraphQL format
    final abilitiesList = <PokemonAbility>[];
    final abilities = json['pokemon_v2_pokemonabilities'] as List<dynamic>? ?? [];
    for (final a in abilities) {
      final ability = PokemonAbility.fromGraphQL(a as Map<String, dynamic>);
      abilitiesList.add(ability);
    }

    // Parse stats from GraphQL format
    final statsMap = <String, int>{};
    final stats = json['pokemon_v2_pokemonstats'] as List<dynamic>? ?? [];
    for (final s in stats) {
      final m = s as Map<String, dynamic>;
      final statName = (m['pokemon_v2_stat'] as Map<String, dynamic>)['name'] as String;
      final value = m['base_stat'] as int;
      statsMap[statName] = value;
    }

    // Parse sprite from GraphQL format
    String sprite = '';
    try {
      final sprites = json['pokemon_v2_pokemonsprites'] as List<dynamic>? ?? [];
      if (sprites.isNotEmpty) {
        final spritesData = sprites[0] as Map<String, dynamic>;
        final spritesJson = spritesData['sprites'] as Map<String, dynamic>?;
        sprite = spritesJson?['other']['official-artwork']['front_default'] as String? ?? '';
        if (sprite.isEmpty) {
          sprite = spritesJson?['front_default'] as String? ?? '';
        }
      }
    } catch (_) {
      sprite = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png';
    }

    // Parse moves from GraphQL format
    final movesList = <PokemonMove>[];
    final moves = json['pokemon_v2_pokemonmoves'] as List<dynamic>? ?? [];
    
    // Definir versiones prioritarias (más nuevas primero)
    const priorityVersions = [
      'scarlet-violet',
      'sword-shield',
      'ultra-sun-ultra-moon',
      'sun-moon',
      'omega-ruby-alpha-sapphire',
      'x-y',
    ];
    
    // Agrupar movimientos por nombre para eliminar duplicados
    final movesMap = <String, PokemonMove>{};
    
    for (final m in moves) {
      final move = PokemonMove.fromGraphQL(m as Map<String, dynamic>);
      
      // Si el movimiento no existe o si la versión actual es más prioritaria
      if (!movesMap.containsKey(move.name)) {
        movesMap[move.name] = move;
      } else {
        final existing = movesMap[move.name]!;
        final currentVersionIndex = priorityVersions.indexOf(move.versionGroup);
        final existingVersionIndex = priorityVersions.indexOf(existing.versionGroup);
        
        // Si la versión actual está en la lista de prioridades y es más alta
        if (currentVersionIndex != -1) {
          if (existingVersionIndex == -1 || currentVersionIndex < existingVersionIndex) {
            movesMap[move.name] = move;
          }
        }
      }
    }
    
    movesList.addAll(movesMap.values);

    // Parse egg groups from GraphQL format
    final eggGroupsList = <String>[];
    final specy = json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    if (specy != null) {
      final eggGroups = specy['pokemon_v2_pokemonegggroups'] as List<dynamic>? ?? [];
      for (final eg in eggGroups) {
        final groupName = (eg as Map<String, dynamic>)['pokemon_v2_egggroup']['name'] as String;
        eggGroupsList.add(groupName);
      }
    }

    // Parse type matchups from GraphQL format
    final typeMatchupsMap = <String, double>{};
    final pokemonTypes = json['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
    for (final pt in pokemonTypes) {
      final typeData = (pt as Map<String, dynamic>)['pokemon_v2_type'] as Map<String, dynamic>?;
      if (typeData != null) {
        final efficacies = typeData['pokemon_v2_typeefficacies'] as List<dynamic>? ?? [];
        for (final e in efficacies) {
          final efficacy = e as Map<String, dynamic>;
          final targetType = (efficacy['pokemonV2TypeByTargetTypeId']
              as Map<String, dynamic>)['name'] as String;
          final damageFactor = (efficacy['damage_factor'] as int) / 100.0;

          // Aggregate damage factors for dual-type Pokémon
          typeMatchupsMap[targetType] = (typeMatchupsMap[targetType] ?? 1.0) * damageFactor;
        }
      }
    }

    // Parse flavor text (descripción de la Pokédex)
    String flavorText = '';
    if (specy != null) {
      final flavorTexts = specy['pokemon_v2_pokemonspeciesflavortexts'] as List<dynamic>? ?? [];
      if (flavorTexts.isNotEmpty) {
        flavorText = (flavorTexts[0] as Map<String, dynamic>)['flavor_text'] as String? ?? '';
        // Limpiar caracteres de salto de línea y espacios extras
        flavorText = flavorText.replaceAll('\n', ' ').replaceAll('\f', ' ').trim();
      }
    }

    // Parse evoluciones desde la query unificada
    final evolutionsList = <PokemonEvolution>[];
    if (specy != null) {
      final evoChain = specy['pokemon_v2_evolutionchain'] as Map<String, dynamic>?;
      if (evoChain != null) {
        final species = evoChain['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
        for (final s in species) {
          final speciesData = s as Map<String, dynamic>;
          final evoId = speciesData['id'] as int;
          final evoName = speciesData['name'] as String;
          
          // Obtener detalles de evolución
          final evolutions = speciesData['pokemon_v2_pokemonevolutions'] as List<dynamic>? ?? [];
          String triggerType = 'other';
          String triggerDetails = 'Base form';
          
          if (evolutions.isNotEmpty) {
            final evoData = evolutions[0] as Map<String, dynamic>;
            final minLevel = evoData['min_level'] as int? ?? 0;
            
            final triggerData = evoData['pokemon_v2_evolutiontrigger'] as Map<String, dynamic>?;
            if (triggerData != null) {
              triggerType = triggerData['name'] as String? ?? 'other';
            }
            
            // Construir detalles según el tipo de trigger
            switch (triggerType) {
              case 'level-up':
                triggerDetails = minLevel > 0 ? 'Nivel $minLevel' : 'Subir nivel';
                break;
              case 'use-item':
                final itemData = evoData['pokemon_v2_item'] as Map<String, dynamic>?;
                if (itemData != null) {
                  final itemName = itemData['name'] as String;
                  triggerDetails = itemName.replaceAll('-', ' ');
                }
                break;
              case 'trade':
                triggerDetails = 'Intercambio';
                break;
              case 'shed':
                triggerDetails = 'Espacio en equipo';
                break;
              default:
                triggerDetails = 'Condición especial';
            }
            
            final timeOfDay = evoData['time_of_day'] as String? ?? '';
            if (timeOfDay.isNotEmpty) {
              triggerDetails += ' ($timeOfDay)';
            }
            
            final locationData = evoData['pokemon_v2_location'] as Map<String, dynamic>?;
            if (locationData != null) {
              final locationName = locationData['name'] as String;
              triggerDetails += ' en ${locationName.replaceAll('-', ' ')}';
            }
          }
          
          evolutionsList.add(PokemonEvolution(
            id: evoId,
            name: evoName,
            imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$evoId.png',
            triggerType: triggerType,
            triggerDetails: triggerDetails,
          ));
        }
      }
    }

    // Parse variantes (Megas, Regionales, Gigantamax)
    final variantsList = <PokemonVariant>[];
    if (specy != null) {
      final pokemons = specy['pokemon_v2_pokemons'] as List<dynamic>? ?? [];
      for (final p in pokemons) {
        final pokemonData = p as Map<String, dynamic>;
        final variantId = pokemonData['id'] as int;
        final variantName = pokemonData['name'] as String;
        
        // Obtener información de la forma
        final forms = pokemonData['pokemon_v2_pokemonforms'] as List<dynamic>? ?? [];
        String formName = '';
        bool isMega = false;
        bool isBattleOnly = false;
        
        if (forms.isNotEmpty) {
          final form = forms[0] as Map<String, dynamic>;
          formName = form['form_name'] as String? ?? '';
          isMega = form['is_mega'] as bool? ?? false;
          isBattleOnly = form['is_battle_only'] as bool? ?? false;
        }
        
        // Filtrar variantes cosméticas (como Pikachu Rock Star, Belle, etc.)
        // Solo incluir: Megas, Gigantamax, formas regionales y formas de batalla
        bool isSignificantVariant = isMega || 
                                    variantName.contains('mega') || 
                                    variantName.contains('gmax') || 
                                    variantName.contains('gigantamax') ||
                                    variantName.contains('alola') || 
                                    variantName.contains('galar') || 
                                    variantName.contains('paldea') ||
                                    variantName.contains('hisui') ||
                                    formName.contains('mega') ||
                                    formName.contains('gigantamax') ||
                                    formName.contains('alola') ||
                                    formName.contains('galar') ||
                                    formName.contains('paldea') ||
                                    formName.contains('hisui');
        
        // Omitir variantes cosméticas que no tienen sprites
        if (!isSignificantVariant) {
          continue;
        }
        
        // Determinar tipo de variante
        String variantType = 'variant';
        if (isMega || variantName.contains('mega') || formName.contains('mega')) {
          variantType = 'mega';
        } else if (variantName.contains('gmax') || formName.contains('gigantamax')) {
          variantType = 'gigantamax';
        } else if (variantName.contains('alola') || formName.contains('alola')) {
          variantType = 'alola';
        } else if (variantName.contains('galar') || formName.contains('galar')) {
          variantType = 'galar';
        } else if (variantName.contains('paldea') || formName.contains('paldea')) {
          variantType = 'paldea';
        } else if (variantName.contains('hisui') || formName.contains('hisui')) {
          variantType = 'hisui';
        }
        
        // Obtener tipos de la variante
        final variantTypes = <String>[];
        final types = pokemonData['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
        for (final t in types) {
          final typeData = (t as Map<String, dynamic>)['pokemon_v2_type'] as Map<String, dynamic>?;
          if (typeData != null) {
            variantTypes.add(typeData['name'] as String);
          }
        }
        
        variantsList.add(PokemonVariant(
          id: variantId,
          name: variantName,
          formName: formName.isEmpty ? variantName : formName,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$variantId.png',
          variantType: variantType,
          types: variantTypes.isNotEmpty ? variantTypes : ['unknown'],
        ));
      }
    }

    return PokemonDetail(
      id: id,
      name: name,
      height: height,
      weight: weight,
      types: typesList,
      abilities: abilitiesList,
      stats: statsMap,
      spriteUrl: sprite,
      moves: movesList,
      eggGroups: eggGroupsList,
      typeMatchups: typeMatchupsMap,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
      evolutions: evolutionsList,
      variants: variantsList,
      flavorText: flavorText,
    );
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
