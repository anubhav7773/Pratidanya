/// Utility to format internal precedent identifiers into standard Indian legal citations
/// and provide permanent, reachable live URLs.
class CitationFormatter {
  static final Map<String, String> _knownPrecedentUrls = {
    '1984_4_SCC_116_SHARAD_BIRDHICHAND': 'https://indiankanoon.org/doc/1454140/',
    '2014_AIR_SC_2756_ARNESH_KUMAR': 'https://indiankanoon.org/doc/2982624/',
    '2014_5_SCC_345_PARMANAND': 'https://indiankanoon.org/doc/47101851/',
    '2012_1_SCC_40_SANJAY_CHANDRA': 'https://indiankanoon.org/doc/1922370/',
    '1954_AIR_SC_39_TRIMBAK': 'https://indiankanoon.org/doc/816576/',
    '2009_8_SCC_751_MOHD_IBRAHIM': 'https://indiankanoon.org/doc/744040/',
    '2013_7_SCC_263_JARNAIL_SINGH': 'https://indiankanoon.org/doc/191295246/',
    '2003_8_SCC_300_KR_INDIRA': 'https://indiankanoon.org/doc/1959728/',
    '2021_6_SCC_230_RAMESH_BHAVAN': 'https://indiankanoon.org/doc/69796030/',
    '1994_3_SCC_299_BABU_SINGH': 'https://indiankanoon.org/doc/148696/',
  };

  /// Formats raw citation slugs like `1984_4_SCC_116_SHARAD_BIRDHICHAND`
  /// into recognized Indian legal citations like `(1984) 4 SCC 116`.
  static String format(String rawCitationId) {
    if (rawCitationId.isEmpty) return 'अभिलेख उपलब्ध नहीं';

    final cleanId = rawCitationId.trim();

    // Pattern 1: Year_Volume_SCC_Page (e.g. 1984_4_SCC_116 or 2012_1_SCC_40_SANJAY_CHANDRA)
    final sccRegex = RegExp(r'^(\d{4})_(\d+)_SCC_(\d+)', caseSensitive: false);
    final sccMatch = sccRegex.firstMatch(cleanId);
    if (sccMatch != null) {
      return '(${sccMatch.group(1)}) ${sccMatch.group(2)} SCC ${sccMatch.group(3)}';
    }

    // Pattern 2: Year_AIR_SC_Page (e.g. 2014_AIR_SC_2756_ARNESH_KUMAR or 1954_AIR_SC_39_TRIMBAK)
    final airRegex = RegExp(r'^(\d{4})_AIR_SC_(\d+)', caseSensitive: false);
    final airMatch = airRegex.firstMatch(cleanId);
    if (airMatch != null) {
      return 'AIR ${airMatch.group(1)} SC ${airMatch.group(2)}';
    }

    // Pattern 3: Year_Volume_SCR_Page (e.g. 2024_1_SCR_100)
    final scrRegex = RegExp(r'^(\d{4})_(\d+)_SCR_(\d+)', caseSensitive: false);
    final scrMatch = scrRegex.firstMatch(cleanId);
    if (scrMatch != null) {
      return '[${scrMatch.group(1)}] ${scrMatch.group(2)} SCR ${scrMatch.group(3)}';
    }

    // Pattern 4: Year_INSC_Number (e.g. 2024_INSC_121)
    final inscRegex = RegExp(r'^(\d{4})_INSC_(\d+)', caseSensitive: false);
    final inscMatch = inscRegex.firstMatch(cleanId);
    if (inscMatch != null) {
      return '${inscMatch.group(1)} INSC ${inscMatch.group(2)}';
    }

    // Fallback: If it starts with standard already, e.g. "AIR 1980 SC 785"
    if (cleanId.contains(' ') && !cleanId.contains('_')) {
      return cleanId;
    }

    // Clean up underscores and strip trailing party names if any
    final parts = cleanId.split('_');
    if (parts.length >= 3) {
      return parts.take(4).join(' ');
    }

    return cleanId.replaceAll('_', ' ');
  }

  /// Returns permanent, live, mobile-accessible URL for judicial precedent
  static String getOfficialPortalUrl(String rawCitationId, String? existingUrl) {
    for (final entry in _knownPrecedentUrls.entries) {
      if (rawCitationId.contains(entry.key) || entry.key.contains(rawCitationId)) {
        return entry.value;
      }
    }
    if (existingUrl != null && existingUrl.startsWith('http') && !existingUrl.contains('judis')) {
      return existingUrl;
    }
    final formatted = format(rawCitationId);
    final encodedQuery = Uri.encodeComponent(formatted);
    return 'https://indiankanoon.org/search/?formInput=$encodedQuery';
  }
}
