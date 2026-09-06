class ExtractedCaseEntities {
  final String? firNumber;
  final String? policeStation;
  final String? district;
  final List<String> accusedNames;
  final String? complainantName;
  final List<String> sections;
  final String custodyStatus;
  final String allegationSummary;
  final String defensePlea;

  ExtractedCaseEntities({
    this.firNumber,
    this.policeStation,
    this.district,
    required this.accusedNames,
    this.complainantName,
    required this.sections,
    required this.custodyStatus,
    required this.allegationSummary,
    required this.defensePlea,
  });

  factory ExtractedCaseEntities.fromJson(Map<String, dynamic> json) {
    return ExtractedCaseEntities(
      firNumber: json['fir_number'] as String?,
      policeStation: json['police_station'] as String?,
      district: json['district'] as String?,
      accusedNames: List<String>.from(json['accused_names'] ?? []),
      complainantName: json['complainant_name'] as String?,
      sections: List<String>.from(json['sections'] ?? []),
      custodyStatus: json['custody_status'] as String? ?? 'JUDICIAL_CUSTODY',
      allegationSummary: json['allegation_summary'] as String? ?? '',
      defensePlea: json['defense_plea'] as String? ?? '',
    );
  }
}

class VoiceDictationResult {
  final String sessionId;
  final String verbatimTranscriptHindi;
  final String cleanedFactualMatrix;
  final int durationSeconds;
  final ExtractedCaseEntities extractedEntities;
  final List<String> chronologicalEvents;
  final bool dpdpEphemeralPurgeVerified;

  VoiceDictationResult({
    required this.sessionId,
    required this.verbatimTranscriptHindi,
    required this.cleanedFactualMatrix,
    required this.durationSeconds,
    required this.extractedEntities,
    required this.chronologicalEvents,
    required this.dpdpEphemeralPurgeVerified,
  });

  factory VoiceDictationResult.fromJson(Map<String, dynamic> json) {
    return VoiceDictationResult(
      sessionId: json['session_id'] as String,
      verbatimTranscriptHindi: json['verbatim_transcript_hindi'] as String,
      cleanedFactualMatrix: json['cleaned_factual_matrix'] as String,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      extractedEntities: ExtractedCaseEntities.fromJson(
        json['extracted_entities'] as Map<String, dynamic>? ?? {},
      ),
      chronologicalEvents: List<String>.from(json['chronological_events'] ?? []),
      dpdpEphemeralPurgeVerified: json['dpdp_ephemeral_purge_verified'] as bool? ?? true,
    );
  }
}
