class CitedPrecedentItem {
  final String citationId;
  final String caseTitle;
  final String courtName;
  final String judgmentDate;
  final String quotedPassage;
  final String verifiedSourceUrl;
  final bool isGroundedInRecord;
  bool isManuallyVerified;

  CitedPrecedentItem({
    required this.citationId,
    required this.caseTitle,
    required this.courtName,
    required this.judgmentDate,
    required this.quotedPassage,
    required this.verifiedSourceUrl,
    required this.isGroundedInRecord,
    this.isManuallyVerified = false,
  });

  factory CitedPrecedentItem.fromJson(Map<String, dynamic> json) {
    return CitedPrecedentItem(
      citationId: json['citation_id'] as String,
      caseTitle: json['case_title'] as String,
      courtName: json['court_name'] as String,
      judgmentDate: json['judgment_date'] as String,
      quotedPassage: json['quoted_passage'] as String,
      verifiedSourceUrl: json['verified_source_url'] as String,
      isGroundedInRecord: json['is_grounded_in_record'] as bool? ?? true,
      isManuallyVerified: json['is_manually_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'citation_id': citationId,
        'case_title': caseTitle,
        'court_name': courtName,
        'judgment_date': judgmentDate,
        'quoted_passage': quotedPassage,
        'verified_source_url': verifiedSourceUrl,
        'is_grounded_in_record': isGroundedInRecord,
        'is_manually_verified': isManuallyVerified,
      };

  CitedPrecedentItem copyWith({bool? isManuallyVerified}) {
    return CitedPrecedentItem(
      citationId: citationId,
      caseTitle: caseTitle,
      courtName: courtName,
      judgmentDate: judgmentDate,
      quotedPassage: quotedPassage,
      verifiedSourceUrl: verifiedSourceUrl,
      isGroundedInRecord: isGroundedInRecord,
      isManuallyVerified: isManuallyVerified ?? this.isManuallyVerified,
    );
  }
}

class CaseAnalysisDraft {
  final String courtHeader;
  final String caseTitle;
  final List<String> statutoryGrounds;
  final List<String> prosecutionWeaknesses;
  final List<String> proceduralObjections;
  final List<CitedPrecedentItem> citedPrecedents;

  CaseAnalysisDraft({
    required this.courtHeader,
    required this.caseTitle,
    required this.statutoryGrounds,
    required this.prosecutionWeaknesses,
    required this.proceduralObjections,
    required this.citedPrecedents,
  });

  factory CaseAnalysisDraft.fromJson(Map<String, dynamic> json) {
    return CaseAnalysisDraft(
      courtHeader: json['court_header'] as String? ?? 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
      caseTitle: json['case_title'] as String? ?? 'राज्य बनाम अभियुक्त',
      statutoryGrounds: List<String>.from(json['statutory_grounds'] ?? []),
      prosecutionWeaknesses: List<String>.from(json['prosecution_weaknesses'] ?? []),
      proceduralObjections: List<String>.from(json['procedural_objections'] ?? []),
      citedPrecedents: (json['cited_precedents'] as List<dynamic>?)
              ?.map((e) => CitedPrecedentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  CaseAnalysisDraft copyWith({
    String? courtHeader,
    String? caseTitle,
    List<String>? statutoryGrounds,
    List<String>? prosecutionWeaknesses,
    List<String>? proceduralObjections,
    List<CitedPrecedentItem>? citedPrecedents,
  }) {
    return CaseAnalysisDraft(
      courtHeader: courtHeader ?? this.courtHeader,
      caseTitle: caseTitle ?? this.caseTitle,
      statutoryGrounds: statutoryGrounds ?? this.statutoryGrounds,
      prosecutionWeaknesses: prosecutionWeaknesses ?? this.prosecutionWeaknesses,
      proceduralObjections: proceduralObjections ?? this.proceduralObjections,
      citedPrecedents: citedPrecedents ?? this.citedPrecedents,
    );
  }
}
