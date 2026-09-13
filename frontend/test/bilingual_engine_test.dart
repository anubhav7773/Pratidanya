import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/core/localization/app_language.dart';
import 'package:pratidnya/src/core/localization/app_strings.dart';
import 'package:pratidnya/src/core/localization/translations_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal 40: Universal Bilingual Engine Tests', () {
    test('Dictionary parity: Every translation key has both Hindi and English entries', () {
      for (final entry in TranslationsDictionary.values.entries) {
        final key = entry.key;
        final map = entry.value;

        expect(
          map.containsKey(AppLanguage.hindi),
          isTrue,
          reason: 'Key "$key" is missing Hindi translation',
        );
        expect(
          map.containsKey(AppLanguage.english),
          isTrue,
          reason: 'Key "$key" is missing English translation',
        );
        expect(
          map[AppLanguage.hindi]!.isNotEmpty,
          isTrue,
          reason: 'Key "$key" has empty Hindi translation',
        );
        expect(
          map[AppLanguage.english]!.isNotEmpty,
          isTrue,
          reason: 'Key "$key" has empty English translation',
        );
      }
    });

    test('AppLanguageNotifier toggles reactively between Hindi and English with disk persistence', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is Hindi
      expect(container.read(appLanguageProvider), AppLanguage.hindi);
      expect(
        AppStrings.tr(container, 'active_dockets'),
        'सक्रिय आपराधिक डॉकेट',
      );

      // Toggle to English
      await container.read(appLanguageProvider.notifier).toggleLanguage();
      expect(container.read(appLanguageProvider), AppLanguage.english);
      expect(
        AppStrings.tr(container, 'active_dockets'),
        'Active Criminal Dockets',
      );

      // Verify written to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pratidnya_app_language'), 'en');

      // Toggle back to Hindi
      await container.read(appLanguageProvider.notifier).toggleLanguage();
      expect(container.read(appLanguageProvider), AppLanguage.hindi);
      expect(prefs.getString('pratidnya_app_language'), 'hi');
    });

    test('Specialized trial defense keys resolve correctly in both languages', () {
      expect(
        TranslationsDictionary.values['mod_default_bail']?[AppLanguage.hindi],
        'डिफ़ॉल्ट जमानत (Sec 187 BNSS)',
      );
      expect(
        TranslationsDictionary.values['mod_default_bail']?[AppLanguage.english],
        'Default Bail (Sec 187 BNSS / 167 CrPC)',
      );

      expect(
        TranslationsDictionary.values['mod_bsa_cert']?[AppLanguage.hindi],
        'इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र',
      );
      expect(
        TranslationsDictionary.values['mod_bsa_cert']?[AppLanguage.english],
        'Electronic Evidence Certificate',
      );
    });
  });
}
