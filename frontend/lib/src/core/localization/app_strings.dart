import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';
import 'translations_dictionary.dart';

class AppStrings {
  /// Looks up translation reactively using Riverpod WidgetRef, ProviderContainer, or Ref
  static String tr(dynamic ref, String key) {
    AppLanguage language;
    if (ref is WidgetRef) {
      language = ref.watch(appLanguageProvider);
    } else if (ref is ProviderContainer) {
      language = ref.read(appLanguageProvider);
    } else if (ref is Ref) {
      language = ref.watch(appLanguageProvider);
    } else if (ref is AppLanguage) {
      language = ref;
    } else {
      language = AppLanguage.hindi;
    }
    return TranslationsDictionary.values[key]?[language] ?? key;
  }

  /// Static non-reactive lookup by language
  static String trStatic(AppLanguage language, String key) {
    return TranslationsDictionary.values[key]?[language] ?? key;
  }
}

/// Fluent BuildContext extension: context.tr(ref, 'key')
extension LocalizationExtension on BuildContext {
  String tr(WidgetRef ref, String key) {
    return AppStrings.tr(ref, key);
  }
}
