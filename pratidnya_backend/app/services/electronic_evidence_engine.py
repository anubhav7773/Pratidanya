import re
from datetime import datetime
from typing import List, Dict, Any
from app.schemas.electronic_evidence_schema import (
    ElectronicEvidenceAuditRequest,
    ElectronicEvidenceAuditResponse,
    StatutoryDefectItem
)

class ElectronicEvidenceEngine:
    """
    Electronic Evidence Admissibility & Forensic Certificate Auditor:
    - Verifies compliance with Section 63 BSA 2023 Schedule (Part A & Part B mandates).
    - Inspects alphanumeric cryptographic hash values (SHA-256, SHA-1, MD5).
    - Checks device hardware identifiers (IMEI, MAC, serial number) under Section 63(4)(a).
    - Leverages Arjun Panditrao Khotkar (2020) and Anvar P.V. (2014) to flag fatal defects.
    - Generates ready-to-file Devanagari written objections against marking exhibits.
    """

    PRECEDENTS = [
        {
            "case_title": "अर्जुन पंडितराव खोतकर बनाम कैलाश कुशनराव गोरंट्याल (2020) 7 SCC 1",
            "citation": "AIR 2020 SC 3406",
            "ratio_hindi": "उच्चतम न्यायालय की तीन-न्यायाधीशों की पीठ के अनुसार द्वितीयक इलेक्ट्रॉनिक साक्ष्य प्रस्तुत करते समय धारा 65B(4) [अब धारा 63 बी.एस.ए.] का प्रमाण पत्र प्रस्तुत करना एक अनिवार्य पूर्व-शर्त है। बिना विधिक प्रमाण पत्र के इलेक्ट्रॉनिक साक्ष्य पूर्णतः अग्राह्य (Inadmissible) है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/47621.pdf"
        },
        {
            "case_title": "अनवर पी.वी. बनाम पी.के. बशीर (2014) 10 SCC 473",
            "citation": "AIR 2015 SC 180",
            "ratio_hindi": "इलेक्ट्रॉनिक साक्ष्य की ग्राह्यता केवल विशिष्ट सांविधिक प्रावधानों के अंतर्गत ही तय हो सकती है। सामान्य मौखिक साक्ष्य या अधिकारी की सामान्य गवाही द्वारा द्वितीयक इलेक्ट्रॉनिक अभिलेख को सिद्ध नहीं किया जा सकता।",
            "source_url": "https://main.sci.gov.in/judgment/judis/41924.pdf"
        },
        {
            "case_title": "राज्य (एन.सी.टी. दिल्ली) बनाम नवजोत संधू (2005) 11 SCC 600 [अंशतः निरस्त]",
            "citation": "(2005) 11 SCC 600",
            "ratio_hindi": "नवजोत संधू में दी गई यह छूट कि बिना प्रमाण पत्र के भी द्वितीयक साक्ष्य ग्राह्य हो सकता है, अर्जुन खोतकर व अनवर पी.वी. द्वारा स्पष्ट रूप से निरस्त (Overruled) कर दी गई है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/27125.pdf"
        }
    ]

    HASH_REGEX_MAP = {
        "SHA256": re.compile(r"^[a-fA-F0-9]{64}$"),
        "SHA1": re.compile(r"^[a-fA-F0-9]{40}$"),
        "MD5": re.compile(r"^[a-fA-F0-9]{32}$"),
    }

    @classmethod
    def audit_certificate(cls, req: ElectronicEvidenceAuditRequest) -> ElectronicEvidenceAuditResponse:
        defects: List[StatutoryDefectItem] = []

        # 1. Audit Schedule Format (Section 63(4)(c) BSA 2023)
        if not req.schedule_format_matched:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4)(c) बी.एस.ए. 2023 सपठित अनुसूची (Schedule)",
                governing_doctrine="सांविधिक प्रारूप का आज्ञापक अनुपालन",
                severity="FATAL",
                defect_description_hindi="प्रस्तुत प्रमाण पत्र भारतीय साक्ष्य अधिनियम 2023 की अनुसूची के विहित प्रारूप (भाग क व भाग ख) के अनुरूप नहीं है।",
                trial_countermeasure="प्रारूप विचलन के आधार पर साक्ष्य प्रदर्श (Exhibit Mark) अंकित करने पर प्रारंभिक आपत्ति उठाएं।"
            ))

        # 2. Audit Part A Execution (Person producing electronic record)
        if not req.part_a_executed:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4)(c) अनुसूची (भाग क - पक्षकार द्वारा भरा जाने वाला)",
                governing_doctrine="अभिलेख प्रस्तुतकर्ता का वैधानिक दायित्व",
                severity="FATAL",
                defect_description_hindi="प्रमाण पत्र के भाग 'क' पर अभिलेख उत्पन्न/प्रस्तुत करने वाले अधिकृत व्यक्ति के वैध हस्ताक्षर मौजूद नहीं हैं।",
                trial_countermeasure="प्रमाण पत्र के अपूर्ण होने के कारण संबंधित दस्तावेज़ को अग्राह्य घोषित करने की प्रार्थना करें।"
            ))

        # 3. Audit Part B Execution (Forensic / Cyber Expert Certification)
        if not req.part_b_executed:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4)(c) अनुसूची (भाग ख - विशेषज्ञ द्वारा भरा जाने वाला)",
                governing_doctrine="क्रिप्टोग्राफिक व तकनीकी सत्यनिष्ठा",
                severity="FATAL",
                defect_description_hindi="प्रमाण पत्र के भाग 'ख' का निष्पादन किसी मान्यता प्राप्त साइबर अथवा फॉरेंसिक विशेषज्ञ द्वारा नहीं कराया गया है।",
                trial_countermeasure="अन्वेषण अधिकारी की व्यक्तिगत गवाही के समय भाग ख के अभाव को रिकॉर्ड पर अंकित कराएं।"
            ))

        # 4. Cryptographic Hash Validation
        is_hash_valid = False
        raw_hash = (req.declared_hash_value or "").strip()
        algo = req.hash_algorithm.upper()

        if algo == "NONE" or not raw_hash:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4)(c) अनुसूची (क्रिप्टोग्राफिक हैश मान)",
                governing_doctrine="अपरिवर्तनीय डिजिटल अखंडता (Digital Chain of Integrity)",
                severity="FATAL",
                defect_description_hindi="प्रमाण पत्र में किसी भी स्वीकृत हैश एल्गोरिदम (SHA-256 / SHA-1 / MD5) द्वारा उत्पन्न अल्फ़ान्यूमेरिक हैश मान घोषित नहीं किया गया है।",
                trial_countermeasure="डिजिटल डेटा में फेरबदल (Tampering) की संभावना स्थापित करते हुए संपूर्ण इलेक्ट्रॉनिक अभिलेख को अस्वीकार कराएं।"
            ))
        else:
            matcher = cls.HASH_REGEX_MAP.get(algo)
            if matcher and matcher.match(raw_hash):
                is_hash_valid = True
            else:
                defects.append(StatutoryDefectItem(
                    statutory_clause="धारा 63(4)(c) अनुसूची (हैश सत्यापन)",
                    governing_doctrine="हैश मान की गणितीय शुद्धता",
                    severity="FATAL",
                    defect_description_hindi=f"घोषित हैश मान '{raw_hash}' {algo} एल्गोरिदम के विधिक डाइजेस्ट प्रारूप से मेल नहीं खाता है।",
                    trial_countermeasure="हैश प्रारूप की असत्यता को चुनौती देते हुए मूल मीडिया तलब करने का आवेदन दें।"
                ))

        # 5. Device Identifiers Audit (Section 63(4)(a))
        dev = req.device_identifiers
        has_hardware_id = bool(dev.imei_number or dev.mac_address or dev.serial_number)
        if not has_hardware_id:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4)(a) बी.एस.ए. 2023",
                governing_doctrine="उपकरण पहचान एवं स्रोत सत्यापन (Source Traceability)",
                severity="MATERIAL",
                defect_description_hindi="प्रमाण पत्र में प्रयुक्त हार्डवेयर का IMEI नंबर, MAC एड्रेस अथवा सीरियल नंबर दर्ज नहीं किया गया है।",
                trial_countermeasure="उपकरण की स्रोत पहचान अज्ञात होने के आधार पर साक्ष्य की विश्वसनीयता को खंडित करें।"
            ))

        # 6. Contemporaneous Execution Audit
        if not req.contemporaneous_acquisition:
            defects.append(StatutoryDefectItem(
                statutory_clause="धारा 63(4) सपठित अर्जुन खोतकर सिद्धांत",
                governing_doctrine="समकालीन निष्पादन (Contemporaneous Certificate)",
                severity="MATERIAL",
                defect_description_hindi="प्रमाण पत्र डेटा जब्ती/प्राप्ति के समय समकालीन रूप से निष्पादित नहीं किया गया, बल्कि विचारण में देरी से गढ़ा गया प्रतीत होता है।",
                trial_countermeasure="बाद में तैयार किए गए प्रमाण पत्र की वैधता पर जिरह करें।"
            ))

        # 7. Admissibility Status Determination
        has_fatal = any(d.severity == "FATAL" for d in defects)
        if has_fatal:
            admissibility_status = "FATAL_DEFECT_INADMISSIBLE"
            actionable_objection = (
                f"प्रदर्श {req.exhibit_mark} धारा 63 बी.एस.ए. 2023 के आज्ञापक प्रावधानों व अनुसूची के प्रारूप का घोर उल्लंघन होने के कारण "
                "अभिलेख पर साक्ष्य में पढ़े जाने योग्य नहीं है। साक्ष्य अधिनियम की धारा 63 व अर्जुन खोतकर (2020) के तहत प्रदर्श अंकित करने पर तत्काल लिखित आपत्ति दाखिल की जाए।"
            )
        elif defects:
            admissibility_status = "SUBSTANTIAL_REGULARITY_CHALLENGEABLE"
            actionable_objection = (
                f"प्रदर्श {req.exhibit_mark} में प्रक्रियात्मक कमियां (हार्डवेयर पहचान का अभाव) विद्यमान हैं। मुख्य परीक्षा के दौरान आपत्ति दर्ज कराई जाए।"
            )
        else:
            admissibility_status = "PRIMA_FACIE_ADMISSIBLE"
            actionable_objection = "प्रमाण पत्र प्रथम दृष्टया सांविधिक अनुसूची के अनुरूप है; सामग्री के गुणावगुण पर जिरह केंद्रित करें।"

        # 8. Synthesize Devanagari Written Objection
        written_objection = cls._generate_written_objection(
            req=req,
            defects=defects,
            has_fatal=has_fatal
        )

        return ElectronicEvidenceAuditResponse(
            case_id=req.case_id,
            exhibit_mark=req.exhibit_mark,
            admissibility_status=admissibility_status,
            is_schedule_compliant=req.schedule_format_matched and req.part_a_executed and req.part_b_executed,
            is_hash_valid=is_hash_valid,
            statutory_defects=defects,
            actionable_courtroom_objection=actionable_objection,
            written_objection_petition_draft=written_objection,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_written_objection(
        cls,
        req: ElectronicEvidenceAuditRequest,
        defects: List[StatutoryDefectItem],
        has_fatal: bool
    ) -> str:
        date_str = datetime.now().strftime("%d-%m-%Y")
        
        draft = f"""न्यायालय श्रीमान {req.court_name}, {req.district}

मुकदमा अपराध संख्या: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}

राज्य बनाम {req.accused_name}

आपत्ति पत्र विरुद्ध साक्ष्य में प्रदर्श {req.exhibit_mark} ({req.evidence_type}) अंकित किए जाने बाबत
(अंतर्गत धारा 63 भारतीय साक्ष्य अधिनियम, 2023 सपठित न्याय-सिद्धांत अर्जुन पंडितराव खोतकर बनाम कैलाश गोरंट्याल)

महोदय,
    आवेदक / अभियुक्त {req.accused_name} की ओर से अभियोजन द्वारा प्रस्तुत विवादित इलेक्ट्रॉनिक साक्ष्य / प्रमाण पत्र के विरुद्ध निम्नलिखित विधिक आपत्तियां सादर प्रस्तुत हैं:-

1. यह कि अभियोजन पक्ष द्वारा पत्रावली पर प्रस्तुत कथित इलेक्ट्रॉनिक अभिलेख ({req.evidence_type}) को साक्ष्य में ग्राह्य कराने हेतु जो प्रमाण पत्र प्रस्तुत किया गया है, वह भारतीय साक्ष्य अधिनियम, 2023 की धारा 63 की अनिवार्य पूर्व-शर्तों को पूरा नहीं करता है।

2. यह कि धारा 63(4)(c) बी.एस.ए. के अनुसार प्रमाण पत्र का उक्त अधिनियम से संलग्न आज्ञापक 'अनुसूची' (Schedule) के प्रारूप के अनुसार होना अनिवार्य है, जिसके अंतर्गत भाग 'क' (अभिलेख प्रस्तुतकर्ता) तथा भाग 'ख' (फॉरेंसिक अथवा साइबर विशेषज्ञ) दोनों का स्वतंत्र निष्पादन होना वैधानिक अनिवार्यता है।
"""

        idx = 3
        for d in defects:
            draft += f"\n{idx}. यह कि {d.statutory_clause} का प्रत्यक्ष उल्लंघन है: {d.defect_description_hindi} ({d.governing_doctrine})"
            idx += 1

        draft += f"""
{idx}. यह कि माननीय उच्चतम न्यायालय की तीन-न्यायाधीशों की वृहद पीठ ने 'अर्जुन पंडितराव खोतकर बनाम कैलाश कुशनराव गोरंट्याल (2020) 7 SCC 1' में स्पष्ट व्यवस्था दी है कि बिना वैध व पूर्ण विधिक प्रमाण पत्र के कोई भी द्वितीयक इलेक्ट्रॉनिक साक्ष्य न्यायालयीन अभिलेख पर साक्ष्य में ग्राह्य (Admissible) नहीं हो सकता।

{idx+1}. यह कि हैश मान और विशेषज्ञ सत्यापन के अभाव में यह पूर्ण संभावना है कि कथित इलेक्ट्रॉनिक डेटा में अन्वेषण के दौरान हेरफेर, छेड़छाड़ (Tampering) अथवा कांट-छांट की गई हो, जिससे अभियुक्त के निष्पक्ष विचारण (Fair Trial) का मौलिक अधिकार दूषित होता है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि उपरोक्त वैधानिक त्रुटियों के आलोक में अभियोजन पक्ष द्वारा प्रस्तुत कथित इलेक्ट्रॉनिक अभिलेख (प्रदर्श {req.exhibit_mark}) को साक्ष्य में अग्राह्य घोषित फरमाने एवं पत्रावली पर प्रदर्श अंकित न किए जाने का आदेश पारित करने की कृपा की जाए।

दिनांक: {date_str}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
"""
        return draft.strip()
