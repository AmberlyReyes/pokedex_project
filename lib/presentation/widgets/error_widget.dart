import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de error reutilizable que puede usarse en cualquier pantalla
/// Muestra un mensaje de error con un icono y un botón de reintentar
class ErrorMessageWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;
  final Color? iconColor;

  const ErrorMessageWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de error
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.red[400],
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              title,
              style: GoogleFonts.limelight(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Mensaje descriptivo
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botón de reintentar
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: const Color(0xFF0A0E27),
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
