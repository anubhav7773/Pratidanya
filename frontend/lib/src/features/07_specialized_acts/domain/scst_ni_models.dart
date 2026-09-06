class ScstComplianceResult {
  final String caseId;
  final bool isPublicViewTestSatisfied;
  final bool isAnticipatoryBailMaintainable;
  final String section18BarBypassRatio;
  final String section14aAppealLimitationStatus;
  final int delayDays;
  final String mandatoryVictimNoticeWarning;
  final List<String> tailoredGrounds;
  final List<Map<String, dynamic>> citedPrecedents;

  ScstComplianceResult({
    required this.caseId,
    required this.isPublicViewTestSatisfied,
    required this.isAnticipatoryBailMaintainable,
    required this.section18BarBypassRatio,
    required this.section14aAppealLimitationStatus,
    required this.delayDays,
    required this.mandatoryVictimNoticeWarning,
    required this.tailoredGrounds,
    required this.citedPrecedents,
  });

  factory ScstComplianceResult.fromJson(Map<String, dynamic> json) {
    return ScstComplianceResult(
      caseId: json['case_id'] as String,
      isPublicViewTestSatisfied: json['is_public_view_test_satisfied'] as bool? ?? false,
      isAnticipatoryBailMaintainable: json['is_anticipatory_bail_maintainable'] as bool? ?? false,
      section18BarBypassRatio: json['section_18_bar_bypass_ratio'] as String,
      section14aAppealLimitationStatus: json['section_14a_appeal_limitation_status'] as String,
      delayDays: json['delay_days'] as int? ?? 0,
      mandatoryVictimNoticeWarning: json['mandatory_victim_notice_warning'] as String,
      tailoredGrounds: List<String>.from(json['tailored_grounds'] ?? []),
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class NiActComplianceResult {
  final String caseId;
  final bool dispatchWithin30Days;
  final DateTime curePeriod15DaysExpiryDate;
  final bool isPrematureComplaint;
  final bool isTimeBarred;
  final List<String> fatalDefectsDetected;
  final List<String> defenseRebuttalStrategy;
  final List<String> statutoryDischargeOrQuashingGrounds;
  final String? compoundingGuidelinesUnder147;
  final List<Map<String, dynamic>> citedPrecedents;

  NiActComplianceResult({
    required this.caseId,
    required this.dispatchWithin30Days,
    required this.curePeriod15DaysExpiryDate,
    required this.isPrematureComplaint,
    required this.isTimeBarred,
    required this.fatalDefectsDetected,
    required this.defenseRebuttalStrategy,
    required this.statutoryDischargeOrQuashingGrounds,
    this.compoundingGuidelinesUnder147,
    required this.citedPrecedents,
  });

  factory NiActComplianceResult.fromJson(Map<String, dynamic> json) {
    return NiActComplianceResult(
      caseId: json['case_id'] as String,
      dispatchWithin30Days: json['dispatch_within_30_days'] as bool? ?? true,
      curePeriod15DaysExpiryDate: DateTime.parse(json['cure_period_15_days_expiry_date'] as String),
      isPrematureComplaint: json['is_premature_complaint'] as bool? ?? false,
      isTimeBarred: json['is_time_barred'] as bool? ?? false,
      fatalDefectsDetected: List<String>.from(json['fatal_defects_detected'] ?? []),
      defenseRebuttalStrategy: List<String>.from(json['defense_rebuttal_strategy'] ?? []),
      statutoryDischargeOrQuashingGrounds: List<String>.from(json['statutory_discharge_or_quashing_grounds'] ?? []),
      compoundingGuidelinesUnder147: json['compounding_guidelines_under_147'] as String?,
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
