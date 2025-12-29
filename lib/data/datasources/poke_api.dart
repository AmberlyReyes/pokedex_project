import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pokemon_list_item.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_evolution.dart';
import '../models/pokemon_encounter.dart';
import '../models/pokemon_variant.dart';

class PokeApi {
  static const _graphqlEndpoint = 'https://beta.pokeapi.co/graphql/v1beta';
  static const _restEndpoint = 'https://pokeapi.co/api/v2';
  static late GraphQLClient _client;

  /// Initialize the GraphQL client (call this once on app startup)
  static void initGraphQL() {
    final HttpLink httpLink = HttpLink(_graphqlEndpoint);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  /// Fetch the full list of pokemons using GraphQL with offset/limit pagination
  static Future<List<PokemonListItem>> fetchAllPokemons({int limit = 50, int offset = 0}) async {
    const query = '''
      query GetPokemons(\$limit: Int!, \$offset: Int!) {
        pokemon_v2_pokemonspecies(limit: \$limit, offset: \$offset, order_by: {id: asc}) {
          id
          name
          pokemon_v2_pokemons {
            id
            name
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'limit': limit,
            'offset': offset,
          },
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon list: ${result.exception}');
      }

      final species = result.data?['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      return species.map((s) {
        final speciesData = s as Map<String, dynamic>;
        final id = speciesData['id'] as int;
        final pokemons = speciesData['pokemon_v2_pokemons'] as List<dynamic>? ?? [];

        if (pokemons.isNotEmpty) {
          final pokemon = pokemons[0] as Map<String, dynamic>;
          final pokemonName = pokemon['name'] as String;
          return PokemonListItem(
            name: pokemonName,
            id: id,
            imageUrl:
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
          );
        }
        return null;
      }).whereType<PokemonListItem>().toList();
    } catch (e) {
      throw Exception('Error fetching pokemon list: $e');
    }
  }

  /// Fetch detailed info for a single pokemon by id using GraphQL
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
              pokemon_v2_abilityeffecttexts {
                effect
              }
            }
          }
          pokemon_v2_pokemonmoves {
            level
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

  /// Fetch the evolution chain with detailed trigger information
  static Future<List<PokemonEvolution>> fetchEvolutionChain(int pokemonId) async {
    const query = '''
      query GetEvolutionChain(\$pokemonId: Int!) {
        pokemon_v2_pokemonspecies(where: {id: {_eq: \$pokemonId}}) {
          pokemon_v2_evolutionchain {
            pokemon_v2_pokemonspecies(order_by: {id: asc}) {
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
        final pokemonTypes =
            typeData['pokemon_v2_pokemontypes'] as List<dynamic>? ?? [];
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
          .map((t) =>
              (t as Map<String, dynamic>)['pokemon_v2_type']['name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error fetching pokemon types: $e');
    }
  }

  /// Fetch detailed stats for a Pokémon
  static Future<Map<String, dynamic>> fetchPokemonStats(int id) async {
    const query = '''
      query GetPokemonStats(
        \$id: Int!
      ) {
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

  /// Search pokemon by name globally across all pokemons
  static Future<List<PokemonListItem>> searchPokemonByName(String query) async {
    const queryTemplate = '''
      query SearchPokemon(\$query: String!) {
        pokemon_v2_pokemonspecies(where: {name: {_ilike: \$query}}, limit: 20, order_by: {id: asc}) {
          id
          name
          pokemon_v2_pokemons {
            id
            name
          }
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

      final species = result.data?['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      return species.map((s) {
        final speciesData = s as Map<String, dynamic>;
        final id = speciesData['id'] as int;
        final pokemons = speciesData['pokemon_v2_pokemons'] as List<dynamic>? ?? [];

        if (pokemons.isNotEmpty) {
          final pokemon = pokemons[0] as Map<String, dynamic>;
          final pokemonName = pokemon['name'] as String;
          return PokemonListItem(
            name: pokemonName,
            id: id,
            imageUrl:
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
          );
        }
        return null;
      }).whereType<PokemonListItem>().toList();
    } catch (e) {
      throw Exception('Error searching pokemon: $e');
    }
  }

  /// Search pokemon by ID
  static Future<PokemonListItem?> searchPokemonById(int id) async {
    const query = '''
      query GetPokemonById(\$id: Int!) {
        pokemon_v2_pokemonspecies(where: {id: {_eq: \$id}}) {
          id
          name
          pokemon_v2_pokemons {
            id
            name
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

      if (result.hasException) return null;

      final species = result.data?['pokemon_v2_pokemonspecies'] as List<dynamic>? ?? [];
      if (species.isEmpty) return null;

      final speciesData = species[0] as Map<String, dynamic>;
      final pokemons = speciesData['pokemon_v2_pokemons'] as List<dynamic>? ?? [];

      if (pokemons.isNotEmpty) {
        final pokemon = pokemons[0] as Map<String, dynamic>;
        final pokemonName = pokemon['name'] as String;
        return PokemonListItem(
          name: pokemonName,
          id: id,
          imageUrl:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch pokemon encounters by location name
  /// Extrae información detallada: chance, min/max level, method, version
  static Future<List<PokemonEncounter>> fetchPokemonByLocation(String locationName) async {
    try {
      // Extraer solo la región (primera parte antes del /)
      String region = locationName.contains('/') 
          ? locationName.split('/').first 
          : locationName;
      
      // Primera petición: obtener las áreas de la location
      final locationUrl = '$_restEndpoint/location/${region.toLowerCase()}';
      print('DEBUG POKE_API: locationName original: $locationName');
      print('DEBUG POKE_API: región extraída: $region');
      print('DEBUG POKE_API: Primera petición a: $locationUrl');
      
      final locationResponse = await http.get(Uri.parse(locationUrl));

      print('DEBUG POKE_API: Status de respuesta: ${locationResponse.statusCode}');

      if (locationResponse.statusCode != 200) {
        throw Exception('Error fetching location: ${locationResponse.statusCode}');
      }

      final locationData = jsonDecode(locationResponse.body) as Map<String, dynamic>;
      final areas = locationData['areas'] as List<dynamic>? ?? [];

      print('DEBUG POKE_API: Áreas encontradas: ${areas.length}');

      if (areas.isEmpty) {
        return [];
      }

      final allPokemon = <String, PokemonEncounter>{}; // Map para evitar duplicados

      // Para cada área, obtener los pokemon encounters
      for (int i = 0; i < areas.length; i++) {
        final area = areas[i];
        final areaData = area as Map<String, dynamic>;
        final areaUrl = areaData['url'] as String?;

        print('DEBUG POKE_API: Área $i URL: $areaUrl');

        if (areaUrl != null) {
          try {
            final areaResponse = await http.get(Uri.parse(areaUrl));

            if (areaResponse.statusCode == 200) {
              final areaDetailData = jsonDecode(areaResponse.body) as Map<String, dynamic>;
              final pokemonEncounters = areaDetailData['pokemon_encounters'] as List<dynamic>? ?? [];

              print('DEBUG POKE_API: Pokémon encontrados en esta área: ${pokemonEncounters.length}');

              for (final encounter in pokemonEncounters) {
                final encounterData = encounter as Map<String, dynamic>;
                final pokemonData = encounterData['pokemon'] as Map<String, dynamic>?;
                final versionDetails = encounterData['version_details'] as List<dynamic>? ?? [];

                if (pokemonData != null && versionDetails.isNotEmpty) {
                  final pokemonUrl = pokemonData['url'] as String?;
                  final pokemonName = pokemonData['name'] as String?;

                  if (pokemonUrl != null && pokemonName != null) {
                    // Extraer el ID del URL
                    final idMatch = RegExp(r'/pokemon/(\d+)/?$').firstMatch(pokemonUrl);
                    if (idMatch != null) {
                      final id = int.parse(idMatch.group(1)!);

                      // Procesar detalles de versión
                      for (final versionDetail in versionDetails) {
                        final versionDetailData = versionDetail as Map<String, dynamic>;
                        final version = versionDetailData['version'] as Map<String, dynamic>?;
                        final versionName = version?['name'] as String? ?? 'unknown';
                        
                        final chance = versionDetailData['max_chance'] as int? ?? 0;
                        
                        final encounterDetails = versionDetailData['encounter_details'] as List<dynamic>? ?? [];
                        
                        if (encounterDetails.isNotEmpty) {
                          final encounterDetail = encounterDetails[0] as Map<String, dynamic>;
                          final method = (encounterDetail['method'] as Map<String, dynamic>?)?['name'] as String? ?? 'unknown';
                          final minLevel = encounterDetail['min_level'] as int? ?? 0;
                          final maxLevel = encounterDetail['max_level'] as int? ?? 0;

                          final key = '$id-$versionName-$method';
                          
                          if (!allPokemon.containsKey(key)) {
                            allPokemon[key] = PokemonEncounter(
                              id: id,
                              name: pokemonName,
                              imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png',
                              chance: chance,
                              minLevel: minLevel,
                              maxLevel: maxLevel,
                              method: method,
                              version: versionName,
                            );
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('DEBUG POKE_API: Error en área: $e');
            continue;
          }
        }
      }

      print('DEBUG POKE_API: Total de Pokémon encontrados: ${allPokemon.length}');
      final result = allPokemon.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      return result;
    } catch (e) {
      print('DEBUG POKE_API: Error general: $e');
      throw Exception('Error fetching pokemon by location: $e');
    }
  }

  /// Fetch pokemon variants (mega, gigantamax, regional forms)
  static Future<List<PokemonVariant>> fetchPokemonVariants(String pokemonName) async {
    const query = '''
      query GetPokemonVariants(\$name: String!) {
        pokemon_v2_pokemon(where: {name: {_eq: \$name}}) {
          id
          pokemon_v2_pokemonforms {
            id
            form_name
            pokemon {
              name
              id
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
          variables: {'name': pokemonName},
        ),
      );

      if (result.hasException) {
        throw Exception('Error fetching pokemon variants: ${result.exception}');
      }

      final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
      if (pokemons.isEmpty) return [];

      final pokemon = pokemons[0] as Map<String, dynamic>;
      final forms = pokemon['pokemon_v2_pokemonforms'] as List<dynamic>? ?? [];

      // Filter for important variants only (mega, gigantamax, regional forms)
      final variants = <PokemonVariant>[];
      for (final form in forms) {
        final formData = form as Map<String, dynamic>;
        final formName = formData['form_name'] as String? ?? '';
        
        // Only include mega, gigantamax, alola, galar, paldea forms and skip the default form
        if ((formName.contains('mega') || 
             formName.contains('gigantamax') || 
             formName.contains('alola') || 
             formName.contains('galar') || 
             formName.contains('paldea')) &&
            formName.isNotEmpty) {
          try {
            final variant = PokemonVariant.fromGraphQL(formData);
            variants.add(variant);
          } catch (e) {
            continue;
          }
        }
      }

      return variants;
    } catch (e) {
      return [];
    }
  }
}

