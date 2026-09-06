import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/07_specialized_acts/domain/scst_ni_models.dart';
import 'package:pratidnya/src/features/07_specialized_acts/presentation/screens/scst_appeal_screen.dart';
import 'package:pratidnya/src/features/07_specialized_acts/presentation/screens/ni_act_defense_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 17: SC/ST PoA Act & NI Act 138 Domain Model Tests', () {
    test('ScstComplianceResult deserializes and validates statutory fields', () {
      final json = {
        'case_id': 'test-case-scst-1',
        'is_public_view_test_satisfied': false,
        'is_anticipatory_bail_maintainable': true,
        'section_18_bar_bypass_ratio': 'अग्रिम जमानत पोषणीय है (पृथ्वी राज चौहान सिद्धांत): प्रथम दृष्टया धारा 3 के आवश्यक तत्व अनुपस्थित हैं।',
        'section_14a_appeal_limitation_status': 'BARRED_BEYOND_180_DAYS',
        'delay_days': 15,
        'mandatory_victim_notice_warning': 'धारा 15A(3) एवं 15A(5) का आज्ञापक अनुपालन: जमानत सुनवाई से पूर्व पीड़ित/वादी को विधिक सूचना तामील कराना अनिवार्य है।',
        'tailored_grounds': [
          'यह कि कथित घटना किसी सार्वजनिक दृष्टिगोचर स्थान पर घटित नहीं हुई है (हितेश वर्मा बनाम उत्तराखंड राज्य)।',
          'यह कि दोनों पक्षों के मध्य पूर्व से ही दीवानी व भूमि विवाद विचाराधीन है।'
        ],
        'cited_precedents': [
          {
            'case_title': 'हितेश वर्मा बनाम उत्तराखंड राज्य (2020) 10 SCC 710',
            'ratio': 'धारा 3(1)(r) के तहत अपराध घटित होने हेतु अपमान सार्वजनिक दृष्टिगोचर स्थान पर होना अनिवार्य है।',
            'citation_url': 'https://main.sci.gov.in/judgment/judis/47035.pdf'
          }
        ]
      };

      final result = ScstComplianceResult.fromJson(json);
      expect(result.caseId, 'test-case-scst-1');
      expect(result.isPublicViewTestSatisfied, isFalse);
      expect(result.isAnticipatoryBailMaintainable, isTrue);
      expect(result.section18BarBypassRatio, contains('पृथ्वी राज चौहान'));
      expect(result.section14aAppealLimitationStatus, 'BARRED_BEYOND_180_DAYS');
      expect(result.delayDays, 15);
      expect(result.mandatoryVictimNoticeWarning, contains('धारा 15A'));
      expect(result.tailoredGrounds.length, 2);
      expect(result.tailoredGrounds.first, contains('हितेश वर्मा'));
      expect(result.citedPrecedents.length, 1);
    });

    test('NiActComplianceResult deserializes and validates Section 138 timeline defects', () {
      final json = {
        'case_id': 'test-case-ni-1',
        'dispatch_within_30_days': false,
        'cure_period_15_days_expiry_date': '2026-08-16',
        'is_premature_complaint': true,
        'is_time_barred': false,
        'fatal_defects_detected': [
          'अपरिपक्व परिवाद (Premature Complaint): 15 दिन की वैधानिक अवधि पूर्ण होने से पूर्व परिवाद दाखिल किया गया (योगेंद्र प्रताप सिंह संविधान पीठ उल्लंघन)।',
          'दोषपूर्ण एकमुश्त मांग नोटिस (Omnibus Demand): चेक की मूल राशि के स्थान पर एकमुश्त मांग (के.आर. इंदिरा सिद्धांत)।'
        ],
        'defense_rebuttal_strategy': [
          'सुरक्षा चेक (Security Cheque) का दुरुपयोग: विवादित चेक किसी मौजूदा विधिक देयता के भुगतान हेतु नहीं दिया गया था।'
        ],
        'statutory_discharge_or_quashing_grounds': [
          'यह कि वर्तमान परिवाद धारा 138 की अनिवार्य पूर्व-शर्तों को पूरा न करने के कारण प्रथम दृष्टया पोषणीय नहीं है।'
        ],
        'compounding_guidelines_under_147': 'धारा 147 एन.आई. एक्ट के तहत शमन: उच्चतम न्यायालय (दामोदर एस. प्रभु) के अनुसार चेक राशि के भुगतान पर वाद का पूर्ण निस्तारण।',
        'cited_precedents': [
          {
            'case_title': 'योगेंद्र प्रताप सिंह बनाम सावित्री पांडे (2014) 10 SCC 713',
            'ratio': '15 दिन पूरे होने से पूर्व दायर परिवाद अपरिपक्व एवं शून्य है।',
            'citation_url': 'https://main.sci.gov.in/judgment/judis/41935.pdf'
          }
        ]
      };

      final result = NiActComplianceResult.fromJson(json);
      expect(result.caseId, 'test-case-ni-1');
      expect(result.dispatchWithin30Days, isFalse);
      expect(result.curePeriod15DaysExpiryDate, DateTime(2026, 8, 16));
      expect(result.isPrematureComplaint, isTrue);
      expect(result.isTimeBarred, isFalse);
      expect(result.fatalDefectsDetected.length, 2);
      expect(result.fatalDefectsDetected.first, contains('योगेंद्र प्रताप सिंह'));
      expect(result.compoundingGuidelinesUnder147, contains('दामोदर एस. प्रभु'));
      expect(result.citedPrecedents.length, 1);
    });
  });

  group('Goal 17: Devanagari UI Rendering & Statutory Text Line Height Tests', () {
    testWidgets('ScstAppealScreen renders Section 18 bypass controls & Devanagari typography cleanly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ScstAppealScreen(caseId: 'test-case-scst-101'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Sections
      expect(find.text('एस.सी./एस.टी. एक्ट धारा 18 एवं 14A अपील परीक्षण'), findsOneWidget);
      expect(find.text('सार्वजनिक दृष्टिगोचर स्थान परीक्षण (Hitesh Verma Test)'), findsOneWidget);
      expect(find.text('धारा 14A उच्च न्यायालय सांविधिक अपील (Appeal against Bail Rejection)'), findsOneWidget);

      // Verify Controls
      expect(find.text('क्या घटना के समय जनता के स्वतंत्र साक्षी उपस्थित थे?'), findsOneWidget);
      expect(find.text('क्या दोनों पक्षों के मध्य पूर्व से भूमि / दीवानी विवाद लंबित है?'), findsOneWidget);
      expect(find.text('धारा 15A(3): क्या पीड़ित/वादी को विधिक सूचना तामील हो चुकी है?'), findsOneWidget);

      // Verify Submit Button
      expect(find.text('धारा 18 अग्रिम जमानत व अपील पोषणीयता जांचें'), findsOneWidget);

      // Verify Devanagari line heights (1.40 - 1.45)
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTexts) {
        if (textWidget.style?.height != null) {
          expect(textWidget.style!.height, greaterThanOrEqualTo(1.40));
          expect(textWidget.style!.height, lessThanOrEqualTo(1.45));
        }
      }
    });

    testWidgets('NiActDefenseScreen renders Section 138 timeline audit controls & Devanagari typography', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NiActDefenseScreen(caseId: 'test-case-ni-101'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Sections
      expect(find.text('धारा 138 एन.आई. एक्ट नोटिस व मियाद परीक्षण'), findsOneWidget);
      expect(find.text('चेक विवरण एवं धनराशि'), findsOneWidget);
      expect(find.text('सांविधिक मियाद शृंखला (Statutory 30 & 15-Day Timeline)'), findsOneWidget);
      expect(find.text('धारा 139 उपधारणा खंडन एवं धारा 147 शमन'), findsOneWidget);

      // Verify Controls & Timeline Tiles
      expect(find.text('1. बैंक वापसी मेमो दिनांक'), findsOneWidget);
      expect(find.text('2. विधिक मांग नोटिस भेजने का दिनांक (30 दिन)'), findsOneWidget);
      expect(find.text('3. विधिक नोटिस प्राप्त/तामील होने का दिनांक'), findsOneWidget);
      expect(find.text('4. न्यायालय में परिवाद दाखिल करने का दिनांक'), findsOneWidget);
      expect(find.text('दोषपूर्ण एकमुश्त मांग (Omnibus Demand)?'), findsOneWidget);
      expect(find.text('धारा 147 के तहत शमन (Compounding / Settlement)?'), findsOneWidget);

      // Verify Submit Button
      expect(find.text('नोटिस एवं परिवाद की विधिक वैधता जांचें'), findsOneWidget);

      // Verify Devanagari line heights (1.40 - 1.45)
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
