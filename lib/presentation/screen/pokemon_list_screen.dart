
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/pokemon_list_item.dart';
import '../../data/datasources/poke_api.dart';
import '../../data/providers/pokemon_providers.dart'; 
import '../widgets/animated_list_item.dart';
import '../widgets/page_transitions.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_widget.dart';
import '../../data/helpers/error_formatter.dart';
import 'pokemon_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Color principal para opciones seleccionadas
const Color kFilterAccentColor = Color(0xFF00D9FF);

class PokemonListScreen extends ConsumerStatefulWidget {
  final bool openFiltersAutomatically;
  final String? preSelectedFilter;
  
  const PokemonListScreen({
    super.key,
    this.openFiltersAutomatically = false,
    this.preSelectedFilter,
  });

  @override
  ConsumerState<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends ConsumerState<PokemonListScreen> {
 
  List<PokemonListItem> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Claves de persistencia
  static const _prefsKeyGen = 'pokedez_filter_generation';
  static const _prefsKeyTypes = 'pokedez_filter_types';
  static const _prefsKeySort = 'pokedez_filter_sort';
  static const _prefsKeyPower = 'pokedez_filter_power';

  // Filtros locales (para UI)
  String? _selectedGeneration;
  List<String> _selectedTypes = [];
  PowerRange? _selectedPower;
  SortOption _selectedSort = SortOption.number;
  bool _filtersLoaded = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadSavedFilters();
  }

  /// Carga filtros guardados y los aplica al provider
  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGen = prefs.getString(_prefsKeyGen);
    final savedTypes = prefs.getStringList(_prefsKeyTypes) ?? [];
    final savedSortIndex = prefs.getInt(_prefsKeySort) ?? 0;
    final savedPowerIndex = prefs.getInt(_prefsKeyPower);
    
    if (!mounted) return;
    
    setState(() {
      _selectedGeneration = savedGen;
      _selectedTypes = savedTypes;
      _selectedPower = savedPowerIndex != null 
          ? PowerRange.values[savedPowerIndex.clamp(0, PowerRange.values.length - 1)] 
          : null;
      _selectedSort = SortOption.values[savedSortIndex.clamp(0, SortOption.values.length - 1)];
      _filtersLoaded = true;
    });

    // Aplicar filtros al provider
    final notifier = ref.read(pokemonListProvider.notifier);
    int? genId;
    if (savedGen != null && savedGen.isNotEmpty) {
      final genMap = {'I': 1, 'II': 2, 'III': 3, 'IV': 4, 'V': 5, 'VI': 6, 'VII': 7, 'VIII': 8, 'IX': 9};
      genId = genMap[savedGen];
    }
    
    notifier.setFiltersFromPersistence(
      generation: genId,
      types: savedTypes.isNotEmpty ? savedTypes : null,
      power: _selectedPower,
      sort: _selectedSort,
    );
    
    // Limpiar búsqueda previa al cargar (evita que persista entre navegaciones)
    notifier.clearSearch();
    
