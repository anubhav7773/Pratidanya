class OralPromptRejoinder {
  final String counterLegalGround;
  final String promptTextHindi;
  final String leadCitation;
  final String statutoryLever;

  OralPromptRejoinder({
    required this.counterLegalGround,
    required this.promptTextHindi,
    required this.leadCitation,
    required this.statutoryLever,
  });

  factory OralPromptRejoinder.fromJson(Map<String, dynamic> json) => OralPromptRejoinder(
        counterLegalGround: json['counter_legal_ground'] as String? ?? '',
        promptTextHindi: json['prompt_text_hindi'] as String? ?? '',
        leadCitation: json['lead_citation'] as String? ?? '',
        statutoryLever: json['statutory_lever'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'counter_legal_ground': counterLegalGround,
        'prompt_text_hindi': promptTextHindi,
        'lead_citation': leadCitation,
        'statutory_lever': statutoryLever,
      };
}

class EdgeOralPromptResult {
  final String detectedAdversarialRatio;
  final List<OralPromptRejoinder> immediateCounterRatios;
  final Map<String, dynamic>? benchInsights;
  final Map<String, dynamic> latencyMs;

  EdgeOralPromptResult({
    required this.detectedAdversarialRatio,
    required this.immediateCounterRatios,
    this.benchInsights,
    required this.latencyMs,
  });

  factory EdgeOralPromptResult.fromJson(Map<String, dynamic> json) => EdgeOralPromptResult(
        detectedAdversarialRatio: json['detected_adversarial_ratio'] as String? ?? '',
        immediateCounterRatios: (json['immediate_counter_ratios'] as List<dynamic>?)
                ?.map((e) => OralPromptRejoinder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        benchInsights: json['bench_insights'] as Map<String, dynamic>?,
        latencyMs: Map<String, dynamic>.from(json['latency_ms'] as Map? ?? {}),
      );
}

class SuretyAuditResult {
  final String caseId;
  final bool isConditionOnerous;
  final List<String> motiRamViolationReasons;
  final String suggestedStatutoryRelief;
  final String modificationPetitionDraftHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  SuretyAuditResult({
    required this.caseId,
    required this.isConditionOnerous,
    required this.motiRamViolationReasons,
    required this.suggestedStatutoryRelief,
    required this.modificationPetitionDraftHindi,
    required this.citedPrecedents,
  });

  factory SuretyAuditResult.fromJson(Map<String, dynamic> json) => SuretyAuditResult(
        caseId: json['case_id'] as String,
        isConditionOnerous: json['is_condition_onerous'] as bool? ?? false,
        motiRamViolationReasons: List<String>.from(json['moti_ram_violation_reasons'] ?? []),
        suggestedStatutoryRelief: json['suggested_statutory_relief'] as String? ?? '',
        modificationPetitionDraftHindi: json['modification_petition_draft_hindi'] as String? ?? '',
        citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
}
