import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/core/theme/theme_controller.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';
import 'package:pratidnya/src/core/theme/luxury_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Goal 39: ThemeController toggles between Light and Dark mode with persistence', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state is Light Mode
    expect(container.read(appThemeProvider), ThemeMode.light);

    // Toggle to Dark Mode
    await container.read(appThemeProvider.notifier).toggleTheme();
    expect(container.read(appThemeProvider), ThemeMode.dark);

    // Verify written to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pratidnya_theme_mode'), 'dark');

    // Toggle back to Light Mode
    await container.read(appThemeProvider.notifier).toggleTheme();
    expect(container.read(appThemeProvider), ThemeMode.light);
    expect(prefs.getString('pratidnya_theme_mode'), 'light');
  });

  test('Goal 39: Luxury Palette and ThemeData properties resolve correctly', () {
    final light = StitchTheme.lightTheme;
    final dark = StitchTheme.darkTheme;

    // Light theme checks
    expect(light.brightness, Brightness.light);
    expect(light.scaffoldBackgroundColor, LuxuryPalette.offWhiteCanvas);
    expect(light.colorScheme.primary, LuxuryPalette.courtNavy);

    // Dark theme checks
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, LuxuryPalette.midnightCanvas);
    expect(dark.colorScheme.primary, LuxuryPalette.champagneGold);
  });
}
