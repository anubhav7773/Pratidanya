class VerifiedExportPayload {
  final String courtHeaderHindi;
  final String firNumber;
  final String policeStation;
  final String district;
  final String accusedName;
  final String advocateName;
  final String barCouncilNumber;
  final List<String> verifiedGrounds;
  final List<String> verifiedCitations;
  final String prayerText;
  final DateTime filingDate;

  VerifiedExportPayload({
    required this.courtHeaderHindi,
    required this.firNumber,
    required this.policeStation,
    required this.district,
    required this.accusedName,
    required this.advocateName,
    required this.barCouncilNumber,
    required this.verifiedGrounds,
    required this.verifiedCitations,
    required this.prayerText,
    required this.filingDate,
  });
}
