from typing import Dict, Any, List, Tuple
from app.schemas.specialized_acts_schema import NdpsAuditRequest, NdpsComplianceEvaluation

class NdpsComplianceEngine:
    """
    Statutory Compliance Engine for NDPS Act, 1985:
    1. Quantity Classification per Official Government of India NDPS Notification (SO 1055(E)).
    2. Section 50 Personal Search Fatal Defect Evaluation (*State of Rajasthan v. Parmanand*, *Arif Khan*).
    3. Section 52A Magistrate Sample Inventory & Malkhana link chain scrutiny (*Union of India v. Mohanlal*).
    4. Section 37 Twin Conditions Bypass Logic for Intermediate and Non-Commercial recoveries.
    """

    # Substance Thresholds: [Small Quantity (g), Commercial Quantity (g)]
    SUBSTANCE_THRESHOLDS: Dict[str, Tuple[float, float]] = {
        "ganja": (1000.0, 20000.0),       # Small <= 1 kg, Commercial >= 20 kg
        "charas": (100.0, 1000.0),        # Small <= 100 g, Commercial >= 1 kg
        "heroin": (5.0, 250.0),           # Small <= 5 g, Commercial >= 250 g
        "smack": (5.0, 250.0),            # Small <= 5 g, Commercial >= 250 g
        "opium": (25.0, 2500.0),          # Small <= 25 g, Commercial >= 2.5 kg
        "tramadol": (5.0, 250.0),         # Small <= 5 g, Commercial >= 250 g
        "alprazolam": (5.0, 100.0),       # Small <= 5 g, Commercial >= 100 g
        "cocaine": (2.0, 100.0),          # Small <= 2 g, Commercial >= 100 g
    }

    PRECEDENTS = [
        {
            "case_title": "राजस्थान राज्य बनाम परमानंद एवं अन्य (2014) 5 SCC 345",
            "ratio": "धारा 50 एन.डी.पी.एस. अधिनियम के तहत अभियुक्त को यह विकल्प देना कि उसकी तलाशी राजपत्रित अधिकारी अथवा उपस्थित पुलिस दल द्वारा ली जा सकती है (तीसरा विकल्प), संपूर्ण तलाशी एवं बरामदगी को अवैध बनाता है। संयुक्त नोटिस भी शून्य है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/41285.pdf"
        },
        {
            "case_title": "विजयासिंह चंदूभा जडेजा बनाम गुजरात राज्य (2011) 1 SCC 492",
            "ratio": "संविधान पीठ: धारा 50 का अनुपालन अनिवार्य है। अभियुक्त को यह अवगत कराना कि उसके पास राजपत्रित अधिकारी या मजिस्ट्रेट के समक्ष तलाशी कराने का अधिकार है, एक सांविधिक अधिकार है जिसका कड़ाई से अनुपालन किया जाना आवश्यक है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/37021.pdf"
        },
        {
            "case_title": "आरिफ खान उर्फ आगा खान बनाम उत्तराखंड राज्य (2018) 18 SCC 380",
            "ratio": "यदि अभियुक्त मजिस्ट्रेट अथवा राजपत्रित अधिकारी के समक्ष ले जाने से इनकार भी कर दे, तब भी पुलिस का यह सांविधिक दायित्व है कि तलाशी केवल सक्षम राजपत्रित अधिकारी या मजिस्ट्रेट के समक्ष ही कराई जाए।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/45371.pdf"
        },
        {
            "case_title": "भारत संघ बनाम मोहनलाल एवं अन्य (2016) 3 SCC 379",
            "ratio": "धारा 52A के अंतर्गत न्यायिक मजिस्ट्रेट के समक्ष नमूने निकालने और सूची प्रमाणित कराने की प्रक्रिया आज्ञापक है। जब्ती के तुरंत बाद मजिस्ट्रेट प्रमाणीकरण न होना जब्ती को संदेहास्पद बनाता है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/43312.pdf"
        }
    ]

    @classmethod
    def evaluate(cls, req: NdpsAuditRequest) -> NdpsComplianceEvaluation:
        substance_key = req.substance_name.strip().lower()
        thresholds = cls.SUBSTANCE_THRESHOLDS.get(substance_key, (5.0, 250.0))
        small_limit, comm_limit = thresholds

        # 1. Quantity Classification
        if req.recovered_quantity_grams <= small_limit:
            quantity_cat = "SMALL_QUANTITY"
            sec_37_bar = False
        elif req.recovered_quantity_grams >= comm_limit:
            quantity_cat = "COMMERCIAL_QUANTITY"
            sec_37_bar = True
        else:
            quantity_cat = "INTERMEDIATE_QUANTITY"
            sec_37_bar = False

        defects: List[str] = []
        grounds: List[str] = []

        # 2. Section 50 Personal Search Scrutiny
        if req.is_personal_search:
            if not req.section_50_notice_given or req.section_50_notice_type == "NO_NOTICE":
                defects.append("धारा 50 का पूर्ण उल्लंघन: व्यक्तिगत तलाशी से पूर्व अभियुक्त को कोई विधिक नोटिस नहीं दिया गया।")
                sec_50_status = "FATAL_DEFECT"
            elif req.section_50_notice_type == "JOINT_NOTICE_DEFECTIVE":
                defects.append("अवैध संयुक्त नोटिस: एकाधिक अभियुक्तों को संयुक्त धारा 50 नोटिस देना विधि विरुद्ध है (परमानंद सिद्धांत)।")
                sec_50_status = "FATAL_DEFECT"
            elif req.third_option_defect_present:
                defects.append("तीसरा अवैध विकल्प: नोटिस में पुलिस अधिकारी द्वारा स्वयं तलाशी लेने का विकल्प दिया गया (विजयासिंह जडेजा एवं परमानंद सिद्धांत उल्लंघन)।")
                sec_50_status = "FATAL_DEFECT"
            elif not (req.was_searched_before_gazetted_officer or req.was_searched_before_magistrate):
                defects.append("तलाशी राजपत्रित अधिकारी अथवा मजिस्ट्रेट के समक्ष नहीं कराई गई।")
                sec_50_status = "FATAL_DEFECT"
            else:
                sec_50_status = "COMPLIANT"
        else:
            sec_50_status = "NOT_APPLICABLE"

        # 3. Section 42, 52A & Malkhana Defects
        if not req.information_recorded_in_writing:
            defects.append("धारा 42(1) का उल्लंघन: गुप्त सूचना को लिखित रूप में अभिलिखित नहीं किया गया।")

        if not req.information_sent_to_superior_within_72h:
            defects.append("धारा 42(2) का उल्लंघन: लिखित सूचना 72 घंटे के भीतर वरिष्ठ पुलिस अधिकारी को प्रेषित नहीं की गई।")

        if not req.independent_public_witnesses_present:
            defects.append("स्वतंत्र साक्षियों का अभाव: जब्ती के समय सार्वजनिक स्थल होने के उपरांत भी किसी स्वतंत्र साक्षी को सम्मिलित नहीं किया गया।")

        if not req.sample_drawn_before_magistrate_sec_52a:
            defects.append("धारा 52A का उल्लंघन: मादक पदार्थ के नमूने मजिस्ट्रेट के समक्ष प्रमाणित नहीं कराए गए (मोहनलाल सिद्धांत)।")

        if req.malkhana_entry_delay_days > 2:
            defects.append(f"मालखाना प्रविष्टि में {req.malkhana_entry_delay_days} दिन का अनुचित विलंब: लिंक एविडेंस खंडित।")

        # 4. Synthesize Authentic Devanagari Bail Grounds
        if not sec_37_bar:
            grounds.append(
                f"यह कि कथित बरामदगी मात्र {req.recovered_quantity_grams} ग्राम {req.substance_name} की दर्शाई गई है, "
                f"जो वाणिज्यिक मात्रा (Commercial Quantity - {comm_limit} ग्राम) से काफी कम है। अतः धारा 37 एन.डी.पी.एस. का कठोर प्रतिबंध लागू नहीं होता।"
            )
        else:
            grounds.append(
                "यह कि यद्यपि बरामदगी वाणिज्यिक मात्रा की दर्शाई गई है, परंतु तलाशी एवं जब्ती की संपूर्ण प्रक्रिया में सांविधिक प्रावधानों "
                "का ऐसा घोर उल्लंघन हुआ है जो अभियोजन की सत्यता को प्रथम दृष्टया नष्ट करता है, जिससे धारा 37 की शर्तें संतुष्ट होती हैं।"
            )

        if sec_50_status == "FATAL_DEFECT":
            grounds.append(
                "यह कि अभियुक्त की व्यक्तिगत तलाशी के समय धारा 50 एन.डी.पी.एस. अधिनियम के आज्ञापक प्रावधानों का पूर्ण उल्लंघन किया गया है। "
                "उच्चतम न्यायालय की संविधान पीठ (विजयासिंह चंदूभा जडेजा) तथा राजस्थान राज्य बनाम परमानंद के अनुसार तीसरा विकल्प देना अथवा "
                "धारा 50 की अवहेलना संपूर्ण अभियोजन और जब्ती को शून्य बनाती है।"
            )

        if not req.sample_drawn_before_magistrate_sec_52a:
            grounds.append(
                "यह कि धारा 52A के तहत जब्ती की सूची और नमूने न्यायिक मजिस्ट्रेट के समक्ष प्रमाणित नहीं कराए गए, "
                "जिससे कथित बरामद माल और न्यायालय में प्रस्तुत नमूनों की शुद्धता संदेह के घेरे में है (भारत संघ बनाम मोहनलाल)।"
            )

        if not req.independent_public_witnesses_present:
            grounds.append(
                "यह कि कथित जब्ती के समय मौके पर कोई स्वतंत्र स्थानीय साक्षी उपस्थित नहीं था और केवल पुलिस कर्मियों की एकपक्षीय "
                "गवाही के आधार पर झूठा मामला गढ़ा गया है।"
            )

        return NdpsComplianceEvaluation(
            case_id=req.case_id,
            substance_name=req.substance_name,
            quantity_category=quantity_cat,
            is_section_37_bar_applicable=sec_37_bar,
            section_50_compliance_status=sec_50_status,
            detected_procedural_defects=defects,
            tailored_bail_grounds=grounds,
            cited_supreme_court_precedents=cls.PRECEDENTS
        )
