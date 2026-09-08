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
    '2019_5_SCC_418_BASALINGAPPA': 'https://indiankanoon.org/doc/87091644/',
    '1998_8_SCC_493_SATISH': 'https://indiankanoon.org/doc/371583/',
    '1989_CriLJ_127_PAWAN_KUMAR': 'https://indiankanoon.org/doc/1928699/',
    '1972_2_SCC_194_GUNWANTLAL': 'https://indiankanoon.org/doc/1332361/',
    '1967_3_SCR_281_BOOSENNA': 'https://indiankanoon.org/doc/214899/',
    '2023_4_SCC_731_NEERAJ_DUTTA': 'https://indiankanoon.org/doc/15799208/',
    '2009_8_SCC_751_MOHD_IBRAHIM': 'https://indiankanoon.org/doc/409057/',
    '2012_1_SCC_40_SANJAY_CHANDRA': 'https://indiankanoon.org/doc/1563495/',
    '2016_3_SCC_379_MOHANLAL': 'https://indiankanoon.org/doc/129387304/',
    'SC-ARIF-KHAN-2018': 'https://indiankanoon.org/doc/173720727/',
    'SC-VIJAYSINH-2011': 'https://indiankanoon.org/doc/1145861/',
    'SC-MOHANLAL-2018': 'https://indiankanoon.org/doc/38505268/',
    'SC-SANJAY-CHANDRA-2011': 'https://indiankanoon.org/doc/1563495/',
    'SC-SHARAD-BIRDHICHAND-1984': 'https://indiankanoon.org/doc/13149785/',
    'SC-MANISH-SISODIA-2024': 'https://indiankanoon.org/doc/132771982/',
    // Canonical Standard Law Report Citations
    '2018_17_SCC_627': 'https://indiankanoon.org/doc/38505268/',
    '2018_17_SCC_627_MOHAN_LAL': 'https://indiankanoon.org/doc/38505268/',
    '2016_3_SCC_379': 'https://indiankanoon.org/doc/129387304/',
    '2014_5_SCC_345': 'https://indiankanoon.org/doc/155481249/',
    '2014_AIR_SC_2756': 'https://indiankanoon.org/doc/2982624/',
    '1984_4_SCC_116': 'https://indiankanoon.org/doc/13149785/',
    '1954_AIR_SC_39': 'https://indiankanoon.org/doc/858387/',
    '2012_1_SCC_40': 'https://indiankanoon.org/doc/1563495/',
    '2024_INSC_595': 'https://indiankanoon.org/doc/132771982/',
    '2021_3_SCC_713': 'https://indiankanoon.org/doc/18346623/',
    '2020_5_SCC_1': 'https://indiankanoon.org/doc/123660783/',
    '2020_10_SCC_616': 'https://indiankanoon.org/doc/10807134/',
    '2011_1_SCC_609': 'https://indiankanoon.org/doc/1145861/',
    '2018_18_SCC_380': 'https://indiankanoon.org/doc/173720727/',
    '2013_7_SCC_263': 'https://indiankanoon.org/doc/70565223/',
    '2019_9_SCC_608': 'https://indiankanoon.org/doc/107689273/',
    '2022_6_SCC_599': 'https://indiankanoon.org/doc/76640285/',
    '2021_6_SCC_1': 'https://indiankanoon.org/doc/59224804/',
    '2020_10_SCC_710': 'https://indiankanoon.org/doc/111507500/',
    '2020_4_SCC_727': 'https://indiankanoon.org/doc/31336209/',
    '1972_2_SCC_194': 'https://indiankanoon.org/doc/1332361/',
    '1989_CRILJ_127': 'https://indiankanoon.org/doc/1928699/',
    '2022_INSC_514': 'https://indiankanoon.org/doc/49647060/',
    '1967_3_SCR_281': 'https://indiankanoon.org/doc/214899/',
    '2022_INSC_929': 'https://indiankanoon.org/doc/14485072/',
    '2015_5_SCC_1': 'https://indiankanoon.org/doc/110813550/',
    '2023_4_SCC_731': 'https://indiankanoon.org/doc/15799208/',
    '2003_8_SCC_300': 'https://indiankanoon.org/doc/1265791/',
    '2019_5_SCC_418': 'https://indiankanoon.org/doc/87091644/',
    '2009_8_SCC_751': 'https://indiankanoon.org/doc/409057/',
    '1998_8_SCC_493': 'https://indiankanoon.org/doc/371583/',
    '2014_9_SCC_772': 'https://indiankanoon.org/doc/76417350/',
    '2020_7_SCC_1': 'https://indiankanoon.org/doc/172105947/',
    '2024_INSC_26': 'https://indiankanoon.org/doc/91474193/',
    '2008_15_SCC_133': 'https://indiankanoon.org/doc/1921282/',
    '2023_INSC_352': 'https://indiankanoon.org/doc/135015744/',

  };

  /// Set of blacklisted Kanoon document IDs that were historically hallucinated,
  /// citing cases, or unrelated cases. These must NEVER be opened.
  static const Set<String> _blacklistedKanoonDocIds = {
    '171587391', // Broken Satender Antil ID
    '1841394',   // Hans Raj Banga wrong doc ID for Babu Singh
    '816576',    // Sadakathulla wrong doc ID for Trimbak
    '1570775',   // Nelly Ghosh wrong doc ID for Raju
    '1454140',   // Sri G N Raju wrong doc ID for Sharad Birdhichand
    '744040',    // P.R. Saju wrong doc ID for Mohd Ibrahim
    '1959728',   // R. C. Vaish wrong doc ID for K.R. Indira
    '148696',    // Kedar Prasad Keshri wrong doc ID for Babu Singh
    '182697843', // New India Assurance wrong doc ID for Perumal Raja
    '1173934',   // Sunita Devi wrong doc ID for Satish
    '1218529',   // UP Shri Badrinath wrong doc ID for Gunwantlal
    '1359654',   // Neeraj Dixit wrong doc ID for Pawan Kumar
    '152912440', // 404 Act/Judgment not found wrong doc ID for Vijay Madanlal
    '58835166',  // Vinod Kumar Bhutani citing case for Mohd Ibrahim
    '57663853',  // Citing case for Satish
    '123800627', // Citing case for Pawan Kumar
    '178563237', // Wrong doc ID for Gunwantlal
    '176021959', // Soman wrong doc ID for Boosenna
    '152183853', // Rabban Alam wrong doc ID for Neeraj Dutta
    '37685697',  // Citing case for Basalingappa
    '182449767', // Citing case for Sanjay
    '164577294', // Thounaojam Punima Singh wrong doc ID for Mohanlal
    '47469744',  // Om Parkash wrong doc ID for Parmanand
    '166289850', // Amit Agrawal wrong doc ID for Sanjay Chandra
    '86152259',  // Yadaiah wrong doc ID for Rahim
    '47101851',  // Om Parkash wrong doc ID for Parmanand
    '182882772', // High Court wrong doc ID for Neeraj Dutta
    '1749714',   // High Court wrong doc ID for Vijaysinh Jadeja
    '526714',    // High Court wrong doc ID for Boosenna
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
  /// Eliminates incorrect matches, citing cases, and prevents opening unrelated cases.
  static String getOfficialPortalUrl(String rawCitationId, [String? existingUrl]) {
    if (rawCitationId.isEmpty) return 'https://indiankanoon.org/';

    final cleanId = rawCitationId.trim().toUpperCase().replaceAll(' ', '_');
    final rawLower = rawCitationId.toLowerCase();

    // 1. Direct verified ID lookup in canonical map
    if (_knownPrecedentUrls.containsKey(cleanId)) {
      return _knownPrecedentUrls[cleanId]!;
    }

    // 2. Specific case keyword overrides for robust mapping in English and Devanagari
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
    if (cleanId.contains('SANJAY_CHANDRA') ||
        rawLower.contains('संजय चंद्रा') ||
        rawLower.contains('sanjay chandra')) {
      return 'https://indiankanoon.org/doc/1563495/';
    }
    if (cleanId.contains('SHARAD_BIRDHICHAND') ||
        cleanId.contains('SARDA') ||
        rawLower.contains('शरद बिरधीचंद') ||
        rawLower.contains('सारडा') ||
        rawLower.contains('birdhichand')) {
      return 'https://indiankanoon.org/doc/13149785/';
    }
    if (cleanId.contains('PARMANAND') ||
        rawLower.contains('परमानंद') ||
        rawLower.contains('parmanand')) {
      return 'https://indiankanoon.org/doc/155481249/';
    }
    if (cleanId.contains('TRIMBAK') ||
        rawLower.contains('त्रिम्बक') ||
        rawLower.contains('trimbak')) {
      return 'https://indiankanoon.org/doc/858387/';
    }
    if (cleanId.contains('MOHD_IBRAHIM') ||
        cleanId.contains('MD_IBRAHIM') ||
        rawLower.contains('मोहम्मद इब्राहिम') ||
        rawLower.contains('mohd ibrahim') ||
        rawLower.contains('md.ibrahim')) {
      return 'https://indiankanoon.org/doc/409057/';
    }
    if (cleanId.contains('JARNAIL_SINGH') ||
        rawLower.contains('जरनैल सिंह') ||
        rawLower.contains('jarnail singh')) {
      return 'https://indiankanoon.org/doc/70565223/';
    }
    if (cleanId.contains('KR_INDIRA') ||
        cleanId.contains('INDIRA') ||
        rawLower.contains('के.आर. इंदिरा') ||
        rawLower.contains('indira')) {
      return 'https://indiankanoon.org/doc/1265791/';
    }
    if (cleanId.contains('RAMESH_BHAVAN') ||
        rawLower.contains('रमेश भवन') ||
        rawLower.contains('ramesh bhavan')) {
      return 'https://indiankanoon.org/doc/41350772/';
    }
    if (cleanId.contains('MANISH_SISODIA') ||
        rawLower.contains('मनीष सिसोदिया') ||
        rawLower.contains('sisodia')) {
      return 'https://indiankanoon.org/doc/132771982/';
    }
    if (cleanId.contains('SUSHILA_AGGARWAL') ||
        rawLower.contains('सुशीला अग्रवाल') ||
        rawLower.contains('sushila aggarwal')) {
      return 'https://indiankanoon.org/doc/123660783/';
    }
    if (cleanId.contains('BIKRAMJIT_SINGH') ||
        rawLower.contains('बिक्रमजीत सिंह') ||
        rawLower.contains('bikramjit')) {
      return 'https://indiankanoon.org/doc/10807134/';
    }
    if (cleanId.contains('ARJUN_KHOTKAR') ||
        rawLower.contains('अर्जुन खोतकर') ||
        rawLower.contains('khotkar')) {
      return 'https://indiankanoon.org/doc/172105947/';
    }
    if (cleanId.contains('PERUMAL_RAJA') ||
        rawLower.contains('पेरुमल राजा') ||
        rawLower.contains('perumal raja')) {
      return 'https://indiankanoon.org/doc/91474193/';
    }
    if (cleanId.contains('MOHD_MUSLIM') ||
        rawLower.contains('मोहम्मद मुस्लिम') ||
        rawLower.contains('mohd muslim')) {
      return 'https://indiankanoon.org/doc/135015744/';
    }
    if (cleanId.contains('PRAMOD_PAWAR') ||
        rawLower.contains('प्रमोद सूर्यभान') ||
        rawLower.contains('pramod pawar')) {
      return 'https://indiankanoon.org/doc/107689273/';
    }
    if (cleanId.contains('KAHKASHAN') ||
        rawLower.contains('कहकशां') ||
        rawLower.contains('kahkashan')) {
      return 'https://indiankanoon.org/doc/76640285/';
    }
    if (cleanId.contains('SATBIR_SINGH') ||
        rawLower.contains('सतबीर सिंह') ||
        rawLower.contains('satbir singh')) {
      return 'https://indiankanoon.org/doc/59224804/';
    }
    if (cleanId.contains('RAJU') ||
        rawLower.contains('राजू उर्फ रतन') ||
        rawLower.contains('raju @ ratan')) {
      return 'https://indiankanoon.org/doc/1921282/';
    }
    if (cleanId.contains('HITESH_VERMA') ||
        rawLower.contains('हितेश वर्मा') ||
        rawLower.contains('hitesh verma')) {
      return 'https://indiankanoon.org/doc/111507500/';
    }
    if (cleanId.contains('PRATHVI_RAJ') ||
        rawLower.contains('पृथ्वी राज चौहान') ||
        rawLower.contains('prathvi raj')) {
      return 'https://indiankanoon.org/doc/31336209/';
    }
    if (cleanId.contains('GUNWANTLAL') ||
        rawLower.contains('गुणवंतलाल') ||
        rawLower.contains('gunwantlal')) {
      return 'https://indiankanoon.org/doc/1332361/';
    }
    if (cleanId.contains('PAWAN_KUMAR') ||
        rawLower.contains('पवन कुमार') ||
        rawLower.contains('pawan kumar')) {
      return 'https://indiankanoon.org/doc/1928699/';
    }
    if (cleanId.contains('SHRADDHA_GUPTA') ||
        rawLower.contains('श्रद्धा गुप्ता') ||
        rawLower.contains('shraddha gupta')) {
      return 'https://indiankanoon.org/doc/49647060/';
    }
    if (cleanId.contains('BOOSENNA') ||
        rawLower.contains('बूसेन्ना') ||
        rawLower.contains('boosenna')) {
      return 'https://indiankanoon.org/doc/214899/';
    }
    if (cleanId.contains('VIJAY_MADANLAL') ||
        rawLower.contains('विजय मदनलाल') ||
        rawLower.contains('vijay madanlal')) {
      return 'https://indiankanoon.org/doc/14485072/';
    }
    if (cleanId.contains('KA_NAJEEB') ||
        cleanId.contains('NAJEEB') ||
        rawLower.contains('नजीब') ||
        rawLower.contains('najeeb')) {
      return 'https://indiankanoon.org/doc/18346623/';
    }
    if (cleanId.contains('SHREYA_SINGHAL') ||
        rawLower.contains('श्रेया सिंघल') ||
        rawLower.contains('shreya singhal')) {
      return 'https://indiankanoon.org/doc/110813550/';
    }
    if (cleanId.contains('NEERAJ_DUTTA') ||
        rawLower.contains('नीरज दत्ता') ||
        rawLower.contains('neeraj dutta')) {
      return 'https://indiankanoon.org/doc/15799208/';
    }
    if (cleanId.contains('BASALINGAPPA') ||
        rawLower.contains('बसालिनगप्पा') ||
        rawLower.contains('basalingappa')) {
      return 'https://indiankanoon.org/doc/87091644/';
    }
    if (cleanId.contains('STATE_SANJAY') ||
        cleanId.contains('SANJAY_SAND') ||
        rawLower.contains('संजय बनाम राज्य') ||
        rawLower.contains('state of nct of delhi vs sanjay')) {
      return 'https://indiankanoon.org/doc/76417350/';
    }
    if (cleanId.contains('RAHIM') ||
        rawLower.contains('रहीम') ||
        rawLower.contains('rahim')) {
      return 'https://indiankanoon.org/doc/91621822/';
    }
    if (cleanId.contains('SATISH') ||
        rawLower.contains('सतीश') ||
        rawLower.contains('satish')) {
      return 'https://indiankanoon.org/doc/371583/';
    }
    if (cleanId.contains('ARIF_KHAN') ||
        rawLower.contains('आरिफ खान') ||
        rawLower.contains('arif khan')) {
      return 'https://indiankanoon.org/doc/173720727/';
    }
    if (cleanId.contains('VIJAYSINH') ||
        cleanId.contains('JADEJA') ||
        rawLower.contains('विजय सिंह चंदुभा जडेजा') ||
        rawLower.contains('विजयसिंह चंदुभा जडेजा') ||
        rawLower.contains('विजय सिंह') ||
        rawLower.contains('विजयपुर सिंह') ||
        rawLower.contains('विजयसिंह') ||
        rawLower.contains('जडेजा') ||
        rawLower.contains('vijaysinh') ||
        rawLower.contains('jadeja')) {
      return 'https://indiankanoon.org/doc/1145861/';
    }
    if (cleanId.contains('MOHANLAL') ||
        rawLower.contains('मोहनलाल') ||
        rawLower.contains('mohanlal')) {
      return 'https://indiankanoon.org/doc/129387304/';
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

    // 4. Fallback to existingUrl ONLY if valid and NOT in the blacklisted set
    if (existingUrl != null &&
        existingUrl.startsWith('https://indiankanoon.org/') &&
        !existingUrl.contains('search')) {
      bool isBlacklisted = false;
      for (final badId in _blacklistedKanoonDocIds) {
        if (existingUrl.contains('/doc/$badId/')) {
          isBlacklisted = true;
          break;
        }
      }
      if (!isBlacklisted) {
        return existingUrl;
      }
    }

    // 5. Targeted search query on Indian Kanoon that ensures exact match at the top
    final formatted = format(rawCitationId);
    final encodedQuery = Uri.encodeComponent(formatted);
    return 'https://indiankanoon.org/search/?formInput=$encodedQuery';
  }
}
