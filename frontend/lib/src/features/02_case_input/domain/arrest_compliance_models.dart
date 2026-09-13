class ProceduralViolation {
  final String statutoryProvision;
  final String governingDoctrine;
  final String severity; // 'FATAL', 'MATERIAL', 'PROCEDURAL'
  final String findingHindi;
  final String actionableRemedy;

  ProceduralViolation({
    required this.statutoryProvision,
    required this.governingDoctrine,
    required this.severity,
    required this.findingHindi,
    required this.actionableRemedy,
  });

  factory ProceduralViolation.fromJson(Map<String, dynamic> json) {
    return ProceduralViolation(
      statutoryProvision: json['statutory_provision'] as String? ?? '',
      governingDoctrine: json['governing_doctrine'] as String? ?? '',
      severity: json['severity'] as String? ?? 'PROCEDURAL',
      findingHindi: json['finding_hindi'] as String? ?? '',
      actionableRemedy: json['actionable_remedy'] as String? ?? '',
    );
  }
}

class ArrestComplianceAuditResult {
  final String caseId;
  final String antilCategory; // 'CATEGORY_A', 'CATEGORY_B', 'CATEGORY_C', 'CATEGORY_D'
  final String complianceVerdict; // 'NON_COMPLIANT_VOID_ARREST', 'SUBSTANTIAL_IRREGULARITY', 'COMPLIANT_PROCEDURE'
  final double hoursToProduction;
  final bool isConstitutionallyTimeBarred;
  final List<ProceduralViolation> violations;
  final String magistrateDirectiveRecommendation;
  final String instantObjectionPetitionDraft;
  final List<Map<String, dynamic>> citedPrecedents;

  ArrestComplianceAuditResult({
    required this.caseId,
    required this.antilCategory,
    required this.complianceVerdict,
    required this.hoursToProduction,
    required this.isConstitutionallyTimeBarred,
    required this.violations,
    required this.magistrateDirectiveRecommendation,
    required this.instantObjectionPetitionDraft,
    required this.citedPrecedents,
  });

  factory ArrestComplianceAuditResult.fromJson(Map<String, dynamic> json) {
    return ArrestComplianceAuditResult(
      caseId: json['case_id'] as String,
      antilCategory: json['antil_category'] as String? ?? 'CATEGORY_A',
      complianceVerdict: json['compliance_verdict'] as String? ?? 'COMPLIANT_PROCEDURE',
      hoursToProduction: (json['hours_to_production'] as num?)?.toDouble() ?? 0.0,
      isConstitutionallyTimeBarred: json['is_constitutionally_time_barred'] as bool? ?? false,
      violations: (json['violations'] as List<dynamic>?)
              ?.map((e) => ProceduralViolation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      magistrateDirectiveRecommendation: json['magistrate_directive_recommendation'] as String? ?? '',
      instantObjectionPetitionDraft: json['instant_objection_petition_draft'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
