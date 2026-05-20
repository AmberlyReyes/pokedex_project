import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  // Inicializa el locale desde las preferencias guardadas o usa 'es' por defecto
  LocaleNotifier() : super(const Locale('es')) {
    _loadLocale();
  }

  // carga el locale guardado en SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'es';
    state = Locale(languageCode);
  }

  // cambia el locale y lo guarda en SharedPreferences
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}

// Proveedor global para acceder y modificar el locale de la app
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
