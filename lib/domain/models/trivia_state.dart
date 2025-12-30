import 'package:equatable/equatable.dart';
import '../../data/models/pokemon_list_item.dart';

enum GameStatus {
  initial,
  loading,
  playing,
  revealed,
  gameOver,
  error,
}

class TriviaState extends Equatable {
  final PokemonListItem? currentPokemon;
  final List<String> options;
  final int score;
  final int timeLeft;
  final int questionNumber;
  final GameStatus status;
  final int highScore;
  final bool isCorrect;
  final String? selectedAnswer;
  final int lives;
  final List<String> achievements;
  final List<String> newlyUnlockedAchievements;
  final String? errorMessage;

  const TriviaState({
    this.currentPokemon,
    this.options = const [],
    this.score = 0,
    this.timeLeft = 15,
    this.questionNumber = 0,
    this.status = GameStatus.initial,
    this.highScore = 0,
    this.isCorrect = false,
    this.selectedAnswer,
    this.lives = 5,
    this.achievements = const [],
    this.newlyUnlockedAchievements = const [],
    this.errorMessage,
  });

  TriviaState copyWith({
    PokemonListItem? currentPokemon,
    List<String>? options,
    int? score,
    int? timeLeft,
    int? questionNumber,
    GameStatus? status,
    int? highScore,
    bool? isCorrect,
    String? selectedAnswer,
    int? lives,
    List<String>? achievements,
    List<String>? newlyUnlockedAchievements,
    String? errorMessage,
  }) {
    return TriviaState(
      currentPokemon: currentPokemon ?? this.currentPokemon,
      options: options ?? this.options,
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
      questionNumber: questionNumber ?? this.questionNumber,
      status: status ?? this.status,
      highScore: highScore ?? this.highScore,
      isCorrect: isCorrect ?? this.isCorrect,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      lives: lives ?? this.lives,
      achievements: achievements ?? this.achievements,
      newlyUnlockedAchievements: newlyUnlockedAchievements ?? this.newlyUnlockedAchievements,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentPokemon,
        options,
        score,
        timeLeft,
        questionNumber,
        status,
        highScore,
        isCorrect,
        selectedAnswer,
        lives,
        achievements,
        newlyUnlockedAchievements,
        errorMessage,
      ];
}
