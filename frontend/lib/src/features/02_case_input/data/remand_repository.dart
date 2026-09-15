import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/chamber_http_client.dart';
import '../domain/arrest_compliance_models.dart';
import '../domain/default_bail_models.dart';
import '../domain/undertrial_models.dart';

final remandRepositoryProvider = Provider<RemandRepository>((ref) {
  return RemandRepository(ref.read(chamberHttpClientProvider));
});

class RemandRepository {
  final ChamberHttpClient _client;

  RemandRepository(this._client);

  Future<DefaultBailAuditResult> auditDefaultBail({
    required String caseId,
    required DateTime firstRemandDate,
    required String statutoryRegime,
    required List<Map<String, dynamic>> offenseSections,
    List<Map<String, dynamic>> custodyHistory = const [],
    bool chargesheetFiled = false,
    DateTime? chargesheetFilingDate,
    List<String> chargesheetAnnexures = const [],
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final response = await _client.post(
      path: '/api/v1/remand/audit-default-bail',
      actionName: 'AUDIT_DEFAULT_BAIL_SEC_187',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'first_remand_date': firstRemandDate.toIso8601String().split('T').first,
        'statutory_regime': statutoryRegime,
        'offense_sections': offenseSections,
        'custody_history': custodyHistory,
        'chargesheet_filed': chargesheetFiled,
        'chargesheet_filing_date': chargesheetFilingDate?.toIso8601String().split('T').first,
        'chargesheet_annexures': chargesheetAnnexures,
        'accused_name': accusedName,
        'police_station': policeStation,
        'district': district,
        'court_name': 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return DefaultBailAuditResult.fromJson(data);
    } else {
      throw Exception('डिफ़ॉल्ट जमानत मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<ArrestComplianceAuditResult> auditArrestCompliance({
    required String caseId,
    required String accusedName,
    required String policeStation,
    required String district,
    required String courtName,
    required List<Map<String, dynamic>> charges,
    required DateTime arrestTimestamp,
    required DateTime remandProductionTimestamp,
    required bool noticeIssuedSec35Bnss,
    required bool flightOrTamperingRiskRecorded,
    required int arrestMemoWitnessCount,
    required bool familyIntimationRecorded,
    required bool medicalExaminationConducted,
    required bool magistrateIndependentReasonsRecorded,
    String? policeRemandReasonsRawText,
  }) async {
    final response = await _client.post(
      path: '/api/v1/remand/audit-arrest-compliance',
      actionName: 'AUDIT_ARREST_REMAND_COMPLIANCE',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'accused_name': accusedName,
        'police_station': policeStation,
        'district': district,
        'court_name': courtName,
        'charges': charges,
        'arrest_timestamp': arrestTimestamp.toIso8601String(),
        'remand_production_timestamp': remandProductionTimestamp.toIso8601String(),
        'notice_issued_sec_35_bnss': noticeIssuedSec35Bnss,
        'flight_or_tampering_risk_recorded': flightOrTamperingRiskRecorded,
        'arrest_memo_witness_count': arrestMemoWitnessCount,
        'family_intimation_recorded': familyIntimationRecorded,
        'medical_examination_conducted': medicalExaminationConducted,
        'magistrate_independent_reasons_recorded': magistrateIndependentReasonsRecorded,
        'police_remand_reasons_raw_text': policeRemandReasonsRawText,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ArrestComplianceAuditResult.fromJson(data);
    } else {
      throw Exception('रिमांड अनुपालन मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<UndertrialReliefAuditResult> auditUndertrialRelief({
    required String caseId,
    required String accusedName,
    required String jailName,
    required DateTime custodyStartDate,
    DateTime? calculationDate,
    required bool isFirstTimeOffender,
    required bool multipleCasesPending,
    required List<Map<String, dynamic>> charges,
    required String firNumber,
    required String policeStation,
    required String district,
  }) async {
    final response = await _client.post(
      path: '/api/v1/remand/audit-undertrial-relief',
      actionName: 'AUDIT_UNDERTRIAL_RELIEF_SEC_479',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'accused_name': accusedName,
        'jail_name': jailName,
        'custody_start_date': custodyStartDate.toIso8601String().split('T').first,
        'calculation_date': calculationDate?.toIso8601String().split('T').first,
        'is_first_time_offender': isFirstTimeOffender,
        'multiple_cases_pending': multipleCasesPending,
        'charges': charges,
        'fir_number': firNumber,
        'police_station': policeStation,
        'district': district,
        'court_name': 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return UndertrialReliefAuditResult.fromJson(data);
    } else {
      throw Exception('विचाराधीन राहत मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
