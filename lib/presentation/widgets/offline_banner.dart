import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final bool hasCache;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    required this.hasCache,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: hasCache ? Colors.orange[700] : Colors.red[700],
      child: Row(
        children: [
          Icon(
            hasCache ? Icons.cloud_off : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasCache 
                ? '📦 Modo offline - Mostrando datos guardados'
                : '❌ Sin conexión - Algunas funciones no disponibles',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
