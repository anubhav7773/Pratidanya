class QuestionStepItemModel {
  final int stepNumber;
  final String objectiveHindi;
  final String leadingQuestionHindi;
  final String expectedAnswer; // 'YES' or 'NO'
  final String trapMitigationHindi;
  final String pivotTacticHindi;
  final String statutoryBasis;

  QuestionStepItemModel({
    required this.stepNumber,
    required this.objectiveHindi,
    required this.leadingQuestionHindi,
    required this.expectedAnswer,
    required this.trapMitigationHindi,
    required this.pivotTacticHindi,
    required this.statutoryBasis,
  });

  factory QuestionStepItemModel.fromJson(Map<String, dynamic> json) {
    return QuestionStepItemModel(
      stepNumber: json['step_number'] as int? ?? 1,
      objectiveHindi: json['objective_hindi'] as String? ?? '',
      leadingQuestionHindi: json['leading_question_hindi'] as String? ?? '',
      expectedAnswer: json['expected_answer'] as String? ?? 'YES',
      trapMitigationHindi: json['trap_mitigation_hindi'] as String? ?? '',
      pivotTacticHindi: json['pivot_tactic_hindi'] as String? ?? '',
      statutoryBasis: json['statutory_basis'] as String? ?? '',
    );
  }
}

class LeadingQuestionResult {
  final String caseId;
  final String witnessName;
  final String defenseTheory;
  final String questionnaireStrategyHindi;
  final List<QuestionStepItemModel> questionTrees;
  final String trialTacticsSummaryHindi;
  final List<Map<String, dynamic>> citedPrecedents;

  LeadingQuestionResult({
    required this.caseId,
    required this.witnessName,
    required this.defenseTheory,
    required this.questionnaireStrategyHindi,
    required this.questionTrees,
    required this.trialTacticsSummaryHindi,
    required this.citedPrecedents,
  });

  factory LeadingQuestionResult.fromJson(Map<String, dynamic> json) {
    return LeadingQuestionResult(
      caseId: json['case_id'] as String,
      witnessName: json['witness_name'] as String? ?? '',
      defenseTheory: json['defense_theory'] as String? ?? '',
      questionnaireStrategyHindi: json['questionnaire_strategy_hindi'] as String? ?? '',
      questionTrees: (json['question_trees'] as List<dynamic>?)
              ?.map((e) => QuestionStepItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trialTacticsSummaryHindi: json['trial_tactics_summary_hindi'] as String? ?? '',
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
