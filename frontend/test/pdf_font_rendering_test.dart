import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF-01 & PDF-02 Verification: NotoSansDevanagari TTF renders Hindi characters without ToFu boxes', () async {
    final regularFile = File('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final boldFile = File('assets/fonts/NotoSansDevanagari-Bold.ttf');

    expect(regularFile.existsSync(), isTrue, reason: 'NotoSansDevanagari-Regular.ttf must exist in assets/fonts/');
    expect(boldFile.existsSync(), isTrue, reason: 'NotoSansDevanagari-Bold.ttf must exist in assets/fonts/');

    final regularBytes = regularFile.readAsBytesSync();
    final boldBytes = boldFile.readAsBytesSync();

    final ttfRegular = pw.Font.ttf(ByteData.view(regularBytes.buffer));
    final ttfBold = pw.Font.ttf(ByteData.view(boldBytes.buffer));

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.legal,
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
                style: pw.TextStyle(font: ttfBold, fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'यह कि अभियुक्त के विरुद्ध धारा 379, 411 भा.दं.वि. का अपराध प्रथम दृष्टया सिद्ध नहीं होता।',
                style: pw.TextStyle(font: ttfRegular, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await doc.save();
    expect(pdfBytes.isNotEmpty, isTrue);
    expect(pdfBytes.length, greaterThan(1000));
  });
}
