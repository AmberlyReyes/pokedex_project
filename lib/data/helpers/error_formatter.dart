import 'dart:async';
import 'dart:io';

/// Helper para formatear mensajes de error de manera consistente
/// y proporcionar información útil al usuario
class ErrorFormatter {
  /// Retorna un mensaje amigable basado en el tipo de error
  static String getUserMessage(dynamic error) {
    if (error is SocketException) {
      return 'No hay conexión a internet.\nVerifica tu conexión de datos o WiFi.';
    } else if (error is TimeoutException) {
      return 'La solicitud tardó demasiado.\nIntenta de nuevo más tarde.';
    } else if (error is HttpException) {
      return 'Error de servidor.\nIntenta de nuevo más tarde.';
    } else if (error is FormatException) {
      return 'Error al procesar los datos.\nIntenta de nuevo.';
    } else if (error is ArgumentError) {
      return 'Datos inválidos.\nVerifica tu entrada.';
    } else if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('404')) {
        return 'Recurso no encontrado.';
      } else if (msg.contains('500') || msg.contains('503')) {
        return 'El servidor no está disponible.\nIntenta más tarde.';
      } else if (msg.contains('401') || msg.contains('403')) {
        return 'No tienes permiso para acceder.';
      }
    }
    
    // Error desconocido
    return '\nIntenta de nuevo.';
  }

  /// Retorna un título apropiado para el error
  static String getTitle(dynamic error) {
    if (error is SocketException) {
      return 'Sin conexión';
    } else if (error is TimeoutException) {
      return 'Tiempo agotado';
    } else if (error is FormatException) {
      return 'Error de datos';
    } else if (error is ArgumentError) {
      return 'Entrada inválida';
    } else if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('404')) return 'No encontrado';
      if (msg.contains('500') || msg.contains('503')) return 'Error del servidor';
      if (msg.contains('401') || msg.contains('403')) return 'Acceso denegado';
    }
    
    return 'Algo salió mal';
  }


  /// Retorna detalles técnicos del error (para debugging)
  static String? getDetails(dynamic error, {bool showDetails = false}) {
    if (!showDetails) return null;
    
    return error.toString();
  }

  /// Retorna todos los datos del error formateados
  static ErrorData format(dynamic error, {bool showDetails = false}) {
    return ErrorData(
      title: getTitle(error),
      message: getUserMessage(error),
      details: getDetails(error, showDetails: showDetails),
    );
  }
}

/// Clase para encapsular los datos del error formateado
class ErrorData {
  final String title;
  final String message;
  final String? details;

  ErrorData({
    required this.title,
    required this.message,
    required this.details,
  });
}
