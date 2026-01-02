
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';
import '../models/pokemon_list_item.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_encounter.dart';
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
  // 1. LISTADO CON PAGINACIÓN Y FILTROS - UNA SOLA QUERY
  // ============================================================
  
  /// Obtiene pokémon con filtros opcionales en UNA SOLA query GraphQL
  /// Incluye tipos para evitar llamadas adicionales en las cards
  static Future<List<PokemonListItem>> fetchPokemonsWithFilters({
    int limit = 50, 
    int offset = 0,
    int? generationId,
    List<String>? types,
    int? minPower,
    int? maxPower,
    String? searchQuery,
  }) async {
    // Construir condiciones dinámicamente
    final conditions = <String>['is_default: {_eq: true}'];
    final variables = <String, dynamic>{'limit': limit, 'offset': offset};
    
    // Filtro de búsqueda por nombre/ID
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final numericId = int.tryParse(searchQuery);
      if (numericId != null) {
        conditions.add('_or: [{name: {_ilike: \$search}}, {id: {_eq: $numericId}}]');
      } else {
        conditions.add('name: {_ilike: \$search}');
      }
      variables['search'] = '%$searchQuery%';
    }
    
    // Filtro de generación
    if (generationId != null) {
      conditions.add('pokemon_v2_pokemonspecy: {generation_id: {_eq: \$genId}}');
      variables['genId'] = generationId;
    }
    
    // Filtro de tipos (múltiples)
    if (types != null && types.isNotEmpty) {
      for (var i = 0; i < types.length; i++) {
        conditions.add('pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_eq: \$type$i}}}');
        variables['type$i'] = types[i];
      }
    }
    
    final whereClause = conditions.join(', ');
    
    // Construir declaración de variables
    var varDeclaration = '\$limit: Int!, \$offset: Int!';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      varDeclaration += ', \$search: String!';
    }
    if (generationId != null) {
      varDeclaration += ', \$genId: Int!';
    }
    if (types != null) {
      for (var i = 0; i < types.length; i++) {
        varDeclaration += ', \$type$i: String!';
      }
    }
    
    // Incluir stats solo si necesitamos filtrar por poder
    final needsPowerFilter = minPower != null && maxPower != null;
    final statsField = needsPowerFilter ? '''
          pokemon_v2_pokemonstats_aggregate {
            aggregate {
              sum {
                base_stat
              }
            }
          }
    ''' : '';
    
    final query = '''
      query GetPokemonsFiltered($varDeclaration) {
        pokemon_v2_pokemon(
          limit: \$limit, 
          offset: \$offset, 
          order_by: {id: asc},
          where: {$whereClause}
        ) {
          id
          name
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
          $statsField
        }
      }
    ''';

    // Log para monitorear llamadas
    final filterInfo = <String>[];
    if (searchQuery != null) filterInfo.add('search="$searchQuery"');
    if (generationId != null) filterInfo.add('gen=$generationId');
    if (types != null && types.isNotEmpty) filterInfo.add('types=${types.join(",")}');
    if (minPower != null) filterInfo.add('power=$minPower-$maxPower');
    print('🔍 API Call: offset=$offset, limit=$limit ${filterInfo.isNotEmpty ? "(${filterInfo.join(", ")})" : ""}');

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: variables,
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        print('❌ Error GraphQL: ${result.exception}');
        // Fallback a caché si existe
        return await _getFromCacheOrThrow(offset, limit, result.exception.toString());
      }

      final list = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      print('✅ Respuesta: ${list.length} pokémon');
      
      // Filtrar por poder en memoria si es necesario
      var filtered = list;
      if (needsPowerFilter) {
        filtered = list.where((p) {
          final pokemon = p as Map<String, dynamic>;
          final aggregate = pokemon['pokemon_v2_pokemonstats_aggregate']?['aggregate'];
          final sumData = aggregate?['sum'];
          final totalStat = sumData?['base_stat'] as int? ?? 0;
          return totalStat >= minPower && totalStat <= maxPower;
        }).toList();
      }
      
      final pokemons = filtered.map((data) {
        final pokemon = data as Map<String, dynamic>;
        final id = pokemon['id'] as int;
        
        // Extraer tipos directamente de la query
        final typesData = pokemon['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
        final typesList = typesData
            .map((t) => (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String)
            .toList();
        
        return PokemonListItem(
          id: id,
          name: pokemon['name'] as String,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
          types: typesList,
        );
      }).toList();

      // Guardar en caché solo si no hay filtros (lista base)
      if (generationId == null && types == null && minPower == null && searchQuery == null) {
        final shouldUpdate = await _shouldUpdateCache(offset, limit);
        if (shouldUpdate) {
          await _saveToCache(pokemons, offset, limit);
        }
      }

      return pokemons;
    } catch (e) {
      print('⚠️ Error de red: $e');
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
        // Verificar si el caché está expirado (más de 7 días)
        if (cached.isExpired(maxAge: const Duration(days: 7))) {
          print('⏰ Caché expirado (${cached.cachedAt}), pero se usará por falta de conexión');
        } else {
          print('📦 Usando caché válido (${cached.cachedAt})');
        }
        return cached.pokemons;
      }
    } catch (e) {
      print('⚠️ Error leyendo caché: $e');
    }
    throw Exception('Sin conexión y sin datos en caché. Error original: $originalError');
  }
  
  /// Helper: Verificar si el caché necesita actualizarse (si es antiguo o no existe)
  static Future<bool> _shouldUpdateCache(int offset, int limit) async {
    try {
      final cacheBox = await Hive.openBox<CachedPokemonList>('pokemon_cache');
      final cacheKey = 'list_${offset}_$limit';
      final cached = cacheBox.get(cacheKey);
      
      // Si no existe caché, debe actualizarse
      if (cached == null) return true;
      
      // Si está expirado (más de 1 día), debe actualizarse
      return cached.isExpired(maxAge: const Duration(hours: 24));
    } catch (e) {
      return true; // En caso de error, intentar actualizar
    }
  }
  
  /// Helper: Guardar en caché
  static Future<void> _saveToCache(List<PokemonListItem> pokemons, int offset, int limit) async {
    try {
      final cacheBox = await Hive.openBox<CachedPokemonList>('pokemon_cache');
      final cacheKey = 'list_${offset}_$limit';
      
      // Limitar tamaño del caché (máximo 30 páginas)
      if (cacheBox.length >= 30) {
        final keys = cacheBox.keys.toList();
        final oldestKey = keys.first;
        await cacheBox.delete(oldestKey);
      }
      
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
  // 3. ENCUENTROS POR UBICACIÓN - UNA SOLA QUERY OPTIMIZADA
  //    Busca por nombre de location area directamente
  // ============================================================
  
  static Future<List<PokemonEncounter>> fetchPokemonByLocation(String locationName) async {
    // Normalizar el nombre (remover región si existe, ej: "kanto/pallet-town" -> "pallet-town")
    final parts = locationName.toLowerCase().split('/');
    final cleanName = parts.length > 1 ? parts[1].replaceAll(' ', '-') : parts[0].replaceAll(' ', '-');
    
    print('🗺️ Buscando Pokémon en: $locationName (limpio: $cleanName)');
    
    // UNA SOLA QUERY: Buscar encounters directamente por nombre de location area
    const query = '''
      query GetEncountersByLocationName(\$name: String!) {
        pokemon_v2_encounter(
          where: {
            pokemon_v2_locationarea: {
              pokemon_v2_location: {
                name: {_ilike: \$name}
              }
            }
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
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'name': '%$cleanName%'},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        print('❌ Error en query: ${result.exception}');
        throw Exception('Error fetching encounters: ${result.exception}');
      }

      final encounters = result.data?['pokemon_v2_encounter'] as List<dynamic>? ?? [];
      print('📊 Encuentros encontrados: ${encounters.length}');
      
      if (encounters.isEmpty) {
        print('⚠️ No se encontraron Pokémon en: $cleanName');
        return [];
      }
      
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

      final pokemonList = pokemonMap.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      print('🎯 Total de Pokémon únicos: ${pokemonList.length}');
      return pokemonList;
    } catch (e) {
      print('💥 Error general: $e');
      throw Exception('Error fetching pokemon by location: $e');
    }
  }

  // ============================================================
  // 5. BÚSQUEDA POR IDs (usado por trivia - UNA SOLA LLAMADA)
  // ============================================================

  /// Obtiene múltiples pokémon por IDs en UNA SOLA query (para trivia)
  static Future<List<PokemonListItem>> fetchPokemonsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    final query = '''
      query GetPokemonsByIds(\$ids: [Int!]!) {
        pokemon_v2_pokemon(
          where: {id: {_in: \$ids}, is_default: {_eq: true}},
          order_by: {id: asc}
        ) {
          id
          name
        }
      }
    ''';

    print('🎮 Trivia: Buscando ${ids.length} pokémon en 1 llamada');

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'ids': ids},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        print('❌ Error en trivia: ${result.exception}');
        return [];
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      print('✅ Trivia: ${pokemons.length} pokémon obtenidos');
      
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
      print('⚠️ Error en trivia: $e');
      return [];
    }
  }
}
