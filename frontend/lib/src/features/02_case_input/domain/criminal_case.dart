class CriminalCase {
  final String id;
  final String advocateId;
  final String firNumber;
  final String policeStation;
  final String district;
  final String state;
  final String accusedName;
  final String accusedCustodyStatus; // 'JUDICIAL_CUSTODY', 'POLICE_CUSTODY', 'ON_BAIL', 'ANTICIPATORY'
  final String? complainantName;
  final String statuteSystem; // 'HYBRID', 'BNS_BNSS', 'IPC_CRPC'
  final List<String> underSections;
  final String courtDesignation;
  final String? caseNumber;
  final String? cnrNumber;
  final String stageOfCase; // 'REMAND', 'BAIL', 'CHARGESHEET', 'CHARGES_FRAMED', 'EVIDENCE'
  final DateTime? nextHearingDate;
  final String? lastCourtOrder;
  final DateTime? arrestDate;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  CriminalCase({
    required this.id,
    required this.advocateId,
    required this.firNumber,
    required this.policeStation,
    required this.district,
    required this.state,
    required this.accusedName,
    required this.accusedCustodyStatus,
    this.complainantName,
    required this.statuteSystem,
    required this.underSections,
    required this.courtDesignation,
    this.caseNumber,
    this.cnrNumber,
    required this.stageOfCase,
    this.nextHearingDate,
    this.lastCourtOrder,
    this.arrestDate,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CriminalCase.fromJson(Map<String, dynamic> json) {
    return CriminalCase(
      id: json['id'] as String,
      advocateId: json['advocate_id'] as String,
      firNumber: json['fir_number'] as String,
      policeStation: json['police_station'] as String,
      district: json['district'] as String,
      state: json['state'] as String? ?? 'Uttar Pradesh',
      accusedName: json['accused_name'] as String,
      accusedCustodyStatus: json['accused_custody_status'] as String? ?? 'JUDICIAL_CUSTODY',
      complainantName: json['complainant_name'] as String?,
      statuteSystem: json['statute_system'] as String? ?? 'HYBRID',
      underSections: List<String>.from(json['under_sections'] ?? []),
      courtDesignation: json['court_designation'] as String,
      caseNumber: json['case_number'] as String?,
      cnrNumber: json['cnr_number'] as String?,
      stageOfCase: json['stage_of_case'] as String? ?? 'BAIL',
      nextHearingDate: json['next_hearing_date'] != null
          ? DateTime.parse(json['next_hearing_date'] as String)
          : null,
      lastCourtOrder: json['last_court_order'] as String?,
      arrestDate: json['arrest_date'] != null
          ? DateTime.tryParse(json['arrest_date'] as String)
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'advocate_id': advocateId,
        'fir_number': firNumber,
        'police_station': policeStation,
        'district': district,
        'state': state,
        'accused_name': accusedName,
        'accused_custody_status': accusedCustodyStatus,
        'complainant_name': complainantName,
        'statute_system': statuteSystem,
        'under_sections': underSections,
        'court_designation': courtDesignation,
        'case_number': caseNumber,
        'cnr_number': cnrNumber,
        'stage_of_case': stageOfCase,
        'next_hearing_date': nextHearingDate?.toIso8601String().split('T').first,
        'last_court_order': lastCourtOrder,
        'arrest_date': arrestDate?.toIso8601String().split('T').first,
        'is_archived': isArchived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CriminalCase copyWith({
    String? stageOfCase,
    DateTime? nextHearingDate,
    String? lastCourtOrder,
    DateTime? arrestDate,
    bool? isArchived,
  }) {
    return CriminalCase(
      id: id,
      advocateId: advocateId,
      firNumber: firNumber,
      policeStation: policeStation,
      district: district,
      state: state,
      accusedName: accusedName,
      accusedCustodyStatus: accusedCustodyStatus,
      complainantName: complainantName,
      statuteSystem: statuteSystem,
      underSections: underSections,
      courtDesignation: courtDesignation,
      caseNumber: caseNumber,
      cnrNumber: cnrNumber,
      stageOfCase: stageOfCase ?? this.stageOfCase,
      nextHearingDate: nextHearingDate ?? this.nextHearingDate,
      lastCourtOrder: lastCourtOrder ?? this.lastCourtOrder,
      arrestDate: arrestDate ?? this.arrestDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
