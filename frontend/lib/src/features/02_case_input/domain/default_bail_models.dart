class PrecedentCitation {
  final String caseTitle;
  final String citation;
  final String legalRatioHindi;
  final String verifiedUrl;

  PrecedentCitation({
    required this.caseTitle,
    required this.citation,
    required this.legalRatioHindi,
    required this.verifiedUrl,
  });

  factory PrecedentCitation.fromJson(Map<String, dynamic> json) {
    return PrecedentCitation(
      caseTitle: json['case_title'] as String? ?? '',
      citation: json['citation'] as String? ?? '',
      legalRatioHindi: json['legal_ratio_hindi'] as String? ?? '',
      verifiedUrl: json['verified_url'] as String? ?? '',
    );
  }
}

class DefaultBailAuditResult {
  final String caseId;
  final int statutoryThresholdDays;
  final int daysElapsedInCustody;
  final bool isDefaultBailCrystallized;
  final DateTime defaultBailAccrualTimestamp;
  final double hoursUntilDefaultBail;
  final int policeCustodyDaysUsed;
  final int policeCustodyDaysRemaining;
  final bool policeCustodyWindowExpired;
  final String policeCustodyAlertHindi;
  final bool isChargesheetIncomplete;
  final String? defectType;
  final List<String> missingMandatoryReports;
  final String chargesheetDefectSummaryHindi;
  final String statutoryPetitionDraftHindi;
  final List<PrecedentCitation> citedPrecedents;

  DefaultBailAuditResult({
    required this.caseId,
    required this.statutoryThresholdDays,
    required this.daysElapsedInCustody,
    required this.isDefaultBailCrystallized,
    required this.defaultBailAccrualTimestamp,
    required this.hoursUntilDefaultBail,
    required this.policeCustodyDaysUsed,
    required this.policeCustodyDaysRemaining,
    required this.policeCustodyWindowExpired,
    required this.policeCustodyAlertHindi,
    required this.isChargesheetIncomplete,
    this.defectType,
    required this.missingMandatoryReports,
    required this.chargesheetDefectSummaryHindi,
    required this.statutoryPetitionDraftHindi,
    required this.citedPrecedents,
  });

  factory DefaultBailAuditResult.fromJson(Map<String, dynamic> json) {
    return DefaultBailAuditResult(
      caseId: json['case_id'] as String,
      statutoryThresholdDays: json['statutory_threshold_days'] as int? ?? 60,
      daysElapsedInCustody: json['days_elapsed_in_custody'] as int? ?? 0,
      isDefaultBailCrystallized: json['is_default_bail_crystallized'] as bool? ?? false,
      defaultBailAccrualTimestamp: DateTime.parse(json['default_bail_accrual_timestamp'] as String),
      hoursUntilDefaultBail: (json['hours_until_default_bail'] as num?)?.toDouble() ?? 0.0,
      policeCustodyDaysUsed: json['police_custody_days_used'] as int? ?? 0,
      policeCustodyDaysRemaining: json['police_custody_days_remaining'] as int? ?? 15,
      policeCustodyWindowExpired: json['police_custody_window_expired'] as bool? ?? false,
      policeCustodyAlertHindi: json['police_custody_alert_hindi'] as String? ?? '',
      isChargesheetIncomplete: json['is_chargesheet_incomplete'] as bool? ?? false,
      defectType: json['defect_type'] as String?,
      missingMandatoryReports: List<String>.from(json['missing_mandatory_reports'] ?? []),
      chargesheetDefectSummaryHindi: json['chargesheet_defect_summary_hindi'] as String? ?? '',
      statutoryPetitionDraftHindi: json['statutory_petition_draft_hindi'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => PrecedentCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
