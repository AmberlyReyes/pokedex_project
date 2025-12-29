import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/poke_api.dart';
import '../../data/models/pokemon_list_item.dart';
import '../../domain/models/trivia_state.dart';

final triviaProvider = StateNotifierProvider<TriviaNotifier, TriviaState>((ref) {
  return TriviaNotifier();
});

class TriviaNotifier extends StateNotifier<TriviaState> {
  TriviaNotifier() : super(const TriviaState()) {
    _loadHighScore();
  }

  Timer? _timer;
  final Random _random = Random();
  static const int _maxTime = 15;
  static const int _pointsPerQuestion = 100;
  static const int _timeBonus = 10;
  bool _isDisposed = false;

  Future<void> _loadHighScore() async {
    try {
      final box = await Hive.openBox('trivia');
      final highScore = box.get('highScore', defaultValue: 0) as int;
      final achievements = box.get('achievements', defaultValue: <String>[]) as List;
      state = state.copyWith(
        highScore: highScore,
        achievements: achievements.cast<String>().toList(),
      );
    } catch (e) {
      // Error loading high score
    }
  }

  Future<void> _saveHighScore(int score) async {
    try {
      final box = await Hive.openBox('trivia');
      final currentHigh = box.get('highScore', defaultValue: 0) as int;
      if (score > currentHigh) {
        await box.put('highScore', score);
        state = state.copyWith(highScore: score);
      }
      // Guardar achievements desbloqueados
      final allAchievements = box.get('achievements', defaultValue: <String>[]) as List;
      final currentAchievements = Set<String>.from(allAchievements.cast<String>());
      currentAchievements.addAll(state.achievements);
      await box.put('achievements', currentAchievements.toList());
    } catch (e) {
      // Error saving high score
    }
  }

  Future<void> startGame() async {
    // Guardar achievements previos para no perderlos
    final savedAchievements = state.achievements;
    
    state = state.copyWith(
      status: GameStatus.loading,
      score: 0,
      questionNumber: 0,
      lives: 5,
      achievements: savedAchievements, // Mantener logros previos
    );

    await _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    _timer?.cancel();

    state = state.copyWith(
      status: GameStatus.loading,
      timeLeft: _maxTime,
      isCorrect: false,
      selectedAnswer: null,
    );

    try {
      // Obtener 4 Pokémon aleatorios IDs entre 1-1024
      final randomIds = <int>{};
      while (randomIds.length < 4) {
        randomIds.add(_random.nextInt(1024) + 1);
      }

      // Fetch los 4 Pokémon
      final pokemonList = <PokemonListItem>[];
      int failedAttempts = 0;
      
      for (final id in randomIds) {
        try {
          final pokemon = await PokeApi.searchPokemonById(id);
          if (pokemon != null) {
            pokemonList.add(pokemon);
          }
        } catch (e) {
          failedAttempts++;
          // Si fallan todos, es probable que no haya internet
          if (failedAttempts >= randomIds.length) {
            throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet.');
          }
        }
      }

      if (pokemonList.length < 3) {
        // Si no hay suficientes Pokémon después de intentar, es un error de red
        throw Exception('No se pudo cargar suficientes Pokémon. Verifica tu conexión a internet.');
      }

      // Seleccionar uno como correcto
      final correctPokemon = pokemonList[_random.nextInt(pokemonList.length)];

      // Preparar las opciones (mezclar)
      final options = pokemonList.map((p) => _capitalize(p.name)).toList();
      options.shuffle();

      state = state.copyWith(
        currentPokemon: correctPokemon,
        options: options,
        status: GameStatus.playing,
        questionNumber: state.questionNumber + 1,
        timeLeft: _maxTime,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _timeOut();
      }
    });
  }

  void _timeOut() {
    if (_isDisposed) return;
    _timer?.cancel();
    
    // Perder una vida por timeout
    final newLives = state.lives - 1;
    
    state = state.copyWith(
      status: GameStatus.revealed,
      isCorrect: false,
      lives: newLives,
    );
    
    // Auto-avance después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (_isDisposed) return;
      if (newLives <= 0) {
        endGame();
      } else {
        _loadNextQuestion();
      }
    });
  }

  Future<void> checkAnswer(String selectedName) async {
    if (state.status != GameStatus.playing || state.currentPokemon == null) {
      return;
    }

    _timer?.cancel();

    final correctName = _capitalize(state.currentPokemon!.name);
    final isCorrect = selectedName == correctName;

    int newScore = state.score;
    int newLives = state.lives;
    List<String> newAchievements = List.from(state.achievements);
    
    if (isCorrect) {
      // Puntos base + bonus por tiempo restante
      newScore += _pointsPerQuestion + (state.timeLeft * _timeBonus);
      
      // Desbloquear logros
      _checkAchievements(newScore, state.questionNumber + 1, newAchievements);
    } else {
      // Perder una vida
      newLives -= 1;
    }

    state = state.copyWith(
      status: GameStatus.revealed,
      isCorrect: isCorrect,
      selectedAnswer: selectedName,
      score: newScore,
      lives: newLives,
      achievements: newAchievements,
    );
    
    // Auto-avance después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (_isDisposed) return;
      if (newLives <= 0) {
        endGame();
      } else {
        _loadNextQuestion();
      }
    });
  }
  
  void _checkAchievements(int score, int questionNumber, List<String> achievements) {
    // Primera Captura: Responder correctamente la primera pregunta
    if (questionNumber == 1 && !achievements.contains('primera_captura')) {
      achievements.add('primera_captura');
    }
    
    // Racha de Fuego: 5 preguntas correctas seguidas (sin perder vidas en las primeras 5)
    if (questionNumber >= 5 && state.lives == 5 && !achievements.contains('racha_fuego')) {
      achievements.add('racha_fuego');
    }
    
    // Maestro Pokémon: Alcanzar 1000 puntos
    if (score >= 1000 && !achievements.contains('maestro_pokemon')) {
      achievements.add('maestro_pokemon');
    }
    
    // Experto: Alcanzar 2000 puntos
    if (score >= 2000 && !achievements.contains('experto')) {
      achievements.add('experto');
    }
    
    // Leyenda: Alcanzar 5000 puntos
    if (score >= 5000 && !achievements.contains('leyenda')) {
      achievements.add('leyenda');
    }
  }

  Future<void> nextQuestion() async {
    await _loadNextQuestion();
  }

  Future<void> endGame() async {
    _timer?.cancel();
    await _saveHighScore(state.score);
    state = state.copyWith(status: GameStatus.gameOver);
  }

  void resetGame() {
    _timer?.cancel();
    // Cargar achievements previos antes de resetear
    final savedAchievements = state.achievements;
    final savedHighScore = state.highScore;
    state = TriviaState(
      status: GameStatus.initial,
      achievements: savedAchievements,
      highScore: savedHighScore,
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
