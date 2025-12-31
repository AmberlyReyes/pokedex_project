
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';
import '../models/pokemon_list_item.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_evolution.dart';
import '../models/pokemon_encounter.dart';
import '../models/pokemon_variant.dart';
import '../models/cached_pokemon_list.dart';

class PokeApi {
  static const _graphqlEndpoint = 'https://beta.pokeapi.co/graphql/v1beta';
  static late GraphQLClient _client;

  /// Initialize the GraphQL client (call this once on app startup)
  static void initGraphQL() {
    final HttpLink httpLink = HttpLink(_graphqlEndpoint);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  // ============================================================
  // 1. LISTADO CON PAGINACIÓN - ONLINE-FIRST
  // ============================================================
  
 
  static Future<List<PokemonListItem>> fetchAllPokemons({
    int limit = 50, 
    int offset = 0,
  }) async {
    const query = '''
      query GetPokemons(\$limit: Int!, \$offset: Int!) {
        pokemon_v2_pokemon(
          limit: \$limit, 
          offset: \$offset, 
          order_by: {id: asc},
          where: {is_default: {_eq: true}}
        ) {
          id
          name
        }
      }
    ''';

    try {
      // 1. SIEMPRE intentar API primero
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'limit': limit, 'offset': offset},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('❌ Error GraphQL: ${result.exception}');
        // Fallback a caché
        return await _getFromCacheOrThrow(offset, limit, result.exception.toString());
      }

      final list = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      final pokemons = list.map((data) {
        final pokemon = data as Map<String, dynamic>;
        final id = pokemon['id'] as int;
        return PokemonListItem(
          id: id,
          name: pokemon['name'] as String,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
        );
      }).toList();

      // 2. Actualizar caché con datos frescos
      await _saveToCache(pokemons, offset, limit);
      print('✅ Datos de API, caché actualizado');

      return pokemons;
    } catch (e) {
      print('⚠️ Error de red: $e');
      // Fallback a caché
      return await _getFromCacheOrThrow(offset, limit, e.toString());
    }
  }
  
  /// Helper: Obtener de caché o lanzar error
  static Future<List<PokemonListItem>> _getFromCacheOrThrow(int offset, int limit, String originalError) async {
    try {
      final cacheBox = await Hive.openBox<CachedPokemonList>('pokemon_cache');
      final cacheKey = 'list_${offset}_$limit';
      final cached = cacheBox.get(cacheKey);
      if (cached != null) {
        print('📦 Usando caché (offline fallback)');
        return cached.pokemons;
      }
    } catch (e) {
      print('⚠️ Error leyendo caché: $e');
    }
    throw Exception('Sin conexión y sin datos en caché. Error original: $originalError');
  }
  
  /// Helper: Guardar en caché
  static Future<void> _saveToCache(List<PokemonListItem> pokemons, int offset, int limit) async {
    try {
      final cacheBox = await Hive.openBox<CachedPokemonList>('pokemon_cache');
      final cacheKey = 'list_${offset}_$limit';
      await cacheBox.put(cacheKey, CachedPokemonList(
        pokemons: pokemons,
        cachedAt: DateTime.now(),
        offset: offset,
        limit: limit,
      ));
    } catch (e) {
      print('⚠️ Error guardando caché: $e');
    }
  }

  // ============================================================
  // 2. SUPER QUERY - DETALLE COMPLETO EN UNA SOLA LLAMADA
  //    Incluye: Stats, Tipos, Habilidades, Movimientos, Evoluciones, Variantes
  // ============================================================
  
  static Future<PokemonDetail> fetchPokemonDetail(int id) async {
    const query = '''
      query GetPokemonDetail(\$id: Int!) {
        pokemon_v2_pokemon(where: {id: {_eq: \$id}}) {
          id
          name
          height
          weight
          pokemon_v2_pokemonsprites {
            sprites
          }
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
              pokemon_v2_typeefficacies {
                damage_factor
                pokemonV2TypeByTargetTypeId {
                  name
                }
              }
            }
          }
          pokemon_v2_pokemonstats {
            pokemon_v2_stat {
              name
            }
            base_stat
          }
          pokemon_v2_pokemonabilities {
            is_hidden
            pokemon_v2_ability {
              name
              pokemon_v2_abilityeffecttexts(where: {language_id: {_eq: 9}}) {
                effect
              }
            }
          }
          pokemon_v2_pokemonmoves(distinct_on: move_id, order_by: {move_id: asc}) {
            level
            pokemon_v2_movelearnmethod {
              name
            }
            pokemon_v2_move {
              name
            }
            pokemon_v2_versiongroup {
              name
            }
          }
          pokemon_v2_pokemonspecy {
            name
            pokemon_v2_pokemonegggroups {
              pokemon_v2_egggroup {
                name
              }
            }
            # Flavor text (descripción Pokédex)
            pokemon_v2_pokemonspeciesflavortexts(
              where: {language_id: {_eq: 9}}, 
              limit: 1,
              order_by: {version_id: desc}
            ) {
              flavor_text
            }
            # CADENA EVOLUTIVA (Anidada)
            pokemon_v2_evolutionchain {
              pokemon_v2_pokemonspecies(order_by: {order: asc}) {
                id
                name
                pokemon_v2_pokemonevolutions {
                  min_level
                  time_of_day
                  pokemon_v2_evolutiontrigger {
                    name
                  }
                  pokemon_v2_item {
                    name
                  }
                  pokemon_v2_location {
                    name
                  }
                }
              }
            }
            # VARIANTES / MEGAS (Hermanos de especie, excluyendo default)
            pokemon_v2_pokemons(where: {is_default: {_eq: false}}) {
              id
              name
              pokemon_v2_pokemonforms {
                form_name
                is_mega
                is_battle_only
              }
              pokemon_v2_pokemontypes {
                pokemon_v2_type {
                  name
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon detail: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;
      if (pokemons == null || pokemons.isEmpty) {
        throw Exception('Pokemon not found');
      }

      final pokemon = pokemons[0] as Map<String, dynamic>;
      return PokemonDetail.fromGraphQL(pokemon);
    } catch (e) {
      throw Exception('Error fetching pokemon detail: $e');
    }
  }

  // ============================================================
  // 3. CADENA EVOLUTIVA (Separada para casos donde solo se necesita esto)
  // ============================================================
  
  static Future<List<PokemonEvolution>> fetchEvolutionChain(int pokemonId) async {
    const query = '''
      query GetEvolutionChain(\$pokemonId: Int!) {
        pokemon_v2_pokemonspecies(where: {id: {_eq: \$pokemonId}}) {
          pokemon_v2_evolutionchain {
            pokemon_v2_pokemonspecies(order_by: {order: asc}) {
              id
              name
              pokemon_v2_pokemonevolutions {
                min_level
                time_of_day
                pokemon_v2_evolutiontrigger {
                  name
                }
                pokemon_v2_item {
                  name
                }
                pokemon_v2_location {
                  name
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'pokemonId': pokemonId},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching evolution chain: ${result.exception}');
      }

      final species = result.data?['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      if (species.isEmpty) return [];

      final evolutionChainData = (species[0] as Map<String, dynamic>)['pokemon_v2_evolutionchain'];
      
      if (evolutionChainData == null || evolutionChainData is! Map<String, dynamic>) {
        return [];
      }

      final evolutionChain = evolutionChainData;
      final allSpecies = evolutionChain['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      
      return allSpecies.map((s) {
        final speciesData = s as Map<String, dynamic>;
        if (speciesData.containsKey('name') && speciesData.containsKey('id')) {
          return PokemonEvolution.fromGraphQL(speciesData);
        }
        return null;
      }).whereType<PokemonEvolution>().toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 4. VARIANTES / FORMAS (Megas, Regionales, Gigantamax)
  //  
  // ============================================================
  
  static Future<List<PokemonVariant>> fetchPokemonVariants(String pokemonName) async {
    const query = '''
      query GetPokemonVariants(\$name: String!) {
        pokemon_v2_pokemonspecies(where: {name: {_eq: \$name}}) {
          pokemon_v2_pokemons(where: {is_default: {_eq: false}}) {
            id
            name
            pokemon_v2_pokemonforms {
              form_name
              is_mega
              is_battle_only
            }
            pokemon_v2_pokemontypes {
              pokemon_v2_type {
                name
              }
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'name': pokemonName.toLowerCase()},
        ),
      );

      if (result.hasException) {
        return [];
      }

      final species = result.data?['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      if (species.isEmpty) return [];

      final variants = <PokemonVariant>[];
      final pokemons = (species[0] as Map<String, dynamic>)['pokemon_v2_pokemons'] as List<dynamic>? ?? [];

      for (final pokemonData in pokemons) {
        final pokemon = pokemonData as Map<String, dynamic>;
        final id = pokemon['id'] as int;
        final name = pokemon['name'] as String;
        
        // Obtener form_name de pokemon_v2_pokemonforms
        final forms = pokemon['pokemon_v2_pokemonforms'] as List<dynamic>? ?? [];
        String formName = '';
        bool isMega = false;
        
        if (forms.isNotEmpty) {
          final form = forms[0] as Map<String, dynamic>;
          formName = form['form_name'] as String? ?? '';
          isMega = form['is_mega'] as bool? ?? false;
        }
        
        // Determinar el tipo de variante
        String variantType = _extractVariantType(name, formName, isMega);
        
        // Obtener tipos
        final typesList = <String>[];
        final types = pokemon['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
        for (final t in types) {
          final typeName = (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String;
          typesList.add(typeName);
        }
        
        variants.add(PokemonVariant(
          id: id,
          name: name,
          formName: formName.isEmpty ? name : formName,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
          variantType: variantType,
          types: typesList.isNotEmpty ? typesList : ['unknown'],
        ));
      }

      return variants;
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 5. UBICACIONES DONDE APARECE UN POKÉMON
  // ============================================================
  
  /// Obtiene las regiones/ubicaciones donde se puede encontrar un Pokémon
  static Future<List<String>> fetchPokemonLocations(int pokemonId) async {
    const query = '''
      query GetPokemonLocations(\$pokemonId: Int!) {
        pokemon_v2_encounter(
          where: {pokemon_id: {_eq: \$pokemonId}},
          distinct_on: [location_area_id]
        ) {
          pokemon_v2_locationarea {
            name
            pokemon_v2_location {
              name
              pokemon_v2_region {
                name
              }
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'pokemonId': pokemonId},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        return [];
      }

      final encounters = result.data?['pokemon_v2_encounter'] as List<dynamic>? ?? [];
      final Set<String> locations = {};

      for (final encounter in encounters) {
        final locationArea = encounter['pokemon_v2_locationarea'] as Map<String, dynamic>?;
        if (locationArea != null) {
          final location = locationArea['pokemon_v2_location'] as Map<String, dynamic>?;
          if (location != null) {
            final region = location['pokemon_v2_region'] as Map<String, dynamic>?;
            final regionName = region?['name'] as String? ?? '';
            final locationName = location['name'] as String;
            
            // Formato: "Region - Location" o solo "Location" si no hay región
            if (regionName.isNotEmpty) {
              locations.add('${_capitalizeWords(regionName)} - ${_capitalizeWords(locationName.replaceAll('-', ' '))}');
            } else {
              locations.add(_capitalizeWords(locationName.replaceAll('-', ' ')));
            }
          }
        }
      }

      return locations.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ============================================================
  // 6. ENCUENTROS POR UBICACIÓN - 
  //    Consulta directa a pokemon_v2_encounter
  // ============================================================
  
  static Future<List<PokemonEncounter>> fetchPokemonByLocation(String locationName) async {
    // Normalizar el nombre (remover región si existe, ej: "kanto/pallet-town" -> "pallet-town")
    final parts = locationName.toLowerCase().split('/');
    final cleanName = parts.length > 1 ? parts[1].replaceAll(' ', '-') : parts[0].replaceAll(' ', '-');
    
    print('🗺️ Buscando Pokémon en: $locationName (limpio: $cleanName)');
    
    // Paso 1: Obtener el ID de la ubicación AREA (más específico)
    const locationAreaQuery = '''
      query GetLocationArea(\$name: String!) {
        pokemon_v2_locationarea(where: {name: {_ilike: \$name}}) {
          id
          name
          location_id
        }
      }
    ''';

    try {
      final locationResult = await _client.query(
        QueryOptions(
          document: gql(locationAreaQuery),
          variables: {'name': '%$cleanName%'},
        ),
      );

      if (locationResult.hasException) {
        print('❌ Error en query: ${locationResult.exception}');
        throw Exception('Error fetching location: ${locationResult.exception}');
      }

      final locationAreas = locationResult.data?['pokemon_v2_locationarea'] as List<dynamic>? ?? [];
      if (locationAreas.isEmpty) {
        print('⚠️ No se encontró el área: $cleanName');
        return [];
      }

      final locationAreaId = (locationAreas[0] as Map<String, dynamic>)['id'] as int;
      print('✅ Área encontrada ID: $locationAreaId');

      // Paso 2: Obtener encuentros de esa área específica
      const encounterQuery = '''
        query GetEncounters(\$areaId: Int!) {
          pokemon_v2_encounter(
            where: {
              location_area_id: {_eq: \$areaId}
            },
            distinct_on: pokemon_id,
            order_by: {pokemon_id: asc}
          ) {
            pokemon_id
            min_level
            max_level
            pokemon_v2_pokemon {
              id
              name
            }
            pokemon_v2_encounterslot {
              rarity
              pokemon_v2_encountermethod {
                name
              }
            }
            pokemon_v2_version {
              name
            }
            pokemon_v2_locationarea {
              name
            }
          }
        }
      ''';

      final encounterResult = await _client.query(
        QueryOptions(
          document: gql(encounterQuery),
          variables: {'areaId': locationAreaId},
        ),
      );

      if (encounterResult.hasException) {
        print('❌ Error en encounters: ${encounterResult.exception}');
        return [];
      }

      final encounters = encounterResult.data?['pokemon_v2_encounter'] as List<dynamic>? ?? [];
      print('📊 Encuentros encontrados: ${encounters.length}');
      
      // Agrupar por pokemon_id para evitar duplicados
      final pokemonMap = <int, PokemonEncounter>{};
      
      for (final enc in encounters) {
        final encounterData = enc as Map<String, dynamic>;
        final pokemon = encounterData['pokemon_v2_pokemon'] as Map<String, dynamic>?;
        
        if (pokemon == null) continue;
        
        final id = pokemon['id'] as int;
        final name = pokemon['name'] as String;
        
        // Si ya existe, no lo sobrescribimos (ya tenemos uno)
        if (pokemonMap.containsKey(id)) continue;
        
        final minLevel = encounterData['min_level'] as int? ?? 0;
        final maxLevel = encounterData['max_level'] as int? ?? 0;
        
        // Obtener método y rarity del slot
        final slot = encounterData['pokemon_v2_encounterslot'] as Map<String, dynamic>?;
        final rarity = slot?['rarity'] as int? ?? 0;
        final methodData = slot?['pokemon_v2_encountermethod'] as Map<String, dynamic>?;
        final method = methodData?['name'] as String? ?? 'unknown';
        
        final version = encounterData['pokemon_v2_version'] as Map<String, dynamic>?;
        final versionName = version?['name'] as String? ?? 'unknown';
        
        pokemonMap[id] = PokemonEncounter(
          id: id,
          name: name,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
          chance: rarity,
          minLevel: minLevel,
          maxLevel: maxLevel,
          method: method,
          version: versionName,
        );
      }

      final result = pokemonMap.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      print('🎯 Total de Pokémon únicos: ${result.length}');
      return result;
    } catch (e) {
      print('💥 Error general: $e');
      throw Exception('Error fetching pokemon by location: $e');
    }
  }

  // ============================================================
  // 6. FILTROS Y BÚSQUEDA
  // ============================================================
  
  /// Fetch pokemon names by type using GraphQL
  static Future<Set<String>> fetchPokemonNamesByType(String type) async {
    const query = '''
      query GetPokemonByType(\$typeName: String!) {
        pokemon_v2_type(where: {name: {_eq: \$typeName}}) {
          pokemon_v2_pokemontypes {
            pokemon_v2_pokemon {
              name
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'typeName': type},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching type $type: ${result.exception}');
      }

      final types = result.data?['pokemon_v2_type'] as List<dynamic>? ?? [];
      final names = <String>{};

      for (final typeData in types) {
        final pokemonTypes = typeData['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
        for (final pt in pokemonTypes) {
          final pokemon = pt['pokemon_v2_pokemon'] as Map<String, dynamic>?;
          if (pokemon != null) {
            final name = pokemon['name'] as String?;
            if (name != null) names.add(name);
          }
        }
      }

      return names;
    } catch (e) {
      throw Exception('Error fetching type $type: $e');
    }
  }

  /// Fetch pokemon names by generation using GraphQL
  static Future<Set<String>> fetchPokemonNamesByGeneration(int generationId) async {
    const query = '''
      query GetPokemonByGeneration(\$genId: Int!) {
        pokemon_v2_generation(where: {id: {_eq: \$genId}}) {
          pokemon_v2_pokemonspecies {
            name
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'genId': generationId},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching generation $generationId: ${result.exception}');
      }

      final generations = result.data?['pokemon_v2_generation'] as List<dynamic>? ?? [];
      final names = <String>{};

      for (final gen in generations) {
        final species = gen['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
        for (final s in species) {
          final name = s['name'] as String?;
          if (name != null) names.add(name);
        }
      }

      return names;
    } catch (e) {
      throw Exception('Error fetching generation $generationId: $e');
    }
  }

  /// Fetch pokemon names by base stat total range
  /// Rangos comunes:
  /// - Bajo: 0-300 (débiles como Caterpie, Magikarp)
  /// - Medio: 301-450 (promedio como Pikachu, starters básicos)
  /// - Alto: 451-550 (fuertes como starters finales)
  /// - Muy Alto: 551-600 (pseudo-legendarios)
  /// - Legendario: 600+ (legendarios y míticos)
  static Future<Set<String>> fetchPokemonNamesByPowerRange(int minStat, int maxStat) async {
    const query = '''
      query GetPokemonByPower {
        pokemon_v2_pokemon(
          where: {
            is_default: {_eq: true}
          }
        ) {
          name
          pokemon_v2_pokemonstats_aggregate {
            aggregate {
              sum {
                base_stat
              }
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon by power: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      final names = <String>{};

      for (final pokemon in pokemons) {
        final aggregate = pokemon['pokemon_v2_pokemonstats_aggregate']?['aggregate'];
        final sumData = aggregate?['sum'];
        final totalStat = sumData?['base_stat'] as int? ?? 0;
        
        if (totalStat >= minStat && totalStat <= maxStat) {
          final name = pokemon['name'] as String?;
          if (name != null) names.add(name);
        }
      }

      return names;
    } catch (e) {
      print('⚠️ Error fetching pokemon by power: $e');
      return {};
    }
  }

  /// Fetch pokemon types by id using GraphQL
  static Future<List<String>> fetchPokemonTypes(int id) async {
    const query = '''
      query GetPokemonTypes(\$id: Int!) {
        pokemon_v2_pokemon(where: {id: {_eq: \$id}}) {
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': id},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon types: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      if (pokemons.isEmpty) return [];

      final pokemon = pokemons[0] as Map<String, dynamic>;
      final types = pokemon['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];

      return types
          .map((t) => (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error fetching pokemon types: $e');
    }
  }

  /// Fetch detailed stats for a Pokémon
  static Future<Map<String, dynamic>> fetchPokemonStats(int id) async {
    const query = '''
      query GetPokemonStats(\$id: Int!) {
        pokemon_v2_pokemon(where: {id: {_eq: \$id}}) {
          pokemon_v2_pokemonstats {
            base_stat
            pokemon_v2_stat {
              name
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': id},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon stats: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;
      if (pokemons == null || pokemons.isEmpty) {
        throw Exception('Pokemon not found');
      }

      final stats = pokemons[0]['pokemon_v2_pokemonstats'] as List<dynamic>;
      final Map<String, dynamic> statsMap = {};

      for (final stat in stats) {
        final statName = stat['pokemon_v2_stat']['name'] as String;
        final baseStat = stat['base_stat'] as int;
        statsMap[statName] = baseStat;
      }

      return statsMap;
    } catch (e) {
      throw Exception('Error fetching pokemon stats: $e');
    }
  }

  // ============================================================
  // 7. BÚSQUEDA GLOBAL
  // ============================================================
  
  /// Search pokemon by name globally across all pokemons
  static Future<List<PokemonListItem>> searchPokemonByName(String query) async {
    const queryTemplate = '''
      query SearchPokemon(\$query: String!) {
        pokemon_v2_pokemon(
          where: {
            name: {_ilike: \$query},
            is_default: {_eq: true}
          }, 
          limit: 20, 
          order_by: {id: asc}
        ) {
          id
          name
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(queryTemplate),
          variables: {'query': '%$query%'},
        ),
      );

      if (result.hasException) {
        throw Exception('Error searching pokemon: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      return pokemons.map((p) {
        final pokemon = p as Map<String, dynamic>;
        final id = pokemon['id'] as int;
        return PokemonListItem(
          id: id,
          name: pokemon['name'] as String,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error searching pokemon: $e');
    }
  }

  /// Search pokemon by ID
  static Future<PokemonListItem?> searchPokemonById(int id) async {
    const query = '''
      query GetPokemonById(\$id: Int!) {
        pokemon_v2_pokemon(where: {id: {_eq: \$id}, is_default: {_eq: true}}) {
          id
          name
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': id},
        ),
      );

      if (result.hasException) return null;

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      if (pokemons.isEmpty) return null;

      final pokemon = pokemons[0] as Map<String, dynamic>;
      return PokemonListItem(
        id: pokemon['id'] as int,
        name: pokemon['name'] as String,
        imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // UTILIDADES PRIVADAS
  // ============================================================
  
  /// Extract variant type from pokemon name and form data
  static String _extractVariantType(String pokemonName, String formName, bool isMega) {
    final nameLower = pokemonName.toLowerCase();
    final formLower = formName.toLowerCase();
    
    if (isMega || nameLower.contains('mega') || formLower.contains('mega')) {
      return 'mega';
    } else if (nameLower.contains('gmax') || formLower.contains('gigantamax')) {
      return 'gigantamax';
    } else if (nameLower.contains('alola') || formLower.contains('alola')) {
      return 'alola';
    } else if (nameLower.contains('galar') || formLower.contains('galar')) {
      return 'galar';
    } else if (nameLower.contains('paldea') || formLower.contains('paldea')) {
      return 'paldea';
    } else if (nameLower.contains('hisui') || formLower.contains('hisui')) {
      return 'hisui';
    }
    
    return 'variant';
  }
}
