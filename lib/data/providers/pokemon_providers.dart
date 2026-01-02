import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/poke_api.dart';
import '../models/pokemon_list_item.dart';
import '../models/pokemon_encounter.dart';

/// Enum para opciones de ordenación
enum SortOption { number, nameAsc, nameDesc }

/// Enum para rangos de poder (base stat total)
enum PowerRange {
  low,      // 0-300: Débiles (Caterpie, Magikarp)
  medium,   // 301-450: Promedio (Pikachu, starters básicos)  
  high,     // 451-550: Fuertes (starters finales)
  veryHigh, // 551-600: Pseudo-legendarios
  legendary // 600+: Legendarios y míticos
}

// convirtiendo los enums en rangos numéricos
extension PowerRangeExtension on PowerRange {
  int get minStat {
    switch (this) {
      case PowerRange.low: return 0;
      case PowerRange.medium: return 301;
      case PowerRange.high: return 451;
      case PowerRange.veryHigh: return 551;
      case PowerRange.legendary: return 600;
    }
  }
  
  int get maxStat {
    switch (this) {
      case PowerRange.low: return 300;
      case PowerRange.medium: return 450;
      case PowerRange.high: return 550;
      case PowerRange.veryHigh: return 599;
      case PowerRange.legendary: return 9999;
    }
  }
}

final pokemonListProvider = StateNotifierProvider<PokemonListNotifier, AsyncValue<List<PokemonListItem>>>((ref) {
  return PokemonListNotifier();
});

// manejo de fetching, paginación, filtros, búsqueda, ordenación, refrescar y control de estado
class PokemonListNotifier extends StateNotifier<AsyncValue<List<PokemonListItem>>> {
  /// Reinicia los filtros activos
  void resetFilters() {
    _filterGeneration = null;
    _filterTypes = null;
    _filterPower = null;
    _searchQuery = null;
    _sortOption = SortOption.number;
  }
  
  /// Limpia solo la búsqueda pero mantiene filtros
  void clearSearch() {
    _searchQuery = null;
  }

  // carga automatica de la primera página
  PokemonListNotifier() : super(const AsyncValue.loading()) {
    fetchPokemons(); // Initial automatic fetch
  }

  int _offset = 0; // Paginación
  final int _pageSize = 50; // cuantos pokemones traer por página
  bool _hasMore = true; // si hay más pokemones para cargar
  bool _isFetching = false; // si ya se está haciendo una petición

  // guardado de todos los pokemones cargados
  List<PokemonListItem> _allPokemons = [];

  // Filtros activos
  int? _filterGeneration;
  List<String>? _filterTypes;
  PowerRange? _filterPower;
  String? _searchQuery;
  SortOption _sortOption = SortOption.number;

  // Getters para exponer filtros activos
  int? get filterGeneration => _filterGeneration;
  List<String>? get filterTypes => _filterTypes;
  PowerRange? get filterPower => _filterPower;
  String? get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get isLoadingMore => _isFetching;

  /// Establece filtros para la persistencia (se llamar al inicio)
  void setFiltersFromPersistence({
    int? generation,
    List<String>? types,
    PowerRange? power,
    SortOption? sort,
  }) {
    _filterGeneration = generation;
    _filterTypes = types;
    _filterPower = power;
    _sortOption = sort ?? SortOption.number;
  }

  /// Ordena la lista según la opción seleccionada
  List<PokemonListItem> _sortList(List<PokemonListItem> list) {
    final sorted = List<PokemonListItem>.from(list);
    switch (_sortOption) {
      case SortOption.number:
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  Future<void> fetchPokemons({
    bool isRefresh = false, // si es una recarga completa
    int? generation,
    List<String>? types,
    PowerRange? power,
    String? searchQuery, // nombre de pokemon para búsqueda
  }) async {
    // Evita llamadas concurrentes o si no hay más pokemones
    if (_isFetching || (!isRefresh && !_hasMore)) return;

    // Marca que se está haciendo una petición para evitar sobrepeticion
    _isFetching = true;

    // Guardar filtros activos (solo si se pasan explícitamente)
    if (generation != null || isRefresh) _filterGeneration = generation;
    if (types != null || isRefresh) _filterTypes = types;
    if (power != null || isRefresh) _filterPower = power;
    if (searchQuery != null) _searchQuery = searchQuery;

    if (isRefresh) {
      _offset = 0; // reinicia paginación
      _allPokemons.clear(); // limpia lista actual
      _hasMore = true; // perimete nuevas cargas
      state = const AsyncValue.loading(); // estado de carga
    }

    try {
      // 🚀 UNA SOLA LLAMADA con todos los filtros
      final newPokemons = await PokeApi.fetchPokemonsWithFilters(
        limit: _pageSize,
        offset: _offset,
        generationId: _filterGeneration,
        types: _filterTypes,
        minPower: _filterPower?.minStat,
        maxPower: _filterPower?.maxStat,
        searchQuery: _searchQuery,
      );

      // Si no hay nuevos pokemones, marca que no hay más para cargar
      if (newPokemons.isEmpty) {
        _hasMore = false;
      } else { // Si hay nuevos pokemones, actualiza offset y lista
        _offset += newPokemons.length;
        _allPokemons.addAll(newPokemons);
      }

      // Aplicar ordenación
      final sortedList = _sortList(_allPokemons);
      state = AsyncValue.data(sortedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  // Refresca la lista actual con los filtros activos
  Future<void> refreshPokemons() async {
    _hasMore = true;
    await fetchPokemons(
      isRefresh: true,
      generation: _filterGeneration,
      types: _filterTypes,
      power: _filterPower,
      searchQuery: _searchQuery,
    );
  }

  // Aplica nuevos filtros y refresca la lista
  Future<void> applyFilters({
    int? generation,
    List<String>? types,
    PowerRange? power,
    String? searchQuery,
    SortOption? sort,
  }) async {
    _filterGeneration = generation;
    _filterTypes = types;
    _filterPower = power;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (sort != null) _sortOption = sort;
    
    _hasMore = true;
    _offset = 0;
    _allPokemons.clear();
    await fetchPokemons(
      isRefresh: true,
      generation: _filterGeneration,
      types: _filterTypes,
      power: _filterPower,
      searchQuery: _searchQuery,
    );
  }

  /// Cambiar ordenación y re-ordenar lista actual
  void setSortOption(SortOption option) {
    _sortOption = option;
    if (_allPokemons.isNotEmpty) {
      final sortedList = _sortList(_allPokemons);
      state = AsyncValue.data(sortedList);
    }
  }

  /// busca todos los pokemones(RESPETA filtros activos)
  Future<void> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      await refreshPokemons();
      return;
    }
    
    // Reutiliza fetchPokemons con el query de búsqueda
    _searchQuery = query.trim();
    _hasMore = true;
    _offset = 0;
    _allPokemons.clear();
    
    await fetchPokemons(
      isRefresh: true,
      generation: _filterGeneration,
      types: _filterTypes,
      power: _filterPower,
      searchQuery: _searchQuery,
    );
  }

  /// Fetch pokemon encounters by location
  Future<List<PokemonEncounter>> fetchPokemonByLocation(String locationName) async {
    return await PokeApi.fetchPokemonByLocation(locationName);
  }
}