class BasePredicateCase {
  final String crimeNumber;
  final String sections;
  final String status;
  final String? disposalDate;

  BasePredicateCase({
    required this.crimeNumber,
    required this.sections,
    required this.status,
    this.disposalDate,
  });

  Map<String, dynamic> toJson() => {
        'crime_number': crimeNumber,
        'sections': sections,
        'status': status,
        'disposal_date': disposalDate,
      };

  factory BasePredicateCase.fromJson(Map<String, dynamic> json) => BasePredicateCase(
        crimeNumber: json['crime_number'] as String? ?? '',
        sections: json['sections'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING_TRIAL',
        disposalDate: json['disposal_date'] as String?,
      );
}

class GroundOfChallenge {
  final String doctrine;
  final String ruleOrStatute;
  final String severity;
  final String argumentHindi;
  final String statutoryRemedy;

  GroundOfChallenge({
    required this.doctrine,
    required this.ruleOrStatute,
    required this.severity,
    required this.argumentHindi,
    required this.statutoryRemedy,
  });

  factory GroundOfChallenge.fromJson(Map<String, dynamic> json) => GroundOfChallenge(
        doctrine: json['doctrine'] as String? ?? '',
        ruleOrStatute: json['rule_or_statute'] as String? ?? '',
        severity: json['severity'] as String? ?? 'MATERIAL_IRREGULARITY',
        argumentHindi: json['argument_hindi'] as String? ?? '',
        statutoryRemedy: json['statutory_remedy'] as String? ?? '',
      );
}

class RegionalActsAuditResult {
  final String caseId;
  final String statuteApplied;
  final String proceduralViability;
  final bool isFarhanaCollapseTriggered;
  final bool isRamjiPandeyDefectTriggered;
  final List<GroundOfChallenge> groundsOfChallenge;
  final String recommendedForum;
  final String draftPetitionType;
  final String draftPetitionHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  RegionalActsAuditResult({
    required this.caseId,
    required this.statuteApplied,
    required this.proceduralViability,
    required this.isFarhanaCollapseTriggered,
    required this.isRamjiPandeyDefectTriggered,
    required this.groundsOfChallenge,
    required this.recommendedForum,
    required this.draftPetitionType,
    required this.draftPetitionHindi,
    required this.citedPrecedents,
  });

  factory RegionalActsAuditResult.fromJson(Map<String, dynamic> json) => RegionalActsAuditResult(
        caseId: json['case_id'] as String,
        statuteApplied: json['statute_applied'] as String? ?? 'UP_GANGSTERS_ACT_1986',
        proceduralViability: json['procedural_viability'] as String? ?? 'PRIMA_FACIE_REGULAR',
        isFarhanaCollapseTriggered: json['is_farhana_collapse_triggered'] as bool? ?? false,
        isRamjiPandeyDefectTriggered: json['is_ramji_pandey_defect_triggered'] as bool? ?? false,
        groundsOfChallenge: (json['grounds_of_challenge'] as List<dynamic>?)
                ?.map((e) => GroundOfChallenge.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recommendedForum: json['recommended_forum'] as String? ?? '',
        draftPetitionType: json['draft_petition_type'] as String? ?? '',
        draftPetitionHindi: json['draft_petition_hindi'] as String? ?? '',
        citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
}
