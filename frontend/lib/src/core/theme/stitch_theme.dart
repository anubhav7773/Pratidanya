import 'package:flutter/material.dart';
import 'stitch_colors.dart';
import 'stitch_typography.dart';

class StitchTheme {
  static const List<String> kDevanagariFontFallback = [
    'NotoSansDevanagari',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kDevanagariFontFallback,
      scaffoldBackgroundColor: StitchColors.legalParchment,
      colorScheme: const ColorScheme.light(
        primary: StitchColors.courtNavy,
        secondary: StitchColors.chamberSlate,
        surface: StitchColors.pureWhite,
        error: StitchColors.alertCrimson,
      ),
      textTheme: StitchTypography.textTheme(StitchColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: StitchColors.courtNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontFamilyFallback: kDevanagariFontFallback,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: StitchColors.borderSubtle, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: StitchColors.borderSubtle,
        thickness: 1.0,
      ),
    );
  }

  static ThemeData get chamberDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kDevanagariFontFallback,
      scaffoldBackgroundColor: StitchColors.darkCanvas,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.amber,
        surface: StitchColors.darkSurface,
        error: StitchColors.alertCrimson,
      ),
      textTheme: StitchTypography.textTheme(Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: StitchColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontFamilyFallback: kDevanagariFontFallback,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: StitchColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: StitchColors.darkSurfaceVariant, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: StitchColors.darkSurfaceVariant,
        thickness: 1.0,
      ),
    );
  }
}
