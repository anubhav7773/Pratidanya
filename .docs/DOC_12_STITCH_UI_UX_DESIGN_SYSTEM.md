================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-12
MODULE         : STITCH UI/UX DESIGN SYSTEM, DEVANAGARI TOKENS & COURT LAYOUTS
TARGET RUNTIME : Flutter 3.19+ (Material 3 Engine / Impeller Canvas)
DESIGN SYSTEM  : Stitch Design System (Adapted for Subordinate Court Decorum)
STANDARDS      : WCAG AAA Contrast (7:1) | Indian Court Legal Paper Standards
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. DESIGN PHILOSOPHY & SUBORDINATE COURT REALITIES
District Court lawyers din bhar do extreme physical environments ke beech switch karte hain:

Bright, Glaring Sunlight: Open court corridors, bar library lawns, aur tapish-bhari police chaukis jahan low-contrast UI bilkul unreadable ho jaati hai.

Dim, Fluorescent Chambers: Raat ke waqt purane court chambers jahan continuous typing aur reading se eye-strain hota hai.

┌────────────────────────────────────────────────────────────────────────┐
│                   STITCH DESIGN SYSTEM PILLARS                         │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Zero-Distraction Decorum : Sober legal palette (Navy, Slate, Cream) │
│ 2. WCAG AAA Contrast        : 7:1 minimum contrast ratio for text      │
│ 3. Devanagari Integrity     : 1.45 line-height (Zero matra clipping)   │
│ 4. Deterministic Print Layout: 1.5" left margin for green legal paper  │
└────────────────────────────────────────────────────────────────────────┘
2. DESIGN TOKENS SPECIFICATION
A. Color Palette (Light & Chamber Dark Mode)
Dart
// lib/src/core/theme/stitch_colors.dart
import 'package:flutter/material.dart';

class StitchColors {
  // Institutional Palette (Light Mode)
  static const Color courtNavy = Color(0xFF0A192F);       // Primary Headers & AppBars
  static const Color chamberSlate = Color(0xFF1E293B);   // Primary Surface & Cards
  static const Color legalParchment = Color(0xFFF8FAFC); // High-Legibility Background
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Chamber Dark Mode (Night Research Palette)
  static const Color darkCanvas = Color(0xFF0F172A);      // Deep Slate Canvas
  static const Color darkSurface = Color(0xFF1E293B);     // Elevated Card Surface
  static const Color darkSurfaceVariant = Color(0xFF334155);

  // Statutory Verification Tokens
  static const Color verifiedGreen = Color(0xFF166534);  // Verified Citations (Dark Emerald)
  static const Color verifiedGreenBg = Color(0xFFDCFCE7);
  static const Color unverifiedAmber = Color(0xFF9A3412);// Gate Pending (Deep Amber)
  static const Color unverifiedAmberBg = Color(0xFFFEF3C7);
  static const Color alertCrimson = Color(0xFF991B1B);   // Statutory Breach / Hallucination
  static const Color alertCrimsonBg = Color(0xFFFEE2E2);

  // Muted & Structural Tokens
  static const Color borderSubtle = Color(0xFFCBD5E1);
  static const Color borderMedium = Color(0xFF94A3B8);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
}
B. Typography Tokens & Scaled Hierarchy
Devanagari script ke vertical vowel signs (ि, ी, ु, ू) aur top bindu (ं) standard Android system fonts par katne se rokne ke liye vertical line-height multiplier 1.40x se 1.50x hona anivarya hai:

Dart
// lib/src/core/theme/stitch_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stitch_colors.dart';

class StitchTypography {
  static const List<String> fallbackFonts = [
    'Noto Sans Devanagari',
    'Mangal',
    'Arial Unicode MS',
    'sans-serif',
  ];

  static TextTheme textTheme(Color textColor) {
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
        height: 1.35,
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

      // Citations, Metadata Tags & Verification Chips
      labelLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.1,
        color: textColor,
      ).copyWith(fontFamilyFallback: fallbackFonts),

      labelSmall: GoogleFonts.notoSansDevanagari(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 1.30,
        letterSpacing: 0.2,
        color: textColor.withOpacity(0.8),
      ).copyWith(fontFamilyFallback: fallbackFonts),
    );
  }
}
C. 4px / 8px Grid & Elevation Hierarchy
Spacing Scale:

xxs: 4.0 px (Tight tag padding)

xs: 8.0 px (Standard chip and list separation)

sm: 12.0 px (Form inner padding)

md: 16.0 px (Standard container margin)

lg: 24.0 px (Section breaks)

xl: 32.0 px (Court draft header spacing)

