/// Utility to format internal precedent identifiers into standard Indian legal citations
/// and provide permanent, reachable live URLs.
class CitationFormatter {
  static final Map<String, String> _knownPrecedentUrls = {
    '1954_AIR_SC_39_TRIMBAK': 'https://indiankanoon.org/doc/858387/',
    '2024_INSC_26_PERUMAL_RAJA': 'https://indiankanoon.org/doc/91474193/',
    '2008_15_SCC_133_RAJU': 'https://indiankanoon.org/doc/1921282/',
    '2014_AIR_SC_2756_ARNESH_KUMAR': 'https://indiankanoon.org/doc/2982624/',
    '1984_4_SCC_116_SHARAD_BIRDHICHAND': 'https://indiankanoon.org/doc/13149785/',
    '1994_3_SCC_299_BABU_SINGH': 'https://indiankanoon.org/doc/1515744/',
    'SC-BABU-SINGH-1978': 'https://indiankanoon.org/doc/1515744/',
    'AIR_1978_SC_527': 'https://indiankanoon.org/doc/1515744/',
    '1978_1_SCC_579': 'https://indiankanoon.org/doc/1515744/',
    '1978_AIR_SC_527_BABU_SINGH': 'https://indiankanoon.org/doc/1515744/',
    '1978_1_SCC_579_BABU_SINGH': 'https://indiankanoon.org/doc/1515744/',
    'AIR_1978_SC_527_BABU_SINGH': 'https://indiankanoon.org/doc/1515744/',
    'BABU_SINGH': 'https://indiankanoon.org/doc/1515744/',
    'SC-SATENDER-ANTIL-2022': 'https://indiankanoon.org/doc/7148380/',
    '2022_10_SCC_51': 'https://indiankanoon.org/doc/7148380/',
    '2022_10_SCC_51_SATENDER_KUMAR_ANTIL': 'https://indiankanoon.org/doc/7148380/',
    '2022_INSC_690': 'https://indiankanoon.org/doc/7148380/',
    'SATENDER_KUMAR_ANTIL': 'https://indiankanoon.org/doc/7148380/',
    'SATENDER_ANTIL': 'https://indiankanoon.org/doc/7148380/',
    '2024_INSC_595_MANISH_SISODIA': 'https://indiankanoon.org/doc/132771982/',
    '2020_5_SCC_1_SUSHILA_AGGARWAL': 'https://indiankanoon.org/doc/123660783/',
    '2020_10_SCC_616_BIKRAMJIT_SINGH': 'https://indiankanoon.org/doc/10807134/',
    '2020_7_SCC_1_ARJUN_KHOTKAR': 'https://indiankanoon.org/doc/172105947/',
    '2023_INSC_352_MOHD_MUSLIM': 'https://indiankanoon.org/doc/135015744/',
    '2019_9_SCC_608_PRAMOD_PAWAR': 'https://indiankanoon.org/doc/107689273/',
    '2022_6_SCC_599_KAHKASHAN_KAUSAR': 'https://indiankanoon.org/doc/76640285/',
    '2021_6_SCC_1_SATBIR_SINGH': 'https://indiankanoon.org/doc/59224804/',
    '2020_10_SCC_710_HITESH_VERMA': 'https://indiankanoon.org/doc/111507500/',
    '2020_4_SCC_727_PRATHVI_RAJ': 'https://indiankanoon.org/doc/31336209/',
    '2022_INSC_514_SHRADDHA_GUPTA': 'https://indiankanoon.org/doc/49647060/',
    '2021_3_SCC_713_KA_NAJEEB': 'https://indiankanoon.org/doc/18346623/',
    '2015_5_SCC_1_SHREYA_SINGHAL': 'https://indiankanoon.org/doc/110813550/',
    '2014_9_SCC_772_STATE_SANJAY': 'https://indiankanoon.org/doc/76417350/',
    '2013_7_SCC_263_JARNAIL_SINGH': 'https://indiankanoon.org/doc/70565223/',
    '2021_6_SCC_230_RAMESH_BHAVAN': 'https://indiankanoon.org/doc/41350772/',
    '2003_8_SCC_300_KR_INDIRA': 'https://indiankanoon.org/doc/1265791/',
    '2014_5_SCC_345_PARMANAND': 'https://indiankanoon.org/doc/155481249/',
    '2022_INSC_929_VIJAY_MADANLAL': 'https://indiankanoon.org/doc/14485072/',
    '2021_ALLHC_RAHIM': 'https://indiankanoon.org/doc/91621822/',
    '2019_5_SCC_418_BASALINGAPPA': 'https://indiankanoon.org/doc/37685697/',
    '1998_8_SCC_493_SATISH': 'https://indiankanoon.org/doc/57663853/',
    '1989_CriLJ_127_PAWAN_KUMAR': 'https://indiankanoon.org/doc/123800627/',
    '1972_2_SCC_194_GUNWANTLAL': 'https://indiankanoon.org/doc/178563237/',
    '1967_3_SCR_281_BOOSENNA': 'https://indiankanoon.org/doc/176021959/',
    '2023_4_SCC_731_NEERAJ_DUTTA': 'https://indiankanoon.org/doc/152183853/',
    '2009_8_SCC_751_MOHD_IBRAHIM': 'https://indiankanoon.org/doc/58835166/',
    '2012_1_SCC_40_SANJAY_CHANDRA': 'https://indiankanoon.org/search/?formInput=Sanjay+Chandra+v.+CBI+2012+1+SCC+40',
    '2016_3_SCC_379_MOHANLAL': 'https://indiankanoon.org/doc/164577294/',
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

  /// Returns permanent, live, mobile-accessible URL for judicial precedent.
  /// Eliminates incorrect matches and prevents opening unrelated cases.
  static String getOfficialPortalUrl(String rawCitationId, [String? existingUrl]) {
    if (rawCitationId.isEmpty) return 'https://indiankanoon.org/';

    final cleanId = rawCitationId.trim().toUpperCase().replaceAll(' ', '_');

    // 1. Direct verified ID lookup
    if (_knownPrecedentUrls.containsKey(cleanId)) {
      return _knownPrecedentUrls[cleanId]!;
    }

    // 2. Specific case keyword overrides for robust mapping
    final rawLower = rawCitationId.toLowerCase();
    if (cleanId.contains('SATENDER') ||
        cleanId.contains('ANTIL') ||
        rawLower.contains('सत्येंद्र') ||
        rawLower.contains('सतेंदर') ||
        rawLower.contains('अंतिल') ||
        rawLower.contains('antil')) {
      return 'https://indiankanoon.org/doc/7148380/';
    }
    if (cleanId.contains('BABU_SINGH') ||
        rawLower.contains('बाबू सिंह') ||
        rawLower.contains('babu singh')) {
      return 'https://indiankanoon.org/doc/1515744/';
    }
    if (cleanId.contains('ARNESH') ||
        cleanId.contains('ARNESH_KUMAR') ||
        rawLower.contains('अर्नेश') ||
        rawLower.contains('arnesh')) {
      return 'https://indiankanoon.org/doc/2982624/';
    }

    // 3. Exact or prefix match with length threshold to prevent false positive short matches
    for (final entry in _knownPrecedentUrls.entries) {
      final entryKey = entry.key.toUpperCase();
      if (cleanId == entryKey) {
        return entry.value;
      }
      if (cleanId.length >= 12 && entryKey.startsWith(cleanId)) {
        return entry.value;
      }
      if (entryKey.length >= 12 && cleanId.startsWith(entryKey)) {
        return entry.value;
      }
    }

    // 4. Fallback to existingUrl if valid and not one of the deprecated bad/wrong IDs
    if (existingUrl != null &&
        existingUrl.startsWith('https://indiankanoon.org/') &&
        !existingUrl.contains('1570775') && // Nelly Ghosh bad doc ID
        !existingUrl.contains('816576') &&  // Sadakathulla bad doc ID
        !existingUrl.contains('171587391') && // Broken Satender Antil ID
        !existingUrl.contains('1841394')) {  // Hans Raj Banga wrong doc ID for Babu Singh
      return existingUrl;
    }

    // 4. Targeted search query on Indian Kanoon that ensures exact match at the top
    final formatted = format(rawCitationId);
    final encodedQuery = Uri.encodeComponent(formatted);
    return 'https://indiankanoon.org/search/?formInput=$encodedQuery';
  }
}
