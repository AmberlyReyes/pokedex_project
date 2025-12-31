import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pokédex'**
  String get appTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @addFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add your favorite Pokémon by tapping the heart icon'**
  String get addFavorites;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @eggGroups.
  ///
  /// In en, this message translates to:
  /// **'Egg Groups'**
  String get eggGroups;

  /// No description provided for @abilities.
  ///
  /// In en, this message translates to:
  /// **'Abilities'**
  String get abilities;

  /// No description provided for @evolutions.
  ///
  /// In en, this message translates to:
  /// **'Evolutions'**
  String get evolutions;

  /// No description provided for @noEvolutions.
  ///
  /// In en, this message translates to:
  /// **'No evolutions found'**
  String get noEvolutions;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Lv'**
  String get level;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @combat.
  ///
  /// In en, this message translates to:
  /// **'Combat'**
  String get combat;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Stats Overview'**
  String get statsOverview;

  /// No description provided for @totalStats.
  ///
  /// In en, this message translates to:
  /// **'Total Stats'**
  String get totalStats;

  /// No description provided for @detailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed Stats'**
  String get detailedStats;

  /// No description provided for @moves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get moves;

  /// No description provided for @noMoves.
  ///
  /// In en, this message translates to:
  /// **'No moves available'**
  String get noMoves;

  /// No description provided for @weaknesses.
  ///
  /// In en, this message translates to:
  /// **'Weaknesses'**
  String get weaknesses;

  /// No description provided for @resistances.
  ///
  /// In en, this message translates to:
  /// **'Resistances'**
  String get resistances;

  /// No description provided for @immunities.
  ///
  /// In en, this message translates to:
  /// **'Immunities'**
  String get immunities;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get shareCard;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @hp.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get hp;

  /// No description provided for @attack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attack;

  /// No description provided for @defense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get defense;

  /// No description provided for @specialAttack.
  ///
  /// In en, this message translates to:
  /// **'Sp. Atk'**
  String get specialAttack;

  /// No description provided for @specialDefense.
  ///
  /// In en, this message translates to:
  /// **'Sp. Def'**
  String get specialDefense;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @learnMethod.
  ///
  /// In en, this message translates to:
  /// **'Learn Method'**
  String get learnMethod;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noMovesFilter.
  ///
  /// In en, this message translates to:
  /// **'No moves match the current filters'**
  String get noMovesFilter;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust the filters to see more moves'**
  String get adjustFilters;

  /// No description provided for @triviaTitle.
  ///
  /// In en, this message translates to:
  /// **'Pokémon Trivia'**
  String get triviaTitle;

  /// No description provided for @highScore.
  ///
  /// In en, this message translates to:
  /// **'High Score'**
  String get highScore;

  /// No description provided for @whoIsThatPokemon.
  ///
  /// In en, this message translates to:
  /// **'Who\'s that Pokémon?'**
  String get whoIsThatPokemon;

  /// No description provided for @triviaInstructions.
  ///
  /// In en, this message translates to:
  /// **'Guess the Pokémon by its silhouette.\nFaster = more points!\n5 lives per game :p'**
  String get triviaInstructions;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get play;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points} points'**
  String correct(int points);

  /// No description provided for @timeOut.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timeOut;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect! It was {name}'**
  String incorrect(String name);

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'NEW RECORD!'**
  String get newRecord;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get finalScore;

  /// No description provided for @questionsAnswered.
  ///
  /// In en, this message translates to:
  /// **'Questions Answered'**
  String get questionsAnswered;

  /// No description provided for @personalRecord.
  ///
  /// In en, this message translates to:
  /// **'Personal Record'**
  String get personalRecord;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievements Unlocked'**
  String get achievementsUnlocked;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get playAgain;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @firstCapture.
  ///
  /// In en, this message translates to:
  /// **'First Capture'**
  String get firstCapture;

  /// No description provided for @fireStreak.
  ///
  /// In en, this message translates to:
  /// **'Fire Streak'**
  String get fireStreak;

  /// No description provided for @pokemonMaster.
  ///
  /// In en, this message translates to:
  /// **'Pokémon Master'**
  String get pokemonMaster;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @trivia.
  ///
  /// In en, this message translates to:
  /// **'Trivia'**
  String get trivia;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @generations.
  ///
  /// In en, this message translates to:
  /// **'Generations'**
  String get generations;

  /// No description provided for @types.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get types;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @selectGeneration.
  ///
  /// In en, this message translates to:
  /// **'Select Generation'**
  String get selectGeneration;

  /// No description provided for @selectTypes.
  ///
  /// In en, this message translates to:
  /// **'Select Types'**
  String get selectTypes;

  /// No description provided for @generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get generation;

  /// No description provided for @allGenerations.
  ///
  /// In en, this message translates to:
  /// **'All Generations'**
  String get allGenerations;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or adjust filters'**
  String get tryDifferentSearch;

  /// No description provided for @pokemonList.
  ///
  /// In en, this message translates to:
  /// **'Pokémon List'**
  String get pokemonList;

  /// No description provided for @abilitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Abilities'**
  String get abilitiesTab;

  /// No description provided for @abilityEffect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get abilityEffect;

  /// No description provided for @hiddenAbility.
  ///
  /// In en, this message translates to:
  /// **'Hidden Ability'**
  String get hiddenAbility;

  /// No description provided for @abilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Ability Details'**
  String get abilityDetails;

  /// No description provided for @checkMyCard.
  ///
  /// In en, this message translates to:
  /// **'Check out my {name} card! #Pokedex'**
  String checkMyCard(String name);

  /// No description provided for @testYourKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge!'**
  String get testYourKnowledge;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @grass.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get grass;

  /// No description provided for @electric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get electric;

  /// No description provided for @ice.
  ///
  /// In en, this message translates to:
  /// **'Ice'**
  String get ice;

  /// No description provided for @fighting.
  ///
  /// In en, this message translates to:
  /// **'Fighting'**
  String get fighting;

  /// No description provided for @poison.
  ///
  /// In en, this message translates to:
  /// **'Poison'**
  String get poison;

  /// No description provided for @ground.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get ground;

  /// No description provided for @flying.
  ///
  /// In en, this message translates to:
  /// **'Flying'**
  String get flying;

  /// No description provided for @psychic.
  ///
  /// In en, this message translates to:
  /// **'Psychic'**
  String get psychic;

  /// No description provided for @bug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get bug;

  /// No description provided for @rock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get rock;

  /// No description provided for @ghost.
  ///
  /// In en, this message translates to:
  /// **'Ghost'**
  String get ghost;

  /// No description provided for @dragon.
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get dragon;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @steel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get steel;

  /// No description provided for @fairy.
  ///
  /// In en, this message translates to:
  /// **'Fairy'**
  String get fairy;

  /// No description provided for @generationI.
  ///
  /// In en, this message translates to:
  /// **'Generation I'**
  String get generationI;

  /// No description provided for @generationII.
  ///
  /// In en, this message translates to:
  /// **'Generation II'**
  String get generationII;

  /// No description provided for @generationIII.
  ///
  /// In en, this message translates to:
  /// **'Generation III'**
  String get generationIII;

  /// No description provided for @generationIV.
  ///
  /// In en, this message translates to:
  /// **'Generation IV'**
  String get generationIV;

  /// No description provided for @generationV.
  ///
  /// In en, this message translates to:
  /// **'Generation V'**
  String get generationV;

  /// No description provided for @generationVI.
  ///
  /// In en, this message translates to:
  /// **'Generation VI'**
  String get generationVI;

  /// No description provided for @generationVII.
  ///
  /// In en, this message translates to:
  /// **'Generation VII'**
  String get generationVII;

  /// No description provided for @generationVIII.
  ///
  /// In en, this message translates to:
  /// **'Generation VIII'**
  String get generationVIII;

  /// No description provided for @generationIX.
  ///
  /// In en, this message translates to:
  /// **'Generation IX'**
  String get generationIX;

  /// No description provided for @doesNotEvolve.
  ///
  /// In en, this message translates to:
  /// **'Does not evolve'**
  String get doesNotEvolve;

  /// No description provided for @movesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String movesCount(int count);

  /// No description provided for @noMovesWithMethod.
  ///
  /// In en, this message translates to:
  /// **'No moves with this method'**
  String get noMovesWithMethod;

  /// No description provided for @sortByNumber.
  ///
  /// In en, this message translates to:
  /// **'By Number'**
  String get sortByNumber;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortByNameDesc;

  /// No description provided for @formVariant.
  ///
  /// In en, this message translates to:
  /// **'Form / Variant'**
  String get formVariant;

  /// No description provided for @baseForm.
  ///
  /// In en, this message translates to:
  /// **'Base Form'**
  String get baseForm;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @allPowers.
  ///
  /// In en, this message translates to:
  /// **'All Powers'**
  String get allPowers;

  /// No description provided for @powerLow.
  ///
  /// In en, this message translates to:
  /// **'Weak (0-300)'**
  String get powerLow;

  /// No description provided for @powerMedium.
  ///
  /// In en, this message translates to:
  /// **'Average (301-450)'**
  String get powerMedium;

  /// No description provided for @powerHigh.
  ///
  /// In en, this message translates to:
  /// **'Strong (451-550)'**
  String get powerHigh;

  /// No description provided for @powerVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Pseudo-Legendary (551-599)'**
  String get powerVeryHigh;

  /// No description provided for @powerLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary (600+)'**
  String get powerLegendary;

  /// No description provided for @offlineModeCache.
  ///
  /// In en, this message translates to:
  /// **'Offline mode - Showing cached data'**
  String get offlineModeCache;

  /// No description provided for @offlineModeNoCache.
  ///
  /// In en, this message translates to:
  /// **'No connection - Some features unavailable'**
  String get offlineModeNoCache;

  /// No description provided for @dataFromCache.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data'**
  String get dataFromCache;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
