import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de error completa
/// Se usa cuando una operación completa falla y necesita reintentarse
class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback onRetry;
  final VoidCallback? onHome;
  final IconData icon;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.details,
    this.onHome,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: onHome != null
            ? IconButton(
                icon: const Icon(Icons.home),
                onPressed: onHome,
              )
            : null,
      ),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono animado
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Icon(
                    icon,
                    size: 100,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  title,
                  style: GoogleFonts.limelight(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje principal
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    height: 1.6,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Detalles adicionales (opcional)
                if (details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      details!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        fontFamily: 'monospace',
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // Botones de acción
                Column(
                  children: [
                    // Botón Reintentar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: const Color(0xFF0A0E27),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (onHome != null) ...[
                      const SizedBox(height: 12),
                      // Botón Ir al inicio
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: onHome,
                          icon: const Icon(Icons.home),
                          label: const Text('Ir al inicio'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00D9FF),
                            side: const BorderSide(
                              color: Color(0xFF00D9FF),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
