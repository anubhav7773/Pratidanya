class UndertrialReliefAuditResult {
  final String caseId;
  final bool isReliefApplicable;
  final String governingStatute;
  final String statutoryThresholdFraction; // '1/3' or '1/2'
  final int maxPrescribedTermMonths;
  final double thresholdMonths;
  final double actualDetentionServedMonths;
  final double overstayMonths;
  final bool isDisqualified;
  final String? disqualificationReason;
  final String retrospectiveMandateTextHindi;
  final String jailSuperintendentMandateSec4793;
  final String courtApplicationDraftHindi;
  final String jailSuperintendentNoticeDraftHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  UndertrialReliefAuditResult({
    required this.caseId,
    required this.isReliefApplicable,
    required this.governingStatute,
    required this.statutoryThresholdFraction,
    required this.maxPrescribedTermMonths,
    required this.thresholdMonths,
    required this.actualDetentionServedMonths,
    required this.overstayMonths,
    required this.isDisqualified,
    this.disqualificationReason,
    required this.retrospectiveMandateTextHindi,
    required this.jailSuperintendentMandateSec4793,
    required this.courtApplicationDraftHindi,
    required this.jailSuperintendentNoticeDraftHindi,
    required this.citedPrecedents,
  });

  factory UndertrialReliefAuditResult.fromJson(Map<String, dynamic> json) {
    return UndertrialReliefAuditResult(
      caseId: json['case_id'] as String,
      isReliefApplicable: json['is_relief_applicable'] as bool? ?? false,
      governingStatute: json['governing_statute'] as String? ?? '',
      statutoryThresholdFraction: json['statutory_threshold_fraction'] as String? ?? '1/3',
      maxPrescribedTermMonths: json['max_prescribed_term_months'] as int? ?? 0,
      thresholdMonths: (json['threshold_months'] as num?)?.toDouble() ?? 0.0,
      actualDetentionServedMonths: (json['actual_detention_served_months'] as num?)?.toDouble() ?? 0.0,
      overstayMonths: (json['overstay_months'] as num?)?.toDouble() ?? 0.0,
      isDisqualified: json['is_disqualified'] as bool? ?? false,
      disqualificationReason: json['disqualification_reason'] as String?,
      retrospectiveMandateTextHindi: json['retrospective_mandate_text_hindi'] as String? ?? '',
      jailSuperintendentMandateSec4793: json['jail_superintendent_mandate_sec_479_3'] as String? ?? '',
      courtApplicationDraftHindi: json['court_application_draft_hindi'] as String? ?? '',
      jailSuperintendentNoticeDraftHindi: json['jail_superintendent_notice_draft_hindi'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
