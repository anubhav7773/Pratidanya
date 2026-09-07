import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> loadFontForTest() async {
  final regData = File('assets/fonts/NotoSansDevanagari-Regular.ttf').readAsBytesSync();
  final boldData = File('assets/fonts/NotoSansDevanagari-Bold.ttf').readAsBytesSync();

  final loader = FontLoader('NotoSansDevanagari');
  loader.addFont(Future.value(ByteData.view(regData.buffer)));
  loader.addFont(Future.value(ByteData.view(boldData.buffer)));
  await loader.load();

  final robotoReg = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
  final robotoBold = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();
  final robotoLoader = FontLoader('Roboto');
  robotoLoader.addFont(Future.value(ByteData.view(robotoReg.buffer)));
  robotoLoader.addFont(Future.value(ByteData.view(robotoBold.buffer)));
  await robotoLoader.load();
}

Future<pw.Image> renderHindiTextToPdfImage(
  String text, {
  double fontSize = 11,
  bool isBold = false,
  TextAlign textAlign = TextAlign.left,
  double maxWidth = 450,
  double lineSpacing = 1.4,
}) async {
  final pixelRatio = 3.0; // 300+ DPI crispness
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final textSpan = TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      fontSize: fontSize * pixelRatio,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
      height: lineSpacing,
    ),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textAlign: textAlign,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(maxWidth: maxWidth * pixelRatio);
  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  final width = (textPainter.width).ceil().clamp(1, 10000);
  final height = (textPainter.height).ceil().clamp(1, 10000);

  final img = await picture.toImage(width, height);
  final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final imageBytes = pngBytes!.buffer.asUint8List();

  return pw.Image(
    pw.MemoryImage(imageBytes),
    width: width / pixelRatio,
    height: height / pixelRatio,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFontForTest();
  });

  test('Render full Devanagari petition text with Latin English fallback', () async {
    final pdf = pw.Document();

    final headerImg = await renderHindiTextToPdfImage(
      'न्यायालय मुख्य न्यायिक मजिस्ट्रेट / अपर मुख्य न्यायिक मजिस्ट्रेट, LUCKNOW',
      fontSize: 13,
      isBold: true,
      textAlign: TextAlign.center,
      maxWidth: 450,
    );

    final caseDetailsImg = await renderHindiTextToPdfImage(
      'मुकदमा अपराध संख्या: 36/2025\nथाना: kotawali nagar\nजनपद: lucknow',
      fontSize: 10.5,
      isBold: false,
      textAlign: TextAlign.right,
      maxWidth: 450,
    );

    final precedentImg = await renderHindiTextToPdfImage(
      'उद्धृत न्यायिक मिसालें (Verified Judicial Precedents):\n'
      '- राजू उर्फ रतन बनाम मध्य प्रदेश राज्य (उच्चतम न्यायालय (Supreme Court of India))\n'
      '- पेरुमल राजा उर्फ राजा बनाम राज्य (उच्चतम न्यायालय (Supreme Court of India))\n'
      '- त्रिम्बक बनाम मध्य प्रदेश राज्य (उच्चतम न्यायालय (Supreme Court of India))',
      fontSize: 10,
      isBold: false,
      textAlign: TextAlign.left,
      maxWidth: 450,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.legal,
        margin: const pw.EdgeInsets.all(54),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              headerImg,
              pw.SizedBox(height: 14),
              caseDetailsImg,
              pw.SizedBox(height: 20),
              precedentImg,
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final file = File('C:/Users/kshtr/.gemini/antigravity-ide/brain/4b4f252d-d917-4931-8210-e47609f394df/scratch/sample_hindi_petition.pdf');
    await file.writeAsBytes(pdfBytes);
    print('Saved sample with both NotoSansDevanagari and Roboto loaded');
  });
}
