import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../data/helpers/error_formatter.dart';
import '../widgets/error_widget.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _scaleAnimation;
  bool _showSplash = true;
  bool _hasError = false;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for 4 seconds (longer animation)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Fade in animation (0 to 1) - entrada suave
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Fade out animation (1 to 0) - salida difuminada
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale animation sin rebote - solo crecimiento suave
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation and initialization
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start animation
      _controller.forward();
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 5000));

      if (mounted && !_hasError) {
        setState(() => _showSplash = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = e;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    // Si hay un error durante la inicialización, mostrar pantalla de error
    if (_hasError) {
      final errorData = ErrorFormatter.format(_error, showDetails: false);
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E27),
                Color(0xFF1E2749),
              ],
            ),
          ),
          child: ErrorMessageWidget(
            title: errorData.title,
            message: errorData.message,
            onRetry: () {
              setState(() {
                _hasError = false;
                _error = null;
                _showSplash = true;
              });
              _initializeApp();
            },
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0E27),      // Azul oscuro profundo
                  Color(0xFF1E2749),      // Azul medio
                  Color(0xFF00D9FF),      // Cyan neón
                  Color(0xFFFF0080),      // Magenta vibrante
                  Color(0xFFFF6B35),      // Naranja brillante
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _controller.value < 0.7 ? _fadeInAnimation : _fadeOutAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título y autores
                        Column(
                          children: [
                            // Título principal
                            Text(
                              'Pókedex',
                              style: GoogleFonts.limelight(
                                fontSize: 48,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFFFD700), // Amarillo dorado
                                letterSpacing: 3.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    offset: const Offset(3, 3),
                                    blurRadius: 6,
                                  ),
                                  Shadow(
                                    color: Colors.grey.withOpacity(0.6),
                                    offset: const Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subtítulo con autores
                            Text(
                              'by: Amberly R y Erick D',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Loading indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 4000),
                          builder: (context, value, child) {
                            return SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFD700), 
                                ),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                      ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
