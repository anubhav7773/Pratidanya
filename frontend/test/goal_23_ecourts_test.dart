import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/08_ecourts_cis/domain/ecourts_models.dart';

void main() {
  group('Goal 1: e-Courts CIS 3.2 Domain & Validation Tests', () {
    test('CnrValidator cleans whitespace, dashes and converts to uppercase', () {
      expect(CnrValidator.cleanCnr('up-hc 01-012345-2026'), 'UPHC010123452026');
      expect(CnrValidator.cleanCnr('  uplk010045212026  '), 'UPLK010045212026');
    });

    test('CnrValidator validates exact 16-character format', () {
      // Valid
      expect(CnrValidator.validate('UPHC010123452026'), isNull);
      expect(CnrValidator.validate('UPLK010045212026'), isNull);
      expect(CnrValidator.validate('DLST020011222025'), isNull);
      expect(CnrValidator.validate(null), isNull); // Optional on new filing
      expect(CnrValidator.validate('   '), isNull); // Optional on empty

      // Invalid lengths
      expect(CnrValidator.validate('UPHC01'), contains('16 अक्षरों'));
      expect(CnrValidator.validate('UPHC010123452026EXTRA'), contains('16 अक्षरों'));

      // Invalid pattern (e.g. all digits or numbers in state prefix)
      expect(CnrValidator.validate('1234567890123456'), contains('अमान्य प्रारूप'));
      expect(CnrValidator.validate('UP12010123452026'), contains('अमान्य प्रारूप'));
    });

    test('CnrValidator formats CNR into readable segments', () {
      expect(CnrValidator.format('UPHC010123452026'), 'UP-HC01-012345-2026');
      expect(CnrValidator.format('UPLK010045212025'), 'UP-LK01-004521-2025');
    });

    test('EcourtsSyncResult fromJson deserializes full court record correctly', () {
      final json = {
        'status': 'SUCCESS',
        'cnr_number': 'UPLK010045212026',
        'formatted_cnr': 'UP-LK01-004521-2026',
        'is_verified_ecourts': true,
        'cis_version': 'e-Courts CIS 3.2 (NJDG Synchronized)',
        'court_name': 'जिला एवं सत्र न्यायालय, लखनऊ',
        'court_coram': 'श्री राकेश कुमार सिंह, अपर सत्र न्यायाधीश',
        'court_room_number': 'कोर्ट रूम सं. ४',
        'case_type_and_number': 'आपराधिक वाद सं. 4521/2026',
        'fir_number': '124/2026',
        'police_station': 'कोतवाली नगर',
        'district': 'लखनऊ',
        'state': 'Uttar Pradesh',
        'stage_of_case': 'जमानत प्रार्थना पत्र सुनवाई',
        'next_hearing_date': '2026-09-12',
        'hearing_purpose': 'अग्रिम बहस',
        'cause_list_item_number': 14,
        'last_hearing_date': '2026-09-05',
        'last_court_order': 'केस डायरी तलब की गई।',
        'order_pdf_url': 'https://judgments.ecourts.gov.in/pdfcache/cis_order_uplk010045212026.pdf',
        'synced_at': '2026-09-06T12:00:00Z',
        'proceedings_history': [
          {
            'proceeding_date': '2026-09-05',
            'business_recorded': 'केस डायरी तलब की गई।',
            'purpose_of_next_date': 'जमानत प्रार्थना पत्र सुनवाई',
          }
        ]
      };

      final result = EcourtsSyncResult.fromJson(json);
      expect(result.cnrNumber, 'UPLK010045212026');
      expect(result.formattedCnr, 'UP-LK01-004521-2026');
      expect(result.isVerifiedEcourts, isTrue);
      expect(result.courtCoram, contains('राकेश कुमार'));
      expect(result.courtRoomNumber, 'कोर्ट रूम सं. ४');
      expect(result.nextHearingDate, '2026-09-12');
      expect(result.orderPdfUrl, contains('judgments.ecourts.gov.in'));
      expect(result.proceedingsHistory.length, 1);
    });

    test('DailyCauseList fromJson deserializes listing board correctly', () {
      final json = {
        'court_complex': 'जिला एवं सत्र न्यायालय, लखनऊ',
        'court_room': 'कक्ष संख्या ४',
        'presiding_judge': 'श्री राकेश कुमार सिंह',
        'cause_list_date': '2026-09-06',
        'published_at': '2026-09-06T08:30:00+05:30',
        'total_listed': 2,
        'cis_version': 'CIS 3.2 Daily Board',
        'entries': [
          {
            'item_number': 1,
            'court_room': 'कक्ष सं. ४',
            'court_designation': 'अपर जिला एवं सत्र न्यायालय',
            'coram': 'श्री राकेश कुमार सिंह',
            'case_number': 'Bail Application No. 342/2026',
            'cnr_number': 'UPLK010003422026',
            'fir_details': 'मु.अ.सं. 89/2026, थाना हजरतगंज',
            'applicant_name': 'रोहित कुमार',
            'opposite_party': 'उत्तर प्रदेश राज्य',
            'under_sections': ['303 BNS', '317(2) BNS'],
            'advocate_for_applicant': 'एडवोकेट के. एस. चौहान',
            'advocate_for_opposite': 'ए.डी.जी.सी.',
            'stage_of_hearing': 'जमानत प्रार्थना पत्र सुनवाई',
            'listing_status': 'CALLED_OUT',
            'status_label_hi': 'पुकार हुई (बहस जारी)',
            'is_my_case': true,
          },
          {
            'item_number': 2,
            'court_room': 'कक्ष सं. ४',
            'court_designation': 'अपर जिला एवं सत्र न्यायालय',
            'coram': 'श्री राकेश कुमार सिंह',
            'case_number': 'Sessions Trial No. 124/2025',
            'cnr_number': 'UPLK010001242025',
            'fir_details': 'मु.अ.सं. 412/2025, थाना कैंट',
            'applicant_name': 'दिनेश कुमार वर्मा',
            'opposite_party': 'उत्तर प्रदेश राज्य',
            'under_sections': ['302 IPC'],
            'advocate_for_applicant': 'अधिवक्ता एम. पी. शर्मा',
            'advocate_for_opposite': 'डी.जी.सी.',
            'stage_of_hearing': 'अभियोजन साक्ष्य',
            'listing_status': 'LISTED_TODAY',
            'status_label_hi': 'सूचीबद्ध',
            'is_my_case': false,
          }
        ]
      };

      final causeList = DailyCauseList.fromJson(json);
      expect(causeList.totalListed, 2);
      expect(causeList.entries.length, 2);
      expect(causeList.entries[0].itemNumber, 1);
      expect(causeList.entries[0].isMyCase, isTrue);
      expect(causeList.entries[0].listingStatus, 'CALLED_OUT');
      expect(causeList.entries[1].isMyCase, isFalse);
    });
  });
}