3. SPECIALIZED LEGAL UI COMPONENTS
A. Substantive Statute Chip Selector (BNS vs. IPC Switcher)
District court criminal cases transition phase mein hain (Purane cases IPC/CrPC mein hain, naye BNS/BNSS mein). Single tap se criminal statute switch karne ka component:

Dart
// lib/src/shared/components/statute_selector_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

enum StatuteSystem { hybrid, bnsBnss, ipcCrpc }

class StatuteSelectorBar extends StatelessWidget {
  final StatuteSystem selectedSystem;
  final ValueChanged<StatuteSystem> onSystemChanged;

  const StatuteSelectorBar({
    super.key,
    required this.selectedSystem,
    required this.onSystemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: StitchColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildOption(
            title: 'हाइब्रिड (दोनों)',
            system: StatuteSystem.hybrid,
            isSelected: selectedSystem == StatuteSystem.hybrid,
          ),
          _buildOption(
            title: 'BNS / BNSS',
            system: StatuteSystem.bnsBnss,
            isSelected: selectedSystem == StatuteSystem.bnsBnss,
          ),
          _buildOption(
            title: 'IPC / CrPC',
            system: StatuteSystem.ipcCrpc,
            isSelected: selectedSystem == StatuteSystem.ipcCrpc,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required StatuteSystem system,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onSystemChanged(system),
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? StitchColors.courtNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : StitchColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
B. High-Contrast Devanagari Form Input (Conjunct Aware)
Complex Hindi inputs mein spell-check highlights aur autofocus glitches se bachane ke liye optimized textfield:

Dart
// lib/src/shared/components/stitch_hindi_text_field.dart
import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

class StitchHindiTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const StitchHindiTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: StitchColors.courtNavy,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: StitchColors.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(color: StitchColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(color: StitchColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(color: StitchColors.courtNavy, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(color: StitchColors.alertCrimson),
            ),
          ),
        ),
      ],
    );
  }
}
C. Case Stage Progress Indicator (Criminal Docket Steps)
Criminal trial ke 5 standard stages ko track karne wala horizontal indicator:

[ रिमांड (Remand) ] ➔ [ जमानत (Bail) ] ➔ [ आरोप पत्र (Chargesheet) ] ➔ [ आरोप विरचन (Charges) ] ➔ [ साक्ष्य (Evidence) ]
Dart
// lib/src/shared/components/criminal_stage_stepper.dart
import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

class CriminalStageStepper extends StatelessWidget {
  final String currentStage; // 'REMAND', 'BAIL', 'CHARGESHEET', 'CHARGES_FRAMED', 'EVIDENCE'

  static const List<Map<String, String>> stages = [
    {'key': 'REMAND', 'label': 'रिमांड'},
    {'key': 'BAIL', 'label': 'जमानत'},
    {'key': 'CHARGESHEET', 'label': 'आरोप पत्र'},
    {'key': 'CHARGES_FRAMED', 'label': 'आरोप तय'},
    {'key': 'EVIDENCE', 'label': 'साक्ष्य'},
  ];

