import 'app_language.dart';

class TranslationsDictionary {
  static const Map<String, Map<AppLanguage, String>> values = {
    // =========================================================================
    // 1. GLOBAL, NAVIGATION & EXECUTIVE APP BAR
    // =========================================================================
    'app_title': {
      AppLanguage.hindi: 'प्रतिज्ञा लीगल टेक',
      AppLanguage.english: 'Pratidnya LegalTech',
    },
    'chamber_badge': {
      AppLanguage.hindi: 'अधिवक्ता अनुसंधान प्रकोष्ठ',
      AppLanguage.english: 'Advocate Research Chamber',
    },
    'active_dockets': {
      AppLanguage.hindi: 'सक्रिय आपराधिक डॉकेट',
      AppLanguage.english: 'Active Criminal Dockets',
    },
    'court_jurisdiction': {
      AppLanguage.hindi: 'जिला एवं सत्र न्यायालय (District & Sessions)',
      AppLanguage.english: 'District & Sessions Court Jurisdiction',
    },
    'nav_dockets': {
      AppLanguage.hindi: 'वाद डॉकेट',
      AppLanguage.english: 'Case Dockets',
    },
    'nav_remand_hub': {
      AppLanguage.hindi: 'रिमांड रक्षा',
      AppLanguage.english: 'Remand Defense',
    },
    'nav_forensics': {
      AppLanguage.hindi: 'फॉरेंसिक साक्ष्य',
      AppLanguage.english: 'Forensic Vault',
    },
    'nav_trial_studio': {
      AppLanguage.hindi: 'जिरह स्टूडियो',
      AppLanguage.english: 'Trial Studio',
    },
    'nav_regional_hud': {
      AppLanguage.hindi: 'विशेष एक्ट व HUD',
      AppLanguage.english: 'Special Acts & HUD',
    },

    // =========================================================================
    // 2. DASHBOARD METRICS & CASE OVERVIEW
    // =========================================================================
    'total_cases': {
      AppLanguage.hindi: 'कुल सक्रिय वाद',
      AppLanguage.english: 'Total Active Cases',
    },
    'today_hearings': {
      AppLanguage.hindi: 'आज की पेशी',
      AppLanguage.english: "Today's Hearings",
    },
    'judicial_custody': {
      AppLanguage.hindi: 'न्यायिक अभिरक्षा',
      AppLanguage.english: 'Judicial Custody',
    },
    'filter_by_date': {
      AppLanguage.hindi: 'तारीख वार',
      AppLanguage.english: 'By Date',
    },
    'filter_by_court': {
      AppLanguage.hindi: 'न्यायालय वार',
      AppLanguage.english: 'By Court',
    },
    'filter_custody': {
      AppLanguage.hindi: 'जेल अभिरक्षा',
      AppLanguage.english: 'In Custody',
    },
    'no_cases_title': {
      AppLanguage.hindi: 'कोई सक्रिय केस नहीं मिला',
      AppLanguage.english: 'No Active Cases Found',
    },
    'no_cases_sub': {
      AppLanguage.hindi: 'निचले बटन से नया आपराधिक केस दर्ज करें अथवा सामरिक मॉड्यूल का उपयोग करें।',
      AppLanguage.english: 'Register a new criminal case below or launch any specialized defense tool.',
    },
    'new_case_btn': {
      AppLanguage.hindi: '+ नया केस दर्ज करें',
      AppLanguage.english: '+ File New Criminal Case',
    },

    // =========================================================================
    // 3. TRIAL DEFENSE HUB (MODULE HEADERS & DESCRIPTIONS)
    // =========================================================================
    'defense_hub_title': {
      AppLanguage.hindi: 'विशेष अधीनस्थ रक्षा सूट (Trial Defense Hub)',
      AppLanguage.english: 'Specialized Trial Defense Hub',
    },
    'defense_hub_sub': {
      AppLanguage.hindi: 'सर्वोच्च न्यायालय के ऐतिहासिक न्याय-सिद्धांतों पर आधारित 10 सामरिक टूल्स',
      AppLanguage.english: '10 Strategic Tools Anchored in Supreme Court Ratios & Procedural Codes',
    },
    'mod_default_bail': {
      AppLanguage.hindi: 'डिफ़ॉल्ट जमानत (Sec 187 BNSS)',
      AppLanguage.english: 'Default Bail (Sec 187 BNSS / 167 CrPC)',
    },
    'mod_default_bail_sub': {
      AppLanguage.hindi: '60/90 दिन व अधूरा आरोप-पत्र परीक्षक',
      AppLanguage.english: '60/90 Days & Incomplete Chargesheet Auditor',
    },
    'mod_remand_audit': {
      AppLanguage.hindi: 'गिरफ्तारी व रिमांड अनुपालन',
      AppLanguage.english: 'Arrest & Remand Compliance',
    },
    'mod_remand_audit_sub': {
      AppLanguage.hindi: 'अर्नेश कुमार व धारा 35(3) नोटिस चेक',
      AppLanguage.english: 'Arnesh Kumar & Sec 35(3) Notice Checker',
    },
    'mod_undertrial_relief': {
      AppLanguage.hindi: 'विचाराधीन बंदी राहत (1/3 नियम)',
      AppLanguage.english: 'Undertrial Relief (1/3rd Rule)',
    },
    'mod_undertrial_relief_sub': {
      AppLanguage.hindi: 'धारा 479 BNSS पूर्व प्रभाव आदेश',
      AppLanguage.english: 'Sec 479 BNSS Retrospective Relief',
    },
    'mod_bsa_cert': {
      AppLanguage.hindi: 'इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र',
      AppLanguage.english: 'Electronic Evidence Certificate',
    },
    'mod_bsa_cert_sub': {
      AppLanguage.hindi: 'धारा 63 अनुसूची व हैश सत्यापन',
      AppLanguage.english: 'Sec 63 Schedule & Hash Verification',
    },
    'mod_medico_legal': {
      AppLanguage.hindi: 'चिकित्सीय अंतर्विरोध मैट्रिक्स',
      AppLanguage.english: 'Medico-Legal Conflict Matrix',
    },
    'mod_medico_legal_sub': {
      AppLanguage.hindi: 'PMR बनाम प्रत्यक्षदर्शी चोट मिलान',
      AppLanguage.english: 'PMR vs Ocular Wound Biomechanics',
    },
    'mod_malkhana': {
      AppLanguage.hindi: 'मालखाना रजिस्टर 19 व FSL',
      AppLanguage.english: 'Malkhana Reg 19 & FSL Chain',
    },
    'mod_malkhana_sub': {
      AppLanguage.hindi: '72 घंटे प्रेषण व नमूना मुहर अखंडता',
      AppLanguage.english: '72-Hour Dispatch & Seal Integrity',
    },
    'mod_witness_grid': {
      AppLanguage.hindi: 'साक्षी अंतर्विरोध ग्रिड',
      AppLanguage.english: 'Witness Impeachment Grid',
    },
    'mod_witness_grid_sub': {
      AppLanguage.hindi: '161/164 बनाम मुख्य परीक्षा सुधार',
      AppLanguage.english: '161/164 vs In-Court Omissions',
    },
    'mod_cross_exam': {
      AppLanguage.hindi: 'सूचक जिरह प्रश्न डेक',
      AppLanguage.english: 'Leading Cross-Exam Card Deck',
    },
    'mod_cross_exam_sub': {
      AppLanguage.hindi: 'स्टॉक गवाह, अन्यत्रता व 69 BNS',
      AppLanguage.english: 'Stock Witness, Alibi & Sec 69 BNS',
    },
    'mod_regional_acts': {
      AppLanguage.hindi: 'उ.प्र. गैंगस्टर व गुंडा एक्ट',
      AppLanguage.english: 'UP Gangsters & Goondas Suite',
    },
    'mod_regional_acts_sub': {
      AppLanguage.hindi: 'फरहाना नजीर व नियम 5/16 ऑडिट',
      AppLanguage.english: 'Farhana Ratio & Rules 5/16 Audit',
    },
    'mod_live_hud': {
      AppLanguage.hindi: 'लाइव कोर्टरूम ओरल HUD',
      AppLanguage.english: 'Live Courtroom Oral HUD',
    },
    'mod_live_hud_sub': {
      AppLanguage.hindi: '< 450ms त्वरित प्रत्युत्तर नजीरें',
      AppLanguage.english: '< 450ms Instant Oral Counter-Ratios',
    },

    // =========================================================================
    // 4. CASE INTAKE & STATUTE REGIME
    // =========================================================================
    'new_case_title': {
      AppLanguage.hindi: 'नया आपराधिक वाद पंजीकृत करें',
      AppLanguage.english: 'Register New Criminal Case',
    },
    'statute_selection': {
      AppLanguage.hindi: 'लागू विधिक संहिता चयन (Substantive Code)',
      AppLanguage.english: 'Applicable Substantive Code Selection',
    },
    'statute_hybrid': {
      AppLanguage.hindi: 'हाइब्रिड (समकालिक)',
      AppLanguage.english: 'Hybrid (Transitional)',
    },
    'statute_bns': {
      AppLanguage.hindi: 'बी.एन.एस. / बी.एन.एस.एस. (2023)',
      AppLanguage.english: 'BNS / BNSS (2023)',
    },
    'statute_ipc': {
      AppLanguage.hindi: 'भा.दं.वि. / दं.प्र.सं. (1860/1973)',
      AppLanguage.english: 'IPC / CrPC (1860/1973)',
    },
    'fir_number_label': {
      AppLanguage.hindi: 'मु.अ.सं. / एफ.आई.आर. संख्या *',
      AppLanguage.english: 'FIR / Crime Number *',
    },
    'fir_year_label': {
      AppLanguage.hindi: 'दर्ज वर्ष (Year) *',
      AppLanguage.english: 'Filing Year *',
    },
    'police_station_label': {
      AppLanguage.hindi: 'संबंधित थाना (P.S.) *',
      AppLanguage.english: 'Police Station (P.S.) *',
    },
    'district_label': {
      AppLanguage.hindi: 'जनपद (District) *',
      AppLanguage.english: 'District *',
    },
    'accused_name_label': {
      AppLanguage.hindi: 'मुख्य अभियुक्त का नाम *',
      AppLanguage.english: 'Primary Accused Name *',
    },
    'custody_status_label': {
      AppLanguage.hindi: 'वर्तमान अभिरक्षा स्थिति (Custody Status) *',
      AppLanguage.english: 'Current Custody Status *',
    },
    'court_designation_label': {
      AppLanguage.hindi: 'संबंधित न्यायालय पदनाम *',
      AppLanguage.english: 'Court Designation *',
    },
    'legal_sections_label': {
      AppLanguage.hindi: 'संबंधित विधिक धाराएं (Legal Sections) *',
      AppLanguage.english: 'Charged Legal Sections *',
    },
    'factual_summary_label': {
      AppLanguage.hindi: 'घटना एवं गिरफ्तारी का संक्षिप्त विवरण (Factual Summary)',
      AppLanguage.english: 'Factual Summary of Incident & Arrest',
    },
    'save_case_btn': {
      AppLanguage.hindi: 'केस डायरी में सुरक्षित करें एवं विश्लेषण शुरू करें',
      AppLanguage.english: 'Save to Case Diary & Initialize Analysis',
    },

    // =========================================================================
    // 5. REMAND & DEFAULT BAIL AUDITOR (GOALS 29 & 30)
    // =========================================================================
    'default_bail_title': {
      AppLanguage.hindi: 'सांविधिक डिफ़ॉल्ट जमानत ट्रैकर (धारा 187 BNSS)',
      AppLanguage.english: 'Statutory Default Bail Tracker (Sec 187 BNSS)',
    },
    'status_eligible': {
      AppLanguage.hindi: 'अधिकार प्रोद्भूत (Eligible for Default Bail)',
      AppLanguage.english: 'Right Crystallized (Eligible for Bail)',
    },
    'status_in_progress': {
      AppLanguage.hindi: 'अन्वेषण अवधि प्रगति पर',
      AppLanguage.english: 'Investigation Period in Progress',
    },
    'police_custody_used': {
      AppLanguage.hindi: 'उपयोग की गई पुलिस कस्टडी',
      AppLanguage.english: 'Police Custody Days Used',
    },
    'police_custody_remaining': {
      AppLanguage.hindi: 'शेष ग्राह्य पुलिस कस्टडी',
      AppLanguage.english: 'Remaining Allowable Police Custody',
    },
    'incomplete_cs_alert': {
      AppLanguage.hindi: 'अधूरा आरोप-पत्र दोष (कपिल वाधवान सिद्धांत)',
      AppLanguage.english: 'Incomplete Chargesheet Defect (Kapil Wadhawan)',
    },
    'view_default_bail_draft': {
      AppLanguage.hindi: 'डिफ़ॉल्ट जमानत प्रार्थना पत्र देखें व प्रिंट करें',
      AppLanguage.english: 'View & Print Default Bail Petition',
    },
    'remand_checklist_title': {
      AppLanguage.hindi: 'गिरफ्तारी व रिमांड विधिक अनुपालन चेकलिस्ट',
      AppLanguage.english: 'Arrest & Remand Legal Compliance Checklist',
    },
    'remand_checklist_sub': {
      AppLanguage.hindi: 'अर्नेश कुमार व सतेन्द्र कुमार अंतिल दिशानिर्देश (श्रेणी क-घ)',
      AppLanguage.english: 'Arnesh Kumar & Satender Kumar Antil Guidelines (Cat A-D)',
    },
    'sec_35_notice_question': {
      AppLanguage.hindi: 'क्या धारा 35(3) BNSS / 41A CrPC का नोटिस दिया गया था?',
      AppLanguage.english: 'Was Section 35(3) BNSS / 41A CrPC Notice Served?',
    },
    'flight_risk_question': {
      AppLanguage.hindi: 'क्या केस डायरी में गिरफ्तारी के अनिवार्य कारण दर्ज हैं?',
      AppLanguage.english: 'Were Objective Arrest Reasons Recorded in Case Diary?',
    },
    'witness_memo_question': {
      AppLanguage.hindi: 'क्या गिरफ्तारी मेमो पर स्वतंत्र स्थानीय साक्षी के हस्ताक्षर हैं?',
      AppLanguage.english: 'Is Arrest Memo Attested by Independent Local Witness?',
    },
    'medical_conducted_question': {
      AppLanguage.hindi: 'क्या अभियुक्त का विहित चिकित्सीय परीक्षण कराया गया?',
      AppLanguage.english: 'Was Mandatory Medical Examination Conducted?',
    },
    'evaluate_remand_btn': {
      AppLanguage.hindi: 'प्रक्रियात्मक वैधता जांचें व आपत्ति पत्र बनाएं',
      AppLanguage.english: 'Audit Procedural Legality & Generate Objection',
    },

    // =========================================================================
    // 6. FORENSICS & EVIDENCE VAULT (GOALS 32, 33, 34)
    // =========================================================================
    'bsa_cert_title': {
      AppLanguage.hindi: 'इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (धारा 63 BSA)',
      AppLanguage.english: 'Electronic Evidence Certificate Auditor (Sec 63 BSA)',
    },
    'exhibit_mark_label': {
      AppLanguage.hindi: 'प्रदर्श / मार्क (Exhibit Mark)',
      AppLanguage.english: 'Exhibit / Mark Identifier',
    },
    'evidence_type_label': {
      AppLanguage.hindi: 'डिजिटल साक्ष्य का प्रकार',
      AppLanguage.english: 'Digital Evidence Type',
    },
    'hash_algorithm_label': {
      AppLanguage.hindi: 'क्रिप्टोग्राफिक हैश एल्गोरिदम',
      AppLanguage.english: 'Cryptographic Hash Algorithm',
    },
    'declared_hash_label': {
      AppLanguage.hindi: 'घोषित हैश मान (Hash Digest)',
      AppLanguage.english: 'Declared Alphanumeric Hash Digest',
    },
    'hardware_id_label': {
      AppLanguage.hindi: 'उपकरण पहचान (IMEI / MAC एड्रेस)',
      AppLanguage.english: 'Device Hardware Identifiers (IMEI / MAC)',
    },
    'audit_bsa_cert_btn': {
      AppLanguage.hindi: 'प्रमाण पत्र की वैधानिकता जांचें',
      AppLanguage.english: 'Audit Certificate Statutory Admissibility',
    },
    'medico_legal_title': {
      AppLanguage.hindi: 'चिकित्सीय बनाम प्रत्यक्षदर्शी साक्ष्य मैट्रिक्स',
      AppLanguage.english: 'Medico-Legal vs Ocular Discrepancy Matrix',
    },
    'pmr_number_label': {
      AppLanguage.hindi: 'पोस्टमार्टम / MLC आख्या संख्या',
      AppLanguage.english: 'Post-Mortem / MLC Report Number',
    },
    'fatal_conflict_badge': {
      AppLanguage.hindi: 'घातक वैज्ञानिक अंतर्विरोध',
      AppLanguage.english: 'Fatal Biomechanical Contradiction',
    },
    'consistent_evidence_badge': {
      AppLanguage.hindi: 'सुसंगत चिकित्सकीय साक्ष्य',
      AppLanguage.english: 'Consistent Medical Evidence',
    },
    'malkhana_title': {
      AppLanguage.hindi: 'मालखाना रजिस्टर 19 व FSL अभिरक्षा शृंखला',
      AppLanguage.english: 'Malkhana Reg 19 & FSL Chain of Custody',
    },
    'dispatch_delay_label': {
      AppLanguage.hindi: 'प्रयोगशाला प्रेषण विलंब',
      AppLanguage.english: 'FSL Dispatch Delay',
    },
    'specimen_seal_label': {
      AppLanguage.hindi: 'नमूना मुहर (Specimen Seal) स्थिति',
      AppLanguage.english: 'Specimen Seal (Namuna Mohar) Status',
    },
    'road_cert_label': {
      AppLanguage.hindi: 'मार्ग प्रमाण पत्र (Road Certificate / RC)',
      AppLanguage.english: 'Road Certificate (RC) Verification',
    },
    'sec_254_petition_btn': {
      AppLanguage.hindi: 'धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र',
      AppLanguage.english: 'Section 254 BNSS Record Summoning Draft',
    },

    // =========================================================================
    // 7. TRIAL EXAMINATION & CROSS-EXAM (GOALS 35 & 36)
    // =========================================================================
    'impeachment_grid_title': {
      AppLanguage.hindi: 'साक्षी अंतर्विरोध ग्रिड (तहसीलदार सिंह सिद्धांत)',
      AppLanguage.english: 'Witness Impeachment Grid (Tahsildar Singh Doctrine)',
    },
    'witness_code_label': {
      AppLanguage.hindi: 'साक्षी कोड (उदा. PW-1, PW-2)',
      AppLanguage.english: 'Witness Code (e.g. PW-1, PW-2)',
    },
    'court_chief_label': {
      AppLanguage.hindi: 'न्यायालय में मुख्य परीक्षा बयान (Chief Deposition)',
      AppLanguage.english: 'In-Court Examination-in-Chief Deposition',
    },
    'police_161_label': {
      AppLanguage.hindi: 'पुलिस बयान (धारा 161 CrPC / 183 BNSS)',
      AppLanguage.english: 'Police Statement (Sec 161 CrPC / 183 BNSS)',
    },
    'magistrate_164_label': {
      AppLanguage.hindi: 'मजिस्ट्रेट बयान (धारा 164 CrPC / 186 BNSS)',
      AppLanguage.english: 'Magistrate Statement (Sec 164 CrPC / 186 BNSS)',
    },
    'audit_testimony_btn': {
      AppLanguage.hindi: 'सुधार व अंतर्विरोध निकालें',
      AppLanguage.english: 'Extract Omissions & Contradictions',
    },
    'cross_exam_deck_title': {
      AppLanguage.hindi: 'सूचक जिरह प्रश्न डेक (धारा 147 BSA)',
      AppLanguage.english: 'Leading Cross-Exam Card Deck (Sec 147 BSA)',
    },
    'defense_theory_label': {
      AppLanguage.hindi: 'बचाव पक्ष का सिद्धांत (Defense Theory)',
      AppLanguage.english: 'Selected Defense Theory',
    },
    'expected_answer_label': {
      AppLanguage.hindi: 'अपेक्षित विधिक उत्तर:',
      AppLanguage.english: 'Expected Legal Answer:',
    },
    'trap_mitigation_label': {
      AppLanguage.hindi: 'जाल शमन (Trap Mitigation):',
      AppLanguage.english: 'Trap Mitigation:',
    },
    'pivot_tactic_label': {
      AppLanguage.hindi: 'दस्तावेजी प्रहार (Pivot Tactic):',
      AppLanguage.english: 'Pivot Tactic:',
    },
    'prev_question_btn': {
      AppLanguage.hindi: 'पिछला प्रश्न',
      AppLanguage.english: 'Previous Question',
    },
    'next_question_btn': {
      AppLanguage.hindi: 'अगला प्रश्न',
      AppLanguage.english: 'Next Question',
    },

    // =========================================================================
    // 8. REGIONAL ACTS & LIVE COURTROOM HUD (GOALS 37 & 38)
    // =========================================================================
    'regional_acts_title': {
      AppLanguage.hindi: 'उ.प्र. प्रादेशिक विशेष अधिनियम परीक्षक',
      AppLanguage.english: 'U.P. Regional Special Acts Suite',
    },
    'rule_5_joint_meeting': {
      AppLanguage.hindi: 'नियम 5(3)(a) डीएम-एसएसपी संयुक्त बैठक कार्यवृत्त',
      AppLanguage.english: 'Rule 5(3)(a) DM-SSP Joint Meeting Minutes',
    },
    'rule_16_independent_mind': {
      AppLanguage.hindi: 'नियम 16 डीएम स्वतंत्र संतुष्टि (रबर-स्टाम्प रोक)',
      AppLanguage.english: 'Rule 16 DM Independent Application of Mind',
    },
    'farhana_doctrine_title': {
      AppLanguage.hindi: 'फरहाना नजीर (आधारभूत मुकदमों का पतन)',
      AppLanguage.english: 'Farhana Ratio (Base Predicate Case Collapse)',
    },
    'goondas_sec_3_notice': {
      AppLanguage.hindi: 'गुंडा एक्ट धारा 3 भौतिक आरोपों का सामान्य स्वरूप',
      AppLanguage.english: 'Goondas Act Sec 3 General Nature of Allegations',
    },
    'generate_hc_writ_btn': {
      AppLanguage.hindi: 'उच्च न्यायालय अनुच्छेद 226 रिट याचिका तैयार करें',
      AppLanguage.english: 'Generate High Court Article 226 Writ Petition',
    },
    'live_hud_title': {
      AppLanguage.hindi: 'लाइव कोर्टरूम ओरल प्रॉम्टर (Edge HUD)',
      AppLanguage.english: 'Live Courtroom Oral Prompter (Edge HUD)',
    },
    'live_hud_hint': {
      AppLanguage.hindi: 'अभियोजन पक्ष की दलील दर्ज करें; सिस्टम तुरंत 2-लाइन नजीर प्रस्तुत करेगा:',
      AppLanguage.english: 'Enter or stream prosecution argument; system outputs 2-line counter-ratio:',
    },
    'detected_ratio_label': {
      AppLanguage.hindi: 'पहचाना गया अभियोजन तर्क:',
      AppLanguage.english: 'Detected Adversarial Argument:',
    },
    'counter_argument_label': {
      AppLanguage.hindi: 'बोलने हेतु विधिक तर्क:',
      AppLanguage.english: 'Oral Counter-Argument:',
    },
    'lead_citation_label': {
      AppLanguage.hindi: 'उद्धृत नजीर:',
      AppLanguage.english: 'Governing Precedent Citation:',
    },

    // =========================================================================
    // 9. GENERAL ACTIONS & FEEDBACK
    // =========================================================================
    'copy_clipboard': {
      AppLanguage.hindi: 'क्लिपबोर्ड पर कॉपी करें',
      AppLanguage.english: 'Copy to Clipboard',
    },
    'copied_snackbar': {
      AppLanguage.hindi: 'दस्तावेज़ क्लिपबोर्ड पर कॉपी हो गया।',
      AppLanguage.english: 'Document copied to clipboard successfully.',
    },
    'error_prefix': {
      AppLanguage.hindi: 'त्रुटि: ',
      AppLanguage.english: 'Error: ',
    },
    'loading_text': {
      AppLanguage.hindi: 'समीक्षा जारी है...',
      AppLanguage.english: 'Analyzing legal record...',
    },
    'bci_banner_text': {
      AppLanguage.hindi: 'विधिक अस्वीकरण (BCI नियम 36): यह प्रणाली केवल अधिवक्ता अनुसंधान एवं मसौदा सहायक है। न्यायालय में उपयोग से पूर्व स्वतंत्र पेशेवर परीक्षण अनिवार्य है।',
      AppLanguage.english: 'Legal Disclaimer (BCI Rule 36): This system serves strictly as an advocate research assistant. Independent professional verification is mandatory before court filing.',
    },
  };
}