    // Cargar datos iniciales
    if (mounted && !_initialLoadDone) {
      _initialLoadDone = true;
      await _applyCurrentFilters();
      if (mounted && widget.openFiltersAutomatically) {
        _openFilters();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo cargar si no se ha hecho la carga inicial y los filtros no están cargados
    if (!_initialLoadDone && !_filtersLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialLoadDone) {
          _initialLoadDone = true;
          ref.read(pokemonListProvider.notifier).refreshPokemons();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Limpiar búsqueda al salir para que no persista
    // Nota: No usar ref aquí porque el widget ya está disposed
    super.dispose();
  }

  /// Búsqueda que RESPETA filtros activos con debounce de 400ms
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      
      if (query.isEmpty) {
        // Limpiar búsqueda en el provider y recargar lista completa
        ref.read(pokemonListProvider.notifier).clearSearch();
        _applyCurrentFilters();
      } else {
        // Búsqueda global que respeta filtros
        ref.read(pokemonListProvider.notifier).globalSearch(query);
      }
    });
  }

  void _onEnterPressed() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ref.read(pokemonListProvider.notifier).clearSearch();
      _applyCurrentFilters();
    } else {
      ref.read(pokemonListProvider.notifier).globalSearch(query);
    }
  }

  void _onScroll() {
    final notifier = ref.read(pokemonListProvider.notifier);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !notifier.isLoadingMore) {
      notifier.fetchPokemons();
    }
  }

  /// Aplica filtros actuales (generación, tipos, poder, ordenación)
  Future<void> _applyCurrentFilters() async {
    int? genId;
    if (_selectedGeneration != null && _selectedGeneration!.isNotEmpty) {
      final genMap = {'I': 1, 'II': 2, 'III': 3, 'IV': 4, 'V': 5, 'VI': 6, 'VII': 7, 'VIII': 8, 'IX': 9};
      genId = genMap[_selectedGeneration];
    }
    
    await ref.read(pokemonListProvider.notifier).applyFilters(
      generation: genId,
      types: _selectedTypes.isNotEmpty ? _selectedTypes : null,
      power: _selectedPower,
      sort: _selectedSort,
    );
  }

  /// Guarda filtros en SharedPreferences
  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedGeneration == null || _selectedGeneration!.isEmpty) {
      await prefs.remove(_prefsKeyGen);
    } else {
      await prefs.setString(_prefsKeyGen, _selectedGeneration!);
    }
    await prefs.setStringList(_prefsKeyTypes, _selectedTypes);
    await prefs.setInt(_prefsKeySort, _selectedSort.index);
    
    // Poder
    if (_selectedPower == null) {
      await prefs.remove(_prefsKeyPower);
    } else {
      await prefs.setInt(_prefsKeyPower, _selectedPower!.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pokemonListAsync = ref.watch(pokemonListProvider);
    
    // Indicador visual de filtros activos
    final hasActiveFilters = _selectedGeneration != null || 
        _selectedTypes.isNotEmpty || 
        _selectedPower != null;

    ref.listen<AsyncValue<List<PokemonListItem>>>(pokemonListProvider, (_, next) {
      next.whenData((pokemons) {
        if (mounted) {
          setState(() {
            _filtered = pokemons;
          });
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Siempre ir a Home, sin importar el historial de filtros
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [  Color(0xFFD32F2F),Color(0xFF00D9FF),],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: SizedBox(
            height: 40,
            child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _onEnterPressed(),
            decoration: InputDecoration(
              hintText: '${l10n.search} Pokémon...',
              hintStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 16),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 24),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.nunito(color: Colors.black87, fontSize: 16),
          ),
        ),
        actions: [
          // Indicador de filtros activos
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _openFilters,
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: kFilterAccentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: pokemonListAsync.when(
        loading: () => const ShimmerLoading(itemCount: 15),
        error: (err, stack) {
          final errorData = ErrorFormatter.format(err, showDetails: false);
          return ErrorMessageWidget(
            title: errorData.title,
            message: errorData.message,
            onRetry: () => _applyCurrentFilters(),
          );
        },
        data: (allPokemons) {
          if (_filtered.isEmpty && _searchController.text.isNotEmpty) {
            return ErrorMessageWidget(
              title: l10n.noResults,
              message: 'No se encontraron Pokémon con "${_searchController.text}".\nIntenta con otro término de búsqueda.',
              icon: Icons.search_off,
              iconColor: Colors.orange[400],
              onRetry: () {
                _searchController.clear();
                _applyCurrentFilters();
              },
            );
          }
          
          final notifier = ref.watch(pokemonListProvider.notifier);

          return RefreshIndicator(
            onRefresh: () => _applyCurrentFilters(),
            child: Column(
              children: [
                // Chip de filtros activos
                if (hasActiveFilters)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: kFilterAccentColor.withOpacity(0.1),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (_selectedGeneration != null)
                          Chip(
                            label: Text('Gen $_selectedGeneration', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: kFilterAccentColor,
                            deleteIconColor: Colors.white,
                            onDeleted: () async {
                              setState(() => _selectedGeneration = null);
                              await _saveFilters();
                              await _applyCurrentFilters();
                            },
                          ),
                        if (_selectedPower != null)
                          Chip(
                            label: Text(_getPowerLabel(_selectedPower!, l10n), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: kFilterAccentColor,
                            deleteIconColor: Colors.white,
                            onDeleted: () async {
                              setState(() => _selectedPower = null);
                              await _saveFilters();
                              await _applyCurrentFilters();
                            },
                          ),
                        ..._selectedTypes.map((type) => Chip(
                          label: Text(_capitalize(type), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: kFilterAccentColor,
                          deleteIconColor: Colors.white,
                          onDeleted: () async {
                            setState(() => _selectedTypes.remove(type));
                            await _saveFilters();
                            await _applyCurrentFilters();
                          },
                        )),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final pokemon = _filtered[index];
                      return AnimatedListItem(
                        index: index,
                        child: _PokemonCard(pokemon: pokemon),
                      );
                    },
                  ),
                ),
                if (notifier.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Estado local para el modal
    String? tempGeneration = _selectedGeneration;
    List<String> tempTypes = List.from(_selectedTypes);
    PowerRange? tempPower = _selectedPower;
    SortOption tempSort = _selectedSort;

    const allTypes = [
      'normal', 'fire', 'water', 'grass', 'electric', 'ice', 'fighting', 'poison', 
      'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
    ];
    const generations = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Título
                      Text(
                        'Filtros y Ordenación',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // === ORDENAR POR ===
                      Text(
                        l10n.sortBy,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SortOption>(
                            value: tempSort,
                            isExpanded: true,
                            dropdownColor: Colors.grey[800],
                            icon: Icon(Icons.arrow_drop_down, color: kFilterAccentColor),
                            items: [
                              DropdownMenuItem(
                                value: SortOption.number,
                                child: Text(
                                  l10n.sortByNumber,
                                  style: TextStyle(
                                    color: tempSort == SortOption.number ? kFilterAccentColor : Colors.white,
                                    fontWeight: tempSort == SortOption.number ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: SortOption.nameAsc,
                                child: Text(
                                  l10n.sortByNameAsc,
                                  style: TextStyle(
                                    color: tempSort == SortOption.nameAsc ? kFilterAccentColor : Colors.white,
                                    fontWeight: tempSort == SortOption.nameAsc ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: SortOption.nameDesc,
                                child: Text(
                                  l10n.sortByNameDesc,
                                  style: TextStyle(
                                    color: tempSort == SortOption.nameDesc ? kFilterAccentColor : Colors.white,
                                    fontWeight: tempSort == SortOption.nameDesc ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) => setModalState(() => tempSort = val ?? SortOption.number),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // === PODER (Base Stat Total) ===
                      Text(
                        l10n.power,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PowerRange?>(
                            value: tempPower,
                            isExpanded: true,
                            dropdownColor: Colors.grey[800],
                            hint: Text(
                              l10n.allPowers,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: kFilterAccentColor),
                            items: [
                              DropdownMenuItem<PowerRange?>(
                                value: null,
                                child: Text(l10n.allPowers, style: TextStyle(color: Colors.grey[400])),
                              ),
                              ...PowerRange.values.map((power) => DropdownMenuItem(
                                value: power,
                                child: Text(
                                  _getPowerLabel(power, l10n),
                                  style: TextStyle(
                                    color: tempPower == power ? kFilterAccentColor : Colors.white,
                                    fontWeight: tempPower == power ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              )),
                            ],
                            onChanged: (val) => setModalState(() => tempPower = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // === GENERACIÓN ===
                      Text(
                        l10n.generation,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tempGeneration,
                            isExpanded: true,
                            dropdownColor: Colors.grey[800],
                            hint: Text(
                              l10n.selectGeneration,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: kFilterAccentColor),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(l10n.allGenerations, style: TextStyle(color: Colors.grey[400])),
                              ),
                              ...generations.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(
                                  _getGenerationLabel(g, l10n),
                                  style: TextStyle(
                                    color: tempGeneration == g ? kFilterAccentColor : Colors.white,
                                    fontWeight: tempGeneration == g ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              )),
                            ],
                            onChanged: (val) => setModalState(() => tempGeneration = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // === TIPOS ===
                      Text(
                        l10n.types,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: null,
                            isExpanded: true,
                            dropdownColor: Colors.grey[800],
                            hint: Text(
                              tempTypes.isEmpty 
                                  ? l10n.allTypes
                                  : '${tempTypes.length} ${l10n.types.toLowerCase()}',
                              style: TextStyle(
                                color: tempTypes.isEmpty ? Colors.grey[400] : kFilterAccentColor,
                                fontWeight: tempTypes.isEmpty ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: kFilterAccentColor),
                            items: allTypes.map((type) {
                              final isSelected = tempTypes.contains(type);
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: isSelected ? kFilterAccentColor : Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getTypeLabel(type, l10n),
                                      style: TextStyle(
                                        color: isSelected ? kFilterAccentColor : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  if (tempTypes.contains(val)) {
                                    tempTypes.remove(val);
                                  } else {
                                    tempTypes.add(val);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      // Mostrar tipos seleccionados como chips
                      if (tempTypes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tempTypes.map((type) {
                            return Chip(
                              label: Text(
                                _getTypeLabel(type, l10n),
                                style: const TextStyle(color: Colors.black, fontSize: 12),
                              ),
                              backgroundColor: kFilterAccentColor,
                              deleteIconColor: Colors.black,
                              onDeleted: () {
                                setModalState(() => tempTypes.remove(type));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // === BOTONES ===
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempGeneration = null;
                                  tempTypes.clear();
                                  tempPower = null;
                                  tempSort = SortOption.number;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: kFilterAccentColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                l10n.clearFilters,
                                style: const TextStyle(color: kFilterAccentColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, {
                                  'generation': tempGeneration,
                                  'types': tempTypes,
                                  'power': tempPower,
                                  'sort': tempSort,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kFilterAccentColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                l10n.applyFilters,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedGeneration = result['generation'] as String?;
        _selectedTypes = List<String>.from(result['types'] ?? []);
        _selectedPower = result['power'] as PowerRange?;
        _selectedSort = result['sort'] as SortOption? ?? SortOption.number;
      });

      await _saveFilters();
      await _applyCurrentFilters();
    }
  }

  /// Obtiene la etiqueta legible para un rango de poder
  String _getPowerLabel(PowerRange power, AppLocalizations l10n) {
    switch (power) {
      case PowerRange.low:
        return l10n.powerLow;
      case PowerRange.medium:
        return l10n.powerMedium;
      case PowerRange.high:
        return l10n.powerHigh;
      case PowerRange.veryHigh:
        return l10n.powerVeryHigh;
      case PowerRange.legendary:
        return l10n.powerLegendary;
    }
  }

  String _getGenerationLabel(String g, AppLocalizations l10n) {
    switch (g) {
      case 'I': return l10n.generationI;
      case 'II': return l10n.generationII;
      case 'III': return l10n.generationIII;
      case 'IV': return l10n.generationIV;
      case 'V': return l10n.generationV;
      case 'VI': return l10n.generationVI;
      case 'VII': return l10n.generationVII;
      case 'VIII': return l10n.generationVIII;
      case 'IX': return l10n.generationIX;
      default: return 'Generation $g';
    }
  }

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'normal': return l10n.normal;
      case 'fire': return l10n.fire;
      case 'water': return l10n.water;
      case 'grass': return l10n.grass;
      case 'electric': return l10n.electric;
      case 'ice': return l10n.ice;
      case 'fighting': return l10n.fighting;
      case 'poison': return l10n.poison;
      case 'ground': return l10n.ground;
      case 'flying': return l10n.flying;
      case 'psychic': return l10n.psychic;
      case 'bug': return l10n.bug;
      case 'rock': return l10n.rock;
      case 'ghost': return l10n.ghost;
      case 'dragon': return l10n.dragon;
      case 'dark': return l10n.dark;
      case 'steel': return l10n.steel;
      case 'fairy': return l10n.fairy;
      default: return _capitalize(type);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}

/// Widget for Pokemon card in grid layout
class _PokemonCard extends StatefulWidget {
  final PokemonListItem pokemon;

  const _PokemonCard({required this.pokemon});

  @override
  State<_PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<_PokemonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: InkWell(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fade(PokemonDetailScreen(
                id: widget.pokemon.id,
                name: widget.pokemon.name,
              )),
            );
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[200]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
             /* Positioned(
                top: -40,
                right: -40,
                child: Image.asset(
                  'assets/images/pokeball_A.png',
                  width: 120,
                  height: 120,
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),*/
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'pokemon-${widget.pokemon.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.pokemon.imageUrl,
                        fit: BoxFit.contain,
                        height: 100,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          _capitalize(widget.pokemon.name),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}