class StatutoryDefect {
  final String statutoryClause;
  final String governingDoctrine;
  final String severity; // 'FATAL', 'MATERIAL', 'PROCEDURAL'
  final String defectDescriptionHindi;
  final String trialCountermeasure;

  StatutoryDefect({
    required this.statutoryClause,
    required this.governingDoctrine,
    required this.severity,
    required this.defectDescriptionHindi,
    required this.trialCountermeasure,
  });

  factory StatutoryDefect.fromJson(Map<String, dynamic> json) {
    return StatutoryDefect(
      statutoryClause: json['statutory_clause'] as String? ?? '',
      governingDoctrine: json['governing_doctrine'] as String? ?? '',
      severity: json['severity'] as String? ?? 'PROCEDURAL',
      defectDescriptionHindi: json['defect_description_hindi'] as String? ?? '',
      trialCountermeasure: json['trial_countermeasure'] as String? ?? '',
    );
  }
}

class ElectronicEvidenceAuditResult {
  final String caseId;
  final String exhibitMark;
  final String admissibilityStatus; // 'FATAL_DEFECT_INADMISSIBLE', 'SUBSTANTIAL_REGULARITY_CHALLENGEABLE', 'PRIMA_FACIE_ADMISSIBLE'
  final bool isScheduleCompliant;
  final bool isHashValid;
  final List<StatutoryDefect> statutoryDefects;
  final String actionableCourtroomObjection;
  final String writtenObjectionPetitionDraft;
  final List<Map<String, dynamic>> citedPrecedents;

  ElectronicEvidenceAuditResult({
    required this.caseId,
    required this.exhibitMark,
    required this.admissibilityStatus,
    required this.isScheduleCompliant,
    required this.isHashValid,
    required this.statutoryDefects,
    required this.actionableCourtroomObjection,
    required this.writtenObjectionPetitionDraft,
    required this.citedPrecedents,
  });

  factory ElectronicEvidenceAuditResult.fromJson(Map<String, dynamic> json) {
    return ElectronicEvidenceAuditResult(
      caseId: json['case_id'] as String,
      exhibitMark: json['exhibit_mark'] as String? ?? '',
      admissibilityStatus: json['admissibility_status'] as String? ?? 'FATAL_DEFECT_INADMISSIBLE',
      isScheduleCompliant: json['is_schedule_compliant'] as bool? ?? false,
      isHashValid: json['is_hash_valid'] as bool? ?? false,
      statutoryDefects: (json['statutory_defects'] as List<dynamic>?)
              ?.map((e) => StatutoryDefect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      actionableCourtroomObjection: json['actionable_courtroom_objection'] as String? ?? '',
      writtenObjectionPetitionDraft: json['written_objection_petition_draft'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
