class NdpsComplianceResult {
  final String caseId;
  final String substanceName;
  final String quantityCategory; // 'SMALL_QUANTITY', 'INTERMEDIATE_QUANTITY', 'COMMERCIAL_QUANTITY'
  final bool isSection37BarApplicable;
  final String section50ComplianceStatus; // 'FATAL_DEFECT', 'SUSPICIOUS', 'COMPLIANT', 'NOT_APPLICABLE'
  final List<String> detectedProceduralDefects;
  final List<String> tailoredBailGrounds;
  final List<Map<String, dynamic>> citedSupremeCourtPrecedents;

  NdpsComplianceResult({
    required this.caseId,
    required this.substanceName,
    required this.quantityCategory,
    required this.isSection37BarApplicable,
    required this.section50ComplianceStatus,
    required this.detectedProceduralDefects,
    required this.tailoredBailGrounds,
    required this.citedSupremeCourtPrecedents,
  });

  factory NdpsComplianceResult.fromJson(Map<String, dynamic> json) {
    return NdpsComplianceResult(
      caseId: json['case_id'] as String,
      substanceName: json['substance_name'] as String,
      quantityCategory: json['quantity_category'] as String,
      isSection37BarApplicable: json['is_section_37_bar_applicable'] as bool? ?? false,
      section50ComplianceStatus: json['section_50_compliance_status'] as String,
      detectedProceduralDefects: List<String>.from(json['detected_procedural_defects'] ?? []),
      tailoredBailGrounds: List<String>.from(json['tailored_bail_grounds'] ?? []),
      citedSupremeCourtPrecedents: (json['cited_supreme_court_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class PocsoAgeEvaluationResult {
  final String caseId;
  final String statutoryTierApplicable;
  final double? computedAgeAtIncidentYears;
  final bool isMajorityProbable;
  final String ageDeterminationAnalysisHindi;
  final List<String> presumptionRebuttalStrategy;
  final List<String> bailGroundsPocso;
  final List<Map<String, dynamic>> citedPrecedents;

  PocsoAgeEvaluationResult({
    required this.caseId,
    required this.statutoryTierApplicable,
    this.computedAgeAtIncidentYears,
    required this.isMajorityProbable,
    required this.ageDeterminationAnalysisHindi,
    required this.presumptionRebuttalStrategy,
    required this.bailGroundsPocso,
    required this.citedPrecedents,
  });

  factory PocsoAgeEvaluationResult.fromJson(Map<String, dynamic> json) {
    return PocsoAgeEvaluationResult(
      caseId: json['case_id'] as String,
      statutoryTierApplicable: json['statutory_tier_applicable'] as String,
      computedAgeAtIncidentYears: (json['computed_age_at_incident_years'] as num?)?.toDouble(),
      isMajorityProbable: json['is_majority_probable'] as bool? ?? false,
      ageDeterminationAnalysisHindi: json['age_determination_analysis_hindi'] as String,
      presumptionRebuttalStrategy: List<String>.from(json['presumption_rebuttal_strategy'] ?? []),
      bailGroundsPocso: List<String>.from(json['bail_grounds_pocso'] ?? []),
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
