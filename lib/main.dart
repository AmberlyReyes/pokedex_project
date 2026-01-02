import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/screen/splash_screen.dart';
import 'data/datasources/poke_api.dart';
import 'presentation/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pokedez/data/models/pokemon_detail.dart';
import 'package:pokedez/data/models/pokemon_ability.dart';
import 'package:pokedez/data/models/pokemon_evolution.dart';
import 'package:pokedez/data/models/pokemon_move.dart';
import 'package:pokedez/data/models/pokemon_variant.dart';
import 'package:pokedez/data/models/pokemon_list_item.dart';
import 'package:pokedez/data/models/cached_pokemon_list.dart';
import 'presentation/screen/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive
  await Hive.initFlutter();
  // Registra los adaptadores
  Hive.registerAdapter(PokemonDetailAdapter());
  Hive.registerAdapter(PokemonAbilityAdapter());
  Hive.registerAdapter(PokemonEvolutionAdapter());
  Hive.registerAdapter(PokemonMoveAdapter());
  Hive.registerAdapter(PokemonVariantAdapter());
  Hive.registerAdapter(PokemonListItemAdapter());
  Hive.registerAdapter(CachedPokemonListAdapter());

  await Hive.openBox<PokemonDetail>('favorites');
  await Hive.openBox<CachedPokemonList>('pokemon_cache');

  // Inicializa GraphQL
  PokeApi.initGraphQL();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const SplashScreen(
        child: HomeScreen(),
      ),
    );
  }
}