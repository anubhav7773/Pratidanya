class StatutoryActInfo {
  final String actCode;
  final String actNameHindi;
  final String actNameEnglish;
  final bool isSpecialAct;
  final List<String> popularSections;

  const StatutoryActInfo({
    required this.actCode,
    required this.actNameHindi,
    required this.actNameEnglish,
    this.isSpecialAct = false,
    required this.popularSections,
  });
}

class SpecialActsRegistry {
  static const List<StatutoryActInfo> supportedActs = [
    StatutoryActInfo(
      actCode: 'BNS',
      actNameHindi: 'भारतीय न्याय संहिता 2023 (BNS)',
      actNameEnglish: 'Bharatiya Nyaya Sanhita 2023',
      isSpecialAct: false,
      popularSections: [
        'धारा 103 BNS (हत्या)',
        'धारा 106 BNS (उपेक्षा से मृत्यु)',
        'धारा 109 BNS (हत्या का प्रयास)',
        'धारा 115 BNS (स्वेच्छया उपहति)',
        'धारा 117 BNS (घोर उपहति)',
        'धारा 303 BNS (चोरी)',
        'धारा 305 BNS (आवासीय गृह में चोरी)',
        'धारा 309 BNS (डकैती / लूट)',
        'धारा 316 BNS (आपराधिक न्यासभंग)',
        'धारा 318 BNS (धोखाधड़ी / Cheating)',
        'धारा 329 BNS (अनाधिकार गृह-अतिचार)',
        'धारा 336 BNS (कूटकरण / जालसाजी)',
        'धारा 351 BNS (आपराधिक धमकी)',
        'धारा 352 BNS (शांतिभंग हेतु अपमान)',
        'धारा 64 BNS (बलात्कार)',
        'धारा 69 BNS (विवाह का झूठा वादा कर संबंध)',
        'धारा 85 BNS (दहेज प्रताड़ना / पति-नातेदार क्रूरता)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'IPC',
      actNameHindi: 'भारतीय दंड संहिता 1860 (IPC)',
      actNameEnglish: 'Indian Penal Code 1860',
      isSpecialAct: false,
      popularSections: [
        'धारा 302 IPC (हत्या)',
        'धारा 304A IPC (लापरवाही से मृत्यु)',
        'धारा 307 IPC (हत्या का प्रयास)',
        'धारा 323 IPC (मारपीट / साधारण चोट)',
        'धारा 325 IPC (गंभीर चोट)',
        'धारा 379 IPC (चोरी)',
        'धारा 380 IPC (घर में चोरी)',
        'धारा 392 IPC (लूट)',
        'धारा 395 IPC (डकैती)',
        'धारा 406 IPC (अमानत में खयानत)',
        'धारा 420 IPC (धोखाधड़ी)',
        'धारा 452 IPC (हमले की तैयारी के साथ गृह-अतिचार)',
        'धारा 467 IPC (मूल्यवान प्रतिभूति की जालसाजी)',
        'धारा 468 IPC (धोखाधड़ी हेतु जालसाजी)',
        'धारा 471 IPC (कूटरचित दस्तावेज का असली रूप में उपयोग)',
        'धारा 498A IPC (दहेज उत्पीड़न / क्रूरता)',
        'धारा 504 IPC (गाली-गलौज / अपमान)',
        'धारा 506 IPC (जान से मारने की धमकी)',
        'धारा 376 IPC (बलात्कार)',
        'धारा 354 IPC (शीलभंग / छेड़खानी)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'NDPS',
      actNameHindi: 'एन.डी.पी.एस. एक्ट 1985 (NDPS Act)',
      actNameEnglish: 'Narcotic Drugs & Psychotropic Substances Act 1985',
      isSpecialAct: true,
      popularSections: [
        'धारा 8/20 NDPS (चरस / गांजा बरामदगी)',
        'धारा 8/21 NDPS (स्मैक / हेरोइन / नशीला पाउडर)',
        'धारा 8/22 NDPS (मनःप्रभावी दवाएं / नशीली गोलियां)',
        'धारा 8/18 NDPS (अफीम की बरामदगी)',
        'धारा 27A NDPS (अवैध व्यापार को वित्तपोषण / संश्रय)',
        'धारा 29 NDPS (आपराधिक षड्यंत्र / दुष्प्रेरण)',
        'धारा 50 NDPS (राजपत्रित अधिकारी / मजिस्ट्रेट के समक्ष तलाशी)',
        'धारा 37 NDPS (जमानत की दोहरी कठोर शर्तें)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'POCSO',
      actNameHindi: 'पॉक्सो एक्ट 2012 (POCSO Act)',
      actNameEnglish: 'Protection of Children from Sexual Offences Act 2012',
      isSpecialAct: true,
      popularSections: [
        'धारा 3/4 POCSO (प्रवेशी लैंगिक हमला / Penatrative Assault)',
        'धारा 5/6 POCSO (गंभीर प्रकृत्ति का प्रवेशी लैंगिक हमला)',
        'धारा 7/8 POCSO (लैंगिक हमला / Sexual Assault)',
        'धारा 9/10 POCSO (गंभीर लैंगिक हमला)',
        'धारा 11/12 POCSO (लैंगिक उत्पीड़न / यौन प्रताड़ना)',
        'धारा 16/17 POCSO (दुष्प्रेरण एवं षड्यंत्र)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'ARMS',
      actNameHindi: 'आयुध अधिनियम 1959 (Arms Act)',
      actNameEnglish: 'Arms Act 1959',
      isSpecialAct: true,
      popularSections: [
        'धारा 3/25 Arms Act (अवैध तमंचा / कारतूस बरामदगी)',
        'धारा 4/25 Arms Act (प्रतिबंधित चाकू / छुरी बरामदगी)',
        'धारा 27 Arms Act (अवैध असलहे का उपयोग / फायरिंग)',
        'धारा 29 Arms Act (अनधिकृत व्यक्ति को शस्त्र सौंपना)',
        'धारा 30 Arms Act (लाइसेंस शर्तों का उल्लंघन)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'GANGSTERS',
      actNameHindi: 'उ.प्र. गिरोहबंद अधिनियम 1986 (UP Gangsters Act)',
      actNameEnglish: 'UP Gangsters & Anti-Social Activities Act 1986',
      isSpecialAct: true,
      popularSections: [
        'धारा 2/3 UP Gangsters Act (गैंग संचालन एवं सदस्यता)',
        'धारा 14(1) UP Gangsters Act (आपराधिक संपत्ति कुर्की)',
        'धारा 19(4) UP Gangsters Act (विशेष जमानत शर्तें)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'SC_ST',
      actNameHindi: 'एस.सी./एस.टी. एक्ट 1989 (SC/ST Act)',
      actNameEnglish: 'SC and ST (Prevention of Atrocities) Act 1989',
      isSpecialAct: true,
      popularSections: [
        'धारा 3(1)(r) SC/ST Act (सार्वजनिक दृष्टिगोचर स्थान पर जानबूझकर अपमान)',
        'धारा 3(1)(s) SC/ST Act (जातिसूचक गाली-गलौज व प्रताड़ना)',
        'धारा 3(1)(w) SC/ST Act (लैंगिक प्रताड़ना / शीलभंग)',
        'धारा 3(2)(v) SC/ST Act (आईपीसी/बीएनएस अपराध जातिगत कारण से)',
        'धारा 3(2)(va) SC/ST Act (विशिष्ट अनुसूची अपराध)',
        'धारा 14A SC/ST Act (उच्च न्यायालय में दांडिक अपील)',
        'धारा 18/18A SC/ST Act (अग्रिम जमानत पर सांविधिक रोक)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'UP_EXCISE',
      actNameHindi: 'उ.प्र. आबकारी अधिनियम 1910 (UP Excise Act)',
      actNameEnglish: 'UP Excise Act 1910',
      isSpecialAct: true,
      popularSections: [
        'धारा 60 UP Excise Act (अवैध शराब निर्माण / कब्जा / परिवहन)',
        'धारा 60(2) UP Excise Act (कच्ची / लहन शराब निर्माण)',
        'धारा 60A UP Excise Act (विषाक्त शराब निर्माण जिससे जनहानि का भय)',
        'धारा 62 UP Excise Act (अवैध बिक्री / वितरण)',
        'धारा 72 UP Excise Act (वाहन व सामग्री जब्ती)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'IT_ACT',
      actNameHindi: 'सूचना प्रौद्योगिकी अधिनियम 2000 (IT Act - साइबर अपराध)',
      actNameEnglish: 'Information Technology Act 2000',
      isSpecialAct: true,
      popularSections: [
        'धारा 66 IT Act (कम्प्यूटर संबंधित अपराध / हैकिंग)',
        'धारा 66C IT Act (पहचान चोरी / पासवर्ड चुराना)',
        'धारा 66D IT Act (कंप्यूटर संसाधनों द्वारा प्रतिरूपण कर धोखाधड़ी)',
        'धारा 66E IT Act (गोपनीयता का हनन / तस्वीरें खींचना)',
        'धारा 67 IT Act (अश्लील सामग्री का इलेक्ट्रॉनिक प्रकाशन)',
        'धारा 67A IT Act (लैंगिक रूप से सुस्पष्ट सामग्री का प्रसारण)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'NI_ACT',
      actNameHindi: 'परक्राम्य लिखत अधिनियम 1881 (NI Act - चेक बाउंस)',
      actNameEnglish: 'Negotiable Instruments Act 1881',
      isSpecialAct: true,
      popularSections: [
        'धारा 138 NI Act (खाते में अपर्याप्त निधि के कारण चेक अनादरण)',
        'धारा 141 NI Act (कंपनियों व निदेशकों द्वारा चेक अपराध)',
        'धारा 142 NI Act (परिवाद संज्ञान एवं समय सीमा)',
        'धारा 143A NI Act (अंतरिम प्रतिकर का आदेश)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'PMLA',
      actNameHindi: 'धन शोधन निवारण अधिनियम 2002 (PMLA - मनी लॉन्ड्रिंग)',
      actNameEnglish: 'Prevention of Money Laundering Act 2002',
      isSpecialAct: true,
      popularSections: [
        'धारा 3/4 PMLA (अपराध की आय का शोधन एवं दंड)',
        'धारा 5 PMLA (संपत्ति की अंतरिम कुर्की)',
        'धारा 45 PMLA (जमानत की दोहरी अनिवार्य शर्तें)',
        'धारा 50 PMLA (ईडी द्वारा समन एवं बयान दर्ज करना)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'MV_ACT',
      actNameHindi: 'मोटर यान अधिनियम 1988 (Motor Vehicles Act)',
      actNameEnglish: 'Motor Vehicles Act 1988',
      isSpecialAct: true,
      popularSections: [
        'धारा 181 MV Act (बिना ड्राइविंग लाइसेंस वाहन चलाना)',
        'धारा 184 MV Act (खतरनाक तरीके से तेज गति में वाहन चलाना)',
        'धारा 185 MV Act (शराब या मादक द्रव्य के प्रभाव में वाहन चलाना)',
        'धारा 192A MV Act (बिना परमिट वाहन संचालन)',
      ],
    ),
    StatutoryActInfo(
      actCode: 'ANTI_CORRUPTION',
      actNameHindi: 'भ्रष्टाचार निवारण अधिनियम 1988 (PC Act)',
      actNameEnglish: 'Prevention of Corruption Act 1988',
      isSpecialAct: true,
      popularSections: [
        'धारा 7 PC Act (अनुचित लाभ / रिश्वत की मांग व स्वीकारोक्ति)',
        'धारा 7A PC Act (लोक सेवक को प्रभावित करने हेतु अनुचित लाभ)',
        'धारा 8 PC Act (लोक सेवक को रिश्वत देने का अपराध)',
        'धारा 13(1)(b) PC Act (आपराधिक कदाचार / आय से अधिक संपत्ति)',
        'धारा 17A PC Act (जांच पूर्व सक्षम प्राधिकारी की पूर्व स्वीकृति)',
      ],
    ),
  ];

  static StatutoryActInfo? findByCode(String code) {
    try {
      final normalized = code.trim().toUpperCase();
      return supportedActs.firstWhere(
        (a) =>
            a.actCode == normalized ||
            (normalized == 'EXCISE' && a.actCode == 'UP_EXCISE') ||
            (normalized == 'NI_ACT_138' && a.actCode == 'NI_ACT') ||
            (normalized == 'MOTOR_VEHICLES' && a.actCode == 'MV_ACT'),
      );
    } catch (_) {
      return null;
    }
  }

  static StatutoryActInfo? getActByCode(String code) => findByCode(code);

  static List<String> getAllPopularSections() {
    return supportedActs.expand((a) => a.popularSections).toList();
  }
}
