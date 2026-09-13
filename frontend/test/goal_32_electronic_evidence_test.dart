import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/electronic_evidence_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/electronic_evidence_audit_screen.dart';

void main() {
  group('Goal 32: Section 63 BSA / Section 65B IEA Electronic Evidence Auditor Tests', () {
    final mockInadmissibleResultJson = {
      'case_id': 'TEST-EVID-63-1',
      'exhibit_mark': 'Ex. P-14',
      'admissibility_status': 'FATAL_DEFECT_INADMISSIBLE',
      'is_schedule_compliant': false,
      'is_hash_valid': false,
      'statutory_defects': [
        {
          'statutory_clause': 'धारा 63(4)(c) बी.एस.ए. 2023 सपठित अनुसूची (Schedule)',
          'governing_doctrine': 'सांविधिक प्रारूप का आज्ञापक अनुपालन',
          'severity': 'FATAL',
          'defect_description_hindi': 'प्रस्तुत प्रमाण पत्र भारतीय साक्ष्य अधिनियम 2023 की अनुसूची के विहित प्रारूप के अनुरूप नहीं है।',
          'trial_countermeasure': 'प्रारूप विचलन के आधार पर साक्ष्य प्रदर्श अंकित करने पर प्रारंभिक आपत्ति उठाएं।'
        },
        {
          'statutory_clause': 'धारा 63(4)(c) अनुसूची (भाग ख - विशेषज्ञ द्वारा भरा जाने वाला)',
          'governing_doctrine': 'क्रिप्टोग्राफिक व तकनीकी सत्यनिष्ठा',
          'severity': 'FATAL',
          'defect_description_hindi': 'प्रमाण पत्र के भाग "ख" का निष्पादन किसी साइबर अथवा फॉरेंसिक विशेषज्ञ द्वारा नहीं कराया गया है।',
          'trial_countermeasure': 'अन्वेषण अधिकारी की गवाही के समय भाग ख के अभाव को रिकॉर्ड पर अंकित कराएं।'
        }
      ],
      'actionable_courtroom_objection': 'प्रदर्श Ex. P-14 धारा 63 बी.एस.ए. 2023 के आज्ञापक प्रावधानों का घोर उल्लंघन है।',
      'written_objection_petition_draft': 'न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट, लखनऊ...\nआपत्ति पत्र विरुद्ध साक्ष्य में प्रदर्श Ex. P-14...',
      'cited_precedents': [
        {
          'case_title': 'अर्जुन पंडितराव खोतकर बनाम कैलाश कुशनराव गोरंट्याल (2020) 7 SCC 1',
          'citation': 'AIR 2020 SC 3406',
          'ratio_hindi': 'बिना विधिक प्रमाण पत्र के द्वितीयक इलेक्ट्रॉनिक साक्ष्य पूर्णतः अग्राह्य है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/47621.pdf'
        }
      ]
    };

    test('ElectronicEvidenceAuditResult deserializes JSON accurately', () {
      final result = ElectronicEvidenceAuditResult.fromJson(mockInadmissibleResultJson);

      expect(result.caseId, 'TEST-EVID-63-1');
      expect(result.exhibitMark, 'Ex. P-14');
      expect(result.admissibilityStatus, 'FATAL_DEFECT_INADMISSIBLE');
      expect(result.isScheduleCompliant, isFalse);
      expect(result.isHashValid, isFalse);
      expect(result.statutoryDefects.length, 2);

      final defect = result.statutoryDefects.first;
      expect(defect.severity, 'FATAL');
      expect(defect.statutoryClause, contains('63(4)(c)'));
      expect(result.citedPrecedents.length, 1);
      expect(result.citedPrecedents.first['citation'], 'AIR 2020 SC 3406');
    });

    testWidgets('ElectronicEvidenceAuditScreen renders input fields, checkboxes, and audit button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ElectronicEvidenceAuditScreen(
              caseId: 'CASE-EVID-99',
              accusedName: 'रोहित वर्मा',
              policeStation: 'हजरतगंज',
              district: 'लखनऊ',
            ),
          ),
        ),
      );

      // Verify Title
      expect(find.text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (Sec 63 BSA)'), findsOneWidget);

      // Verify BCI Disclaimer
      expect(find.textContaining('विधिक अस्वीकरण (BCI नियम 5)'), findsOneWidget);

      // Verify Form Elements
      expect(find.text('प्रदर्श / मार्क (Exhibit Mark)'), findsOneWidget);
      expect(find.text('डिजिटल साक्ष्य का प्रकार'), findsOneWidget);

      // Verify Checkboxes
      expect(find.text('क्या प्रमाण पत्र BSA 2023 की विहित अनुसूची प्रारूप में है?'), findsOneWidget);
      expect(find.text('भाग क (Part A) प्रस्तुतकर्ता द्वारा हस्ताक्षरित है?'), findsOneWidget);
      expect(find.text('भाग ख (Part B) साइबर / फॉरेंसिक विशेषज्ञ द्वारा निष्पादित है?'), findsOneWidget);

      // Verify Audit Action Button
      expect(find.text('प्रमाण पत्र की विधिक वैधता जांचें'), findsOneWidget);

      // Toggle first checkbox
      final checkboxFinder = find.byType(Checkbox).first;
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
      expect(checkboxWidget.value, isTrue);
    });
  });
}
