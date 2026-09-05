import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/verified_export_payload.dart';

class CourtPdfBuilder {
  static Future<Uint8List> generateLegalSizeCourtPetition(VerifiedExportPayload payload) async {
    final pdf = pw.Document();

    pw.Font ttfRegular;
    try {
      final fontData = await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf");
      ttfRegular = pw.Font.ttf(fontData);
    } catch (_) {
      ttfRegular = pw.Font.helvetica();
    }

    // Standard Legal Paper with Indian Court Binding Margins:
    // Left: 1.5 in (108 pt), Right: 0.75 in (54 pt), Top: 1.0 in (72 pt), Bottom: 1.0 in (72 pt)
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.only(
        left: 108.0, // Mandatory 1.5" Left Binding Space
        right: 54.0,
        top: 72.0,
        bottom: 72.0,
      ),
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfRegular),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            // 1. Court Hierarchy Header
            pw.Center(
              child: pw.Text(
                payload.courtHeaderHindi.toUpperCase(),
                style: pw.TextStyle(font: ttfRegular, fontSize: 13, lineSpacing: 1.4),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 14),

            // 2. Case Registration Number & Police Details
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'मुकदमा अपराध संख्या: ${payload.firNumber}\nथाना: ${payload.policeStation}\nजनपद: ${payload.district}',
                style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.3),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(height: 16),

            // 3. Litigants Title Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('राज्य (अभियोजन)', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
                pw.Text('...विपक्षी', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
              ],
            ),
            pw.Center(child: pw.Text('बनाम', style: pw.TextStyle(font: ttfRegular, fontSize: 11))),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${payload.accusedName} (आवेदक)', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
                pw.Text('...अभियुक्त/प्रार्थी', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 16),

            // 4. Petition Statutory Title
            pw.Center(
              child: pw.Text(
                'प्रार्थना पत्र अंतर्गत धारा 437/439 दंड प्रक्रिया संहिता (समतुल्य बी.एन.एस.एस.)',
                style: pw.TextStyle(font: ttfRegular, fontSize: 11.5, decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 14),

            // 5. Formal Opening
            pw.Text(
              'महोदय,\nआवेदक/अभियुक्त की ओर से निम्नलिखित सादर निवेदन प्रस्तुत है:-',
              style: pw.TextStyle(font: ttfRegular, fontSize: 11, lineSpacing: 1.4),
            ),
            pw.SizedBox(height: 10),

            // 6. Verified Grounded Paragraphs
            ...payload.verifiedGrounds.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final ground = entry.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$index. ', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.Expanded(
                      child: pw.Text(
                        ground,
                        style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.5),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 7. Verified Precedents Section
            if (payload.verifiedCitations.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'उद्धृत न्यायिक मिसालें (Verified Judicial Precedents):',
                style: pw.TextStyle(font: ttfRegular, fontSize: 11, decoration: pw.TextDecoration.underline),
              ),
              pw.SizedBox(height: 6),
              ...payload.verifiedCitations.map((cit) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6.0),
                    child: pw.Text('• $cit', style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.3)),
                  )),
            ],

            pw.SizedBox(height: 16),

            // 8. Prayer Clause
            pw.Text(
              'प्रार्थना (PRAYER):\n${payload.prayerText}',
              style: pw.TextStyle(font: ttfRegular, fontSize: 11, lineSpacing: 1.4),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 36),

            // 9. Advocate Signature Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('दिनांक: ${payload.filingDate.day}/${payload.filingDate.month}/${payload.filingDate.year}',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                    pw.Text('स्थान: ${payload.district}', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('द्वारा अधिवक्ता', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                    pw.SizedBox(height: 20),
                    pw.Text('(${payload.advocateName})', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.Text('बार काउंसिल संख्या: ${payload.barCouncilNumber}', style: pw.TextStyle(font: ttfRegular, fontSize: 9.5)),
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
