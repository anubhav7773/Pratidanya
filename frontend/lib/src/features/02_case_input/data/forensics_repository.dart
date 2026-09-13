import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/medico_legal_models.dart';
import '../domain/malkhana_models.dart';

final forensicsRepositoryProvider = Provider<ForensicsRepository>((ref) {

  return ForensicsRepository();
});

class ForensicsRepository {
  Future<MedicalMatrixAuditResult> generateMedicalMatrix({
    required String caseId,
    required List<Map<String, dynamic>> ocularAllegations,
    required Map<String, dynamic> postMortemData,
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/forensics/generate-medical-matrix');

    final payload = jsonEncode({
      'case_id': caseId,
      'ocular_allegations': ocularAllegations,
      'post_mortem_data': postMortemData,
      'accused_name': accusedName,
      'police_station': policeStation,
      'district': district,
      'court_name': 'न्यायालय अपर सत्र न्यायाधीश',
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
      return MedicalMatrixAuditResult.fromJson(data);
    } else {
      throw Exception('फॉरेंसिक मेडिकल मैट्रिक्स मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<MalkhanaAuditResult> auditMalkhanaChain({
    required String caseId,
    required String actType,
    required DateTime seizureDate,
    required String seizureSealImpression,
    required DateTime malkhanaDepositDate,
    required String malkhanaRegisterNumber,
    required bool specimenSealDeposited,
    String? gdDepositEntryNumber,
    required DateTime fslDispatchDate,
    required DateTime fslReceivedDate,
    required String fslReceiptSealImpression,
    required bool roadCertificateAnnexed,
    String? roadCertificateNumber,
    String? carrierConstableName,
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/forensics/audit-malkhana-chain');

    final payload = jsonEncode({
      'case_id': caseId,
      'act_type': actType,
      'seizure_date': seizureDate.toIso8601String(),
      'seizure_seal_impression': seizureSealImpression,
      'malkhana_deposit_date': malkhanaDepositDate.toIso8601String(),
      'malkhana_register_number': malkhanaRegisterNumber,
      'specimen_seal_deposited': specimenSealDeposited,
      'gd_deposit_entry_number': gdDepositEntryNumber,
      'fsl_dispatch_date': fslDispatchDate.toIso8601String(),
      'fsl_received_date': fslReceivedDate.toIso8601String(),
      'fsl_receipt_seal_impression': fslReceiptSealImpression,
      'road_certificate_annexed': roadCertificateAnnexed,
      'road_certificate_number': roadCertificateNumber,
      'carrier_constable_name': carrierConstableName ?? 'कांस्टेबल वाहक',
      'accused_name': accusedName,
      'police_station': policeStation,
      'district': district,
      'court_name': 'न्यायालय विशेष न्यायाधीश',
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
      return MalkhanaAuditResult.fromJson(data);
    } else {
      throw Exception('मालखाना अभिरक्षा शृंखला मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}

