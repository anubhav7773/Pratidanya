import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stitch_colors.dart';

class StitchTypography {
  static const List<String> fallbackFonts = [
    'NotoSansDevanagari',
    'Noto Sans Devanagari',
    'Mangal',
    'Arial Unicode MS',
    'sans-serif',
  ];

  static TextTheme textTheme([Color textColor = StitchColors.textPrimary]) {
    return TextTheme(
      // Court Case Headlines (e.g., 'मुकदमा अपराध संख्या 124/2026')
      displayLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        height: 1.45,
        letterSpacing: 0.15,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      // Section Titles (e.g., 'जमानत के विधिक आधार', 'अभियोजन की कमियां')
      titleLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        height: 1.40,
        letterSpacing: 0.1,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      titleMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.40,
        letterSpacing: 0.1,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      titleSmall: GoogleFonts.notoSansDevanagari(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        height: 1.40,
        letterSpacing: 0.1,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      // Legal Drafting Body (Verbatim Extracts, Case Diary Notes)
      bodyLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        height: 1.50, // Critical for preventing line-collision in dense Hindi paragraphs
        letterSpacing: 0.25,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      bodyMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.2,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      bodySmall: GoogleFonts.notoSansDevanagari(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.40,
        letterSpacing: 0.2,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      // Citations, Metadata Tags & Verification Chips
      labelLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.40,
        letterSpacing: 0.1,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      labelMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.2,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      labelSmall: GoogleFonts.notoSansDevanagari(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.2,
        color: textColor.withValues(alpha: 0.8),
      ).copyWith(fontFamilyFallback: fallbackFonts),
    );
  }

  // Quick style getters for inline usage
  static TextStyle headline({Color color = StitchColors.courtNavy, double size = 20.0, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: weight,
      height: 1.45,
      color: color,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }

  static TextStyle title({Color color = StitchColors.courtNavy, double size = 15.0, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: weight,
      height: 1.40,
      color: color,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }

  static TextStyle body({Color color = StitchColors.textPrimary, double size = 13.5, FontWeight weight = FontWeight.w400, double height = 1.45}) {
    return GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }

  static TextStyle label({Color color = StitchColors.textSecondary, double size = 11.5, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: weight,
      height: 1.35,
      color: color,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }
}
