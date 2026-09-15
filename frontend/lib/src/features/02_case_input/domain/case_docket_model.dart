class CaseDocketModel {
  final String id;
  final String crimeNumber;
  final int firYear;
  final String policeStation;
  final String district;
  final String accusedName;
  final String courtName;
  final String substantiveSections;
  final String substantiveRegime; // 'BNS', 'IPC', 'HYBRID'
  final String custodyStatus;     // 'JUDICIAL_CUSTODY', 'POLICE_CUSTODY', 'BAIL_GRANTED'
  final int custodyDaysElapsed;
  final int statutoryThresholdDays;
  final DateTime nextHearingDate;
  final String hearingPurpose;
  final bool isDefaultBailUrgent;
  final bool isUnderTrialReliefEligible;
  final bool hasForensicTamperingAlert;

  CaseDocketModel({
    required this.id,
    required this.crimeNumber,
    required this.firYear,
    required this.policeStation,
    required this.district,
    required this.accusedName,
    required this.courtName,
    required this.substantiveSections,
    required this.substantiveRegime,
    required this.custodyStatus,
    required this.custodyDaysElapsed,
    required this.statutoryThresholdDays,
    required this.nextHearingDate,
    required this.hearingPurpose,
    this.isDefaultBailUrgent = false,
    this.isUnderTrialReliefEligible = false,
    this.hasForensicTamperingAlert = false,
  });

  factory CaseDocketModel.fromJson(Map<String, dynamic> json) {
    return CaseDocketModel(
      id: json['id'] as String,
      crimeNumber: json['crime_number'] as String,
      firYear: json['fir_year'] as int? ?? 2026,
      policeStation: json['police_station'] as String,
      district: json['district'] as String,
      accusedName: json['accused_name'] as String,
      courtName: json['court_name'] as String,
      substantiveSections: json['substantive_sections'] as String,
      substantiveRegime: json['substantive_regime'] as String? ?? 'BNS',
      custodyStatus: json['custody_status'] as String? ?? 'JUDICIAL_CUSTODY',
      custodyDaysElapsed: json['custody_days_elapsed'] as int? ?? 0,
      statutoryThresholdDays: json['statutory_threshold_days'] as int? ?? 90,
      nextHearingDate: DateTime.parse(json['next_hearing_date'] as String),
      hearingPurpose: json['hearing_purpose'] as String,
      isDefaultBailUrgent: json['is_default_bail_urgent'] as bool? ?? false,
      isUnderTrialReliefEligible: json['is_undertrial_relief_eligible'] as bool? ?? false,
      hasForensicTamperingAlert: json['has_forensic_tampering_alert'] as bool? ?? false,
    );
  }
}
