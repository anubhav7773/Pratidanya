import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/07_specialized_acts/domain/specialized_act_models.dart';
import 'package:pratidnya/src/features/07_specialized_acts/presentation/screens/ndps_compliance_screen.dart';
import 'package:pratidnya/src/features/07_specialized_acts/presentation/screens/pocso_age_audit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 16: Specialized Criminal Acts Domain Model Tests', () {
    test('NdpsComplianceResult deserializes and exposes statutory attributes', () {
      final json = {
        'case_id': 'test-case-uuid-1',
        'substance_name': 'Ganja',
        'quantity_category': 'COMMERCIAL_QUANTITY',
        'is_section_37_bar_applicable': true,
        'section_50_compliance_status': 'FATAL_DEFECT',
        'detected_procedural_defects': [
          'धारा 50 का पूर्ण उल्लंघन: व्यक्तिगत तलाशी से पूर्व अभियुक्त को कोई विधिक नोटिस नहीं दिया गया।',
          'तीसरा अवैध विकल्प: नोटिस में पुलिस अधिकारी द्वारा स्वयं तलाशी लेने का विकल्प दिया गया।'
        ],
        'tailored_bail_grounds': [
          'यह कि धारा 50 एन.डी.पी.एस. अधिनियम के आज्ञापक प्रावधानों का पूर्ण उल्लंघन किया गया है।',
          'यह कि धारा 52A के तहत नमूने न्यायिक मजिस्ट्रेट के समक्ष प्रमाणित नहीं कराए गए।'
        ],
        'cited_supreme_court_precedents': [
          {
            'case_title': 'राजस्थान राज्य बनाम परमानंद एवं अन्य (2014) 5 SCC 345',
            'ratio': 'धारा 50 एन.डी.पी.एस. अधिनियम के तहत अभियुक्त को तीसरा विकल्प देना संपूर्ण जब्ती को अवैध बनाता है।',
            'citation_url': 'https://main.sci.gov.in/judgment/judis/41285.pdf'
          }
        ]
      };

      final result = NdpsComplianceResult.fromJson(json);
      expect(result.caseId, 'test-case-uuid-1');
      expect(result.substanceName, 'Ganja');
      expect(result.quantityCategory, 'COMMERCIAL_QUANTITY');
      expect(result.isSection37BarApplicable, isTrue);
      expect(result.section50ComplianceStatus, 'FATAL_DEFECT');
      expect(result.detectedProceduralDefects.length, 2);
      expect(result.tailoredBailGrounds.length, 2);
      expect(result.citedSupremeCourtPrecedents.length, 1);
      expect(result.citedSupremeCourtPrecedents.first['case_title'], contains('परमानंद'));
    });

    test('PocsoAgeEvaluationResult deserializes and verifies Sec 94 JJ Act attributes', () {
      final json = {
        'case_id': 'test-case-uuid-2',
        'statutory_tier_applicable': 'TIER_3_OSSIFICATION',
        'computed_age_at_incident_years': 20.0,
        'is_majority_probable': true,
        'age_determination_analysis_hindi': 'धारा 94(2)(iii) मेडिकल बोर्ड अस्थि परीक्षण: रेडियोलॉजिकल आयु 16.0-18.0 वर्ष पाई गई। 2 वर्ष के विचलन का लाभ देने पर पीड़िता वयस्क संभावित है।',
        'presumption_rebuttal_strategy': [
          'पारस्परिक सहमति एवं प्रेम प्रसंग: अभियुक्त और पीड़िता के मध्य पूर्व से प्रेम संबंध था।',
          'एफ.आई.आर. में 7 दिन का अकारण विलंब।',
          'चिकित्सीय साक्ष्य में किसी प्रकार की आंतरिक अथवा बाह्य चोट का अभाव।'
        ],
        'bail_grounds_pocso': [
          'यह कि धारा 94 किशोर न्याय अधिनियम एवं ऋषिपाल सिंह सोलंकी के अनुसार पीड़िता वयस्क सिद्ध होती है।'
        ],
        'cited_precedents': [
          {
            'case_title': 'ऋषिपाल सिंह सोलंकी बनाम उत्तर प्रदेश राज्य (2021) 12 SCC 540',
            'ratio': 'अस्थि परीक्षण में 2 वर्ष का विचलन मान्य है। विधिक लाभ अभियुक्त को दिया जाना चाहिए।',
            'citation_url': 'https://main.sci.gov.in/judgment/judis/48731.pdf'
          }
        ]
      };

      final result = PocsoAgeEvaluationResult.fromJson(json);
      expect(result.caseId, 'test-case-uuid-2');
      expect(result.statutoryTierApplicable, 'TIER_3_OSSIFICATION');
      expect(result.computedAgeAtIncidentYears, 20.0);
      expect(result.isMajorityProbable, isTrue);
      expect(result.presumptionRebuttalStrategy.length, 3);
      expect(result.bailGroundsPocso.length, 1);
      expect(result.citedPrecedents.length, 1);
      expect(result.citedPrecedents.first['case_title'], contains('ऋषिपाल सिंह सोलंकी'));
    });
  });

  group('Goal 16: Devanagari UI Rendering & Statutory Text Line Height Tests', () {
    testWidgets('NdpsComplianceScreen renders Devanagari titles and compliance controls without overflow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NdpsComplianceScreen(caseId: 'test-case-ndps-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header & Section Headings in Devanagari
      expect(find.text('एन.डी.पी.एस. अनुपालन एवं धारा 50 परीक्षण'), findsOneWidget);
      expect(find.text('स्वापक पदार्थ एवं मात्रा वर्गीकरण'), findsOneWidget);
      expect(find.text('धारा 50 आज्ञापक परीक्षण (व्यक्तिगत तलाशी)'), findsOneWidget);
      expect(find.text('धारा 52A एवं जब्ती साक्ष्य शृंखला (Link Evidence)'), findsOneWidget);

      // Verify Devanagari switches & checkboxes
      expect(find.text('क्या तलाशी अभियुक्त के शरीर (व्यक्तिगत) से ली गई?'), findsOneWidget);
      expect(find.text('धारा 50 का विधिक नोटिस दिया गया था?'), findsOneWidget);
      expect(find.text('तीसरा अवैध विकल्प दिया गया? ("या आप हमारी तलाशी ले सकते हैं")'), findsOneWidget);

      // Verify Submit Button with Devanagari text
      expect(find.text('विधिक अनुपालन एवं जमानत आधार जांचें'), findsOneWidget);

      // Verify Line Heights for Devanagari texts to prevent matra-clipping (1.40 - 1.45)
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTexts) {
        if (textWidget.style?.height != null) {
          expect(textWidget.style!.height, greaterThanOrEqualTo(1.40));
          expect(textWidget.style!.height, lessThanOrEqualTo(1.45));
        }
      }
    });

    testWidgets('PocsoAgeAuditScreen renders Devanagari JJ Act statutory hierarchy controls cleanly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PocsoAgeAuditScreen(caseId: 'test-case-pocso-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header & Section Headings in Devanagari
      expect(find.text('पॉक्सो आयु निर्धारण (Sec 94 JJ Act Audit)'), findsOneWidget);
      expect(find.text('घटना दिनांक एवं प्राथमिक सूचना'), findsOneWidget);
      expect(find.text('धारा 94 किशोर न्याय अधिनियम: सांविधिक वरीयता क्रम'), findsOneWidget);
      expect(find.text('धारा 29/30 सांविधिक उपधारणा खंडन (Defense Angles)'), findsOneWidget);

      // Verify Statutory Hierarchy options
      expect(find.text('प्रथम वरीयता: मैट्रिकुलेशन प्रमाण पत्र उपलब्ध है?'), findsOneWidget);
      expect(find.text('प्रथम वरीयता: प्रथम प्रवेश विद्यालय रजिस्टर उपलब्ध है?'), findsOneWidget);
      expect(find.text('द्वितीय वरीयता: नगर निगम द्वारा जारी जन्म प्रमाण पत्र?'), findsOneWidget);
      expect(find.text('तृतीय वरीयता: मेडिकल बोर्ड द्वारा अस्थि परीक्षण (Ossification)?'), findsOneWidget);

      // Verify Defense angle options
      expect(find.text('पूर्व से प्रेम प्रसंग / आपसी सहमति का साक्ष्य विद्यमान है?'), findsOneWidget);
      expect(find.text('चिकित्सीय परीक्षण में किसी चोट का अभाव?'), findsOneWidget);

      // Verify Submit Button
      expect(find.text('आयु निर्धारण एवं जमानत आधार निकालें'), findsOneWidget);

      // Verify Line Heights for Devanagari texts (1.40 - 1.45)
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTexts) {
        if (textWidget.style?.height != null) {
          expect(textWidget.style!.height, greaterThanOrEqualTo(1.40));
          expect(textWidget.style!.height, lessThanOrEqualTo(1.45));
        }
      }
    });
  });
}
