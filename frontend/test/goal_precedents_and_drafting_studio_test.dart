import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/utils/citation_formatter.dart';
import 'package:pratidnya/src/features/04_draft_generator/data/drafting_repository.dart';
import 'package:pratidnya/src/features/04_draft_generator/domain/case_analysis_draft.dart';
import 'package:pratidnya/src/features/03_precedent_search/domain/precedent_citation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal: Precedents & Drafting Studio Zero-Hallucination and Review Link Verification', () {
    test('100% Primary Landmark Precedent Doc IDs - No Citing or Broken Links', () {
      final expectedDocIds = <String, String>{
        // Bail Jurisprudence
        'SC-SATENDER-ANTIL-2022': '7148380',
        '2022 10 SCC 51': '7148380',
        'सत्येंद्र कुमार अंतिल बनाम सीबीआई': '7148380',
        'SC-BABU-SINGH-1978': '1515744',
        'AIR 1978 SC 527': '1515744',
        'बाबू सिंह बनाम यूपी': '1515744',
        '2012 1 SCC 40': '1563495', // Sanjay Chandra
        'संजय चंद्रा बनाम सीबीआई': '1563495',
        '2024 INSC 595': '132771982', // Manish Sisodia
        'मनीष सिसोदिया बनाम ईडी': '132771982',
        '2021 3 SCC 713': '18346623', // KA Najeeb
        '2020 5 SCC 1': '123660783', // Sushila Aggarwal
        'सुशीला अग्रवाल': '123660783',
        '2020 10 SCC 616': '10807134', // Bikramjit Singh

        // Arrest & Fair Investigation
        '2014 AIR SC 2756': '2982624', // Arnesh Kumar
        'अर्नेश कुमार बनाम बिहार राज्य': '2982624',
        'SC-MOHANLAL-2018': '38505268', // Mohan Lal v Punjab
        '2018 17 SCC 627': '38505268',
        '2016 3 SCC 379': '129387304', // UOI v Mohanlal
        '2021 6 SCC 230': '41350772', // Ramesh Bhavan Rathod

        // Circumstantial & Recovery Law
        '1984 4 SCC 116': '13149785', // Sharad Birdhichand Sarda
        'शरद बिरधीचंद सारडा': '13149785',
        '1954 AIR SC 39': '858387', // Trimbak v MP
        'त्रिम्बक बनाम मध्य प्रदेश': '858387',
        '2024 INSC 26': '91474193', // Perumal Raja
        '2008 15 SCC 133': '1921282', // Raju @ Ratan

        // NDPS Mandatory Compliance
        'SC-VIJAYSINH-2011': '1145861', // Vijaysinh Chandubha Jadeja
        'विजयसिंह चंदुभा जडेजा': '1145861',
        '2011 1 SCC 609': '1145861',
        'SC-ARIF-KHAN-2018': '173720727', // Arif Khan v Uttarakhand
        'आरिफ खान बनाम उत्तराखंड राज्य': '173720727',
        '2018 18 SCC 380': '173720727',
        '2014 5 SCC 345': '155481249', // State of Rajasthan v Parmanand
        'परमानंद बनाम राजस्थान राज्य': '155481249',
        '2023 INSC 352': '135015744', // Mohd Muslim

        // Special Statutes (POCSO, SC/ST, PMLA, Arms, NI Act, PC Act, Excise)
        '2013 7 SCC 263': '70565223', // Jarnail Singh
        '2019 9 SCC 608': '107689273', // Pramod Suryabhan Pawar
        '2022 6 SCC 599': '76640285', // Kahkashan Kausar
        '2021 6 SCC 1': '59224804', // Satbir Singh
        '2020 10 SCC 710': '111507500', // Hitesh Verma
        '2020 4 SCC 727': '31336209', // Prathvi Raj Chauhan
        '1972 2 SCC 194': '1332361', // Gunwantlal
        '1989 CriLJ 127': '1928699', // Pawan Kumar
        '2022 INSC 514': '49647060', // Shraddha Gupta
        '1967 3 SCR 281': '214899', // Madiga Boosenna
        '2022 INSC 929': '14485072', // Vijay Madanlal Choudhary
        '2015 5 SCC 1': '110813550', // Shreya Singhal
        '2023 4 SCC 731': '15799208', // Neeraj Dutta
        '2003 8 SCC 300': '1265791', // KR Indira
        '2019 5 SCC 418': '87091644', // Basalingappa
        '2009 8 SCC 751': '409057', // Mohd Ibrahim
        'मोहम्मद इब्राहिम बनाम बिहार': '409057',
        '1998 8 SCC 493': '371583', // State of Karnataka v Satish
        '2014 9 SCC 772': '76417350', // State of NCT of Delhi v Sanjay
        '2021 ALLHC RAHIM': '91621822', // Rahim v UP
        '2020 7 SCC 1': '172105947', // Arjun Panditrao Khotkar
      };

      for (final entry in expectedDocIds.entries) {
        final url = CitationFormatter.getOfficialPortalUrl(entry.key);
        expect(
          url,
          equals('https://indiankanoon.org/doc/${entry.value}/'),
          reason: 'Citation "${entry.key}" must resolve to authentic doc ID ${entry.value}, got: $url',
        );
      }
    });

    test('Strict Blacklist of Known Flawed & Citing Kanoon Doc IDs', () {
      final blacklistedDocIds = [
        '816576', // Flawed Trimbak citing case
        '1454140', // Flawed Sharad Birdhichand citing case
        '1841394', // Flawed Babu Singh citing case
        '148696',
        '171587391', // Flawed Satender Antil citing case
        '744040', // Flawed Mohd Ibrahim citing case (Vinod Kumar Bhutani)
        '58835166',
        '1959728', // Flawed KR Indira citing case
        '47101851', // Flawed Parmanand citing case (Om Parkash)
        '47469744',
        '182697843', // Flawed Perumal Raja citing case
        '164577294', // Flawed Mohanlal citing case
        '1173934', // Flawed Satish citing case (Sunita Devi)
        '57663853',
        '1570775', // Flawed Raju @ Ratan citing case
        '1218529', // Flawed Gunwantlal citing case
        '178563237',
        '1359654', // Flawed Pawan Kumar citing case
        '123800627',
        '176021959', // Flawed Boosenna citing case (Soman)
        '526714',
        '152912440', // Flawed Vijay Madanlal citing case
        '182882772', // Flawed Neeraj Dutta citing case
        '152183853',
        '37685697', // Flawed Basalingappa citing case
        '1749714', // Flawed Vijaysinh Jadeja citing case
      ];

      for (final badId in blacklistedDocIds) {
        final rawBadUrl = 'https://indiankanoon.org/doc/$badId/';
        final sanitized = CitationFormatter.getOfficialPortalUrl('TEST-ID', rawBadUrl);
        expect(
          sanitized.contains(badId),
          isFalse,
          reason: 'Blacklisted Doc ID $badId must never be rendered in any official portal URL',
        );
      }
    });

    test('DraftingRepository Synthesizes Fully Grounded Precedents for All Core Domains', () {
      final repo = DraftingRepository();

      // NDPS Draft
      final ndpsDraft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'ndps-1',
        firNumber: '12/2026',
        district: 'Varanasi',
        accusedName: 'सुनील',
        sections: ['8/20 NDPS Act'],
        factualSummary: 'पुलिस ने चेकिंग के दौरान अभियुक्त के पास से गांजा बरामद करने का दावा किया है।',
      );
      expect(ndpsDraft.citedPrecedents.length, greaterThanOrEqualTo(2));
      for (final prec in ndpsDraft.citedPrecedents) {
        expect(prec.verifiedSourceUrl, startsWith('https://indiankanoon.org/doc/'));
        expect(prec.courtName, contains('उच्चतम न्यायालय'));
        expect(prec.caseTitle.isNotEmpty, isTrue);
        expect(prec.quotedPassage.isNotEmpty, isTrue);
      }

      // POCSO Draft
      final pocsoDraft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'pocso-1',
        firNumber: '45/2026',
        district: 'Gorakhpur',
        accusedName: 'अमन',
        sections: ['7/8 POCSO Act', '354 IPC'],
        factualSummary: 'नाबालिग पीड़िता के साथ कथित छेड़छाड़ का आरोप लगाया गया है।',
      );
      expect(pocsoDraft.citedPrecedents.length, greaterThanOrEqualTo(2));
      for (final prec in pocsoDraft.citedPrecedents) {
        expect(prec.verifiedSourceUrl, startsWith('https://indiankanoon.org/doc/'));
        expect(prec.courtName, contains('उच्चतम न्यायालय'));
      }

      // SC/ST Act Draft
      final scstDraft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'scst-1',
        firNumber: '88/2026',
        district: 'Prayagraj',
        accusedName: 'दिनेश',
        sections: ['3(1)(r) SC/ST Act', '323 IPC'],
        factualSummary: 'कथित जातिसूचक शब्दों के प्रयोग का आरोप चारदीवारी के भीतर निजी विवाद में लगाया गया।',
      );
      expect(scstDraft.citedPrecedents.length, greaterThanOrEqualTo(2));
      for (final prec in scstDraft.citedPrecedents) {
        expect(prec.verifiedSourceUrl, startsWith('https://indiankanoon.org/doc/'));
      }
    });

    test('PrecedentCitation and CitedPrecedentItem Domain Integrity', () {
      final item = CitedPrecedentItem(
        citationId: '2024 INSC 595',
        caseTitle: 'Manish Sisodia v. ED',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2024',
        quotedPassage: 'Bail is the rule and jail is the exception.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/132771982/',
        isGroundedInRecord: true,
      );

      expect(item.verifiedSourceUrl, equals('https://indiankanoon.org/doc/132771982/'));
      final canonicalUrl = CitationFormatter.getOfficialPortalUrl(item.citationId, item.verifiedSourceUrl);
      expect(canonicalUrl, equals('https://indiankanoon.org/doc/132771982/'));

      final cit = PrecedentCitation(
        id: 'c-1',
        citationId: '2014 5 SCC 345',
        caseTitle: 'State of Rajasthan v. Parmanand',
        courtName: 'उच्चतम न्यायालय',
        judgmentDate: '2014',
        actName: 'NDPS Act',
        sectionNumbers: ['50'],
        headnoteHindi: 'धारा 50 एनडीपीएस का अनुपालन अनिवार्य है।',
        verbatimText: 'Compliance of Section 50 is mandatory.',
        verifiedSourceUrl: 'https://indiankanoon.org/doc/155481249/',
        similarityScore: 0.95,
      );

      final citUrl = CitationFormatter.getOfficialPortalUrl(cit.citationId, cit.verifiedSourceUrl);
      expect(citUrl, equals('https://indiankanoon.org/doc/155481249/'));
    });
  });
}
