class HighCourtPleading {
  final String id;
  final String advocateId;
  final String pleadingType; // 'CRIMINAL_APPEAL', 'CRIMINAL_REVISION', 'SECTION_482_APPLICATION'
  final String highCourtBench; // 'LUCKNOW_BENCH', 'ALLAHABAD_PRINCIPAL'
  final String trialCourtName;
  final String trialCaseNumber;
  final DateTime trialJudgmentDate;
  final String trialPresidingJudge;
  final List<String> convictedSections;
  final String quantumOfSentence;
  final bool fineDeposited;
  final String appellantCustodyStatus; // 'IN_JAIL', 'ON_PROVISIONAL_BAIL_389'
  final int daysInCustody;
  final String caseTitle;
  final List<String> accusedNames;
  final String? complainantName;
  final String policeStation;
  final String district;
  final String firNumber;
  final DateTime? certifiedCopyAppliedDate;
  final DateTime? certifiedCopyReadyDate;
  final DateTime limitationExpiryDate;
  final bool isDelayed;
  final int delayDays;

  HighCourtPleading({
    required this.id,
    required this.advocateId,
    required this.pleadingType,
    required this.highCourtBench,
    required this.trialCourtName,
    required this.trialCaseNumber,
    required this.trialJudgmentDate,
    required this.trialPresidingJudge,
    required this.convictedSections,
    required this.quantumOfSentence,
    required this.fineDeposited,
    required this.appellantCustodyStatus,
    required this.daysInCustody,
    required this.caseTitle,
    required this.accusedNames,
    this.complainantName,
    required this.policeStation,
    required this.district,
    required this.firNumber,
    this.certifiedCopyAppliedDate,
    this.certifiedCopyReadyDate,
    required this.limitationExpiryDate,
    required this.isDelayed,
    required this.delayDays,
  });

  factory HighCourtPleading.fromJson(Map<String, dynamic> json) {
    return HighCourtPleading(
      id: json['id'] as String,
      advocateId: json['advocate_id'] as String,
      pleadingType: json['pleading_type'] as String,
      highCourtBench: json['high_court_bench'] as String? ?? 'LUCKNOW_BENCH',
      trialCourtName: json['trial_court_name'] as String,
      trialCaseNumber: json['trial_case_number'] as String,
      trialJudgmentDate: DateTime.parse(json['trial_judgment_date'] as String),
      trialPresidingJudge: json['trial_presiding_judge'] as String,
      convictedSections: List<String>.from(json['convicted_sections'] ?? []),
      quantumOfSentence: json['quantum_of_sentence'] as String,
      fineDeposited: json['fine_deposited'] as bool? ?? false,
      appellantCustodyStatus: json['appellant_custody_status'] as String? ?? 'IN_JAIL',
      daysInCustody: json['days_in_custody'] as int? ?? 0,
      caseTitle: json['case_title'] as String,
      accusedNames: List<String>.from(json['accused_names'] ?? []),
      complainantName: json['complainant_name'] as String?,
      policeStation: json['police_station'] as String,
      district: json['district'] as String,
      firNumber: json['fir_number'] as String,
      certifiedCopyAppliedDate: json['certified_copy_applied_date'] != null
          ? DateTime.parse(json['certified_copy_applied_date'] as String)
          : null,
      certifiedCopyReadyDate: json['certified_copy_ready_date'] != null
          ? DateTime.parse(json['certified_copy_ready_date'] as String)
          : null,
      limitationExpiryDate: DateTime.parse(json['limitation_expiry_date'] as String),
      isDelayed: json['is_delayed'] as bool? ?? false,
      delayDays: json['delay_days'] as int? ?? 0,
    );
  }
}

class HighCourtGroundItem {
  final int groundNumber;
  final String groundHeading;
  final String groundTextHindi;
  final String statutoryBasis;
  final String legalDoctrine;

  HighCourtGroundItem({
    required this.groundNumber,
    required this.groundHeading,
    required this.groundTextHindi,
    required this.statutoryBasis,
    required this.legalDoctrine,
  });

