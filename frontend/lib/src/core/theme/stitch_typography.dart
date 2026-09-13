import 'package:flutter/material.dart';
import 'luxury_palette.dart';

class StitchTypography {
  static const List<String> kFontFallbacks = [
    'NotoSansDevanagari',
    'Roboto',
    'sans-serif',
  ];

  static TextTheme buildTextTheme({required bool isDark}) {
    final Color primaryColor = isDark ? LuxuryPalette.darkTextPrimary : LuxuryPalette.lightTextPrimary;
    final Color secondaryColor = isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary;
    final Color mutedColor = isDark ? LuxuryPalette.darkTextMuted : LuxuryPalette.lightTextMuted;

    return TextTheme(
      // Courtroom Headlines & Judgments
      displayLarge: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: -0.5,
        height: 1.45,
      ),
      displayMedium: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: -0.3,
        height: 1.45,
      ),
      displaySmall: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.40,
      ),

      // Pleading Titles & Section Benches
      titleLarge: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 16.5,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.1,
        height: 1.40,
      ),
      titleMedium: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.40,
      ),
      titleSmall: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        height: 1.35,
      ),

      // Legal Grounds & Body Arguments
      bodyLarge: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 12.5,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        height: 1.50,
      ),
      bodySmall: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 11.5,
        fontWeight: FontWeight.normal,
        color: mutedColor,
        height: 1.45,
      ),

      // Bench Tags, CNR Labels, Chips
      labelLarge: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 11.0,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontFamilyFallback: kFontFallbacks,
        fontSize: 10.0,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 0.3,
      ),
    );
  }

  static const List<String> fallbackFonts = kFontFallbacks;

  static TextStyle headline({Color color = LuxuryPalette.courtNavy, double size = 20.0, FontWeight weight = FontWeight.w700}) {
    return TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kFontFallbacks,
      fontSize: size,
      fontWeight: weight,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle title({Color color = LuxuryPalette.courtNavy, double size = 15.0, FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kFontFallbacks,
      fontSize: size,
      fontWeight: weight,
      height: 1.40,
      color: color,
    );
  }

  static TextStyle body({Color color = LuxuryPalette.lightTextPrimary, double size = 13.5, FontWeight weight = FontWeight.w400, double height = 1.45}) {
    return TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kFontFallbacks,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle label({Color color = LuxuryPalette.lightTextSecondary, double size = 11.5, FontWeight weight = FontWeight.w500}) {
    return TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: kFontFallbacks,
      fontSize: size,
      fontWeight: weight,
      height: 1.35,
      color: color,
    );
  }
}
