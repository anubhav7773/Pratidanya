class PrecedentCitation {
  final String id;
  final String citationId;
  final String caseTitle;
  final String courtName;
  final String judgmentDate;
  final String actName;
  final List<String> sectionNumbers;
  final String headnoteHindi;
  final String verbatimText;
  final int? paragraphNumber;
  final String verifiedSourceUrl;
  final double similarityScore;
  bool isManuallyVerified; // Checked by Advocate in Verification Gate

  PrecedentCitation({
    required this.id,
    required this.citationId,
    required this.caseTitle,
    required this.courtName,
    required this.judgmentDate,
    required this.actName,
    required this.sectionNumbers,
    required this.headnoteHindi,
    required this.verbatimText,
    this.paragraphNumber,
    required this.verifiedSourceUrl,
    required this.similarityScore,
    this.isManuallyVerified = false,
  });

  factory PrecedentCitation.fromJson(Map<String, dynamic> json) {
    return PrecedentCitation(
      id: json['id'] as String,
      citationId: json['citation_id'] as String,
      caseTitle: json['case_title'] as String,
      courtName: json['court_name'] as String,
      judgmentDate: json['judgment_date'] as String,
      actName: json['act_name'] as String,
      sectionNumbers: List<String>.from(json['section_numbers'] ?? []),
      headnoteHindi: json['headnote_hindi'] as String,
      verbatimText: json['verbatim_text'] as String,
      paragraphNumber: json['paragraph_number'] as int?,
      verifiedSourceUrl: json['verified_source_url'] as String,
      similarityScore: (json['similarity_score'] as num).toDouble(),
      isManuallyVerified: json['is_manually_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'citation_id': citationId,
        'case_title': caseTitle,
        'court_name': courtName,
        'judgment_date': judgmentDate,
        'act_name': actName,
        'section_numbers': sectionNumbers,
        'headnote_hindi': headnoteHindi,
        'verbatim_text': verbatimText,
        'paragraph_number': paragraphNumber,
        'verified_source_url': verifiedSourceUrl,
        'similarity_score': similarityScore,
        'is_manually_verified': isManuallyVerified,
      };

  PrecedentCitation copyWith({bool? isManuallyVerified}) {
    return PrecedentCitation(
      id: id,
      citationId: citationId,
      caseTitle: caseTitle,
      courtName: courtName,
      judgmentDate: judgmentDate,
      actName: actName,
      sectionNumbers: sectionNumbers,
      headnoteHindi: headnoteHindi,
      verbatimText: verbatimText,
      paragraphNumber: paragraphNumber,
      verifiedSourceUrl: verifiedSourceUrl,
      similarityScore: similarityScore,
      isManuallyVerified: isManuallyVerified ?? this.isManuallyVerified,
    );
  }
}
