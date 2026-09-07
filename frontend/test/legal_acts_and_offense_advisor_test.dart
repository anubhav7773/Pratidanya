import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/core/constants/special_acts_registry.dart';
import 'package:pratidnya/src/core/constants/up_districts_registry.dart';
import 'package:pratidnya/src/core/constants/custody_status_registry.dart';
import 'package:pratidnya/src/features/02_case_input/domain/ai_offense_analysis_result.dart';
import 'package:pratidnya/src/features/02_case_input/data/ai_section_advisor_service.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/new_case_form_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/ai_section_advisor_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/controllers/case_controller.dart';
import 'package:pratidnya/src/features/02_case_input/domain/criminal_case.dart';

class MockCaseFormController extends StateNotifier<AsyncValue<CriminalCase?>> implements CaseFormController {
  MockCaseFormController() : super(const AsyncValue.data(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 1: Multi-Act & Special Acts Registry Tests', () {
    test('SpecialActsRegistry contains all major Indian criminal acts', () {
      final actCodes = SpecialActsRegistry.supportedActs.map((a) => a.actCode).toList();

      expect(actCodes, contains('BNS'));
      expect(actCodes, contains('IPC'));
      expect(actCodes, contains('NDPS'));
      expect(actCodes, contains('POCSO'));
      expect(actCodes, contains('ARMS'));
      expect(actCodes, contains('GANGSTERS'));
      expect(actCodes, contains('SC_ST'));
      expect(actCodes, contains('UP_EXCISE'));
      expect(actCodes, contains('IT_ACT'));
      expect(actCodes, contains('NI_ACT'));
      expect(actCodes, contains('PMLA'));
      expect(actCodes, contains('MV_ACT'));
      expect(actCodes, contains('ANTI_CORRUPTION'));

      final armsAct = SpecialActsRegistry.getActByCode('ARMS');
      expect(armsAct, isNotNull);
      expect(armsAct!.popularSections, contains(contains('3/25 Arms Act')));

      final ndpsAct = SpecialActsRegistry.getActByCode('NDPS');
      expect(ndpsAct, isNotNull);
      expect(ndpsAct!.popularSections, contains(contains('8/20 NDPS')));
      expect(ndpsAct.popularSections, contains(contains('50 NDPS')));

      final pocsoAct = SpecialActsRegistry.getActByCode('POCSO');
      expect(pocsoAct, isNotNull);
      expect(pocsoAct!.popularSections, contains(contains('3/4 POCSO')));
    });
  });

  group('Feature 2: Custody Status (12 Authentic Court Conditions) Tests', () {
    test('CustodyStatusRegistry covers all real-world criminal court statuses', () {
      final keys = CustodyStatusRegistry.allStatuses.map((s) => s.key).toList();

      expect(keys.length, greaterThanOrEqualTo(12));
      expect(keys, contains('JUDICIAL_CUSTODY'));
      expect(keys, contains('POLICE_CUSTODY'));
      expect(keys, contains('ON_BAIL'));
      expect(keys, contains('ANTICIPATORY'));
      expect(keys, contains('INTERIM_BAIL'));
      expect(keys, contains('SECTION_35_NOTICE'));
      expect(keys, contains('SURRENDER_PENDING'));
      expect(keys, contains('NBW_ISSUED'));
      expect(keys, contains('ABSCONDING_84_BNSS'));
      expect(keys, contains('HOSPITAL_CUSTODY'));
      expect(keys, contains('JJB_OBSERVATION_HOME'));
      expect(keys, contains('PAROLE_FURLOUGH'));

      // Detention checks
      expect(CustodyStatusRegistry.isPhysicalDetention('JUDICIAL_CUSTODY'), isTrue);
      expect(CustodyStatusRegistry.isPhysicalDetention('POLICE_CUSTODY'), isTrue);
      expect(CustodyStatusRegistry.isPhysicalDetention('HOSPITAL_CUSTODY'), isTrue);
      expect(CustodyStatusRegistry.isPhysicalDetention('JJB_OBSERVATION_HOME'), isTrue);
      expect(CustodyStatusRegistry.isPhysicalDetention('ON_BAIL'), isFalse);
      expect(CustodyStatusRegistry.isPhysicalDetention('SECTION_35_NOTICE'), isFalse);
      expect(CustodyStatusRegistry.isPhysicalDetention('INTERIM_BAIL'), isFalse);
    });
  });

