class CnrValidator {
  static final RegExp _cnrRegExp = RegExp(r'^[A-Z]{4}[0-9]{12}$');

  /// Clean CNR string of whitespace, dashes, and convert to uppercase
  static String cleanCnr(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  /// Validates format: 4 letters + 12 numbers (total 16 chars)
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // CNR is optional on new filings before court registration
    }
    final cleaned = cleanCnr(value);
    if (cleaned.length != 16) {
      return 'CNR संख्या ठीक 16 अक्षरों की होनी चाहिए (वर्तमान: ${cleaned.length})';
    }
    if (!_cnrRegExp.hasMatch(cleaned)) {
      return 'अमान्य प्रारूप। प्रारूप उदाहरण: UPHC010123452026';
    }
    return null;
  }

  /// Formats raw 16-char CNR into human-readable segmented format
  static String format(String? raw) {
    final cleaned = cleanCnr(raw);
    if (cleaned.length != 16) return raw ?? '';
    final state = cleaned.substring(0, 2);
    final est = cleaned.substring(2, 6);
    final seq = cleaned.substring(6, 12);
    final year = cleaned.substring(12, 16);
    return '$state-$est-$seq-$year';
  }
}

class EcourtsSyncResult {
  final String status;
  final String cnrNumber;
  final String formattedCnr;
  final bool isVerifiedEcourts;
  final String cisVersion;
  final String courtName;
  final String courtCoram;
  final String courtRoomNumber;
  final String caseTypeAndNumber;
  final String firNumber;
  final String policeStation;
  final String district;
  final String state;
  final String stageOfCase;
  final String nextHearingDate;
  final String hearingPurpose;
  final int causeListItemNumber;
  final String lastHearingDate;
  final String lastCourtOrder;
  final String orderPdfUrl;
  final String syncedAt;
  final List<Map<String, dynamic>> proceedingsHistory;

  EcourtsSyncResult({
    required this.status,
    required this.cnrNumber,
    required this.formattedCnr,
    required this.isVerifiedEcourts,
    required this.cisVersion,
    required this.courtName,
    required this.courtCoram,
    required this.courtRoomNumber,
    required this.caseTypeAndNumber,
    required this.firNumber,
    required this.policeStation,
    required this.district,
    required this.state,
    required this.stageOfCase,
    required this.nextHearingDate,
    required this.hearingPurpose,
    required this.causeListItemNumber,
    required this.lastHearingDate,
    required this.lastCourtOrder,
    required this.orderPdfUrl,
    required this.syncedAt,
    required this.proceedingsHistory,
  });

  factory EcourtsSyncResult.fromJson(Map<String, dynamic> json) {
    return EcourtsSyncResult(
      status: json['status'] as String? ?? 'SUCCESS',
      cnrNumber: json['cnr_number'] as String? ?? '',
      formattedCnr: json['formatted_cnr'] as String? ?? '',
      isVerifiedEcourts: json['is_verified_ecourts'] as bool? ?? true,
      cisVersion: json['cis_version'] as String? ?? 'CIS 3.2',
      courtName: json['court_name'] as String? ?? '',
      courtCoram: json['court_coram'] as String? ?? '',
      courtRoomNumber: json['court_room_number'] as String? ?? '',
      caseTypeAndNumber: json['case_type_and_number'] as String? ?? '',
      firNumber: json['fir_number'] as String? ?? '',
      policeStation: json['police_station'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      stageOfCase: json['stage_of_case'] as String? ?? '',
      nextHearingDate: json['next_hearing_date'] as String? ?? '',
      hearingPurpose: json['hearing_purpose'] as String? ?? '',
      causeListItemNumber: json['cause_list_item_number'] as int? ?? 0,
      lastHearingDate: json['last_hearing_date'] as String? ?? '',
      lastCourtOrder: json['last_court_order'] as String? ?? '',
      orderPdfUrl: json['order_pdf_url'] as String? ?? '',
      syncedAt: json['synced_at'] as String? ?? '',
      proceedingsHistory: (json['proceedings_history'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class CauseListEntry {
  final int itemNumber;
  final String courtRoom;
  final String courtDesignation;
  final String coram;
  final String caseNumber;
  final String cnrNumber;
  final String firDetails;
  final String applicantName;
  final String oppositeParty;
  final List<String> underSections;
  final String advocateForApplicant;
  final String advocateForOpposite;
  final String stageOfHearing;
  final String listingStatus; // CALLED_OUT, LISTED_TODAY, ORDER_RESERVED, PASSOVER, ADJOURNED
  final String statusLabelHi;
  final bool isMyCase;

  CauseListEntry({
    required this.itemNumber,
    required this.courtRoom,
    required this.courtDesignation,
    required this.coram,
    required this.caseNumber,
    required this.cnrNumber,
    required this.firDetails,
    required this.applicantName,
    required this.oppositeParty,
    required this.underSections,
    required this.advocateForApplicant,
    required this.advocateForOpposite,
    required this.stageOfHearing,
    required this.listingStatus,
    required this.statusLabelHi,
    required this.isMyCase,
  });

  factory CauseListEntry.fromJson(Map<String, dynamic> json) {
    return CauseListEntry(
      itemNumber: json['item_number'] as int? ?? 0,
      courtRoom: json['court_room'] as String? ?? '',
      courtDesignation: json['court_designation'] as String? ?? '',
      coram: json['coram'] as String? ?? '',
      caseNumber: json['case_number'] as String? ?? '',
      cnrNumber: json['cnr_number'] as String? ?? '',
      firDetails: json['fir_details'] as String? ?? '',
      applicantName: json['applicant_name'] as String? ?? '',
      oppositeParty: json['opposite_party'] as String? ?? '',
      underSections: List<String>.from(json['under_sections'] ?? []),
      advocateForApplicant: json['advocate_for_applicant'] as String? ?? '',
      advocateForOpposite: json['advocate_for_opposite'] as String? ?? '',
      stageOfHearing: json['stage_of_hearing'] as String? ?? '',
      listingStatus: json['listing_status'] as String? ?? 'LISTED_TODAY',
      statusLabelHi: json['status_label_hi'] as String? ?? 'सूचीबद्ध',
      isMyCase: json['is_my_case'] as bool? ?? false,
    );
  }
}

class DailyCauseList {
  final String courtComplex;
  final String courtRoom;
  final String presidingJudge;
  final String causeListDate;
  final String publishedAt;
  final int totalListed;
  final String cisVersion;
  final List<CauseListEntry> entries;

  DailyCauseList({
    required this.courtComplex,
    required this.courtRoom,
    required this.presidingJudge,
    required this.causeListDate,
    required this.publishedAt,
    required this.totalListed,
    required this.cisVersion,
    required this.entries,
  });

  factory DailyCauseList.fromJson(Map<String, dynamic> json) {
    return DailyCauseList(
      courtComplex: json['court_complex'] as String? ?? '',
      courtRoom: json['court_room'] as String? ?? '',
      presidingJudge: json['presiding_judge'] as String? ?? '',
      causeListDate: json['cause_list_date'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      totalListed: json['total_listed'] as int? ?? 0,
      cisVersion: json['cis_version'] as String? ?? 'CIS 3.2',
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => CauseListEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
