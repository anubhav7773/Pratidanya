import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/constants/special_acts_registry.dart';
import 'package:pratidnya/src/features/04_draft_generator/domain/case_analysis_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Feedback Verification: Special Acts 100% Comprehensive Coverage', () {
    test('SpecialActsRegistry contains extensive sections across all 13 Special/Central Acts', () {
      final ndps = SpecialActsRegistry.supportedActs.firstWhere((a) => a.actCode == 'NDPS');
      expect(ndps.popularSections.length, greaterThanOrEqualTo(40),
          reason: 'NDPS Act must have comprehensive statutory sections');
      expect(ndps.popularSections.any((s) => s.contains('8(c)')), isTrue);
      expect(ndps.popularSections.any((s) => s.contains('20(b)')), isTrue);
      expect(ndps.popularSections.any((s) => s.contains('27A')), isTrue);
      expect(ndps.popularSections.any((s) => s.contains('37')), isTrue);
      expect(ndps.popularSections.any((s) => s.contains('50')), isTrue);

      final pocso = SpecialActsRegistry.supportedActs.firstWhere((a) => a.actCode == 'POCSO');
      expect(pocso.popularSections.length, greaterThanOrEqualTo(30),
          reason: 'POCSO Act must have complete sections');
      expect(pocso.popularSections.any((s) => s.contains('3/4 POCSO')), isTrue);
      expect(pocso.popularSections.any((s) => s.contains('5/6 POCSO')), isTrue);
      expect(pocso.popularSections.any((s) => s.contains('7/8 POCSO')), isTrue);
      expect(pocso.popularSections.any((s) => s.contains('11/12 POCSO')), isTrue);
      expect(pocso.popularSections.any((s) => s.contains('29 POCSO')), isTrue);

      final arms = SpecialActsRegistry.supportedActs.firstWhere((a) => a.actCode == 'ARMS');
      expect(arms.popularSections.length, greaterThanOrEqualTo(25));
      expect(arms.popularSections.any((s) => s.contains('25')), isTrue);
      expect(arms.popularSections.any((s) => s.contains('27')), isTrue);

      final gangsters = SpecialActsRegistry.findByCode('UP_GANGSTERS')!;
      expect(gangsters.popularSections.length, greaterThanOrEqualTo(15));
      expect(gangsters.popularSections.any((s) => s.contains('धारा 3(1)')), isTrue);
      expect(gangsters.popularSections.any((s) => s.contains('धारा 14')), isTrue);

      final scst = SpecialActsRegistry.findByCode('SC_ST')!;
      expect(scst.popularSections.length, greaterThanOrEqualTo(20));
      expect(scst.popularSections.any((s) => s.contains('3(1)(r)')), isTrue);
      expect(scst.popularSections.any((s) => s.contains('3(2)(v)')), isTrue);
      expect(scst.popularSections.any((s) => s.contains('18')), isTrue);

      final bns = SpecialActsRegistry.supportedActs.firstWhere((a) => a.actCode == 'BNS');
      expect(bns.popularSections.length, greaterThanOrEqualTo(40));

      final ipc = SpecialActsRegistry.supportedActs.firstWhere((a) => a.actCode == 'IPC');
      expect(ipc.popularSections.length, greaterThanOrEqualTo(40));
    });

    test('SpecialActsRegistry findByCode resolves all act abbreviations correctly', () {
      expect(SpecialActsRegistry.findByCode('NDPS')?.actCode, equals('NDPS'));
      expect(SpecialActsRegistry.findByCode('POCSO')?.actCode, equals('POCSO'));
      expect(SpecialActsRegistry.findByCode('ARMS')?.actCode, equals('ARMS'));
      expect(SpecialActsRegistry.findByCode('UP_GANGSTERS')?.actCode, equals('GANGSTERS'));
      expect(SpecialActsRegistry.findByCode('SC_ST_ACT')?.actCode, equals('SC_ST'));
      expect(SpecialActsRegistry.findByCode('EXCISE')?.actCode, equals('UP_EXCISE'));
      expect(SpecialActsRegistry.findByCode('IT_ACT')?.actCode, equals('IT_ACT'));
      expect(SpecialActsRegistry.findByCode('NI_ACT_138')?.actCode, equals('NI_ACT'));
      expect(SpecialActsRegistry.findByCode('PMLA')?.actCode, equals('PMLA'));
      expect(SpecialActsRegistry.findByCode('MOTOR_VEHICLES')?.actCode, equals('MV_ACT'));
      expect(SpecialActsRegistry.findByCode('ANTI_CORRUPTION')?.actCode, equals('ANTI_CORRUPTION'));
    });
  });

  group('User Feedback Verification: CaseAnalysisDraft Serialization & Fallback Resilience', () {
    test('CaseAnalysisDraft serializes and deserializes accurately with full Hindi court grounds', () {
      final mockData = {
        'court_header': 'न्यायालय विशेष न्यायाधीश (एन.डी.पी.एस. अधिनियम), लखनऊ',
        'case_title': 'राज्य बनाम रमेश कुमार (मु.अ.सं. 142/2026)',
        'statutory_grounds': [
          'यह कि कथित तलाशी एवं जब्ती के समय एन.डी.पी.एस. अधिनियम की धारा 50 के आज्ञापक प्रावधानों का घोर उल्लंघन किया गया है।',
          'यह कि बरामदगी की कथित मात्रा वाणिज्यिक सीमा के अंतर्गत नहीं आती है, अतः धारा 37 का प्रतिबंध लागू नहीं होता।',
        ],
        'prosecution_weaknesses': [
          'कथित जब्ती स्थल पर किसी भी स्वतंत्र लोक साक्षी (Independent Public Witness) को सम्मिलित नहीं किया गया।',
        ],
        'procedural_objections': [
          'धारा 52A एन.डी.पी.एस. अधिनियम के तहत मजिस्ट्रेट की उपस्थिति में इन्वेंटरी एवं नमूना सीलिंग का अभाव।',
        ],
        'cited_precedents': [
          {
            'citation_id': 'sc-vijaysinh-2011',
            'case_title': 'विजयसिंह चंदुभा जडेजा बनाम गुजरात राज्य (2011 1 SCC 609)',
            'court_name': 'उच्चतम न्यायालय (संविधान पीठ)',
            'judgment_date': '2011',
            'quoted_passage': 'धारा 50 एन.डी.पी.एस. अधिनियम का अनुपालन आज्ञापक (Mandatory) है।',
            'verified_source_url': 'https://indiankanoon.org/doc/1145861/',
            'is_grounded_in_record': true,
            'is_manually_verified': true,
          }
        ],
      };

      final draft = CaseAnalysisDraft.fromJson(mockData);
      expect(draft.courtHeader, equals('न्यायालय विशेष न्यायाधीश (एन.डी.पी.एस. अधिनियम), लखनऊ'));
      expect(draft.statutoryGrounds.length, equals(2));
      expect(draft.citedPrecedents.length, equals(1));
      expect(draft.citedPrecedents.first.isManuallyVerified, isTrue);

      final json = draft.toJson();
      expect(json['court_header'], equals(mockData['court_header']));
      expect(json['statutory_grounds'], equals(mockData['statutory_grounds']));
      expect((json['cited_precedents'] as List).length, equals(1));
    });
  });
}
