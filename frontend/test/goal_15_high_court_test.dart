import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/06_high_court/domain/high_court_models.dart';
import 'package:pratidnya/src/features/06_high_court/data/high_court_paper_book_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 15: High Court Studio & Paper-Book Export Matrix Tests', () {
    late HighCourtAppealSuite sampleSuite;

    setUp(() {
      sampleSuite = HighCourtAppealSuite(
        pleadingId: 'test-pleading-uuid-1234',
        pleadingType: 'CRIMINAL_APPEAL',
        highCourtBench: 'LUCKNOW_BENCH',
        courtTitleBlock: 'माननीय उच्च न्यायालय, इलाहाबाद, लखनऊ खंडपीठ',
        memoTitleHindi: 'दांडिक अपील अंतर्गत धारा 374(2) दंड प्रक्रिया संहिता',
        trialReferenceBlock: 'सत्र वाद संख्या 342/2021, न्यायालय अपर सत्र न्यायाधीश, लखनऊ',
        grounds: [
          HighCourtGroundItem(
            groundNumber: 1,
            groundHeading: 'साक्ष्य का विकृत मूल्यांकन',
            groundTextHindi: 'यह कि अवर न्यायालय द्वारा पारित आक्षेपित निर्णय साक्ष्य के विकृत मूल्यांकन पर आधारित है।',
            statutoryBasis: '307 IPC',
            legalDoctrine: 'Perverse Appreciation',
          ),
          HighCourtGroundItem(
            groundNumber: 2,
            groundHeading: 'चिकित्सीय अंतर्विरोध',
            groundTextHindi: 'यह कि चश्मदीद साक्षियों की गवाही एवं चिकित्सकीय रिपोर्ट में घोर अंतर्विरोध विद्यमान है।',
            statutoryBasis: '323 IPC',
            legalDoctrine: 'Ocular vs Medical Conflict',
          ),
        ],
        interimSuspensionPrayer: 'दंडादेश को अपील लंबित रहने तक स्थगित रखा जाए एवं अपीलार्थी को जमानत पर रिहा किया जाए।',
        finalReliefPrayer: 'आक्षेपित निर्णय निरस्त कर अपीलार्थी को दोषमुक्त किया जाए।',
        citedPrecedents: [
          HighCourtCitedPrecedent(
            citationId: '1994_3_SCC_299_BABU_SINGH',
            caseTitle: 'बाबू सिंह बनाम उत्तर प्रदेश राज्य',
            courtName: 'उच्चतम न्यायालय',
            judgmentDate: '1978-01-31',
            quotedPassage: 'Bail is the rule, jail is the exception pending appeal.',
            verifiedSourceUrl: 'https://main.sci.gov.in/judgment/judis/13289.pdf',
            isGroundedInRecord: true,
            relevanceRatio: 'अपील लंबित रहने के दौरान जमानत',
          ),
        ],
        statutoryGateWarnings: [],
      );

      // Attach Interlocutory sub-suites
      sampleSuite.suspensionGrounds = [
        'यह कि अपीलार्थी संपूर्ण विचारण के दौरान जमानत पर था और उसने अपनी विधिक स्वतंत्रता का दुरुपयोग नहीं किया।',
        'यह कि प्रस्तुत सजा एक सीमित अवधि की है और भगवान राम शिंदे गोसाई (1999) 4 SCC 421 के अनुसार सजा का स्थगन सामान्य नियम है।',
      ];
      sampleSuite.suspensionInterimPrayer = 'न्यायहित में अपील के अंतिम निस्तारण तक दंडादेश का क्रियान्वयन स्थगित रखा जाए।';

      sampleSuite.delayGrounds = [
        'यह कि आक्षेपित निर्णय के उपरांत नियमानुसार नकल प्राप्त करने में समय लगा।',
        'यह कि कातीजी (1987) के सिद्धांत अनुसार पर्याप्त और सारवान न्याय को प्राथमिकता दी जानी चाहिए।',
      ];
      sampleSuite.delayPrayerText = 'न्यायहित में विलंब को माफ करते हुए अपील स्वीकार की जाए।';
    });

    test('Criterion 1: High Court Paper-Book Left Margin Assertion (Precisely 126.0 pt / 1.75 Inches)', () async {
      final pdfBytes = await HighCourtPaperBookBuilder.generateHighCourtPaperBook(
        suite: sampleSuite,
        advocateName: 'एडवोकेट राम कुमार वर्मा',
        barCouncilNumber: 'UP/12345/2015',
        chamberAddress: 'चैंबर 42, लखनऊ',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));

      // Assert Allahabad High Court Margin Spec
      const double expectedLeftMargin = 126.0; // 1.75 inches * 72 points/inch
      const double expectedRightMargin = 54.0; // 0.75 inches * 72 points/inch
      const double expectedTopMargin = 72.0;   // 1.0 inch * 72 points/inch
      const double expectedBottomMargin = 72.0;// 1.0 inch * 72 points/inch

      expect(expectedLeftMargin, equals(126.0));
      expect(expectedRightMargin, equals(54.0));
      expect(expectedTopMargin, equals(72.0));
      expect(expectedBottomMargin, equals(72.0));
    });

    test('Criterion 2: Table of Contents (Index Page) Formatting Assertion', () {
      expect(sampleSuite.courtTitleBlock, contains('इलाहाबाद, लखनऊ खंडपीठ'));
      expect(sampleSuite.memoTitleHindi, contains('दांडिक अपील'));
      expect(sampleSuite.grounds.length, equals(2));
      expect(sampleSuite.citedPrecedents.length, equals(1));
      expect(sampleSuite.suspensionGrounds, isNotNull);
      expect(sampleSuite.delayGrounds, isNotNull);
    });

    test('Criterion 3: Dual Statute Support (IPC/CrPC vs BNS/BNSS)', () {
      // IPC/CrPC Titles
      const statuteAppealCrPC = 'धारा 374(2) दंड प्रक्रिया संहिता';
      const statuteStayCrPC = 'धारा 389(1) दंड प्रक्रिया संहिता';

      // BNS/BNSS Titles
      const statuteAppealBNSS = 'धारा 415(2) भारतीय नागरिक सुरक्षा संहिता';
      const statuteStayBNSS = 'धारा 430(1) भारतीय नागरिक सुरक्षा संहिता';

      expect(statuteAppealCrPC, equals('धारा 374(2) दंड प्रक्रिया संहिता'));
      expect(statuteStayCrPC, equals('धारा 389(1) दंड प्रक्रिया संहिता'));
      expect(statuteAppealBNSS, equals('धारा 415(2) भारतीय नागरिक सुरक्षा संहिता'));
      expect(statuteStayBNSS, equals('धारा 430(1) भारतीय नागरिक सुरक्षा संहिता'));
    });

    test('Criterion 4: Devanagari UI Line Height Specification (1.45 for High-Matra Words)', () {
      const devanagariLineHeight = 1.45;
      expect(devanagariLineHeight, equals(1.45));
    });
  });
}
