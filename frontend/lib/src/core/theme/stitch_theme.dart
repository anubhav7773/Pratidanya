import 'package:flutter/material.dart';
import 'luxury_palette.dart';
import 'stitch_typography.dart';

class StitchTheme {
  static ThemeData get lightTheme {
    final textTheme = StitchTypography.buildTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: StitchTypography.kFontFallbacks,
      scaffoldBackgroundColor: LuxuryPalette.offWhiteCanvas,
      primaryColor: LuxuryPalette.courtNavy,
      canvasColor: LuxuryPalette.offWhiteCanvas,
      
      colorScheme: const ColorScheme.light(
        primary: LuxuryPalette.courtNavy,
        onPrimary: LuxuryPalette.lightSurface,
        secondary: LuxuryPalette.champagneGold,
        onSecondary: LuxuryPalette.courtNavy,
        surface: LuxuryPalette.lightSurface,
        onSurface: LuxuryPalette.lightTextPrimary,
        error: LuxuryPalette.rubyAlert,
        onError: LuxuryPalette.lightSurface,
      ),

      textTheme: textTheme,

      // App Bar Styling
      appBarTheme: const AppBarTheme(
        backgroundColor: LuxuryPalette.courtNavy,
        foregroundColor: LuxuryPalette.lightSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1.5,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontFamilyFallback: StitchTypography.kFontFallbacks,
          fontSize: 16.5,
          fontWeight: FontWeight.bold,
          color: LuxuryPalette.lightSurface,
        ),
      ),

      // Card Theming (Crisp borders, subtle elevation)
      cardTheme: CardThemeData(
        color: LuxuryPalette.lightSurface,
        elevation: 1.0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: LuxuryPalette.lightBorder, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
      ),

      // Input Decoration Theme (Lawyer Docket Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuxuryPalette.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.champagneGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.rubyAlert, width: 1.0),
        ),
        labelStyle: const TextStyle(
          fontSize: 13.0,
          color: LuxuryPalette.lightTextSecondary,
          fontFamilyFallback: StitchTypography.kFontFallbacks,
        ),
        hintStyle: const TextStyle(
          fontSize: 12.5,
          color: LuxuryPalette.lightTextMuted,
          fontFamilyFallback: StitchTypography.kFontFallbacks,
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuxuryPalette.courtNavy,
          foregroundColor: LuxuryPalette.lightSurface,
          elevation: 1.0,
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            fontFamilyFallback: StitchTypography.kFontFallbacks,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuxuryPalette.courtNavy,
          side: const BorderSide(color: LuxuryPalette.courtNavy, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
            fontFamilyFallback: StitchTypography.kFontFallbacks,
          ),
        ),
      ),

      // Choice / Filter Chips
      chipTheme: ChipThemeData(
        backgroundColor: LuxuryPalette.lightSurfaceSecondary,
        selectedColor: LuxuryPalette.courtNavy,
        side: const BorderSide(color: LuxuryPalette.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),

      dividerColor: LuxuryPalette.lightBorder,
    );
  }

  static ThemeData get chamberDarkTheme => darkTheme;

  static ThemeData get darkTheme {
    final textTheme = StitchTypography.buildTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: StitchTypography.kFontFallbacks,
      scaffoldBackgroundColor: LuxuryPalette.midnightCanvas,
      primaryColor: LuxuryPalette.champagneGold,
      canvasColor: LuxuryPalette.midnightCanvas,

      colorScheme: const ColorScheme.dark(
        primary: LuxuryPalette.champagneGold,
        onPrimary: LuxuryPalette.courtNavy,
        secondary: LuxuryPalette.goldGlow,
        onSecondary: LuxuryPalette.courtNavy,
        surface: LuxuryPalette.midnightSurface,
        onSurface: LuxuryPalette.darkTextPrimary,
        error: LuxuryPalette.rubyAlert,
        onError: LuxuryPalette.lightSurface,
      ),

      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF070E1A),
        foregroundColor: LuxuryPalette.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1.0,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontFamilyFallback: StitchTypography.kFontFallbacks,
          fontSize: 16.5,
          fontWeight: FontWeight.bold,
          color: LuxuryPalette.darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: LuxuryPalette.midnightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: LuxuryPalette.midnightBorder, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuxuryPalette.midnightElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.midnightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.midnightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.champagneGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: LuxuryPalette.rubyAlert, width: 1.0),
        ),
        labelStyle: const TextStyle(
          fontSize: 13.0,
          color: LuxuryPalette.darkTextSecondary,
          fontFamilyFallback: StitchTypography.kFontFallbacks,
        ),
        hintStyle: const TextStyle(
          fontSize: 12.5,
          color: LuxuryPalette.darkTextMuted,
          fontFamilyFallback: StitchTypography.kFontFallbacks,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuxuryPalette.champagneGold,
          foregroundColor: LuxuryPalette.courtNavy,
          elevation: 2.0,
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            fontFamilyFallback: StitchTypography.kFontFallbacks,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuxuryPalette.champagneGold,
          side: const BorderSide(color: LuxuryPalette.champagneGold, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
            fontFamilyFallback: StitchTypography.kFontFallbacks,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: LuxuryPalette.midnightElevated,
        selectedColor: LuxuryPalette.champagneGold,
        side: const BorderSide(color: LuxuryPalette.midnightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),

      dividerColor: LuxuryPalette.midnightBorder,
    );
  }
}
