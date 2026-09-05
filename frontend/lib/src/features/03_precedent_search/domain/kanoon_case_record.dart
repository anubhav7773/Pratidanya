class KanoonCaseRecord {
  final String id;
  final String courtId;
  final String caseNumber;
  final String cnrNumber;
  final String filingDate;
  final String status;
  final String petitioner;
  final String respondent;
  final String policeStation;
  final String firNumber;
  final List<String> underSections;
  final String? presidingJudge;

  KanoonCaseRecord({
    required this.id,
    required this.courtId,
    required this.caseNumber,
    required this.cnrNumber,
    required this.filingDate,
    required this.status,
    required this.petitioner,
    required this.respondent,
    required this.policeStation,
    required this.firNumber,
    required this.underSections,
    this.presidingJudge,
  });

  factory KanoonCaseRecord.fromJson(Map<String, dynamic> json) {
    return KanoonCaseRecord(
      id: json['id'] as String,
      courtId: json['court_id'] as String? ?? '',
      caseNumber: json['case_number'] as String? ?? 'N/A',
      cnrNumber: json['cnr_number'] as String? ?? '',
      filingDate: json['filing_date'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      petitioner: json['petitioner'] as String? ?? '',
      respondent: json['respondent'] as String? ?? '',
      policeStation: json['police_station'] as String? ?? '',
      firNumber: json['fir_number'] as String? ?? '',
      underSections: List<String>.from(json['under_sections'] ?? []),
      presidingJudge: json['presiding_judge'] as String?,
    );
  }
}

class VerifiedCaseOrder {
  final String id;
  final String orderDate;
  final String orderType;
  final String pdfDownloadUrl;
  final String? pdfSha256;
  final String orderTextSnippet;

  VerifiedCaseOrder({
    required this.id,
    required this.orderDate,
    required this.orderType,
    required this.pdfDownloadUrl,
    this.pdfSha256,
    required this.orderTextSnippet,
  });

  factory VerifiedCaseOrder.fromJson(Map<String, dynamic> json) {
    return VerifiedCaseOrder(
      id: json['id'] as String,
      orderDate: json['order_date'] as String? ?? '',
      orderType: json['order_type'] as String? ?? 'ORDER',
      pdfDownloadUrl: json['pdf_download_url'] as String? ?? '',
      pdfSha256: json['pdf_sha256'] as String?,
      orderTextSnippet: json['order_text_snippet'] as String? ?? '',
    );
  }
}
