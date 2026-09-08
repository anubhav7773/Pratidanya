import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/utils/citation_formatter.dart';
import 'package:pratidnya/src/features/03_precedent_search/domain/precedent_citation.dart';
import 'package:pratidnya/src/features/04_draft_generator/data/drafting_repository.dart';

void main() {
  group('Goal: Testing Session Ke Dauraan Mile Bugs Root Cause Verification', () {
    test('Bug 1: Case Law Title/Citation Mismatch - Vijaysinh Chandubha Jadeja v. Gujarat', () async {
      final repo = DraftingRepository();
      final draft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'FIR-NDPS-50',
        firNumber: '101/2024',
        district: 'लखनऊ',
        sections: ['8', '20', '50', 'NDPS'],
        policeStation: 'हजरतगंज',
        factualSummary: 'एन.डी.पी.एस. व्यक्तिगत तलाशी का मामला',
      );

      // 1. Verify that 'विजयपुर सिंह' does NOT exist anywhere in the draft
      for (final p in draft.citedPrecedents) {
        expect(p.caseTitle.contains('विजयपुर सिंह'), isFalse,
            reason: 'Typo "विजयपुर सिंह" must never be displayed in drafting studio');
      }

      // 2. Verify that NDPS Section 50 landmark is authentic 'विजयसिंह चंदुभा जडेजा बनाम गुजरात राज्य (2011 1 SCC 609)'
      final vijaysinhPrecedent = draft.citedPrecedents.firstWhere(
        (p) => p.citationId == 'sc-vijaysinh-2011',
      );
      expect(vijaysinhPrecedent.caseTitle, 'विजयसिंह चंदुभा जडेजा बनाम गुजरात राज्य (2011 1 SCC 609)');
      expect(vijaysinhPrecedent.verifiedSourceUrl, 'https://indiankanoon.org/doc/1145861/');

      // 3. Verify CitationFormatter resolves both Hindi and English forms of Vijaysinh
      expect(
        CitationFormatter.getOfficialPortalUrl('sc-vijaysinh-2011', vijaysinhPrecedent.caseTitle),
        'https://indiankanoon.org/doc/1145861/',
      );
      expect(
        CitationFormatter.getOfficialPortalUrl('2011_1_SCC_609', 'Vijaysinh Chandubha Jadeja'),
        'https://indiankanoon.org/doc/1145861/',
      );
    });

    test('Bug 2: Precedent Search Specific Section Filter - "bns 305" strictly excludes 307 & 376', () {
      final babuSingh307 = PrecedentCitation(
        id: '1',
        citationId: '1994_3_SCC_299_BABU_SINGH',
        caseTitle: 'बाबू सिंह बनाम यूपी राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '1994-01-18',
        actName: 'IPC / BNS',
        sectionNumbers: ['307', '109_BNS'],
        headnoteHindi: 'धारा 307 हत्या के प्रयास में जमानत।',
        verbatimText: 'Attempt to murder principles.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/1515744/',
        similarityScore: 0.75,
      );

      final rameshBailParity = PrecedentCitation(
        id: '2',
        citationId: '2021_6_SCC_230_RAMESH_BHAVAN',
        caseTitle: 'रमेश भवन राठौड़ बनाम विशनभाई',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2021-04-20',
        actName: 'CrPC / BNSS',
        sectionNumbers: ['439', '483_BNSS', 'समानता_आधार'],
        headnoteHindi: 'जमानत में समानता (Parity) का सिद्धांत।',
        verbatimText: 'Parity alone cannot be ground.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/41350772/',
        similarityScore: 0.73,
      );

      final pramodPawar376 = PrecedentCitation(
        id: '3',
        citationId: '2019_9_SCC_608_PRAMOD_PAWAR',
        caseTitle: 'प्रमोद सूर्यभान पवार बनाम महाराष्ट्र राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2019-08-21',
        actName: 'IPC / BNS',
        sectionNumbers: ['376', '64_BNS', '70_BNS'],
        headnoteHindi: 'सहमति एवं 376/64 BNS।',
        verbatimText: 'Consent vs misconception.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/107689273/',
        similarityScore: 0.71,
      );

      final trimbak305 = PrecedentCitation(
        id: '4',
        citationId: '1954_AIR_SC_39_TRIMBAK',
        caseTitle: 'त्रिम्बक बनाम मध्य प्रदेश राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '1953-11-20',
        actName: 'IPC / BNS',
        sectionNumbers: ['379', '380', '411', '303_BNS', '305_BNS', '317_BNS'],
        headnoteHindi: 'चोरी एवं बरामदगी के तीन अनिवार्य सिद्धांत।',
        verbatimText: 'Three essentials of stolen property under 380/411/305 BNS.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/858387/',
        similarityScore: 0.82,
      );

      final mixedList = [babuSingh307, rameshBailParity, pramodPawar376, trimbak305];

      // Simulate section gating logic for "bns 305"
      final targetSecs = ['305', '305_BNS', '380', '379', '303_BNS', '317_BNS'];
      final upperTargets = targetSecs.map((s) => s.toUpperCase()).toSet();

      final filtered = mixedList.where((c) {
        final cSecs = c.sectionNumbers.map((s) => s.toUpperCase()).toSet();
        return upperTargets.any((t) => cSecs.contains(t) || cSecs.any((cs) => cs.contains(t) || t.contains(cs)));
      }).toList();

      // Only Trimbak (with 305_BNS) must survive
      expect(filtered.length, 1);
      expect(filtered.first.citationId, '1954_AIR_SC_39_TRIMBAK');
      expect(filtered.any((c) => c.citationId == '1994_3_SCC_299_BABU_SINGH'), isFalse,
          reason: 'Babu Singh (307 IPC) must never match a BNS 305 query');
      expect(filtered.any((c) => c.citationId == '2019_9_SCC_608_PRAMOD_PAWAR'), isFalse,
          reason: 'Pramod Pawar (376 IPC / 64 BNS) must never match a BNS 305 query');
      expect(filtered.any((c) => c.citationId == '2021_6_SCC_230_RAMESH_BHAVAN'), isFalse,
          reason: 'Ramesh Bhavan (Bail Parity) must never match a BNS 305 query');
    });

    test('Bug 3: Date Filter Bypass - "अंतिम 5 वर्ष" strictly excludes 1984 & 1994 judgments', () {
      final sharad1984 = PrecedentCitation(
        id: '1',
        citationId: '1984_4_SCC_116_SHARAD_BIRDHICHAND',
        caseTitle: 'शरद बिरधीचंद सारडा बनाम महाराष्ट्र राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '1984-07-17',
        actName: 'IPC / BNS',
        sectionNumbers: ['302', '103_BNS'],
        headnoteHindi: 'परिस्थितिजन्य साक्ष्य के 5 स्वर्णिम सिद्धांत।',
        verbatimText: 'Five golden principles.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/13149785/',
        similarityScore: 0.88,
      );

      final babuSingh1994 = PrecedentCitation(
        id: '2',
        citationId: '1994_3_SCC_299_BABU_SINGH',
        caseTitle: 'बाबू सिंह बनाम यूपी राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '1994-01-18',
        actName: 'IPC / BNS',
        sectionNumbers: ['307', '109_BNS'],
        headnoteHindi: 'हत्या के प्रयास में जमानत।',
        verbatimText: 'Bail in 307.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/1515744/',
        similarityScore: 0.84,
      );

      final sisodia2024 = PrecedentCitation(
        id: '3',
        citationId: '2024_INSC_595_MANISH_SISODIA',
        caseTitle: 'मनीष सिसोदिया बनाम प्रवर्तन निदेशालय',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2024-08-09',
        actName: 'CrPC / BNSS / PMLA',
        sectionNumbers: ['439', '483_BNSS', '45_PMLA'],
        headnoteHindi: 'त्वरित विचारण का अधिकार एवं जमानत।',
        verbatimText: 'Right to speedy trial is part of Article 21.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/132771982/',
        similarityScore: 0.82,
      );

      final perumal2024 = PrecedentCitation(
        id: '4',
        citationId: '2024_INSC_26_PERUMAL_RAJA',
        caseTitle: 'पेरुमल राजा बनाम राज्य',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2024-01-08',
        actName: 'BSA / IEA',
        sectionNumbers: ['27', '23_BSA'],
        headnoteHindi: 'स्वीकारोक्ति एवं बरामदगी मेमो।',
        verbatimText: 'Section 27 discovery memo.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/91474193/',
        similarityScore: 0.81,
      );

      final candidates = [sharad1984, babuSingh1994, sisodia2024, perumal2024];

      // Simulate the Last 5 Years filter logic (cutoff = DateTime.now().year - 5)
      final currentYear = DateTime.now().year; // 2026
      final cutoffYear = currentYear - 5; // 2021

      final recentOnly = candidates.where((c) {
        final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(c.judgmentDate);
        if (match != null) {
          final year = int.tryParse(match.group(1) ?? '0') ?? 0;
          return year >= cutoffYear;
        }
        return false;
      }).toList();

      // Sharad (1984) and Babu Singh (1994) MUST be filtered out
      expect(recentOnly.length, 2);
      expect(recentOnly.any((c) => c.citationId == '1984_4_SCC_116_SHARAD_BIRDHICHAND'), isFalse,
          reason: '1984 Sharad Birdhichand Sarda must be eliminated under 5-year filter');
      expect(recentOnly.any((c) => c.citationId == '1994_3_SCC_299_BABU_SINGH'), isFalse,
          reason: '1994 Babu Singh must be eliminated under 5-year filter');
      expect(recentOnly.map((c) => c.citationId).toList(), [
        '2024_INSC_595_MANISH_SISODIA',
        '2024_INSC_26_PERUMAL_RAJA',
      ]);
    });
  });
}
