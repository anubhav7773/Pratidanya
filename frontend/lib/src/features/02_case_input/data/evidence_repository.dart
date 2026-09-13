import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/electronic_evidence_models.dart';

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  return EvidenceRepository();
});

class EvidenceRepository {
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/evidence/audit-bsa-certificate');

    final payload = jsonEncode({
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
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: payload,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ElectronicEvidenceAuditResult.fromJson(data);
    } else {
      throw Exception('इलेक्ट्रॉनिक साक्ष्य मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
