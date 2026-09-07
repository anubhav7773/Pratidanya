class ApplicableSectionModel {
  final String actCode;
  final String actName;
  final String section;
  final String offenseTitle;
  final String bailableStatus;
  final String triableBy;
  final String ingredientsAnalysis;

  const ApplicableSectionModel({
    required this.actCode,
    required this.actName,
    required this.section,
    required this.offenseTitle,
    required this.bailableStatus,
    required this.triableBy,
    required this.ingredientsAnalysis,
  });

  factory ApplicableSectionModel.fromJson(Map<String, dynamic> json) {
    return ApplicableSectionModel(
      actCode: json['act_code'] ?? 'BNS',
      actName: json['act_name'] ?? '',
      section: json['section'] ?? '',
      offenseTitle: json['offense_title'] ?? '',
      bailableStatus: json['bailable_status'] ?? '',
      triableBy: json['triable_by'] ?? '',
      ingredientsAnalysis: json['ingredients_analysis'] ?? '',
    );
  }

  String get actNameDisplay => actName.isNotEmpty ? actName : actCode;
  String get sectionNumber => section;
  String get titleHindi => offenseTitle;
  String get descriptionHindi => ingredientsAnalysis;
  String get maxPunishment => triableBy.isNotEmpty ? triableBy : 'सांविधिक प्रावधानानुसार';

  String get formattedKey {
    final s = section.trim();
    if (s.toUpperCase().contains(actCode.toUpperCase())) {
      return s;
    }
    return '$s $actCode';
  }

  bool get isBailable =>
      !bailableStatus.contains('गैर') &&
      (bailableStatus.contains('जमानत') || bailableStatus.toLowerCase().contains('bailable'));

  bool get isCognizable =>
      !ingredientsAnalysis.contains('असंज्ञेय') && !bailableStatus.contains('असंज्ञेय');
}

class StrategyPointModel {
  final String title;
  final String strategy;
  final String statutoryLoopholeOrProof;

  const StrategyPointModel({
    required this.title,
    required this.strategy,
    required this.statutoryLoopholeOrProof,
  });

  factory StrategyPointModel.fromJson(Map<String, dynamic> json) {
    return StrategyPointModel(
      title: json['title'] ?? '',
      strategy: json['strategy'] ?? '',
      statutoryLoopholeOrProof: json['statutory_loophole_or_proof'] ?? '',
    );
  }

  String get displayText =>
      statutoryLoopholeOrProof.isNotEmpty ? '$title: $strategy ($statutoryLoopholeOrProof)' : '$title: $strategy';
}

class PrecedentCitationModel {
  final String caseTitle;
  final String citation;
  final String legalPrincipleHindi;

  const PrecedentCitationModel({
    required this.caseTitle,
    required this.citation,
    required this.legalPrincipleHindi,
  });

  factory PrecedentCitationModel.fromString(String raw) {
    if (raw.contains(' - ')) {
      final parts = raw.split(' - ');
      final titleAndCit = parts[0];
      final principle = parts.sublist(1).join(' - ');
      return PrecedentCitationModel(
        caseTitle: titleAndCit,
        citation: 'Landmark',
        legalPrincipleHindi: principle,
      );
    }
    return PrecedentCitationModel(
      caseTitle: raw,
      citation: 'Landmark Precedent',
      legalPrincipleHindi: 'संबद्ध विधिक नजीर एवं न्यायालयीन मार्गदर्शन।',
    );
  }
}

class AiOffenseAnalysisResult {
  final String caseSummaryHindi;
  final List<ApplicableSectionModel> applicableSections;
  final List<StrategyPointModel> defenseStrategy360;
  final List<StrategyPointModel> prosecutionStrategy360;
  final List<String> landmarkPrecedentsRaw;

  const AiOffenseAnalysisResult({
    required this.caseSummaryHindi,
    required this.applicableSections,
    required this.defenseStrategy360,
    required this.prosecutionStrategy360,
    List<String>? landmarkPrecedents,
    List<String>? landmarkPrecedentsRaw,
  }) : landmarkPrecedentsRaw = landmarkPrecedentsRaw ?? landmarkPrecedents ?? const [];

  factory AiOffenseAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiOffenseAnalysisResult(
      caseSummaryHindi: json['case_summary_hindi'] ?? '',
      applicableSections: (json['applicable_sections'] as List<dynamic>? ?? [])
          .map((e) => ApplicableSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defenseStrategy360: (json['defense_strategy_360'] as List<dynamic>? ?? [])
          .map((e) => StrategyPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prosecutionStrategy360: (json['prosecution_strategy_360'] as List<dynamic>? ?? [])
          .map((e) => StrategyPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      landmarkPrecedentsRaw: (json['landmark_precedents'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String get analysisSummary => caseSummaryHindi;
  List<ApplicableSectionModel> get identifiedSections => applicableSections;

  List<String> get defendingStrategies =>
      defenseStrategy360.map((e) => e.displayText).toList();

  List<String> get attackingStrategies =>
      prosecutionStrategy360.map((e) => e.displayText).toList();

  List<PrecedentCitationModel> get landmarkPrecedents =>
      landmarkPrecedentsRaw.map((e) => PrecedentCitationModel.fromString(e)).toList();
}