  group('Feature 3: 75 UP Districts & Dynamic Court Hierarchy Tests', () {
    test('UpDistrictsRegistry covers all 75 UP districts with dynamic court designations', () {
      expect(UpDistrictsRegistry.allDistricts.length, 75);

      final districtNames = UpDistrictsRegistry.allDistricts.map((d) => d.hindiName).toList();
      expect(districtNames, contains('लखनऊ'));
      expect(districtNames, contains('कानपुर नगर'));
      expect(districtNames, contains('वाराणसी'));
      expect(districtNames, contains('गोरखपुर'));
      expect(districtNames, contains('प्रयागराज (इलाहाबाद)'));
      expect(districtNames, contains('मेरठ'));
      expect(districtNames, contains('झांसी'));
      expect(districtNames, contains('बरेली'));

      // Dynamic court designations for Varanasi
      final varanasiCourts = UpDistrictsRegistry.getCourtDesignationsForDistrict('वाराणसी');
      expect(varanasiCourts, contains(contains('CJM (मुख्य न्यायिक मजिस्ट्रेट, वाराणसी)')));
      expect(varanasiCourts, contains(contains('विशेष सत्र न्यायाधीश (पॉक्सो / SC-ST कोर्ट, वाराणसी)')));
      expect(varanasiCourts, contains(contains('विशेष एनडीपीएस न्यायालय (NDPS Court, वाराणसी)')));

      // Dynamic court designations for Meerut
      final meerutCourts = UpDistrictsRegistry.getCourtDesignationsForDistrict('मेरठ');
      expect(meerutCourts, contains(contains('CJM (मुख्य न्यायिक मजिस्ट्रेट, मेरठ)')));
      expect(meerutCourts, contains(contains('विशेष न्यायालय (गैंगस्टर्स एक्ट, मेरठ)')));
    });
  });

  group('Feature 4: AI 360° Offense Analyzer & Legal Strategy Tests', () {
    test('AiSectionAdvisorService heuristic fallback extracts applicable sections & 360 strategy', () async {
      // Test Arms Act scenario
      final armsResult = await AiSectionAdvisorService.analyzeOffense360(
        narrative: 'चेकिंग के दौरान अभियुक्त की मोटरसाइकिल से 315 बोर का एक अवैध तमंचा व 2 कारतूस बरामद हुए।',
        preferredStatute: 'HYBRID',
      );

      expect(armsResult.applicableSections, isNotEmpty);
      final hasArmsSec = armsResult.applicableSections.any((s) => s.actCode == 'ARMS');
      expect(hasArmsSec, isTrue);
      expect(armsResult.defenseStrategy360, isNotEmpty);
      expect(armsResult.defendingStrategies.first, contains('जब्ती फर्द'));

      // Test NDPS Act scenario
      final ndpsResult = await AiSectionAdvisorService.analyzeOffense360(
        narrative: 'मुखबिर की सूचना पर पुलिस ने 150 ग्राम चरस बरामद की, तलाशी मौके पर ली गई।',
        preferredStatute: 'HYBRID',
      );

      final hasNdpsSec = ndpsResult.applicableSections.any((s) => s.actCode == 'NDPS');
      expect(hasNdpsSec, isTrue);
      expect(ndpsResult.defendingStrategies.any((s) => s.contains('धारा 50 NDPS')), isTrue);
    });

    testWidgets('AiSectionAdvisorScreen renders incident narrative input, quick chips & analysis trigger', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiSectionAdvisorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('एआई अपराध धारा विश्लेषक'), findsOneWidget);
      expect(find.text('360° विधिक विश्लेषण एवं धाराएं निकालें'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsWidgets);
      expect(find.text('🔫 अवैध तमंचा बरामदगी'), findsOneWidget);
      expect(find.text('💊 नशीला पदार्थ बरामदगी (NDPS)'), findsOneWidget);

      // Tap Quick scenario chip
      await tester.tap(find.text('🔫 अवैध तमंचा बरामदगी'));
      await tester.pumpAndSettle();

      // Trigger Analysis
      await tester.tap(find.text('360° विधिक विश्लेषण एवं धाराएं निकालें'));
      await tester.pumpAndSettle();

      // Verify sections and 360° strategy sections appear
      expect(find.text('पहचानी गई विधिक धाराएं (Identified Sections)'), findsOneWidget);
      expect(find.text('360° बचाव रणनीति (Defense Strategy & Court Loopholes)'), findsOneWidget);
      expect(find.text('अभियोजन / वादी आक्रमण बिंदु (Prosecution Checklist)'), findsOneWidget);
      expect(find.text('केस में धाराएं जोड़ें'), findsOneWidget);
    });

    testWidgets('NewCaseFormScreen renders 75 UP Districts picker, 12 custody statuses & AI advisor banner', (tester) async {
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
              body: NewCaseFormScreen(onCaseSaved: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Special Acts card and dropdown
      expect(find.text('विशेष / स्थानीय अधिनियम (Special Acts)'), findsOneWidget);

      // Verify AI 360 Advisor card
      expect(find.text('धारा समझ नहीं आ रही? AI 360° विधिक विश्लेषक'), findsOneWidget);
      expect(find.text('360° विधिक विश्लेषक खोलें (AI Legal Strategy)'), findsOneWidget);

      // Verify District field
      expect(find.text('जनपद (District) *'), findsOneWidget);

      // Verify Custody status
      expect(find.text('वर्तमान अभिरक्षा स्थिति (Custody Status) *'), findsOneWidget);
    });
  });
}
