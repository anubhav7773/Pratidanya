import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test TextPainter and toImage in flutter_test', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: const TextSpan(
        text: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ\nप्रार्थना पत्र अंतर्गत धारा 437/439 दंड प्रक्रिया संहिता',
        style: TextStyle(fontSize: 14, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: 600);
    painter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 200);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    expect(byteData, isNotNull);
    expect(byteData!.lengthInBytes, greaterThan(100));
    print('Rendered image bytes: ${byteData.lengthInBytes}');
  });
}
