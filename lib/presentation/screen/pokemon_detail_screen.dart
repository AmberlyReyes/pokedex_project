import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/pokemon_detail.dart';
import '../../data/models/pokemon_evolution.dart';
import '../../data/models/pokemon_move.dart';
import '../../data/datasources/poke_api.dart';
import '../widgets/page_transitions.dart';
import '../widgets/radar_chart.dart';
import '../widgets/pokemon_share_card.dart';
import '../widgets/error_widget.dart';
import '../../data/helpers/error_formatter.dart';
import '../../l10n/app_localizations.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int id;
  final String name;

  const PokemonDetailScreen({super.key, required this.id, required this.name});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with TickerProviderStateMixin {
  PokemonDetail? _detail;
  List<PokemonEvolution> _evolutions = [];
  String? _error;
  bool _loading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _tabController = TabController(length: 4, vsync: this);

    _load();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // fetch detail and evolutions individually to prevent type errors
      final detail = await PokeApi.fetchPokemonDetail(widget.id);
      final evolutions = await PokeApi.fetchEvolutionChain(widget.id);

      // Verificar si el Pokémon es favorito
      final box = await Hive.openBox<PokemonDetail>('favorites');
      if (box.containsKey(detail.id)) {
        detail.isFavorite = true;
      }

      setState(() {
        _detail = detail;
        _evolutions = evolutions;
        _loading = false;
      });

      // Start animations after data loads
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));

  String _translateType(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch(type.toLowerCase()) {
      case 'normal':
        return l10n.normal;
      case 'fire':
        return l10n.fire;
      case 'water':
        return l10n.water;
      case 'grass':
        return l10n.grass;
      case 'electric':
        return l10n.electric;
      case 'ice':
        return l10n.ice;
      case 'fighting':
        return l10n.fighting;
      case 'poison':
        return l10n.poison;
      case 'ground':
        return l10n.ground;
      case 'flying':
        return l10n.flying;
      case 'psychic':
        return l10n.psychic;
      case 'bug':
        return l10n.bug;
      case 'rock':
        return l10n.rock;
      case 'ghost':
        return l10n.ghost;
      case 'dragon':
        return l10n.dragon;
      case 'dark':
        return l10n.dark;
      case 'steel':
        return l10n.steel;
      case 'fairy':
        return l10n.fairy;
      default:
        return _capitalize(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fondo blanquecino
      appBar: AppBar(
        title: Text(_capitalize(widget.name)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_detail != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final shareCard = PokemonShareCard(
                  pokemon: _detail!,
                  parentContext: context,
                );
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    contentPadding: EdgeInsets.zero,
                    content: shareCard,
                    actions: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: Text(l10n.close),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await shareCard.shareAsImage();
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.share),
                              label: Text(l10n.share),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: _loading || _error != null || _detail == null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: l10n.basicInfo, icon: const Icon(Icons.info_outline)),
                  Tab(text: l10n.abilitiesTab, icon: const Icon(Icons.auto_awesome)),
                  Tab(text: l10n.statistics, icon: const Icon(Icons.bar_chart)),
                  Tab(text: l10n.combat, icon: const Icon(Icons.shield_outlined)),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorMessageWidget(
                  title: ErrorFormatter.getTitle(_error),
                  message: ErrorFormatter.getUserMessage(_error),
                  onRetry: _load,
                )
              : _detail == null
                  ? Center(child: Text(l10n.noData, style: const TextStyle(color: Colors.black)))
                  : DefaultTextStyle(
                      style: const TextStyle(color: Colors.black),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildBasicInfoTab(),
                              _buildAbilitiesTab(),
                              _buildStatsTab(),
                              _buildCombatTab(),
                            ],
                          ),
                        ),
                      ),
                    ),
      floatingActionButton: _loading || _error != null || _detail == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                setState(() {
                  _detail!.toggleFavorite();
                });

                // Guardar o eliminar en Hive
                final box = await Hive.openBox<PokemonDetail>('favorites');
                if (_detail!.isFavorite) {
                  box.put(_detail!.id, _detail!);
                } else {
                  box.delete(_detail!.id);
                }
              },
              backgroundColor: _detail!.isFavorite
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                _detail!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildBasicInfoTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_detail!.spriteUrl.isNotEmpty)
            Hero(
              tag: 'pokemon_${_detail!.id}',
              child: Center(
                child: _FloatingPokemonImage(
                  imageUrl: _detail!.spriteUrl,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 400),
            child: Center(
              child: Text(
                '#${_detail!.id}  ${_capitalize(_detail!.name)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // types
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 600),
            child: Center(
              child: Wrap(
                spacing: 8,
                children: _detail!.types
                    .map((t) => Chip(
                      label: Text(_translateType(t)),
                    ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // basic info
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(l10n.height,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black)),
                    Text('${_detail!.height / 10} m',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black)),
                  ],
                ),
                Column(
                  children: [
                    Text(l10n.weight,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black)),
                    Text('${_detail!.weight / 10} kg',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black)),
                  ],
                ),
                 if (_detail!.eggGroups.isNotEmpty)
                  Column(
                    children: [
                      Text(l10n.eggGroups,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black)),
                      Text(_detail!.eggGroups.map(_capitalize).join(', '),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAbilitiesTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main abilities list
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Habilidades',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
                const SizedBox(height: 16),
                if (_detail!.abilities.isEmpty)
                  const Text('No hay habilidades disponibles', style: TextStyle(color: Colors.black))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _detail!.abilities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ability = _detail!.abilities[index];
                      
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _capitalize(ability.name),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                              if (ability.isHidden)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Oculta',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Evolutions section
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.evolutions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                const SizedBox(height: 8),
                if (_evolutions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 32,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.doesNotEvolve,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evolutions.length,
                      separatorBuilder: (_, i) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _evolutions[i].triggerDetails,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      itemBuilder: (context, i) {
                        final ev = _evolutions[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              ScalePageRoute(
                                page: PokemonDetailScreen(
                                    id: ev.id, name: ev.name),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    ev.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.image_not_supported, size: 50),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _capitalize(ev.name),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '#${ev.id}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final l10n = AppLocalizations.of(context)!;
    // Calculate total stats
    final totalStats = _detail!.stats.values.reduce((a, b) => a + b);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radar Chart
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stats Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    height: 250,
                    child: StatsRadarChart(
                      data: _detail!.stats,
                      maxValue: 255,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Total stats display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Stats: $totalStats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detailed stats with bars
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detailed Stats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                const SizedBox(height: 8),
                ..._detail!.stats.entries.map((e) {
                  final value = e.value;
                  final pct = (value / 255).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_capitalize(e.key), style: const TextStyle(color: Colors.black)),
                            Text('$value (${(pct * 100).toInt()}%)', style: const TextStyle(color: Colors.black))
                          ],
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pct),
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, child) {
                            return LinearProgressIndicator(
                              value: animValue,
                              minHeight: 8,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Moves
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.moves,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                const SizedBox(height: 8),
                if (_detail!.moves.isEmpty)
                  Text(l10n.noMoves, style: const TextStyle(color: Colors.black))
                else
                  _buildMovesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatTab() {
    final l10n = AppLocalizations.of(context)!;
    final weaknesses = <String, double>{};
    final resistances = <String, double>{};
    final immunities = <String>[];

    _detail!.typeMatchups.forEach((type, factor) {
      if (factor > 1) {
        weaknesses[type] = factor;
      } else if (factor < 1 && factor > 0) {
        resistances[type] = factor;
      } else if (factor == 0) {
        immunities.add(type);
      }
    });

    // Sort by effectiveness
    final sortedWeaknesses = weaknesses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedResistances = resistances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchupSection(l10n.weaknesses, sortedWeaknesses),
          const SizedBox(height: 24),
          _buildMatchupSection(l10n.resistances, sortedResistances),
          const SizedBox(height: 24),
          if (immunities.isNotEmpty)
            _buildImmunitySection(l10n.immunities, immunities),
        ],
      ),
    );
  }

  Widget _buildMovesSection() {
    final l10n = AppLocalizations.of(context)!;
    return _MovesSection(moves: _detail!.moves, l10n: l10n);
  }

  Widget _buildMatchupSection(String title, List<MapEntry<String, double>> matchups) {
    if (matchups.isEmpty) return const SizedBox.shrink();

    return _AnimatedDetailSection(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchups.map((e) {
              return Chip(
                label: Text('${_translateType(e.key)} (x${e.value})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImmunitySection(String title, List<String> immunities) {
    return _AnimatedDetailSection(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: immunities.map((type) {
              return Chip(
                label: Text(_translateType(type)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Widget for movimientos con filtros
class _MovesSection extends StatefulWidget {
  final List<PokemonMove> moves;
  final AppLocalizations l10n;

  const _MovesSection({required this.moves, required this.l10n});

  @override
  State<_MovesSection> createState() => _MovesSectionState();
}

class _MovesSectionState extends State<_MovesSection> {
  late String selectedMethod;
  late String selectedSort;
  late List<PokemonMove> filteredMoves;
  late Set<String> availableMethods;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Get available methods
    availableMethods = widget.moves.map((m) => m.method).toSet();
    
    // Default to level-up if available, otherwise first method
    selectedMethod = availableMethods.contains('level-up') ? 'level-up' : availableMethods.first;
    selectedSort = 'level'; // 'level' o 'name'
    
    _applyFilters();
  }

  void _applyFilters() {
    filteredMoves = widget.moves
        .where((move) => move.method == selectedMethod)
        .toList();

    // Sort
    if (selectedSort == 'level' && selectedMethod == 'level-up') {
      filteredMoves.sort((a, b) {
        final levelA = a.level ?? 999;
        final levelB = b.level ?? 999;
        return levelA.compareTo(levelB);
      });
    } else {
      filteredMoves.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('Método: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(width: 8),
              ...availableMethods.map((method) {
                final isSelected = selectedMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(PokemonMove.getMethodDisplay(method)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedMethod = method;
                        // Reset sort if method doesn't support level
                        if (method != 'level-up' && selectedSort == 'level') {
                          selectedSort = 'name';
                        }
                        _applyFilters();
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ordenamiento
        if (selectedMethod == 'level-up')
          Row(
            children: [
              const Text('Ordenar: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Nivel'),
                selected: selectedSort == 'level',
                onSelected: (selected) {
                  if (selected) {
                    selectedSort = 'level';
                    _applyFilters();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Nombre'),
                selected: selectedSort == 'name',
                onSelected: (selected) {
                  if (selected) {
                    selectedSort = 'name';
                    _applyFilters();
                  }
                },
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Lista de movimientos con virtual scrolling
        Text(widget.l10n.movesCount(filteredMoves.length), 
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 400,
          child: filteredMoves.isEmpty
              ? Center(
                  child: Text(
                    widget.l10n.noMovesWithMethod,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: filteredMoves.length,
                  itemBuilder: (context, index) {
                    final move = filteredMoves[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _capitalize(move.name),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (move.level != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lv ${move.level}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}

/// Widget for animating detail sections with staggered fade and slide
class _AnimatedDetailSection extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedDetailSection({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedDetailSection> createState() => _AnimatedDetailSectionState();
}

class _AnimatedDetailSectionState extends State<_AnimatedDetailSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Más lento
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget for floating Pokemon image with continuous animation
class _FloatingPokemonImage extends StatefulWidget {
  final String imageUrl;

  const _FloatingPokemonImage({required this.imageUrl});

  @override
  State<_FloatingPokemonImage> createState() => _FloatingPokemonImageState();
}

class _FloatingPokemonImageState extends State<_FloatingPokemonImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Image.network(
                widget.imageUrl,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.catching_pokemon,
                  size: 180,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


