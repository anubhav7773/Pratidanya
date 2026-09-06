import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/08_voice_intake/domain/voice_intake_result.dart';
import 'package:pratidnya/src/features/08_voice_intake/presentation/widgets/court_voice_dictation_sheet.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/new_case_form_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/controllers/case_controller.dart';
import 'package:pratidnya/src/features/02_case_input/domain/criminal_case.dart';

class MockCaseFormController extends StateNotifier<AsyncValue<CriminalCase?>> implements CaseFormController {
  MockCaseFormController() : super(const AsyncValue.data(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 18: Voice Dictation Domain Model Tests', () {
    test('VoiceDictationResult deserializes with legal entities & DPDP purge flag', () {
      final json = {
        'session_id': 'voice-session-uuid-101',
        'verbatim_transcript_hindi': 'थाना कोतवाली नगर, मु.अ.सं. 124/2026, धारा 379 भा.दं.वि. के तहत श्यामू को गिरफ्तार किया गया।',
        'cleaned_factual_matrix': 'अभियुक्त श्यामू को थाना कोतवाली नगर के मु.अ.सं. 124/2026 अंतर्गत धारा 379 भा.दं.वि. में गिरफ्तार किया गया।',
        'duration_seconds': 10,
        'extracted_entities': {
          'fir_number': '124/2026',
          'police_station': 'कोतवाली नगर',
          'district': 'लखनऊ',
          'accused_names': ['श्यामू'],
          'complainant_name': 'राम प्रकाश',
          'sections': ['379 IPC'],
          'custody_status': 'JUDICIAL_CUSTODY',
          'allegation_summary': 'चोरी का कथित आरोप',
          'defense_plea': 'मिथ्या आरोप'
        },
        'chronological_events': [
          'तारीख 10-02-2026: कथित घटना'
        ],
        'dpdp_ephemeral_purge_verified': true
      };

      final result = VoiceDictationResult.fromJson(json);
      expect(result.sessionId, 'voice-session-uuid-101');
      expect(result.verbatimTranscriptHindi, contains('कोतवाली नगर'));
      expect(result.durationSeconds, 10);
      expect(result.extractedEntities.firNumber, '124/2026');
      expect(result.extractedEntities.policeStation, 'कोतवाली नगर');
      expect(result.extractedEntities.sections, contains('379 IPC'));
      expect(result.extractedEntities.accusedNames, contains('श्यामू'));
      expect(result.dpdpEphemeralPurgeVerified, isTrue);
    });
  });

  group('Goal 18: Court Voice Dictation Sheet UI Tests', () {
    testWidgets('CourtVoiceDictationSheet renders header, recording controls & Devanagari styling cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CourtVoiceDictationSheet(
                onDictationTransferred: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Initial State
      expect(find.text('न्यायालयीन हिंदी वॉयस डिक्टेशन'), findsOneWidget);
      expect(find.text('डिक्टेशन शुरू करने के लिए नीचे दिए गए बटन को दबाएं'), findsOneWidget);
      expect(find.text('डिक्टेशन प्रारंभ करें'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // Verify line heights (1.40 - 1.45) on Devanagari text widgets
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTexts) {
        if (textWidget.style?.height != null) {
          expect(textWidget.style!.height, greaterThanOrEqualTo(1.40));
          expect(textWidget.style!.height, lessThanOrEqualTo(1.45));
        }
      }
    });

    testWidgets('Tapping microphone in NewCaseFormScreen opens CourtVoiceDictationSheet and populates form fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseFormControllerProvider.overrideWith((ref) => MockCaseFormController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NewCaseFormScreen(
                onCaseSaved: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify mic icon button and quick card are present
      expect(find.byIcon(Icons.mic), findsWidgets);
      expect(find.text('बोलकर केस दर्ज करें (Court Voice Intake)'), findsOneWidget);

      // Tap on Voice Dictation Quick Card
      await tester.tap(find.text('बोलकर केस दर्ज करें (Court Voice Intake)'));
      await tester.pumpAndSettle();

      // Verify CourtVoiceDictationSheet is opened
      expect(find.byType(CourtVoiceDictationSheet), findsOneWidget);
      expect(find.text('न्यायालयीन हिंदी वॉयस डिक्टेशन'), findsOneWidget);

      // Find the callback from the sheet widget in the tree
      final sheetFinder = find.byType(CourtVoiceDictationSheet);
      final sheetWidget = tester.widget<CourtVoiceDictationSheet>(sheetFinder);

      // Simulate transferring parsed dictation
      final testResult = VoiceDictationResult(
        sessionId: 'test-session-123',
        verbatimTranscriptHindi: 'थाना कोतवाली नगर मु.अ.सं. 124/2026 अंतर्गत धारा 379 भा.दं.वि.',
        cleanedFactualMatrix: 'अभियुक्त श्यामू को मु.अ.सं. 124/2026 में गिरफ्तार किया गया।',
        durationSeconds: 10,
        extractedEntities: ExtractedCaseEntities(
          firNumber: '124/2026',
          policeStation: 'कोतवाली नगर',
          district: 'लखनऊ',
          accusedNames: ['श्यामू'],
          complainantName: 'राम प्रकाश',
          sections: ['धारा 379 IPC'],
          custodyStatus: 'JUDICIAL_CUSTODY',
          allegationSummary: 'चोरी का कथित आरोप',
          defensePlea: 'रंजिशन फंसाया जाना',
        ),
        chronologicalEvents: ['10-02-2026 कथित घटना'],
        dpdpEphemeralPurgeVerified: true,
      );

      sheetWidget.onDictationTransferred(testResult);
      Navigator.of(tester.element(sheetFinder)).pop();
      await tester.pumpAndSettle();

      // Verify form fields are auto-populated
      expect(find.text('124'), findsOneWidget);
      expect(find.text('2026'), findsWidgets);
      expect(find.text('कोतवाली नगर'), findsWidgets);
      expect(find.text('श्यामू'), findsOneWidget);
      expect(find.text('धारा 379 IPC'), findsOneWidget);
    });
  });
}
