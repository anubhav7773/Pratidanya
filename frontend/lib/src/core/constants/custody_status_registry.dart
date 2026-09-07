import 'package:flutter/material.dart';

class CustodyStatusOption {
  final String key;
  final String labelHindi;
  final String labelEnglish;
  final String shortLabel;
  final bool isInCarceration; // true if physically detained

  const CustodyStatusOption({
    required this.key,
    required this.labelHindi,
    required this.labelEnglish,
    required this.shortLabel,
    required this.isInCarceration,
  });

  String get code => key;
  String get titleHindi => shortLabel;
  String get titleHindiWithEnglish => '$labelHindi ($labelEnglish)';
  bool get requiresDate => isInCarceration;

  Color get badgeColor {
    if (isInCarceration) return const Color(0xFFD6603B);
    if (key == 'ON_BAIL' || key == 'ANTICIPATORY' || key == 'INTERIM_BAIL') return const Color(0xFF166534);
    if (key == 'NBW_ISSUED' || key == 'ABSCONDING_84_BNSS') return const Color(0xFFB91C1C);
    return const Color(0xFF4338CA);
  }
}

class CustodyStatusRegistry {
  static const String judicialCustody = 'JUDICIAL_CUSTODY';

  static const List<CustodyStatusOption> allStatuses = [
    CustodyStatusOption(
      key: 'JUDICIAL_CUSTODY',
      labelHindi: 'जेल में (न्यायिक अभिरक्षा)',
      labelEnglish: 'In Judicial Custody (Jail)',
      shortLabel: 'न्यायिक अभिरक्षा',
      isInCarceration: true,
    ),
    CustodyStatusOption(
      key: 'POLICE_CUSTODY',
      labelHindi: 'पुलिस कस्टडी रिमांड',
      labelEnglish: 'Police Custody Remand',
      shortLabel: 'पुलिस रिमांड',
      isInCarceration: true,
    ),
    CustodyStatusOption(
      key: 'ON_BAIL',
      labelHindi: 'नियमित जमानत पर रिहा',
      labelEnglish: 'Released on Regular Bail',
      shortLabel: 'जमानत पर रिहा',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'ANTICIPATORY',
      labelHindi: 'अग्रिम जमानत प्राप्त / संरक्षण',
      labelEnglish: 'Anticipatory Bail Granted',
      shortLabel: 'अग्रिम जमानत',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'INTERIM_BAIL',
      labelHindi: 'अंतरिम जमानत पर रिहा',
      labelEnglish: 'On Interim Bail',
      shortLabel: 'अंतरिम जमानत',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'SECTION_35_NOTICE',
      labelHindi: 'धारा 35(3) BNSS / 41A नोटिस (गिरफ्तारी मुक्त)',
      labelEnglish: 'Sec 35(3) BNSS / 41A CrPC Notice (Not Arrested)',
      shortLabel: 'धारा 35 नोटिस',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'SURRENDER_PENDING',
      labelHindi: 'न्यायालय में आत्मसमर्पण प्रार्थना पत्र लंबित',
      labelEnglish: 'Surrender Application Pending in Court',
      shortLabel: 'आत्मसमर्पण अर्जी लंबित',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'NBW_ISSUED',
      labelHindi: 'गैर-जमानती वारंट (NBW) जारी',
      labelEnglish: 'Non-Bailable Warrant Issued',
      shortLabel: 'NBW जारी',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'ABSCONDING_84_BNSS',
      labelHindi: 'फरार / धारा 84 BNSS उद्घोषणा (82 CrPC)',
      labelEnglish: 'Absconding / Sec 84 BNSS Proclamation',
      shortLabel: 'फरार / धारा 84',
      isInCarceration: false,
    ),
    CustodyStatusOption(
      key: 'HOSPITAL_CUSTODY',
      labelHindi: 'चिकित्सीय / अस्पताल अभिरक्षा (Medical Custody)',
      labelEnglish: 'Hospital / Medical Custody',
      shortLabel: 'चिकित्सीय अभिरक्षा',
      isInCarceration: true,
    ),
    CustodyStatusOption(
      key: 'JJB_OBSERVATION_HOME',
      labelHindi: 'बाल संप्रेक्षण गृह (किशोर न्याय बोर्ड / JJB)',
      labelEnglish: 'Juvenile Observation Home',
      shortLabel: 'संप्रेक्षण गृह',
      isInCarceration: true,
    ),
    CustodyStatusOption(
      key: 'PAROLE_FURLOUGH',
      labelHindi: 'पैरोल / अल्पकालिक रिहाई (Parole / Furlough)',
      labelEnglish: 'On Parole / Furlough',
      shortLabel: 'पैरोल पर रिहा',
      isInCarceration: false,
    ),
  ];

  static CustodyStatusOption getStatus(String key) {
    return allStatuses.firstWhere(
      (s) => s.key == key,
      orElse: () => allStatuses.first,
    );
  }

  static String getShortLabel(String key) {
    try {
      return allStatuses.firstWhere((s) => s.key == key).shortLabel;
    } catch (_) {
      return key;
    }
  }

  static String getFullLabel(String key) {
    try {
      final s = allStatuses.firstWhere((s) => s.key == key);
      return '${s.labelHindi} (${s.labelEnglish})';
    } catch (_) {
      return key;
    }
  }

  static bool isPhysicalDetention(String key) {
    try {
      return allStatuses.firstWhere((s) => s.key == key).isInCarceration;
    } catch (_) {
      return false;
    }
  }
}
