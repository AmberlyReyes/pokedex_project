// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pokédex';

  @override
  String get search => 'Buscar';

  @override
  String get favorites => 'Favoritos';

  @override
  String get settings => 'Configuración';

  @override
  String get noFavorites => 'No hay favoritos aún';

  @override
  String get addFavorites =>
      'Agrega tus Pokémon favoritos tocando el ícono de corazón';

  @override
  String get height => 'Altura';

  @override
  String get weight => 'Peso';

  @override
  String get eggGroups => 'Grupos Huevo';

  @override
  String get abilities => 'Habilidades';

  @override
  String get evolutions => 'Evoluciones';

  @override
  String get noEvolutions => 'No se encontraron evoluciones';

  @override
  String get level => 'Nv';

  @override
  String get basicInfo => 'Info Básica';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get combat => 'Combate';

  @override
  String get statsOverview => 'Resumen de Stats';

  @override
  String get totalStats => 'Total de Stats';

  @override
  String get detailedStats => 'Stats Detalladas';

  @override
  String get moves => 'Movimientos';

  @override
  String get noMoves => 'No hay movimientos disponibles';

  @override
  String get weaknesses => 'Debilidades';

  @override
  String get resistances => 'Resistencias';

  @override
  String get immunities => 'Inmunidades';

  @override
  String get close => 'Cerrar';

  @override
  String get share => 'Compartir';

  @override
  String get shareCard => 'Compartir Carta';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get noData => 'Sin datos';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get changeLanguage => 'Cambiar Idioma';

  @override
  String get hp => 'PS';

  @override
  String get attack => 'Ataque';

  @override
  String get defense => 'Defensa';

  @override
  String get specialAttack => 'At. Esp.';

  @override
  String get specialDefense => 'Def. Esp.';

  @override
  String get speed => 'Velocidad';

  @override
  String get learnMethod => 'Método de Aprendizaje';

  @override
  String get all => 'Todos';

  @override
  String get sortBy => 'Ordenar Por';

  @override
  String get name => 'Nombre';

  @override
  String get power => 'Potencia';

  @override
  String get accuracy => 'Precisión';

  @override
  String get type => 'Tipo';

  @override
  String get category => 'Categoría';

  @override
  String get noMovesFilter =>
      'No hay movimientos que coincidan con los filtros actuales';

  @override
  String get adjustFilters => 'Ajusta los filtros para ver más movimientos';

  @override
  String get triviaTitle => 'Trivia Pokémon';

  @override
  String get highScore => 'Récord';

  @override
  String get whoIsThatPokemon => '¿Quién es ese Pokémon?';

  @override
  String get triviaInstructions =>
      'Adivina el Pokémon por su silueta.\n¡ + rápido = + puntos!\n5 vidas x partida :p';

  @override
  String get play => 'JUGAR';

  @override
  String get question => 'Pregunta';

  @override
  String get points => 'Puntos';

  @override
  String get time => 'Tiempo';

  @override
  String correct(int points) {
    return '¡Correcto! +$points puntos';
  }

  @override
  String get timeOut => '¡Tiempo agotado!';

  @override
  String incorrect(String name) {
    return '¡Incorrecto! Era $name';
  }

  @override
  String get newRecord => '¡NUEVO RÉCORD!';

  @override
  String get gameOver => 'Juego Terminado';

  @override
  String get finalScore => 'Puntuación Final';

  @override
  String get questionsAnswered => 'Preguntas Respondidas';

  @override
  String get personalRecord => 'Récord Personal';

  @override
  String get achievementsUnlocked => 'Logros Desbloqueados';

  @override
  String get playAgain => 'JUGAR DE NUEVO';

  @override
  String get home => 'Inicio';

  @override
  String get firstCapture => 'Primera Captura';

  @override
  String get fireStreak => 'Racha de Fuego';

  @override
  String get pokemonMaster => 'Maestro Pokémon';

  @override
  String get expert => 'Experto';

  @override
  String get legend => 'Leyenda';

  @override
  String get trivia => 'Trivia';

  @override
  String get tools => 'Herramientas';

  @override
  String get map => 'Mapa';

  @override
  String get generations => 'Generaciones';

  @override
  String get types => 'Tipos';

  @override
  String get filters => 'Filtros';

  @override
  String get applyFilters => 'Aplicar Filtros';

  @override
  String get clearFilters => 'Limpiar Filtros';

  @override
  String get selectGeneration => 'Seleccionar Generación';

  @override
  String get selectTypes => 'Seleccionar Tipos';

  @override
  String get generation => 'Generación';

  @override
  String get allGenerations => 'Todas las Generaciones';

  @override
  String get searching => 'Buscando...';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get tryDifferentSearch =>
      'Intenta con otro término de búsqueda o ajusta los filtros';

  @override
  String get pokemonList => 'Lista Pokémon';

  @override
  String get abilitiesTab => 'Habilidades';

  @override
  String get abilityEffect => 'Efecto';

  @override
  String get hiddenAbility => 'Habilidad Oculta';

  @override
  String get abilityDetails => 'Detalles de Habilidad';

  @override
  String checkMyCard(String name) {
    return '¡Mira mi carta de $name! #Pokedex';
  }

  @override
  String get testYourKnowledge => '¡Pon a prueba tus conocimientos!';

  @override
  String get normal => 'Normal';

  @override
  String get fire => 'Fuego';

  @override
  String get water => 'Agua';

  @override
  String get grass => 'Planta';

  @override
  String get electric => 'Eléctrico';

  @override
  String get ice => 'Hielo';

  @override
  String get fighting => 'Lucha';

  @override
  String get poison => 'Veneno';

  @override
  String get ground => 'Tierra';

  @override
  String get flying => 'Volador';

  @override
  String get psychic => 'Psíquico';

  @override
  String get bug => 'Bicho';

  @override
  String get rock => 'Roca';

  @override
  String get ghost => 'Fantasma';

  @override
  String get dragon => 'Dragón';

  @override
  String get dark => 'Siniestro';

  @override
  String get steel => 'Acero';

  @override
  String get fairy => 'Hada';

  @override
  String get generationI => 'Generación I';

  @override
  String get generationII => 'Generación II';

  @override
  String get generationIII => 'Generación III';

  @override
  String get generationIV => 'Generación IV';

  @override
  String get generationV => 'Generación V';

  @override
  String get generationVI => 'Generación VI';

  @override
  String get generationVII => 'Generación VII';

  @override
  String get generationVIII => 'Generación VIII';

  @override
  String get generationIX => 'Generación IX';

  @override
  String get doesNotEvolve => 'No evoluciona';

  @override
  String movesCount(int count) {
    return '$count movimientos';
  }

  @override
  String get noMovesWithMethod => 'No hay movimientos con este método';

  @override
  String get sortByNumber => 'Por Número';

  @override
  String get sortByNameAsc => 'Nombre (A-Z)';

  @override
  String get sortByNameDesc => 'Nombre (Z-A)';

  @override
  String get formVariant => 'Forma / Variante';

  @override
  String get baseForm => 'Forma Base';

  @override
  String get allTypes => 'Todos los Tipos';

  @override
  String get allPowers => 'Todos los Poderes';

  @override
  String get powerLow => 'Débil (0-300)';

  @override
  String get powerMedium => 'Promedio (301-450)';

  @override
  String get powerHigh => 'Fuerte (451-550)';

  @override
  String get powerVeryHigh => 'Pseudo-Legendario (551-599)';

  @override
  String get powerLegendary => 'Legendario (600+)';

  @override
  String get offlineModeCache => 'Modo offline - Mostrando datos guardados';

  @override
  String get offlineModeNoCache =>
      'Sin conexión - Algunas funciones no disponibles';

  @override
  String get dataFromCache => 'Mostrando datos en caché';
}
