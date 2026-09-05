class AdvocateProfile {
  final String id; // Firebase UID
  final String email;
  final String fullName;
  final String barCouncilNumber;
  final String enrolledState;
  final String primaryCourtName;
  final String courtType;
  final String? chamberAddress;
  final bool dpdpConsentAccepted;
  final DateTime? dpdpConsentTimestamp;

  AdvocateProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.barCouncilNumber,
    required this.enrolledState,
    required this.primaryCourtName,
    required this.courtType,
    this.chamberAddress,
    required this.dpdpConsentAccepted,
    this.dpdpConsentTimestamp,
  });

  factory AdvocateProfile.fromJson(Map<String, dynamic> json) {
    return AdvocateProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      barCouncilNumber: json['bar_council_number'] as String,
      enrolledState: json['enrolled_state'] as String? ?? 'Uttar Pradesh',
      primaryCourtName: json['primary_court_name'] as String? ?? 'District & Sessions Court',
      courtType: json['court_type'] as String? ?? 'DISTRICT_SUBORDINATE',
      chamberAddress: json['chamber_address'] as String?,
      dpdpConsentAccepted: json['dpdp_consent_accepted'] as bool? ?? false,
      dpdpConsentTimestamp: json['dpdp_consent_timestamp'] != null
          ? DateTime.parse(json['dpdp_consent_timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'bar_council_number': barCouncilNumber,
        'enrolled_state': enrolledState,
        'primary_court_name': primaryCourtName,
        'court_type': courtType,
        'chamber_address': chamberAddress,
        'dpdp_consent_accepted': dpdpConsentAccepted,
        'dpdp_consent_timestamp': dpdpConsentTimestamp?.toIso8601String(),
      };
}
