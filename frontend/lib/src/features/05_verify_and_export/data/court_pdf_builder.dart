import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/verified_export_payload.dart';
import 'devanagari_pdf_renderer.dart';

class CourtPdfBuilder {
  /// Loads TrueType Devanagari Fonts directly from asset bundle.
  static Future<Map<String, pw.Font>> _loadDevanagariFonts() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');

      return {
        'regular': pw.Font.ttf(regularData),
        'bold': pw.Font.ttf(boldData),
      };
    } catch (e) {
      throw StateError(
        'CRITICAL PDF FONT ERROR: NotoSansDevanagari TrueType font files could not be loaded from assets/fonts/. '
        'Verify that fonts are present in assets/fonts/ and declared in pubspec.yaml. Details: $e',
      );
    }
  }

  static Future<Uint8List> generateLegalSizeCourtPetition(VerifiedExportPayload payload) async {
    WidgetsFlutterBinding.ensureInitialized();
    final pdf = pw.Document();
    final fonts = await _loadDevanagariFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    // Standard Legal Paper with Indian Court Binding Margins:
    // Left: 1.5 in (108 pt), Right: 0.75 in (54 pt), Top: 1.0 in (72 pt), Bottom: 1.0 in (72 pt)
    // Usable width: 612 - 108 - 54 = 450 pt
    const double contentWidth = 450.0;

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.only(
        left: 108.0, // Mandatory 1.5" Left Binding Space
        right: 54.0,
        top: 72.0,
        bottom: 72.0,
      ),
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
        fontFallback: [pw.Font.helvetica()],
      ),
    );

    // Render all Devanagari sections using Flutter's HarfBuzz-backed TextPainter
    // for 100% correct glyph shaping, conjunct ligatures, and matra placement.
    final courtHeaderWidget = await DevanagariPdfRenderer.renderText(
      payload.courtHeaderHindi.toUpperCase(),
      fontSize: 13,
      isBold: true,
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final caseDetailsWidget = await DevanagariPdfRenderer.renderText(
      'मुकदमा अपराध संख्या: ${payload.firNumber}\nथाना: ${payload.policeStation}\nजनपद: ${payload.district}',
      fontSize: 10.5,
      textAlign: TextAlign.right,
      maxWidth: contentWidth,
    );

    final litigantsRow1 = await DevanagariPdfRenderer.renderBetweenRow(
      leftText: 'राज्य (अभियोजन)',
      rightText: '...विपक्षी',
      fontSize: 11,
      rowWidth: contentWidth,
    );

    final versusWidget = await DevanagariPdfRenderer.renderText(
      'बनाम',
      fontSize: 11,
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final litigantsRow2 = await DevanagariPdfRenderer.renderBetweenRow(
      leftText: '${payload.accusedName} (आवेदक)',
      rightText: '...अभियुक्त/प्रार्थी',
      fontSize: 11,
      rowWidth: contentWidth,
    );

    final petitionTitleWidget = await DevanagariPdfRenderer.renderText(
      'प्रार्थना पत्र अंतर्गत धारा 437/439 दंड प्रक्रिया संहिता (समतुल्य बी.एन.एस.एस.)',
      fontSize: 11.5,
      isBold: true,
      isUnderline: true,
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final formalOpeningWidget = await DevanagariPdfRenderer.renderText(
      'महोदय,\nआवेदक/अभियुक्त की ओर से निम्नलिखित सादर निवेदन प्रस्तुत है:-',
      fontSize: 11,
      lineSpacing: 1.4,
      maxWidth: contentWidth,
    );

    final List<pw.Widget> groundWidgets = [];
    for (int i = 0; i < payload.verifiedGrounds.length; i++) {
      final index = i + 1;
      final rawGround = payload.verifiedGrounds[i];
      final ground = rawGround
          .replaceAll(RegExp(r'^(?:विधिक\s*आधार\s*\d+\s*[\(\:\-–\.]?\s*|\d+[\.\)]\s*)'), '')
          .replaceAll(RegExp(r'\)$'), '')
          .trim();

      final groundWidget = await DevanagariPdfRenderer.renderText(
        '$index. $ground',
        fontSize: 10.5,
        lineSpacing: 1.5,
        textAlign: TextAlign.justify,
        maxWidth: contentWidth,
      );

      groundWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8.0),
          child: groundWidget,
        ),
      );
    }

    final List<pw.Widget> citationWidgets = [];
    if (payload.verifiedCitations.isNotEmpty) {
      citationWidgets.add(pw.SizedBox(height: 10));
      citationWidgets.add(
        await DevanagariPdfRenderer.renderText(
          'उद्धृत न्यायिक मिसालें (Verified Judicial Precedents):',
          fontSize: 11,
          isBold: true,
          isUnderline: true,
          maxWidth: contentWidth,
        ),
      );
      citationWidgets.add(pw.SizedBox(height: 6));
      for (final cit in payload.verifiedCitations) {
        citationWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6.0),
            child: await DevanagariPdfRenderer.renderText(
              '- $cit',
              fontSize: 10,
              lineSpacing: 1.3,
              maxWidth: contentWidth,
            ),
          ),
        );
      }
    }

    final prayerWidget = await DevanagariPdfRenderer.renderText(
      'प्रार्थना (PRAYER):\n${payload.prayerText}',
      fontSize: 11,
      lineSpacing: 1.4,
      textAlign: TextAlign.justify,
      maxWidth: contentWidth,
    );

    final dateLocationWidget = await DevanagariPdfRenderer.renderText(
      'दिनांक: ${payload.filingDate.day}/${payload.filingDate.month}/${payload.filingDate.year}\nस्थान: ${payload.district}',
      fontSize: 10,
      lineSpacing: 1.3,
      maxWidth: 200.0,
    );

    final advocateSignWidget = await DevanagariPdfRenderer.renderText(
      'द्वारा अधिवक्ता\n\n(${payload.advocateName})\nबार काउंसिल संख्या: ${payload.barCouncilNumber}',
      fontSize: 10,
      textAlign: TextAlign.center,
      maxWidth: 220.0,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            // 1. Court Hierarchy Header
            courtHeaderWidget,
            pw.SizedBox(height: 14),

            // 2. Case Registration Number & Police Details
            caseDetailsWidget,
            pw.SizedBox(height: 16),

            // 3. Litigants Title Block
            litigantsRow1,
            versusWidget,
            litigantsRow2,
            pw.SizedBox(height: 16),

            // 4. Petition Statutory Title
            petitionTitleWidget,
            pw.SizedBox(height: 14),

            // 5. Formal Opening
            formalOpeningWidget,
            pw.SizedBox(height: 10),

            // 6. Verified Grounded Paragraphs
            ...groundWidgets,

            // 7. Verified Precedents Section
            ...citationWidgets,

            pw.SizedBox(height: 16),

            // 8. Prayer Clause
            prayerWidget,
            pw.SizedBox(height: 36),

            // 9. Advocate Signature Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                dateLocationWidget,
                advocateSignWidget,
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateVakalatnamaPdf({
    required String courtName,
    required String firNumber,
    required String policeStation,
    required String district,
    required String accusedName,
    required List<String> underSections,
    required String advocateName,
    required String barCouncilNumber,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final pdf = pw.Document();
    final fonts = await _loadDevanagariFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    const double contentWidth = 450.0;

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.only(
        left: 108.0,
        right: 54.0,
        top: 72.0,
        bottom: 72.0,
      ),
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
        fontFallback: [pw.Font.helvetica()],
      ),
    );

    final titleWidget = await DevanagariPdfRenderer.renderText(
      'वकालतनामा (VAKALATNAMA)',
      fontSize: 16,
      isBold: true,
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final courtNameWidget = await DevanagariPdfRenderer.renderText(
      'न्यायालय: $courtName',
      fontSize: 12,
      isBold: true,
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final firDetailsWidget = await DevanagariPdfRenderer.renderText(
      'मु.अ.सं.: $firNumber\nथाना: $policeStation | जनपद: $district\nधाराएं: ${underSections.join(", ")}',
      fontSize: 10.5,
      lineSpacing: 1.3,
      textAlign: TextAlign.right,
      maxWidth: contentWidth,
    );

    final versusWidget = await DevanagariPdfRenderer.renderText(
      'राज्य बनाम $accusedName',
      fontSize: 13,
      isBold: true,
      maxWidth: contentWidth,
    );

    final poaHeaderWidget = await DevanagariPdfRenderer.renderText(
      'प्राधिकार पत्र (POWER OF ATTORNEY):',
      fontSize: 11,
      isBold: true,
      maxWidth: contentWidth,
    );

    final poaBodyWidget = await DevanagariPdfRenderer.renderText(
      'मैं/हम, उक्त मामले में अभियुक्त/प्रार्थी, एतद्द्वारा विद्वान अधिवक्ता श्री/सुश्री $advocateName '
      '(पंजीकरण संख्या: $barCouncilNumber) को इस वाद में अपनी पैरवी, बहस, प्रार्थना पत्र प्रस्तुत करने, '
      'दस्तावेज दाखिल करने, जमानत स्वीकार कराने एवं अन्य सभी आवश्यक विधिक कार्यवाहियों हेतु अपना अधिवक्ता नियुक्त करता/करती हूँ। '
      'अधिवक्ता महोदय द्वारा की गई प्रत्येक विधिक कार्यवाही मुझ पर पूर्ण रूप से बाध्यकारी होगी।',
      fontSize: 10.5,
      lineSpacing: 1.4,
      textAlign: TextAlign.justify,
      maxWidth: contentWidth,
    );

    final accusedSignWidget = await DevanagariPdfRenderer.renderText(
      'हस्ताक्षर / अंगूठा निशानी अभियुक्त\n\n($accusedName)',
      fontSize: 10,
      textAlign: TextAlign.center,
      maxWidth: 200.0,
    );

    final advocateAcceptWidget = await DevanagariPdfRenderer.renderText(
      'स्वीकृत एवं वकालत दाखिल\n\n$advocateName (अधिवक्ता)\nबार काउंसिल संख्या: $barCouncilNumber',
      fontSize: 10,
      textAlign: TextAlign.center,
      maxWidth: 220.0,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            titleWidget,
            courtNameWidget,
            pw.SizedBox(height: 14),
            firDetailsWidget,
            pw.SizedBox(height: 14),
            versusWidget,
            pw.Divider(height: 16),
            poaHeaderWidget,
            pw.SizedBox(height: 8),
            poaBodyWidget,
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                accusedSignWidget,
                advocateAcceptWidget,
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
