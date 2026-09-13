class ConflictFinding {
  final String parameter;
  final String ocularClaim;
  final String autopsyFinding;
  final String scientificVerdictHindi;
  final String biomechanicalAuthority;
  final String impactOnProsecution;
  final String severity; // 'FATAL_CONTRADICTION', 'MATERIAL_DISCREPANCY'

  ConflictFinding({
    required this.parameter,
    required this.ocularClaim,
    required this.autopsyFinding,
    required this.scientificVerdictHindi,
    required this.biomechanicalAuthority,
    required this.impactOnProsecution,
    required this.severity,
  });

  factory ConflictFinding.fromJson(Map<String, dynamic> json) {
    return ConflictFinding(
      parameter: json['parameter'] as String? ?? '',
      ocularClaim: json['ocular_claim'] as String? ?? '',
      autopsyFinding: json['autopsy_finding'] as String? ?? '',
      scientificVerdictHindi: json['scientific_verdict_hindi'] as String? ?? '',
      biomechanicalAuthority: json['biomechanical_authority'] as String? ?? '',
      impactOnProsecution: json['impact_on_prosecution'] as String? ?? '',
      severity: json['severity'] as String? ?? 'MATERIAL_DISCREPANCY',
    );
  }
}

class MedicalMatrixAuditResult {
  final String caseId;
  final String pmrNumber;
  final bool hasFatalConflict;
  final List<ConflictFinding> irreconcilableConflicts;
  final List<String> crossExaminationCrossfireQuestions;
  final String writtenMedicalArgumentDraftHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  MedicalMatrixAuditResult({
    required this.caseId,
    required this.pmrNumber,
    required this.hasFatalConflict,
    required this.irreconcilableConflicts,
    required this.crossExaminationCrossfireQuestions,
    required this.writtenMedicalArgumentDraftHindi,
    required this.citedPrecedents,
  });

  factory MedicalMatrixAuditResult.fromJson(Map<String, dynamic> json) {
    return MedicalMatrixAuditResult(
      caseId: json['case_id'] as String,
      pmrNumber: json['pmr_number'] as String? ?? '',
      hasFatalConflict: json['has_fatal_conflict'] as bool? ?? false,
      irreconcilableConflicts: (json['irreconcilable_conflicts'] as List<dynamic>?)
              ?.map((e) => ConflictFinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crossExaminationCrossfireQuestions: (json['cross_examination_crossfire_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      writtenMedicalArgumentDraftHindi: json['written_medical_argument_draft_hindi'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
