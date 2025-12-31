import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/pokemon_detail.dart';
import '../../data/models/pokemon_evolution.dart';
import '../../data/models/pokemon_move.dart';
import '../../data/models/pokemon_variant.dart';
import '../../data/datasources/poke_api.dart';
import '../widgets/page_transitions.dart';
import '../widgets/radar_chart.dart';
import '../widgets/pokemon_share_card.dart';
import '../widgets/error_widget.dart';
import '../../data/helpers/error_formatter.dart';
import '../../l10n/app_localizations.dart';
import 'pokemon_list_screen.dart';

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
  List<PokemonVariant> _variants = [];
  String? _error;
  bool _loading = true;
  
  // Estado para variante seleccionada y shiny
  PokemonVariant? _selectedVariant;
  bool _isShiny = false;

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

    _tabController = TabController(length: 5, vsync: this);

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
      // 🚀 AHORA ES SOLO UNA LLAMADA - La super query trae todo
      final detail = await PokeApi.fetchPokemonDetail(widget.id);

      // Verificar si el Pokémon es favorito
      final box = await Hive.openBox<PokemonDetail>('favorites');
      if (box.containsKey(detail.id)) {
        detail.isFavorite = true;
      }

      setState(() {
        _detail = detail;
        // Los datos de evoluciones y variantes ya vienen en el detalle
        _evolutions = detail.evolutions;
        _variants = detail.variants;
        _selectedVariant = null; // Comenzar con el Pokémon base
        _isShiny = false;
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

  // Obtiene la URL del sprite según variante y shiny seleccionados
  String _getCurrentSpriteUrl() {
    final int id = _selectedVariant?.id ?? _detail!.id;
    if (_isShiny) {
      return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/shiny/$id.png';
    }
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png';
  }

  // Obtiene los tipos según la variante seleccionada
  List<String> _getCurrentTypes() {
    if (_selectedVariant != null) {
      return _selectedVariant!.types;
    }
    return _detail!.types;
  }

  // Obtiene el nombre actual a mostrar
  String _getCurrentDisplayName() {
    if (_selectedVariant != null) {
      return '${_capitalize(_detail!.name)} (${_selectedVariant!.getDisplayName()})';
    }
    return _capitalize(_detail!.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fondo blanquecino
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PokemonListScreen()),
            );
          },
        ),
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
                  Tab(text: l10n.moves, icon: const Icon(Icons.sports_martial_arts)),
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
                              PokemonMovesTab(moves: _detail!.moves, l10n: l10n),
                              _buildCombatTab(),
                            ],
                          ),
                        ),
                      ),
                    ),
      floatingActionButton: _loading || _error != null || _detail == null
          ? null
          : Semantics(
              label: _detail!.isFavorite 
                  ? 'Quitar de favoritos' 
                  : 'Añadir a favoritos',
              button: true,
              child: FloatingActionButton(
                heroTag: 'fab_detail_${_detail!.id}',
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _detail!.isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_detail!.isFavorite),
                    color: Colors.white,
                  ),
                ),
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
          // Imagen principal con soporte para variantes y shiny
          Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'pokemon_${_detail!.id}',
                child: Center(
                  child: Semantics(
                    label: 'Imagen de ${_getCurrentDisplayName()}${_isShiny ? ' (Shiny)' : ''}',
                    image: true,
                    child: _FloatingPokemonImage(
                      key: ValueKey('${_selectedVariant?.id ?? _detail!.id}_$_isShiny'),
                      imageUrl: _getCurrentSpriteUrl(),
                    ),
                  ),
                ),
              ),
              // Toggle Shiny en la esquina superior derecha
              Positioned(
                top: 0,
                right: 0,
                child: Tooltip(
                  message: _isShiny ? 'Ver normal' : 'Ver Shiny',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _isShiny = !_isShiny;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isShiny 
                              ? Colors.amber.withValues(alpha: 0.9)
                              : Colors.grey.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: _isShiny ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Shiny',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isShiny ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

          // types - cambian según la variante seleccionada
          _AnimatedDetailSection(
            delay: const Duration(milliseconds: 600),
            child: Center(
              child: Wrap(
                spacing: 8,
                children: _getCurrentTypes()
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

          // Dropdown de variantes (si hay variantes disponibles) - DESPUÉS de info básica
          if (_variants.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnimatedDetailSection(
              delay: const Duration(milliseconds: 850),
              child: _buildVariantDropdown(),
            ),
          ],
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
                                color: Color(0xFF00D9FF),
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
                                  child: CachedNetworkImage(
                                    imageUrl: ev.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getVariantColor(String variantType) {
    switch (variantType) {
      case 'mega':
        return Colors.purple;
      case 'gigantamax':
        return Colors.red;
      case 'alola':
        return Colors.orange;
      case 'galar':
        return Colors.blue;
      case 'paldea':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVariantDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 214, 212, 212),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Color.fromARGB(255, 0, 0, 0), size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.formVariant,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PokemonVariant?>(
                  value: _selectedVariant,
                  isExpanded: true,
                  dropdownColor: Colors.white70,
                  icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 0, 0, 0)),
                  hint: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.baseForm,
                        style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    ],
                  ),
                  items: [
                    // Opción para volver a la forma base
                    DropdownMenuItem<PokemonVariant?>(
                      value: null,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(179, 0, 0, 0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.baseForm, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                        ],
                      ),
                    ),
                    // Variantes disponibles
                    ..._variants.map((variant) {
                      return DropdownMenuItem<PokemonVariant?>(
                        value: variant,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                variant.getDisplayName(),
                                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Mostrar tipos de la variante
                            ...variant.types.take(2).map((type) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _translateType(type),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (PokemonVariant? newVariant) {
                    setState(() {
                      _selectedVariant = newVariant;
                    });
                  },
                ),
              ),
            ),
            // Información adicional si hay una variante seleccionada
            if (_selectedVariant != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _selectedVariant!.imageUrl,
                      width: 40,
                      height: 40,
                      placeholder: (context, url) => const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVariant!.getDisplayName(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tipos: ${_selectedVariant!.types.map(_translateType).join(', ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
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
                        color: Color(0xFF00D9FF),
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

/// Widget para movimientos con virtualización real usando Slivers
class PokemonMovesTab extends StatefulWidget {
  final List<PokemonMove> moves;
  final AppLocalizations l10n;

  const PokemonMovesTab({super.key, required this.moves, required this.l10n});

  @override
  State<PokemonMovesTab> createState() => _PokemonMovesTabState();
}

class _PokemonMovesTabState extends State<PokemonMovesTab> with AutomaticKeepAliveClientMixin {
  String _selectedMethod = 'all';
  String _sortBy = 'level';
  List<PokemonMove> _filteredMoves = [];
  Set<String> _availableMethods = {};

  @override
  void initState() {
    super.initState();
    _availableMethods = widget.moves.map((m) => m.method).toSet();
    _filterMoves();
  }

  void _filterMoves() {
    // Filtrar por método
    if (_selectedMethod == 'all') {
      _filteredMoves = List.from(widget.moves);
    } else {
      _filteredMoves = widget.moves.where((m) => m.method == _selectedMethod).toList();
    }

    // Ordenar
    if (_sortBy == 'level') {
      _filteredMoves.sort((a, b) {
        final levelA = a.level ?? 999;
        final levelB = b.level ?? 999;
        int compareLevel = levelA.compareTo(levelB);
        if (compareLevel != 0) return compareLevel;
        return a.name.compareTo(b.name);
      });
    } else {
      _filteredMoves.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    return CustomScrollView(
      key: const PageStorageKey('moves_tab'),
      slivers: [
        // Cabecera con filtros
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con contador
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.l10n.movesCount(_filteredMoves.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtros de método
                const Text('Filtrar por método:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Todos', 'all'),
                    ..._availableMethods.map((method) => _buildFilterChip(
                      PokemonMove.getMethodDisplay(method), 
                      method
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Ordenamiento
                const Text('Ordenar por:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Nivel'),
                      selected: _sortBy == 'level',
                      onSelected: (_) {
                        setState(() {
                          _sortBy = 'level';
                          _filterMoves();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Nombre'),
                      selected: _sortBy == 'name',
                      onSelected: (_) {
                        setState(() {
                          _sortBy = 'name';
                          _filterMoves();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Lista virtualizada con SliverList
        _filteredMoves.isEmpty
          ? SliverFillRemaining(
              child: Center(
                child: Text(
                  widget.l10n.noMovesWithMethod,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final move = _filteredMoves[index];
                  return _MoveListTile(move: move);
                },
                childCount: _filteredMoves.length,
              ),
            ),

        // Padding final
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedMethod == value,
      onSelected: (_) {
        setState(() {
          _selectedMethod = value;
          _filterMoves();
        });
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Widget optimizado para cada movimiento
class _MoveListTile extends StatelessWidget {
  final PokemonMove move;

  const _MoveListTile({required this.move});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Icono del método
          _getMethodIcon(move.method),
          const SizedBox(width: 12),
          
          // Información del movimiento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.name[0].toUpperCase() + move.name.substring(1).replaceAll('-', ' '),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PokemonMove.getMethodDisplay(move.method),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Nivel o badge
          if (move.level != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Nv ${move.level}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            Icon(
              Icons.circle,
              size: 8,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }

  Widget _getMethodIcon(String method) {
    IconData icon;
    Color color;

    switch (method) {
      case 'level-up':
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case 'machine':
        icon = Icons.album;
        color = Colors.purple;
        break;
      case 'egg':
        icon = Icons.egg;
        color = Colors.orange;
        break;
      case 'tutor':
        icon = Icons.school;
        color = Colors.blue;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
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

  const _FloatingPokemonImage({super.key, required this.imageUrl});

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
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                height: 220,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
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


