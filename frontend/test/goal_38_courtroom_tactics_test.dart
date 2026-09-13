import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/02_case_input/domain/courtroom_tactics_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/live_courtroom_hud_widget.dart';

void main() {
  group('Goal 38: Tactical Courtroom Suite & Edge Oral Prompter Tests', () {
    test('SuretyAuditResult deserializes JSON accurately', () {
      final json = {
        'case_id': 'BAIL-SURETY-001',
        'is_condition_onerous': true,
        'moti_ram_violation_reasons': [
          'स्थानीय प्रतिभू की अवैध बाध्यता: मोती राम (1978)',
          'खतौनी / कृषि भूमि अभिलेख की अनुचित मांग'
        ],
        'suggested_statutory_relief': 'धारा 483(2) बी.एन.एस.एस. संशोधन',
        'modification_petition_draft_hindi': 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ...',
        'cited_precedents': [
          {'case_title': 'मोती राम बनाम मध्य प्रदेश राज्य (1978)', 'citation': 'AIR 1978 SC 1594'}
        ]
      };

      final result = SuretyAuditResult.fromJson(json);

      expect(result.caseId, 'BAIL-SURETY-001');
      expect(result.isConditionOnerous, isTrue);
      expect(result.motiRamViolationReasons.length, 2);
      expect(result.suggestedStatutoryRelief, contains('धारा 483(2)'));
      expect(result.modificationPetitionDraftHindi, contains('न्यायालय'));
      expect(result.citedPrecedents.length, 1);
    });

    test('EdgeOralPromptResult deserializes JSON accurately', () {
      final json = {
        'detected_adversarial_ratio': 'धारा 37 एन.डी.पी.एस. के अंतर्गत जमानत पर सांविधिक प्रतिबंध का तर्क।',
        'immediate_counter_ratios': [
          {
            'counter_legal_ground': 'धारा 52A बी.एन.एस.एस. मजिस्ट्रेट इन्वेंटरी का अभाव।',
            'prompt_text_hindi': 'श्रीमान, मोहनलाल (2016) के अनुसार धारा 52A का अनुपालन अनिवार्य है।',
            'lead_citation': 'Union of India v. Mohanlal (2016) 3 SCC 379',
            'statutory_lever': 'Section 52A NDPS Act / Section 105 BNSS'
          }
        ],
        'bench_insights': {'district': 'लखनऊ'},
        'latency_ms': {
          'transcription_est_ms': 110.0,
          'vector_retrieval_ms': 35.0,
          'generation_ms': 4.5,
          'total_latency_ms': 149.5
        }
      };

      final result = EdgeOralPromptResult.fromJson(json);

      expect(result.detectedAdversarialRatio, contains('धारा 37'));
      expect(result.immediateCounterRatios.length, 1);
      expect(result.immediateCounterRatios.first.statutoryLever, contains('Section 52A'));
      expect(result.latencyMs['total_latency_ms'], 149.5);
    });

    testWidgets('LiveCourtroomHUDWidget renders header, badge, and input field', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: LiveCourtroomHUDWidget(
                  caseId: 'CASE-HUD-001',
                  accusedName: 'राजेश वर्मा',
                  district: 'लखनऊ',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify header and latency badge
      expect(find.text('लाइव कोर्टरूम ओरल प्रॉम्टर (Edge HUD)'), findsOneWidget);
      expect(find.text('< 450ms'), findsOneWidget);

      // Verify instruction text
      expect(
        find.textContaining('अभियोजन पक्ष की बहस दर्ज करें या बोलें'),
        findsOneWidget,
      );

      // Verify text field and send icon button
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Enter prosecution argument
      await tester.enterText(textField, 'अभियुक्त से व्यावसायिक मात्रा बरामद हुई है');
      await tester.pumpAndSettle();

      expect(find.text('अभियुक्त से व्यावसायिक मात्रा बरामद हुई है'), findsOneWidget);
    });
  });
}
