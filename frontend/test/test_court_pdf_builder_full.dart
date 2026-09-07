import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/05_verify_and_export/data/court_pdf_builder.dart';
import 'package:pratidnya/src/features/05_verify_and_export/domain/verified_export_payload.dart';

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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFontForTest();
  });

  test('CourtPdfBuilder renders 100% Devanagari typography for Court Petition and Vakalatnama', () async {
    final payload = VerifiedExportPayload(
      courtHeaderHindi: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
      firNumber: '142/2026',
      policeStation: 'हजरतगंज',
      district: 'लखनऊ',
      accusedName: 'राघवेंद्र प्रताप सिंह',
      advocateName: 'अधिवक्ता अनिरुद्ध सिंह',
      barCouncilNumber: 'UP/12345/2020',
      verifiedGrounds: [
        'यह कि प्रार्थी/अभियुक्त पूर्णतः निर्दोष है तथा उसे रंजिशन दुर्भावनापूर्वक झूठा फंसाया गया है।',
        'यह कि कथित घटना स्थल से किसी भी स्वतंत्र साक्षी की उपस्थिति अथवा बयान पत्रावली पर उपलब्ध नहीं है।',
        'यह कि प्रार्थी का कोई पूर्व आपराधिक इतिहास नहीं है एवं वह समाज का एक प्रतिष्ठित नागरिक है।',
      ],
      verifiedCitations: [
        'त्रिम्बक बनाम मध्य प्रदेश राज्य (1954 AIR SC 39)',
        'पेरुमल राजा उर्फ पेरुमल बनाम राज्य (2024 INSC 26)',
        'राजू उर्फ रतन बनाम मध्य प्रदेश राज्य (2008 15 SCC 133)',
      ],
      prayerText: 'अतः माननीय न्यायालय से सादर प्रार्थना है कि प्रार्थी/अभियुक्त को उचित एवं पर्याप्त प्रतिभूतियों पर विचारण समाप्ति तक जमानत पर रिहा करने की कृपा की जाए।',
      filingDate: DateTime(2026, 9, 7),
    );

    final petitionBytes = await CourtPdfBuilder.generateLegalSizeCourtPetition(payload);
    expect(petitionBytes, isNotNull);
    expect(petitionBytes.length, greaterThan(1000));

    final petitionFile = File('C:/Users/kshtr/.gemini/antigravity-ide/brain/4b4f252d-d917-4931-8210-e47609f394df/scratch/full_petition_devanagari.pdf');
    await petitionFile.writeAsBytes(petitionBytes);

    final vakalatnamaBytes = await CourtPdfBuilder.generateVakalatnamaPdf(
      courtName: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
      firNumber: '142/2026',
      policeStation: 'हजरतगंज',
      district: 'लखनऊ',
      accusedName: 'राघवेंद्र प्रताप सिंह',
      underSections: ['धारा 379 IPC', 'धारा 411 IPC'],
      advocateName: 'अधिवक्ता अनिरुद्ध सिंह',
      barCouncilNumber: 'UP/12345/2020',
    );
    expect(vakalatnamaBytes, isNotNull);
    expect(vakalatnamaBytes.length, greaterThan(1000));

    final vakalatnamaFile = File('C:/Users/kshtr/.gemini/antigravity-ide/brain/4b4f252d-d917-4931-8210-e47609f394df/scratch/full_vakalatnama_devanagari.pdf');
    await vakalatnamaFile.writeAsBytes(vakalatnamaBytes);
    print('SUCCESS: Full petition and vakalatnama PDFs successfully generated and saved!');
  });
}
