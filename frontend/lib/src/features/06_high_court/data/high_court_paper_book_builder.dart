import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/high_court_models.dart';

class HighCourtPaperBookBuilder {
  /// Builds a complete High Court Paper-Book in accordance with Allahabad High Court Rules:
  /// - Mandatory 1.75 Inch (126 pt) Left Binding Margin for heavy cord thread binding.
  /// - Formal Table of Contents / Index Page with columnated Item, Description, Paragraph & Page references.
  /// - Urgent Listing Application, Memo of Appeal/Revision, Sec 389 Stay Petition, Sec 5 Delay Suite.
  /// Loads TrueType Devanagari Fonts for High Court Paper-Book compilation.
  /// Fixes PDF-02: Missing font asset caused Helvetica fallback and unreadable petitions.
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
        'CRITICAL HIGH COURT PDF FONT ERROR: NotoSansDevanagari font assets missing. '
        'Run bash scripts/download_fonts.sh to install font binaries. Details: $e',
      );
    }
  }

  static Future<Uint8List> generateHighCourtPaperBook({
    required HighCourtAppealSuite suite,
    required String advocateName,
    required String barCouncilNumber,
    required String chamberAddress,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadDevanagariFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    // Allahabad High Court Binding Standard: 1.75" Left (126 pt), 0.75" Right (54 pt), 1" Top/Bottom (72 pt)
    final hcPageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.only(
        left: 126.0, // Strictly 1.75 Inches Left Binding Margin
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

    // =========================================================================
    // SECTION 1: MANDATORY HIGH COURT INDEX / TABLE OF CONTENTS
    // =========================================================================
    pdf.addPage(
      pw.Page(
        pageTheme: hcPageTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  suite.courtTitleBlock.toUpperCase(),
                  style: pw.TextStyle(font: ttfRegular, fontSize: 13, lineSpacing: 1.4),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'विषय सूची (INDEX)',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 14, decoration: pw.TextDecoration.underline),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  '${suite.memoTitleHindi}\n${suite.trialReferenceBlock}',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.3),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 16),

              // Formal Court Index Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2), // क्र.सं.
                  1: pw.FlexColumnWidth(6.0), // दस्तावेज विवरण
                  2: pw.FlexColumnWidth(2.0), // अनुलग्नक
                  3: pw.FlexColumnWidth(1.8), // पृष्ठ संख्या
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('क्र.सं.', isHeader: true, ttf: ttfRegular),
                      _buildTableCell('दस्तावेज का विवरण (Particulars)', isHeader: true, ttf: ttfRegular),
                      _buildTableCell('अनुलग्नक (Annexure)', isHeader: true, ttf: ttfRegular),
                      _buildTableCell('पृष्ठ सं.', isHeader: true, ttf: ttfRegular),
                    ],
                  ),
                  _buildIndexRow('1.', 'अति-आवश्यक सुनवाई प्रार्थना पत्र (Urgent Application)', '-', '1 - 2', ttfRegular),
                  _buildIndexRow('2.', 'दांडिक अपील / पुनरीक्षण मेमो (Memo of Appeal)', '-', '3 - 8', ttfRegular),
                  _buildIndexRow('3.', 'दंडादेश स्थगन एवं जमानत प्रार्थना पत्र (Sec 389 Application)', '-', '9 - 11', ttfRegular),
                  _buildIndexRow('4.', 'शपथ पत्र के समर्थन में सजा स्थगन प्रार्थना पत्र', '-', '12 - 14', ttfRegular),
                  if (suite.delayGrounds != null) ...[
                    _buildIndexRow('5.', 'प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम (विलंब माफी)', '-', '15 - 17', ttfRegular),
                    _buildIndexRow('6.', 'शपथ पत्र के समर्थन में विलंब माफी प्रार्थना पत्र', '-', '18 - 20', ttfRegular),
                  ],
                  _buildIndexRow(
                    suite.delayGrounds != null ? '7.' : '5.',
                    'अवर न्यायालय के आक्षेपित निर्णय एवं दंडादेश की प्रमाणित प्रति',
                    'Annexure No. 1',
                    '21 Onwards',
                    ttfRegular,
                  ),
                  _buildIndexRow(
                    suite.delayGrounds != null ? '8.' : '6.',
                    'वकालतनामा (Vakalatnama)',
                    '-',
                    'End',
                    ttfRegular,
                  ),
                ],
              ),
              pw.Spacer(),

              // Advocate Signature & Identification Block
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('हस्ताक्षर अधिवक्ता अपीलार्थी', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.SizedBox(height: 20),
                    pw.Text('($advocateName)', style: pw.TextStyle(font: ttfRegular, fontSize: 11)),
                    pw.Text('बार काउंसिल पंजीकरण संख्या: $barCouncilNumber', style: pw.TextStyle(font: ttfRegular, fontSize: 9.5)),
                    pw.Text(chamberAddress, style: pw.TextStyle(font: ttfRegular, fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // SECTION 2: MEMO OF APPEAL / REVISION (HIGH COURT PETITION)
    // =========================================================================
    pdf.addPage(
      pw.MultiPage(
        pageTheme: hcPageTheme,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                suite.courtTitleBlock.toUpperCase(),
                style: pw.TextStyle(font: ttfRegular, fontSize: 13, lineSpacing: 1.4),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                suite.memoTitleHindi,
                style: pw.TextStyle(font: ttfRegular, fontSize: 12, decoration: pw.TextDecoration.underline),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),

            // Trial Reference Sub-block
            pw.Container(
              padding: const pw.EdgeInsets.all(8.0),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
              child: pw.Text(
                suite.trialReferenceBlock,
                style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.3),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 14),

            pw.Text(
              'महोदय,\nअपीलार्थी/आवेदक की ओर से आक्षेपित निर्णय एवं दंडादेश के विरुद्ध निम्नलिखित विधिक आधार प्रस्तुत हैं:-',
              style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.4),
            ),
            pw.SizedBox(height: 10),

            // Numbered High Court Grounds
            ...suite.grounds.map((g) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${g.groundNumber}. ', style: pw.TextStyle(font: ttfRegular, fontSize: 10.5)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '[${g.groundHeading}]',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, decoration: pw.TextDecoration.underline),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            g.groundTextHindi,
                            style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.45),
                            textAlign: pw.TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Cited High Court / Supreme Court Precedents Section
            if (suite.citedPrecedents.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'उद्धृत न्यायिक दृष्टांत (Cited Precedents):',
                style: pw.TextStyle(font: ttfRegular, fontSize: 11, decoration: pw.TextDecoration.underline),
              ),
              pw.SizedBox(height: 6),
              ...suite.citedPrecedents.map((p) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6.0),
                    child: pw.Text(
                      '• ${p.caseTitle} (${p.courtName}) - "${p.quotedPassage}"',
                      style: pw.TextStyle(font: ttfRegular, fontSize: 9.5, lineSpacing: 1.3),
                    ),
                  )),
            ],

            pw.SizedBox(height: 14),

            // Final Relief Prayer Clause
            pw.Text(
              'प्रार्थना (PRAYER):\n${suite.finalReliefPrayer}',
              style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.4),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 24),
            _buildAdvocateSignature(advocateName, barCouncilNumber, ttfRegular),
          ];
        },
      ),
    );

    // =========================================================================
    // SECTION 3: SECTION 389 CrPC / BNSS 430 SENTENCE SUSPENSION SUITE
    // =========================================================================
    if (suite.suspensionGrounds != null) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: hcPageTheme,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  suite.courtTitleBlock.toUpperCase(),
                  style: pw.TextStyle(font: ttfRegular, fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'प्रार्थना पत्र अंतर्गत धारा 389(1) दंड प्रक्रिया संहिता / BNSS 430\n(दंडादेश के स्थगन एवं अंतरिम जमानत हेतु)',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 11.5, decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 14),

              ...suite.suspensionGrounds!.asMap().entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${e.key + 1}. ', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                      pw.Expanded(
                        child: pw.Text(
                          e.value,
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.4),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 12),
              pw.Text(
                'अंतरिम प्रार्थना (Interim Prayer):\n${suite.suspensionInterimPrayer ?? ""}',
                style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.4),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 20),
              _buildAdvocateSignature(advocateName, barCouncilNumber, ttfRegular),
            ];
          },
        ),
      );
    }

    // =========================================================================
    // SECTION 4: SECTION 5 LIMITATION ACT DELAY CONDONATION SUITE
    // =========================================================================
    if (suite.delayGrounds != null) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: hcPageTheme,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम (Limitation Act, 1963)',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 12, decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),

              ...suite.delayGrounds!.asMap().entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${e.key + 1}. ', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                      pw.Expanded(
                        child: pw.Text(
                          e.value,
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10, lineSpacing: 1.4),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 10),
              pw.Text(
                'प्रार्थना:\n${suite.delayPrayerText ?? ""}',
                style: pw.TextStyle(font: ttfRegular, fontSize: 10.5, lineSpacing: 1.4),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 20),
              _buildAdvocateSignature(advocateName, barCouncilNumber, ttfRegular),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, required pw.Font ttf}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: ttf,
          fontSize: isHeader ? 9.5 : 9.0,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _buildIndexRow(String sno, String desc, String annex, String page, pw.Font ttf) {
    return pw.TableRow(
      children: [
        _buildTableCell(sno, ttf: ttf),
        _buildTableCell(desc, ttf: ttf),
        _buildTableCell(annex, ttf: ttf),
        _buildTableCell(page, ttf: ttf),
      ],
    );
  }

  static pw.Widget _buildAdvocateSignature(String name, String barNo, pw.Font ttf) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('द्वारा अधिवक्ता', style: pw.TextStyle(font: ttf, fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Text('($name)', style: pw.TextStyle(font: ttf, fontSize: 10.5)),
          pw.Text('बार काउंसिल संख्या: $barNo', style: pw.TextStyle(font: ttf, fontSize: 9)),
        ],
      ),
    );
  }
}
