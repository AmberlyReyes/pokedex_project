import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/trivia_state.dart';
import '../providers/trivia_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_widget.dart';
import '../../l10n/app_localizations.dart';

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  
  void _showAchievementNotification(String achievement) {
    final achievementData = _getAchievementData(achievement, context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: achievementData['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievementData['icon'],
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆 ¡Logro Desbloqueado!',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievementData['name'],
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1a1a2e),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: achievementData['color'], width: 2),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios para mostrar notificaciones de logros
    ref.listen(triviaProvider, (previous, next) {
      if (next.newlyUnlockedAchievements.isNotEmpty) {
        for (final achievement in next.newlyUnlockedAchievements) {
          _showAchievementNotification(achievement);
        }
      }
    });
    
    final triviaState = ref.watch(triviaProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          l10n.triviaTitle,
          style: GoogleFonts.limelight(
            fontSize: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.highScore,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                  Text(
                    '${triviaState.highScore}',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: triviaState.status == GameStatus.initial
          ? _buildInitialScreen(context, ref)
          : triviaState.status == GameStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : triviaState.status == GameStatus.error
                  ? _buildErrorScreen(context, ref, triviaState)
                  : triviaState.status == GameStatus.gameOver
                      ? _buildGameOverScreen(context, ref, triviaState)
                      : _buildGameScreen(context, ref, triviaState),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, TriviaState state) {
    return Container(
      color: const Color.fromARGB(255, 1, 8, 42),
      child: ErrorMessageWidget(
        title: 'Se requiere Internet',
        message: '\nVerifica tu conexión y vuelve a intentarlo.',
        icon: Icons.wifi_off,
        iconColor: Colors.orange[400],
        onRetry: () => ref.read(triviaProvider.notifier).startGame(),
      ),
    );
  }

  Widget _buildInitialScreen(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.catching_pokemon,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.whoIsThatPokemon,
              style: GoogleFonts.limelight(
                fontSize: 22,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.triviaInstructions,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Semantics(
              label: 'Iniciar juego de trivia Pokémon',
              button: true,
              child: ElevatedButton(
                onPressed: () => ref.read(triviaProvider.notifier).startGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  l10n.play,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, WidgetRef ref, TriviaState state) {
    final l10n = AppLocalizations.of(context)!;
    final isRevealed = state.status == GameStatus.revealed;
    final pokemon = state.currentPokemon;

    if (pokemon == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Score, Question Number y Vidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.question} ${state.questionNumber}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indicador de vidas (corazones)
                  Semantics(
                    label: 'Vidas restantes: ${state.lives} de 5',
                    readOnly: true,
                    child: Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < state.lives ? Icons.favorite : Icons.favorite_border,
                            color: index < state.lives ? Colors.red : Colors.white38,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'Puntuación actual: ${state.score} puntos',
                readOnly: true,
                child: Text(
                  '${l10n.points}: ${state.score}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: AppTheme.tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timer Progress
          Semantics(
            label: 'Tiempo restante: ${state.timeLeft} segundos',
            liveRegion: true,
            child: Column(
              children: [
                Text(
                  '${l10n.time}: ${state.timeLeft}s',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: state.timeLeft <= 5 ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: state.timeLeft / 15,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    state.timeLeft <= 5 ? Colors.red : AppTheme.primaryColor,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pokemon Image (silueta o revelado)
          Semantics(
            label: isRevealed 
                ? 'Pokémon revelado: ${pokemon.name}' 
                : 'Silueta de Pokémon oculto. Adivina quién es',
            image: true,
            child: Container(
              height: 200,
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRevealed
                      ? (state.isCorrect ? Colors.green : Colors.red)
                      : AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isRevealed
                  ? Image.network(
                      pokemon.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.white54,
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: Image.network(
                        pokemon.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback de respuesta
          if (isRevealed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.isCorrect
                    ? l10n.correct(100 + (state.timeLeft * 10))
                    : state.timeLeft == 0
                        ? l10n.timeOut
                        : l10n.incorrect(pokemon.name[0].toUpperCase() + pokemon.name.substring(1)),
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: state.isCorrect ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Opciones
          Expanded(
            child: ListView(
              children: state.options.map((option) {
                final isSelected = state.selectedAnswer == option;
                final correctAnswer = pokemon.name[0].toUpperCase() + pokemon.name.substring(1);
                final isCorrectOption = option == correctAnswer;

                Color buttonColor;
                if (isRevealed) {
                  if (isCorrectOption) {
                    buttonColor = Colors.green;
                  } else if (isSelected) {
                    buttonColor = Colors.red;
                  } else {
                    buttonColor = Colors.white24;
                  }
                } else {
                  buttonColor = AppTheme.primaryColor;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    label: 'Opción: $option',
                    button: true,
                    enabled: !isRevealed,
                    hint: isRevealed 
                        ? (isCorrectOption ? 'Respuesta correcta' : (isSelected ? 'Tu respuesta incorrecta' : ''))
                        : 'Toca para seleccionar esta opción',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isRevealed
                            ? null
                            : () => ref.read(triviaProvider.notifier).checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          disabledBackgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, WidgetRef ref, TriviaState state) {
    final l10n = AppLocalizations.of(context)!;
    final isNewRecord = state.score > 0 && state.score == state.highScore;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            if (isNewRecord) ...[
              const Icon(
                Icons.emoji_events,
                size: 70,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.newRecord,
                style: GoogleFonts.limelight(
                  fontSize: 24,
                  color: Colors.amber,
                ),
              ),
            ] else ...[
              Icon(
                Icons.catching_pokemon,
                size: 70,
                color: AppTheme.primaryColor.withOpacity(0.8),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.gameOver,
                style: GoogleFonts.limelight(
                  fontSize: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildStatCard(l10n.finalScore, state.score, AppTheme.secondaryColor, context),
            const SizedBox(height: 12),
            _buildStatCard(l10n.questionsAnswered, state.questionNumber, AppTheme.primaryColor, context),
            const SizedBox(height: 12),
            _buildStatCard(l10n.personalRecord, state.highScore, AppTheme.tertiaryColor, context),
            
            // Logros desbloqueados
            if (state.achievements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.achievementsUnlocked,
                style: GoogleFonts.limelight(
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: state.achievements.map((achievement) {
                  return _buildAchievementBadge(achievement, context);
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Jugar de nuevo',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => ref.read(triviaProvider.notifier).startGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        l10n.playAgain,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Volver al menú principal',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementBadge(String achievement, BuildContext context) {
    final achievementData = _getAchievementData(achievement, context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achievementData['color'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievementData['icon'],
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            achievementData['name'],
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, dynamic> _getAchievementData(String achievement, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (achievement) {
      case 'primera_captura':
        return {
          'name': l10n.firstCapture,
          'icon': Icons.star,
          'color': const Color(0xFF4CAF50),
        };
      case 'racha_fuego':
        return {
          'name': l10n.fireStreak,
          'icon': Icons.local_fire_department,
          'color': const Color(0xFFFF5722),
        };
      case 'maestro_pokemon':
        return {
          'name': l10n.pokemonMaster,
          'icon': Icons.military_tech,
          'color': const Color(0xFF2196F3),
        };
      case 'experto':
        return {
          'name': l10n.expert,
          'icon': Icons.workspace_premium,
          'color': const Color(0xFF9C27B0),
        };
      case 'leyenda':
        return {
          'name': l10n.legend,
          'icon': Icons.emoji_events,
          'color': const Color(0xFFFFD700),
        };
      default:
        return {
          'name': achievement,
          'icon': Icons.verified,
          'color': Colors.grey,
        };
    }
  }

  Widget _buildStatCard(String label, int value, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}