  factory HighCourtGroundItem.fromJson(Map<String, dynamic> json) {
    return HighCourtGroundItem(
      groundNumber: json['ground_number'] as int,
      groundHeading: json['ground_heading'] as String,
      groundTextHindi: json['ground_text_hindi'] as String,
      statutoryBasis: json['statutory_basis'] as String,
      legalDoctrine: json['legal_doctrine'] as String,
    );
  }
}

class HighCourtCitedPrecedent {
  final String citationId;
  final String caseTitle;
  final String courtName;
  final String judgmentDate;
  final String quotedPassage;
  final String verifiedSourceUrl;
  final bool isGroundedInRecord;
  final String relevanceRatio;
  bool isManuallyVerified;

  HighCourtCitedPrecedent({
    required this.citationId,
    required this.caseTitle,
    required this.courtName,
    required this.judgmentDate,
    required this.quotedPassage,
    required this.verifiedSourceUrl,
    required this.isGroundedInRecord,
    required this.relevanceRatio,
    this.isManuallyVerified = false,
  });

  factory HighCourtCitedPrecedent.fromJson(Map<String, dynamic> json) {
    return HighCourtCitedPrecedent(
      citationId: json['citation_id'] as String,
      caseTitle: json['case_title'] as String,
      courtName: json['court_name'] as String,
      judgmentDate: json['judgment_date'] as String,
      quotedPassage: json['quoted_passage'] as String,
      verifiedSourceUrl: json['verified_source_url'] as String,
      isGroundedInRecord: json['is_grounded_in_record'] as bool? ?? true,
      relevanceRatio: json['relevance_ratio'] as String? ?? '',
      isManuallyVerified: json['is_manually_verified'] as bool? ?? false,
    );
  }
}

class HighCourtAppealSuite {
  final String pleadingId;
  final String pleadingType;
  final String highCourtBench;
  final String courtTitleBlock;
  final String memoTitleHindi;
  final String trialReferenceBlock;
  final List<HighCourtGroundItem> grounds;
  final String? interimSuspensionPrayer;
  final String finalReliefPrayer;
  final List<HighCourtCitedPrecedent> citedPrecedents;
  final List<String> statutoryGateWarnings;

  // Interlocutory Sub-Suites
  List<String>? suspensionGrounds;
  String? suspensionInterimPrayer;
  String? suspensionAffidavitText;

  List<String>? delayGrounds;
  String? delayPrayerText;
  String? delayAffidavitDeponent;
  List<String>? delayAffidavitParagraphs;
  String? delayAffidavitVerification;

  HighCourtAppealSuite({
    required this.pleadingId,
    required this.pleadingType,
    required this.highCourtBench,
    required this.courtTitleBlock,
    required this.memoTitleHindi,
    required this.trialReferenceBlock,
    required this.grounds,
    this.interimSuspensionPrayer,
    required this.finalReliefPrayer,
    required this.citedPrecedents,
    required this.statutoryGateWarnings,
  });

  factory HighCourtAppealSuite.fromJson(Map<String, dynamic> json) {
    return HighCourtAppealSuite(
      pleadingId: json['pleading_id'] as String,
      pleadingType: json['pleading_type'] as String,
      highCourtBench: json['high_court_bench'] as String,
      courtTitleBlock: json['court_title_block'] as String,
      memoTitleHindi: json['memo_title_hindi'] as String,
      trialReferenceBlock: json['trial_reference_block'] as String,
      grounds: (json['grounds'] as List<dynamic>)
          .map((g) => HighCourtGroundItem.fromJson(g as Map<String, dynamic>))
          .toList(),
      interimSuspensionPrayer: json['interim_suspension_prayer'] as String?,
      finalReliefPrayer: json['final_relief_prayer'] as String,
      citedPrecedents: (json['cited_precedents'] as List<dynamic>)
          .map((p) => HighCourtCitedPrecedent.fromJson(p as Map<String, dynamic>))
          .toList(),
      statutoryGateWarnings: List<String>.from(json['statutory_gate_warnings'] ?? []),
    );
  }
}
