class CustodyVulnerability {
  final String issueCode;
  final String severity; // 'FATAL_CHAIN_BREAK', 'MATERIAL_TAMPERING_RISK'
  final String statutoryViolationHindi;
  final String impactAnalysisHindi;
  final String precedentAuthority;

  CustodyVulnerability({
    required this.issueCode,
    required this.severity,
    required this.statutoryViolationHindi,
    required this.impactAnalysisHindi,
    required this.precedentAuthority,
  });

  factory CustodyVulnerability.fromJson(Map<String, dynamic> json) {
    return CustodyVulnerability(
      issueCode: json['issue_code'] as String? ?? '',
      severity: json['severity'] as String? ?? 'MATERIAL_TAMPERING_RISK',
      statutoryViolationHindi: json['statutory_violation_hindi'] as String? ?? '',
      impactAnalysisHindi: json['impact_analysis_hindi'] as String? ?? '',
      precedentAuthority: json['precedent_authority'] as String? ?? '',
    );
  }
}

class MalkhanaAuditResult {
  final String caseId;
  final bool isChainOfCustodyIntact;
  final bool hasFatalTamperingRisk;
  final int fslDispatchDelayDays;
  final List<CustodyVulnerability> fatalVulnerabilities;
  final String actionableDefenseStrategyHindi;
  final String applicationSec254BnssDraftHindi;
  final List<String> crossExaminationCarrierQuestions;
  final List<Map<String, dynamic>> citedPrecedents;

  MalkhanaAuditResult({
    required this.caseId,
    required this.isChainOfCustodyIntact,
    required this.hasFatalTamperingRisk,
    required this.fslDispatchDelayDays,
    required this.fatalVulnerabilities,
    required this.actionableDefenseStrategyHindi,
    required this.applicationSec254BnssDraftHindi,
    required this.crossExaminationCarrierQuestions,
    required this.citedPrecedents,
  });

  factory MalkhanaAuditResult.fromJson(Map<String, dynamic> json) {
    return MalkhanaAuditResult(
      caseId: json['case_id'] as String,
      isChainOfCustodyIntact: json['is_chain_of_custody_intact'] as bool? ?? false,
      hasFatalTamperingRisk: json['has_fatal_tampering_risk'] as bool? ?? false,
      fslDispatchDelayDays: json['fsl_dispatch_delay_days'] as int? ?? 0,
      fatalVulnerabilities: (json['fatal_vulnerabilities'] as List<dynamic>?)
              ?.map((e) => CustodyVulnerability.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      actionableDefenseStrategyHindi: json['actionable_defense_strategy_hindi'] as String? ?? '',
      applicationSec254BnssDraftHindi: json['application_sec_254_bnss_draft_hindi'] as String? ?? '',
      crossExaminationCarrierQuestions: List<String>.from(json['cross_examination_carrier_questions'] ?? []),
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
