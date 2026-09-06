from datetime import date, timedelta
from typing import Dict, Any, List
from app.schemas.scst_and_ni_schema import ScstAuditRequest, ScstComplianceEvaluation

class ScstComplianceEngine:
    """
    Statutory Scrutiny Engine for SC/ST (Prevention of Atrocities) Act, 1989:
    1. Section 18 & 18A Bar Bypass Test:
       - *Prathvi Raj Chauhan v. Union of India* (2020) 4 SCC 727: Anticipatory bail is not barred
         if the complaint does not disclose a prima facie case under the Act.
       - *Hitesh Verma v. State of Uttarakhand* (2020) 10 SCC 710: Offense under Sec 3(1)(r)/(s)
         must be committed in "any place within public view". Insult inside a private house/room
         or arising out of a pure civil/land dispute does not attract the Act.
    2. Section 14A High Court Appeal Limitation:
       - Sec 14A(3): 90-day appeal limit; extendable up to 180 days with condonation; second proviso
         bars appeal after 180 days completely.
    3. Section 15A(3) & 15A(5) Mandatory Victim Notice before hearing bail.
    """

    PRECEDENTS = [
        {
            "case_title": "हितेश वर्मा बनाम उत्तराखंड राज्य (2020) 10 SCC 710",
            "ratio": "धारा 3(1)(r) के तहत अपराध घटित होने हेतु अपमान 'सार्वजनिक दृष्टिगोचर स्थान' (Place within public view) पर होना अनिवार्य है। यदि घटना किसी के निजी मकान, चारदीवारी या बिना जनता की मौजूदगी वाले स्थान पर हुई है, तो धारा 3(1)(r) लागू नहीं होती। शुद्ध दीवानी या भूमि विवाद को जातिगत अपराध का रूप नहीं दिया जा सकता।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/47035.pdf"
        },
        {
            "case_title": "पृथ्वी राज चौहान बनाम भारत संघ (2020) 4 SCC 727",
            "ratio": "यद्यपि धारा 18 व 18A अग्रिम जमानत पर रोक लगाती हैं, परंतु यदि प्राथमिकी के तथ्यों से प्रथम दृष्टया अधिनियम के तहत कोई संज्ञेय अपराध नहीं बनता, तो अग्रिम जमानत याचिका पूर्णतः पोषणीय है। न्यायालय प्रथम दृष्टया मूल्यांकन करने का क्षेत्राधिकार रखता है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/46115.pdf"
        },
        {
            "case_title": "स्वर्ण सिंह बनाम राज्य (2008) 8 SCC 435",
            "ratio": "सार्वजनिक दृष्टिगोचर स्थान का तात्पर्य यह नहीं है कि स्थान सार्वजनिक हो, बल्कि यह है कि घटना को जनता के स्वतंत्र व्यक्तियों (Public witnesses) द्वारा प्रत्यक्ष देखा या सुना गया हो। निजी चैंबर अथवा बंद कमरे में घटित संवाद इसके दायरे में नहीं आता।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/32252.pdf"
        }
    ]

    @classmethod
    def evaluate(cls, req: ScstAuditRequest) -> ScstComplianceEvaluation:
        defects: List[str] = []
        grounds: List[str] = []

        # 1. Evaluate Public View Test (Hitesh Verma / Swaran Singh)
        is_private_place = req.incident_place_type in ["PRIVATE_HOUSE_ROOM", "ENCLOSED_CHAMBER"]
        public_view_satisfied = not is_private_place and req.independent_public_witnesses_present

        if is_private_place:
            defects.append("सार्वजनिक दृष्टिगोचर स्थान का अभाव: कथित घटना निजी चारदीवारी/कमरे के भीतर हुई है, जो धारा 3(1)(r)/(s) की अनिवार्य शर्त पूरी नहीं करती।")
        if not req.independent_public_witnesses_present:
            defects.append("स्वतंत्र जनसाक्षियों की अनुपस्थिति: कथित घटना के समय जनता का कोई स्वतंत्र सदस्य उपस्थित नहीं था।")

        # 2. Section 18 / 18A Anticipatory Bail Bar Bypassability
        can_bypass_sec_18 = False
        if is_private_place or req.prior_land_or_civil_dispute_existing:
            can_bypass_sec_18 = True
            bypass_ratio = (
                "अग्रिम जमानत पोषणीय है (पृथ्वी राज चौहान सिद्धांत): प्रथम दृष्टया धारा 3 के आवश्यक तत्व "
                "(सार्वजनिक दृष्टिगोचर स्थान व जातिगत विद्वेष) अनुपस्थित हैं और विवाद मूलतः दीवानी/भूमि विवाद से प्रेरित है।"
            )
        else:
            bypass_ratio = "धारा 18/18A का प्रतिबंध प्रथम दृष्टया लागू होता है; नियमित जमानत अथवा धारा 14A अपील ही उपयुक्त है।"

        # 3. Section 14A High Court Appeal Limitation Scrutiny
        delay_days = 0
        limitation_status = "WITHIN_90_DAYS"

        if req.special_court_order_date:
            days_elapsed = (req.proposed_appeal_filing_date - req.special_court_order_date).days
            if days_elapsed <= 90:
                limitation_status = "WITHIN_90_DAYS"
            elif 90 < days_elapsed <= 180:
                limitation_status = "EXTENDED_90_TO_180_DAYS_REQUIRES_CONDONATION"
                delay_days = days_elapsed - 90
                defects.append(f"धारा 14A(3) अपील में 90 दिन से अधिक ({delay_days} दिन) का विलंब: शपथ पत्र सहित विलंब माफी आवेदन अनिवार्य है।")
            else:
                limitation_status = "BARRED_BEYOND_180_DAYS"
                delay_days = days_elapsed - 180
                defects.append("अपील पूर्णतः कालबाधित: धारा 14A(3) के दूसरे परंतुक के अनुसार 180 दिन व्यतीत होने के उपरांत उच्च न्यायालय को भी अपील ग्रहण करने का अधिकार नहीं है।")

        # 4. Mandatory Section 15A Victim Notice Warning
        victim_warning = (
            "धारा 15A(3) एवं 15A(5) का आज्ञापक अनुपालन: जमानत सुनवाई से पूर्व पीड़ित/वादी को राज्य द्वारा "
            "लिखित विधिक सूचना तामील कराना अनिवार्य है। बिना सूचना तामील हुए जमानत सुनवाई न्यायालयीन प्रक्रिया को दूषित करती है।"
        )

        # 5. Formulate Authentic Devanagari Bail / Appeal Grounds
        if can_bypass_sec_18:
            grounds.append(
                "यह कि प्राथमिकी के अवलोकन से प्रथम दृष्टया अनुसूचित जाति एवं अनुसूचित जनजाति (अत्याचार निवारण) अधिनियम के "
                "आवश्यक तत्व गठित नहीं होते, क्योंकि कथित घटना किसी सार्वजनिक दृष्टिगोचर स्थान पर घटित नहीं हुई है (हितेश वर्मा बनाम उत्तराखंड राज्य)।"
            )

        if req.prior_land_or_civil_dispute_existing:
            grounds.append(
                "यह कि दोनों पक्षों के मध्य पूर्व से ही दीवानी व भूमि विवाद विचाराधीन है। अभियुक्त पर अनुचित दबाव बनाने एवं संविदात्मक दायित्वों "
                "से बचने के उद्देश्य से इस विशेष अधिनियम की कठोर धाराओं का सहारा लेकर मिथ्या प्राथमिकी दर्ज कराई गई है।"
            )

        grounds.append(
            "यह कि कथित घटना के समय मौके पर कोई स्वतंत्र स्थानीय साक्षी उपस्थित नहीं था और मात्र सामान्य व अस्पष्ट आरोपों के आधार पर "
            "अभियुक्त को व्यक्तिगत स्वतंत्रता से वंचित रखना संविधान के अनुच्छेद 21 का उल्लंघन है।"
        )

        return ScstComplianceEvaluation(
            case_id=req.case_id,
            is_public_view_test_satisfied=public_view_satisfied,
            is_anticipatory_bail_maintainable=can_bypass_sec_18,
            section_18_bar_bypass_ratio=bypass_ratio,
            section_14a_appeal_limitation_status=limitation_status,
            delay_days=delay_days,
            mandatory_victim_notice_warning=victim_warning,
            tailored_grounds=grounds,
            cited_precedents=cls.PRECEDENTS
        )