  const CriminalStageStepper({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final currentIndex = stages.indexWhere((s) => s['key'] == currentStage);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Colors.white,
      child: Row(
        children: List.generate(stages.length * 2 - 1, (index) {
          if (index.isOdd) {
            final prevStageIndex = index ~/ 2;
            final isPassed = prevStageIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 2.0,
                color: isPassed ? StitchColors.courtNavy : StitchColors.borderSubtle,
              ),
            );
          }

          final stageIndex = index ~/ 2;
          final isCompleted = stageIndex < currentIndex;
          final isCurrent = stageIndex == currentIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? StitchColors.courtNavy
                      : (isCompleted ? StitchColors.verifiedGreen : Colors.white),
                  border: Border.all(
                    color: isCurrent || isCompleted
                        ? StitchColors.courtNavy
                        : StitchColors.borderSubtle,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${stageIndex + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : StitchColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stages[stageIndex]['label']!,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? StitchColors.courtNavy : StitchColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
4. DETERMINISTIC COURT-READY PRINT SPECIFICATION (1.5" LEFT MARGIN)
Indian District Courts aur High Courts mein petitions aur bail applications standard Legal Paper (8.5" x 14") ya A4 Paper (8.27" x 11.69") par file hoti hain. Court rules ke anusar:

Left Margin: Strictly 1.5 Inches (108 Points / 38.1 mm) — Yeh space court reader aur munsif dwara file ko thread se bind/tag karne ke liye chhodna anivarya hota hai.

Top & Bottom Margin: 1.0 Inch (72 Points).

Right Margin: 0.75 Inch (54 Points).

Line Spacing: Double Spacing (1.5 se 2.0) with Justified Alignment.

Formatted Legal Draft PDF Generator (court_pdf_builder.dart)
Dart
// lib/src/features/05_verify_and_export/data/court_pdf_builder.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/verified_export_payload.dart';

class CourtPdfBuilder {
  static Future<Uint8List> generateLegalSizeCourtPetition(VerifiedExportPayload payload) async {
    final pdf = pw.Document();

    // Load Noto Sans Devanagari font for PDF canvas
    final fontData = await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/NotoSansDevanagari-Bold.ttf");
    final ttfRegular = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    // Standard Legal Paper with Court Filing Margins:
    // Left: 1.5 in (108 pt), Right: 0.75 in (54 pt), Top: 1.0 in (72 pt), Bottom: 1.0 in (72 pt)
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.only(
        left: 108.0,  // Mandatory 1.5" Filing Margin
        right: 54.0,
        top: 72.0,
        bottom: 72.0,
      ),
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            // 1. Court Hierarchy Header (Centered)
            pw.Center(
              child: pw.Text(
                payload.courtHeaderHindi.toUpperCase(),
                style: pw.TextStyle(font: ttfBold, fontSize: 13, lineSpacing: 1.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Case Registration Number
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'मुकदमा अपराध संख्या: ${payload.firNumber}\nथाना: ${payload.policeStation}\nजिला: ${payload.district}',
                style: pw.TextStyle(font: ttfRegular, fontSize: 11, lineSpacing: 1.3),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(height: 16),

            // 3. Parties Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('राज्य (अभियोजन)', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                pw.Text('...विपक्षी', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
              ],
            ),
            pw.Center(child: pw.Text('बनाम', style: pw.TextStyle(font: ttfBold, fontSize: 11))),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${payload.accusedName} (आवेदक)', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                pw.Text('...अभियुक्त/प्रार्थी', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 16),

            // 4. Petition Title
            pw.Center(
              child: pw.Text(
                'प्रार्थना पत्र अंतर्गत धारा 437/439 दंड प्रक्रिया संहिता (या बी.एन.एस.एस.)',
                style: pw.TextStyle(font: ttfBold, fontSize: 12, decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 14),

            // 5. Humble Submission
            pw.Text(
              'महोदय,\nआवेदक/अभियुक्त की ओर से निम्नलिखित सादर निवेदन प्रस्तुत है:-',
              style: pw.TextStyle(font: ttfRegular, fontSize: 11.5, lineSpacing: 1.4),
            ),
            pw.SizedBox(height: 10),

            // 6. Numbered Grounds for Bail (Grounded Verbatim Paragraphs)
            ...payload.verifiedGrounds.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final ground = entry.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$index. ', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                    pw.Expanded(
                      child: pw.Text(
                        ground,
                        style: pw.TextStyle(font: ttfRegular, fontSize: 11, lineSpacing: 1.5),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 14),

            // 7. Prayer Clause
            pw.Text(
              'प्रार्थना (PRAYER):\nअतः माननीय न्यायालय से सादर प्रार्थना है कि न्यायहित में आवेदक/अभियुक्त '
              'को विचारण के दौरान जमानत पर रिहा करने की कृपा की जाए।',
              style: pw.TextStyle(font: ttfBold, fontSize: 11.5, lineSpacing: 1.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 36),

            // 8. Advocate Signature Block (Court Filing Convention)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('दिनांक: ________________', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.Text('स्थान: ${payload.district}', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('द्वारा अधिवक्ता', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.SizedBox(height: 24),
                    pw.Text('(${payload.advocateName})', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                    pw.Text('बार काउंसिल संख्या: ${payload.barCouncilNumber}', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
5. APP-WIDE THEME DEFINITION (Material 3)
Dart
// lib/src/core/theme/stitch_theme.dart
import 'package:flutter/material.dart';
import 'stitch_colors.dart';
import 'stitch_typography.dart';

class StitchTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
      ),
      cardTheme: CardTheme(
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
      ),
      cardTheme: CardTheme(
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
6. ANTIGRAVITY NON-NEGOTIABLE DESIGN CHECKLIST (DOC-12)
Antigravity UI code generate karte waqt in exact visual rules ko enforce karega:

[ ] Base typography line height for Devanagari text must never fall below 1.40 (Prevents matra clipping).

[ ] Printable PDF document layouts must strictly maintain a 1.5-inch left margin (left: 108.0) to satisfy district court filing and binding standards.

[ ] No neon, bright violet, or playful fonts; use strictly sober StitchColors.courtNavy, StitchColors.chamberSlate, and StitchColors.legalParchment.

[ ] High contrast WCAG AAA (7:1 text-to-background contrast) must be preserved in both Light and Chamber Dark modes.

[ ] Form text fields must use StitchHindiTextField with explicit text sanitization and conjunct support.