class BarCouncilValidator {
  /// Standardized State Bar Council Prefix Registry under Section 17 & 22 of Advocates Act 1961
  static const Map<String, List<String>> statePrefixes = {
    'Uttar Pradesh': ['UP'],
    'Delhi': ['D'],
    'Maharashtra & Goa': ['MAH'],
    'Madhya Pradesh': ['MP'],
    'Bihar': ['BR', 'BIH'],
    'Rajasthan': ['R', 'RAJ'],
    'Punjab & Haryana': ['PH', 'P&H'],
    'West Bengal': ['WB'],
    'Gujarat': ['G', 'GJ'],
    'Karnataka': ['KAR'],
    'Tamil Nadu & Puducherry': ['MS', 'TN'],
    'Andhra Pradesh': ['AP'],
    'Telangana': ['TS'],
    'Kerala': ['K'],
    'Uttarakhand': ['UK', 'UA'],
    'Jharkhand': ['JH'],
    'Chhattisgarh': ['CG'],
    'Odisha': ['O', 'OR'],
    'Assam & North East': ['AS'],
  };

  /// Validates format: [STATE_PREFIX]/[ENROLLMENT_NUMBER]/[YEAR]
  /// Examples: UP/1234/2018, D/456/2015, MAH/7890/2022
  static String? validateEnrollmentNumber(String? value, String selectedState) {
    if (value == null || value.trim().isEmpty) {
      return 'बार काउंसिल पंजीकरण संख्या अनिवार्य है।';
    }

    final normalized = value.trim().toUpperCase();
    final parts = normalized.split('/');

    if (parts.length != 3) {
      return 'अमान्य प्रारूप। सही प्रारूप: राज्य/क्रमांक/वर्ष (उदा. UP/1234/2018)';
    }

    final prefix = parts[0];
    final sequence = parts[1];
    final yearStr = parts[2];

    // 1. Validate Prefix against selected State Bar Council
    final allowedPrefixes = statePrefixes[selectedState] ?? [];
    if (!allowedPrefixes.contains(prefix)) {
      return '$selectedState बार काउंसिल हेतु उपसर्ग ${allowedPrefixes.join(" या ")} होना चाहिए (प्राप्त: $prefix)।';
    }

    // 2. Validate Sequential Number (Numeric, 1 to 6 digits)
    final seqNumber = int.tryParse(sequence);
    if (seqNumber == null || seqNumber <= 0 || sequence.length > 6) {
      return 'अमान्य अनुक्रमांक ($sequence)। केवल 1 से 6 अंकों की संख्या मान्य है।';
    }

    // 3. Validate Year (from 1950 up to 2026)
    final year = int.tryParse(yearStr);
    final currentYear = DateTime.now().year;
    if (year == null || year < 1950 || year > currentYear) {
      return 'अमान्य नामांकन वर्ष ($yearStr)। वर्ष 1950 से $currentYear के मध्य होना चाहिए।';
    }

    return null;
  }
}
