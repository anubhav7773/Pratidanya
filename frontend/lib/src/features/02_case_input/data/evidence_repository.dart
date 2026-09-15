import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/chamber_http_client.dart';
import '../domain/electronic_evidence_models.dart';

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  return EvidenceRepository(ref.read(chamberHttpClientProvider));
});

class EvidenceRepository {
  final ChamberHttpClient _client;

  EvidenceRepository(this._client);

  Future<ElectronicEvidenceAuditResult> auditBsaCertificate({
    required String caseId,
    required String exhibitMark,
    required String evidenceType,
    required bool scheduleFormatMatched,
    required bool partAExecuted,
    String? partASignatoryType,
    required bool partBExecuted,
    String? partBExpertDesignation,
    required String hashAlgorithm,
    String? declaredHashValue,
    String? makeModel,
    String? serialNumber,
    String? imeiNumber,
    String? macAddress,
    required bool contemporaneousAcquisition,
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final response = await _client.post(
      path: '/api/v1/evidence/audit-bsa-certificate',
      actionName: 'AUDIT_BSA_SEC_63_CERTIFICATE',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'exhibit_mark': exhibitMark,
        'evidence_type': evidenceType,
        'certificate_statute': 'BSA_SECTION_63',
        'schedule_format_matched': scheduleFormatMatched,
        'part_a_executed': partAExecuted,
        'part_a_signatory_type': partASignatoryType ?? 'INVESTIGATING_OFFICER',
        'part_b_executed': partBExecuted,
        'part_b_expert_designation': partBExpertDesignation,
        'hash_algorithm': hashAlgorithm,
        'declared_hash_value': declaredHashValue,
        'device_identifiers': {
          'make_model': makeModel,
          'serial_number': serialNumber,
          'imei_number': imeiNumber,
          'mac_address': macAddress,
        },
        'contemporaneous_acquisition': contemporaneousAcquisition,
        'accused_name': accusedName,
        'police_station': policeStation,
        'district': district,
        'court_name': 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ElectronicEvidenceAuditResult.fromJson(data);
    } else {
      throw Exception('इलेक्ट्रॉनिक साक्ष्य मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
