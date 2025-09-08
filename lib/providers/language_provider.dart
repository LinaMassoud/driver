import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Localizable language provider for the whole app
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')); // default locale

  /// Select a language
  void selectLanguage(String languageCode) {
    state = Locale(languageCode);
  }

  /// Save the language (optional: persist in SharedPreferences)
  void saveLanguage() {
    print('Language saved: ${state.languageCode}');
  }
}

/// Provider type: Locale
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
