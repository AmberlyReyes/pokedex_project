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
  
  PokemonListNotifier() : super(const AsyncValue.loading()) {
    fetchPokemons(); // Initial automatic fetch
  }

  int _offset = 0;
  final int _pageSize = 50;
  bool _hasMore = true;
  bool _isFetching = false;

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

  /// Establece filtros desde persistencia (llamar al inicio)
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
    bool isRefresh = false,
    int? generation,
    List<String>? types,
    PowerRange? power,
    String? searchQuery,
  }) async {
    if (_isFetching || (!isRefresh && !_hasMore)) return;

    _isFetching = true;

    // Guardar filtros activos (solo si se pasan explícitamente)
    if (generation != null || isRefresh) _filterGeneration = generation;
    if (types != null || isRefresh) _filterTypes = types;
    if (power != null || isRefresh) _filterPower = power;
    if (searchQuery != null) _searchQuery = searchQuery;

    if (isRefresh) {
      _offset = 0;
      _allPokemons.clear();
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      List<PokemonListItem> filtered = [];
      int localOffset = _offset;
      bool keepFetching = true;

      while (filtered.length < _pageSize && keepFetching) {
        final newPokemons = await PokeApi.fetchAllPokemons(limit: _pageSize, offset: localOffset);
        
        if (newPokemons.isEmpty) {
          keepFetching = false;
          _hasMore = false;
          break;
        }
        localOffset += newPokemons.length;

        List<PokemonListItem> toAdd = newPokemons;
        
        // Filtrado por generación
        if (_filterGeneration != null) {
          final genNames = await PokeApi.fetchPokemonNamesByGeneration(_filterGeneration!);
          toAdd = toAdd.where((p) => genNames.contains(p.name)).toList();
        }
        
        // Filtrado por tipos
        if (_filterTypes != null && _filterTypes!.isNotEmpty) {
          for (final t in _filterTypes!) {
            final typeNames = await PokeApi.fetchPokemonNamesByType(t);
            toAdd = toAdd.where((p) => typeNames.contains(p.name)).toList();
          }
        }
        
        // Filtrado por poder (base stat total)
        if (_filterPower != null) {
          final powerNames = await PokeApi.fetchPokemonNamesByPowerRange(
            _filterPower!.minStat, 
            _filterPower!.maxStat
          );
          toAdd = toAdd.where((p) => powerNames.contains(p.name)).toList();
        }
        
        // Filtrado por búsqueda (respeta filtros activos)
        if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
          final q = _searchQuery!.trim().toLowerCase();
          final numericId = int.tryParse(q);
          toAdd = toAdd.where((p) {
            final matchName = p.name.toLowerCase().contains(q);
            final matchId = numericId != null && p.id == numericId;
            return matchName || matchId;
          }).toList();
        }
        
        filtered.addAll(toAdd);
        if (newPokemons.length < _pageSize) {
          keepFetching = false;
          _hasMore = false;
        }
      }

      _offset = localOffset;
      _allPokemons.addAll(filtered);
      
      // Aplicar ordenación
      final sortedList = _sortList(_allPokemons);
      state = AsyncValue.data(sortedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

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

  /// Búsqueda que RESPETA filtros activos (generación, tipos, poder)
  Future<void> searchWithFilters(String query) async {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
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

  /// Search globally across all pokemons (RESPETA filtros activos)
  Future<void> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      await refreshPokemons();
      return;
    }

    _isFetching = true;
    _searchQuery = query;
    state = const AsyncValue.loading();

    try {
      List<PokemonListItem> results = [];

      final nameResults = await PokeApi.searchPokemonByName(query);
      
      // Aplicar filtros activos a los resultados de búsqueda
      List<PokemonListItem> filteredResults = nameResults;
      
      if (_filterGeneration != null) {
        final genNames = await PokeApi.fetchPokemonNamesByGeneration(_filterGeneration!);
        filteredResults = filteredResults.where((p) => genNames.contains(p.name)).toList();
      }
      
      if (_filterTypes != null && _filterTypes!.isNotEmpty) {
        for (final t in _filterTypes!) {
          final typeNames = await PokeApi.fetchPokemonNamesByType(t);
          filteredResults = filteredResults.where((p) => typeNames.contains(p.name)).toList();
        }
      }
      
      if (_filterPower != null) {
        final powerNames = await PokeApi.fetchPokemonNamesByPowerRange(
          _filterPower!.minStat, 
          _filterPower!.maxStat
        );
        filteredResults = filteredResults.where((p) => powerNames.contains(p.name)).toList();
      }
      
      results.addAll(filteredResults);

      final numericId = int.tryParse(query.trim());
      if (numericId != null) {
        final idResult = await PokeApi.searchPokemonById(numericId);
        if (idResult != null && !results.any((p) => p.id == idResult.id)) {
          // Verificar si cumple con los filtros activos
          bool passesFilters = true;
          
          if (_filterGeneration != null) {
            final genNames = await PokeApi.fetchPokemonNamesByGeneration(_filterGeneration!);
            passesFilters = genNames.contains(idResult.name);
          }
          
          if (passesFilters && _filterTypes != null && _filterTypes!.isNotEmpty) {
            for (final t in _filterTypes!) {
              final typeNames = await PokeApi.fetchPokemonNamesByType(t);
              if (!typeNames.contains(idResult.name)) {
                passesFilters = false;
                break;
              }
            }
          }
          
          if (passesFilters && _filterPower != null) {
            final powerNames = await PokeApi.fetchPokemonNamesByPowerRange(
              _filterPower!.minStat, 
              _filterPower!.maxStat
            );
            passesFilters = powerNames.contains(idResult.name);
          }
          
          if (passesFilters) {
            results.add(idResult);
          }
        }
      }

      _allPokemons = _sortList(results);
      state = AsyncValue.data(_allPokemons);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  /// Fetch pokemon encounters by location
  Future<List<PokemonEncounter>> fetchPokemonByLocation(String locationName) async {
    return await PokeApi.fetchPokemonByLocation(locationName);
  }
}