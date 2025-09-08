import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Localizable language provider for the whole app
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')); // default locale
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Select a language
  void selectLanguage(String languageCode) async {
    state = Locale(languageCode);
    await _secureStorage.write(key: 'lang', value: languageCode);
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
