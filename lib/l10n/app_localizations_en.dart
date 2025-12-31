// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pokédex';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get addFavorites =>
      'Add your favorite Pokémon by tapping the heart icon';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get eggGroups => 'Egg Groups';

  @override
  String get abilities => 'Abilities';

  @override
  String get evolutions => 'Evolutions';

  @override
  String get noEvolutions => 'No evolutions found';

  @override
  String get level => 'Lv';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get statistics => 'Statistics';

  @override
  String get combat => 'Combat';

  @override
  String get statsOverview => 'Stats Overview';

  @override
  String get totalStats => 'Total Stats';

  @override
  String get detailedStats => 'Detailed Stats';

  @override
  String get moves => 'Moves';

  @override
  String get noMoves => 'No moves available';

  @override
  String get weaknesses => 'Weaknesses';

  @override
  String get resistances => 'Resistances';

  @override
  String get immunities => 'Immunities';

  @override
  String get close => 'Close';

  @override
  String get share => 'Share';

  @override
  String get shareCard => 'Share Card';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get hp => 'HP';

  @override
  String get attack => 'Attack';

  @override
  String get defense => 'Defense';

  @override
  String get specialAttack => 'Sp. Atk';

  @override
  String get specialDefense => 'Sp. Def';

  @override
  String get speed => 'Speed';

  @override
  String get learnMethod => 'Learn Method';

  @override
  String get all => 'All';

  @override
  String get sortBy => 'Sort By';

  @override
  String get name => 'Name';

  @override
  String get power => 'Power';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get type => 'Type';

  @override
  String get category => 'Category';

  @override
  String get noMovesFilter => 'No moves match the current filters';

  @override
  String get adjustFilters => 'Adjust the filters to see more moves';

  @override
  String get triviaTitle => 'Pokémon Trivia';

  @override
  String get highScore => 'High Score';

  @override
  String get whoIsThatPokemon => 'Who\'s that Pokémon?';

  @override
  String get triviaInstructions =>
      'Guess the Pokémon by its silhouette.\nFaster = more points!\n5 lives per game :p';

  @override
  String get play => 'PLAY';

  @override
  String get question => 'Question';

  @override
  String get points => 'Points';

  @override
  String get time => 'Time';

  @override
  String correct(int points) {
    return 'Correct! +$points points';
  }

  @override
  String get timeOut => 'Time\'s up!';

  @override
  String incorrect(String name) {
    return 'Incorrect! It was $name';
  }

  @override
  String get newRecord => 'NEW RECORD!';

  @override
  String get gameOver => 'Game Over';

  @override
  String get finalScore => 'Final Score';

  @override
  String get questionsAnswered => 'Questions Answered';

  @override
  String get personalRecord => 'Personal Record';

  @override
  String get achievementsUnlocked => 'Achievements Unlocked';

  @override
  String get playAgain => 'PLAY AGAIN';

  @override
  String get home => 'Home';

  @override
  String get firstCapture => 'First Capture';

  @override
  String get fireStreak => 'Fire Streak';

  @override
  String get pokemonMaster => 'Pokémon Master';

  @override
  String get expert => 'Expert';

  @override
  String get legend => 'Legend';

  @override
  String get trivia => 'Trivia';

  @override
  String get tools => 'Tools';

  @override
  String get map => 'Map';

  @override
  String get generations => 'Generations';

  @override
  String get types => 'Types';

  @override
  String get filters => 'Filters';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get selectGeneration => 'Select Generation';

  @override
  String get selectTypes => 'Select Types';

  @override
  String get generation => 'Generation';

  @override
  String get allGenerations => 'All Generations';

  @override
  String get searching => 'Searching...';

  @override
  String get noResults => 'No results found';

  @override
  String get tryDifferentSearch =>
      'Try a different search term or adjust filters';

  @override
  String get pokemonList => 'Pokémon List';

  @override
  String get abilitiesTab => 'Abilities';

  @override
  String get abilityEffect => 'Effect';

  @override
  String get hiddenAbility => 'Hidden Ability';

  @override
  String get abilityDetails => 'Ability Details';

  @override
  String checkMyCard(String name) {
    return 'Check out my $name card! #Pokedex';
  }

  @override
  String get testYourKnowledge => 'Test your knowledge!';

  @override
  String get normal => 'Normal';

  @override
  String get fire => 'Fire';

  @override
  String get water => 'Water';

  @override
  String get grass => 'Grass';

  @override
  String get electric => 'Electric';

  @override
  String get ice => 'Ice';

  @override
  String get fighting => 'Fighting';

  @override
  String get poison => 'Poison';

  @override
  String get ground => 'Ground';

  @override
  String get flying => 'Flying';

  @override
  String get psychic => 'Psychic';

  @override
  String get bug => 'Bug';

  @override
  String get rock => 'Rock';

  @override
  String get ghost => 'Ghost';

  @override
  String get dragon => 'Dragon';

  @override
  String get dark => 'Dark';

  @override
  String get steel => 'Steel';

  @override
  String get fairy => 'Fairy';

  @override
  String get generationI => 'Generation I';

  @override
  String get generationII => 'Generation II';

  @override
  String get generationIII => 'Generation III';

  @override
  String get generationIV => 'Generation IV';

  @override
  String get generationV => 'Generation V';

  @override
  String get generationVI => 'Generation VI';

  @override
  String get generationVII => 'Generation VII';

  @override
  String get generationVIII => 'Generation VIII';

  @override
  String get generationIX => 'Generation IX';

  @override
  String get doesNotEvolve => 'Does not evolve';

  @override
  String movesCount(int count) {
    return '$count moves';
  }

  @override
  String get noMovesWithMethod => 'No moves with this method';

  @override
  String get sortByNumber => 'By Number';

  @override
  String get sortByNameAsc => 'Name (A-Z)';

  @override
  String get sortByNameDesc => 'Name (Z-A)';

  @override
  String get formVariant => 'Form / Variant';

  @override
  String get baseForm => 'Base Form';

  @override
  String get allTypes => 'All Types';

  @override
  String get allPowers => 'All Powers';

  @override
  String get powerLow => 'Weak (0-300)';

  @override
  String get powerMedium => 'Average (301-450)';

  @override
  String get powerHigh => 'Strong (451-550)';

  @override
  String get powerVeryHigh => 'Pseudo-Legendary (551-599)';

  @override
  String get powerLegendary => 'Legendary (600+)';

  @override
  String get offlineModeCache => 'Offline mode - Showing cached data';

  @override
  String get offlineModeNoCache => 'No connection - Some features unavailable';

  @override
  String get dataFromCache => 'Showing cached data';
}
