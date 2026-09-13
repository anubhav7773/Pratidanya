import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  hindi('hi', 'हिन्दी', 'Devanagari Hindi'),
  english('en', 'English', 'Indian Legal English');

  final String code;
  final String nativeName;
  final String englishName;

  const AppLanguage(this.code, this.nativeName, this.englishName);

  static AppLanguage fromCode(String code) {
    return code == 'en' ? AppLanguage.english : AppLanguage.hindi;
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  static const String _kLanguagePrefKey = 'pratidnya_app_language';

  AppLanguageNotifier() : super(AppLanguage.hindi) {
    _loadPersistedLanguage();
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLanguagePrefKey);
      if (savedCode != null) {
        state = AppLanguage.fromCode(savedCode);
      }
    } catch (_) {
      // Default to Hindi on error
    }
  }

  Future<void> toggleLanguage() async {
    state = state == AppLanguage.hindi ? AppLanguage.english : AppLanguage.hindi;
    await _persistLanguage();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state != language) {
      state = language;
      await _persistLanguage();
    }
  }

  Future<void> _persistLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguagePrefKey, state.code);
    } catch (_) {}
  }
}
