class ContradictionGridItemModel {
  final String statementSegment;
  final String statement161;
  final String? statement164;
  final String chiefDeposition;
  final String classification;
  final String severity; // 'FATAL', 'MATERIAL', 'TRIVIAL'
  final String tahsildarSinghApplicabilityHindi;
  final String statutoryConfrontationScriptHindi;
  final String markedExhibitIdentifier;

  ContradictionGridItemModel({
    required this.statementSegment,
    required this.statement161,
    this.statement164,
    required this.chiefDeposition,
    required this.classification,
    required this.severity,
    required this.tahsildarSinghApplicabilityHindi,
    required this.statutoryConfrontationScriptHindi,
    required this.markedExhibitIdentifier,
  });

  factory ContradictionGridItemModel.fromJson(Map<String, dynamic> json) {
    return ContradictionGridItemModel(
      statementSegment: json['statement_segment'] as String? ?? '',
      statement161: json['statement_161'] as String? ?? '',
      statement164: json['statement_164'] as String?,
      chiefDeposition: json['chief_deposition'] as String? ?? '',
      classification: json['classification'] as String? ?? 'MATERIAL_IMPROVEMENT',
      severity: json['severity'] as String? ?? 'MATERIAL',
      tahsildarSinghApplicabilityHindi: json['tahsildar_singh_applicability_hindi'] as String? ?? '',
      statutoryConfrontationScriptHindi: json['statutory_confrontation_script_hindi'] as String? ?? '',
      markedExhibitIdentifier: json['marked_exhibit_identifier'] as String? ?? 'Ex. D-1',
    );
  }
}

class WitnessImpeachmentAuditResult {
  final String caseId;
  final String witnessCode;
  final String witnessName;
  final bool hasFatalContradictions;
  final List<ContradictionGridItemModel> gridAnalysis;
  final List<Map<String, dynamic>> markedExhibitsSummary;
  final List<String> ioCrossExaminationReminders;
  final String confrontationMasterScriptHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  WitnessImpeachmentAuditResult({
    required this.caseId,
    required this.witnessCode,
    required this.witnessName,
    required this.hasFatalContradictions,
    required this.gridAnalysis,
    required this.markedExhibitsSummary,
    required this.ioCrossExaminationReminders,
    required this.confrontationMasterScriptHindi,
    required this.citedPrecedents,
  });

  factory WitnessImpeachmentAuditResult.fromJson(Map<String, dynamic> json) {
    return WitnessImpeachmentAuditResult(
      caseId: json['case_id'] as String,
      witnessCode: json['witness_code'] as String? ?? 'PW-1',
      witnessName: json['witness_name'] as String? ?? 'साक्षी',
      hasFatalContradictions: json['has_fatal_contradictions'] as bool? ?? false,
      gridAnalysis: (json['grid_analysis'] as List<dynamic>?)
              ?.map((e) => ContradictionGridItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      markedExhibitsSummary: (json['marked_exhibits_summary'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      ioCrossExaminationReminders: List<String>.from(json['io_cross_examination_reminders'] ?? []),
      confrontationMasterScriptHindi: json['confrontation_master_script_hindi'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
