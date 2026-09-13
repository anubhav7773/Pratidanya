from datetime import datetime
from typing import List, Dict, Any
from app.schemas.regional_acts_schema import (
    RegionalActsAuditRequest,
    RegionalActsAuditResponse,
    GroundOfChallengeItem
)

class RegionalActsEngine:
    """
    High-Stakes Regional Defense Engine:
    - UP Gangsters and Anti-Social Activities (Prevention) Act 1986 & Rules 2021 (Rules 5, 10, 16).
    - Applies Farhana v. State of U.P. (SC 2024) predicate acquittal collapse doctrine.
    - Applies Radha v. State of U.P. on mechanical DM rubber-stamped gang chart approval.
    - Audits UP Control of Goondas Act 1970 Section 3 show-cause notices against Ramji Pandey (Full Bench 1981).
    - Generates Allahabad High Court Article 226 Criminal Misc. Writ Petitions for quashing approvals & FIRs.
    """

    PRECEDENTS = [
        {
            "case_title": "फरहाना बनाम उत्तर प्रदेश राज्य (2024) 4 SCC 685",
            "citation": "2024 INSC 121 / Cr. Appeal No. 719/2024",
            "ratio_hindi": "उच्चतम न्यायालय ने स्पष्ट व्यवस्था दी है कि यदि गैंग चार्ट में उल्लिखित आधारभूत पूर्व मुकदमों (Predicate Base Cases) में अभियुक्त दोषमुक्त (Acquit), उन्मोचित (Discharge) अथवा एफ.आई.आर. निरस्त (Quashed) हो चुकी है, तो उन आधारों पर उत्तर प्रदेश गिरोहबंद अधिनियम के अंतर्गत दर्ज मुकदमा स्वतंत्र रूप से जीवित नहीं रह सकता।",
            "source_url": "https://main.sci.gov.in/judgment/judis/50412.pdf"
        },
        {
            "case_title": "राधा बनाम उत्तर प्रदेश राज्य (इलाहाबाद उच्च न्यायालय)",
            "citation": "2022 (9) ADJ 412 (DB)",
            "ratio_hindi": "गैंगस्टर्स रूल्स 2021 के नियम 16 के तहत जिला मजिस्ट्रेट द्वारा गैंग चार्ट का अनुमोदन एक अर्द्ध-न्यायिक कार्य है। केवल 'स्वीकृत' या मोहर लगाकर हस्ताक्षर कर देना स्वतंत्र विधिक विवेक के प्रयोग (Independent Application of Mind) का अभाव दर्शाता है और संपूर्ण अनुमोदन को अवैध बनाता है।",
            "source_url": "https://elegalix.allahabadhighcourt.in/elegalix/WebShowJudgment.do?judgmentID=53346"
        },
        {
            "case_title": "रामजी पांडेय बनाम उत्तर प्रदेश राज्य (इलाहाबाद उच्च न्यायालय पूर्ण पीठ 1981)",
            "citation": "1981 CriLJ 1083 (FB) / AIR 1981 All 226",
            "ratio_hindi": "गुंडा नियंत्रण अधिनियम की धारा 3 के अंतर्गत जारी कारण बताओ नोटिस में केवल मुकदमों के अपराध संख्या दर्ज कर देना वैधानिक आवश्यकता की पूर्ति नहीं करता। जब तक जनता में भय, आतंक अथवा गवाहों को धमकाने के भौतिक आरोपों का सामान्य स्वरूप (General Nature of Material Allegations) स्पष्ट न लिखा हो, नोटिस अधिकारिताविहीन (Void ab initio) होता है।",
            "source_url": "https://indiankanoon.org/doc/480258/"
        }
    ]

    RUBBER_STAMP_MARKERS = [
        "approved", "स्वीकृत", "recommen", "संस्तुति", "सहमति", "हस्ताक्षर", "मोहर", "stamped"
    ]

    @classmethod
    def audit_regional_act(cls, req: RegionalActsAuditRequest) -> RegionalActsAuditResponse:
        grounds: List[GroundOfChallengeItem] = []
        is_farhana_triggered = False
        is_ramji_triggered = False
        rec_forum = "माननीय उच्च न्यायालय, इलाहाबाद (प्रधान पीठ अथवा लखनऊ खंडपीठ)"
        petition_type = "WRIT_CRIMINAL_ARTICLE_226_QUASHING"

        # =========================================================================
        # 1. UP GANGSTERS ACT 1986 & RULES 2021 AUDIT
        # =========================================================================
        if req.statute_applied == "UP_GANGSTERS_ACT_1986":
            # Check 1: Rule 5(3)(a) Mandatory Joint Meeting between DM & SSP
            if not req.joint_meeting_rule_5_documented:
                grounds.append(GroundOfChallengeItem(
                    doctrine="नियम 5(3)(a) उत्तर प्रदेश गिरोहबंद एवं समाज विरोधी क्रियाकलाप (निवारण) नियमावली, 2021",
                    rule_or_statute="Rule 5(3)(a) UP Gangsters Rules 2021",
                    severity="JURISDICTIONAL_FATALITY",
                    argument_hindi="गैंग चार्ट के अनुमोदन से पूर्व जिला मजिस्ट्रेट तथा वरिष्ठ पुलिस अधीक्षक / पुलिस अधीक्षक के मध्य औपचारिक संयुक्त बैठक तथा उसके कार्यवृत्त (Minutes/Resolution) अभिलिखित नहीं किए गए। नियमावली के आज्ञापक प्रावधान का उल्लंघन अनुमोदन को अधिकारिता-विहीन बनाता है।",
                    statutory_remedy="अनुच्छेद 226 के तहत रिट याचिका में गैंग चार्ट की वैधता को चुनौती देना।"
                ))

            # Check 2: Rule 16 Independent Mind / Rubber-Stamp Approval
            dm_text = (req.dm_endorsement_raw_text or "").lower()
            is_rubber_stamped = not req.dm_independent_mind_applied or any(m in dm_text for m in cls.RUBBER_STAMP_MARKERS)

            if is_rubber_stamped:
                grounds.append(GroundOfChallengeItem(
                    doctrine="नियम 16 नियमावली 2021 सपठित राधा बनाम उत्तर प्रदेश राज्य",
                    rule_or_statute="Rule 16 UP Gangsters Rules 2021",
                    severity="JURISDICTIONAL_FATALITY",
                    argument_hindi=f"जिला मजिस्ट्रेट द्वारा गैंग चार्ट पर अंकित आदेश ('{req.dm_endorsement_raw_text}') से यह स्पष्ट है कि अनुमोदन मात्र यांत्रिक (Mechanical Rubber-Stamped) रूप से पुलिस संस्तुति पर किया गया है। पत्रावली के स्वतंत्र परिशीलन व संतुष्टि का पूर्ण अभाव है।",
                    statutory_remedy="न्यायालयीन मिसालों के आलोक में गैंग चार्ट अनुमोदन आदेश को निरस्त कराना।"
                ))

            # Check 3: Farhana v. State of U.P. (2024) Predicate Cases Collapse
            if req.base_cases:
                cleared_cases = [
                    c for c in req.base_cases
                    if c.status in ["ACQUITTED_ON_MERITS", "DISCHARGED", "QUASHED_BY_HIGH_COURT"]
                ]
                # If all base cases are cleared OR the solitary base case is cleared
                if len(cleared_cases) == len(req.base_cases):
                    is_farhana_triggered = True
                    grounds.append(GroundOfChallengeItem(
                        doctrine="फरहाना बनाम उत्तर प्रदेश राज्य (सर्वोच्च न्यायालय 2024) सिद्धांत",
                        rule_or_statute="Section 2/3 UP Gangsters Act 1986",
                        severity="SUBSTANTIVE_FATALITY",
                        argument_hindi=f"गैंग चार्ट में उल्लिखित सभी आधारभूत मुकदमे ({', '.join(c.crime_number for c in cleared_cases)}) में अभियुक्त या तो बाइज्जत बरी हो चुका है अथवा मुकदमा निरस्त हो चुका है। उच्चतम न्यायालय की विधि व्यवस्था के अनुसार आधारभूत अपराध के अभाव में गैंगस्टर एक्ट की कार्यवाही कानूनी रूप से शून्य (Void) है।",
                        statutory_remedy="माननीय उच्च न्यायालय से प्रथम सूचना रिपोर्ट को तत्काल प्रभाव से क्वैश (Quash) कराना।"
                    ))
                elif cleared_cases:
                    grounds.append(GroundOfChallengeItem(
                        doctrine="फरहाना बनाम उत्तर प्रदेश राज्य आंशिक पतन",
                        rule_or_statute="Section 2/3 UP Gangsters Act 1986",
                        severity="MATERIAL_IRREGULARITY",
                        argument_hindi=f"गैंग चार्ट में दर्शाए गए मुकदमों में से {len(cleared_cases)} मुकदमे पहले ही दोषमुक्ति/निरस्तीकरण में समाप्त हो चुके हैं, जिन्हें भ्रामक रूप से पत्रावली पर जीवित दर्शाया गया।",
                        statutory_remedy="धारा 19(4) के तहत जमानत प्रार्थना पत्र में दोषमुक्ति को मुख्य आधार बनाना।"
                    ))

            petition_type = "WRIT_CRIMINAL_ARTICLE_226_QUASHING_GANG_CHART"

        # =========================================================================
        # 2. UP CONTROL OF GOONDAS ACT 1970 AUDIT
        # =========================================================================
        elif req.statute_applied == "UP_GOONDAS_ACT_1970":
            # Check 1: Ramji Pandey Full Bench Doctrine
            if req.notice_only_lists_firs and not req.notice_has_material_allegations:
                is_ramji_triggered = True
                grounds.append(GroundOfChallengeItem(
                    doctrine="रामजी पांडेय बनाम उत्तर प्रदेश राज्य (इलाहाबाद उच्च न्यायालय पूर्ण पीठ 1981)",
                    rule_or_statute="Section 3(1) UP Control of Goondas Act 1970",
                    severity="JURISDICTIONAL_FATALITY",
                    argument_hindi="जिला मजिस्ट्रेट द्वारा जारी कारण बताओ नोटिस में केवल आपराधिक मुकदमों की संख्या का उल्लेख किया गया है, किंतु जनता में भय, आतंक अथवा गवाहों के साक्ष्य देने से डरने के भौतिक आरोपों का सामान्य स्वरूप (General Nature of Material Allegations) पूर्णतः अनुपस्थित है। नोटिस मूलतः अधिकारिताविहीन (Void ab initio) है।",
                    statutory_remedy="अनुच्छेद 226 के अंतर्गत कारण बताओ नोटिस एवं जिला बदर (Externment) आदेश को निरस्त कराना।"
                ))

            petition_type = "WRIT_CIVIL_MISC_ARTICLE_226_GOONDAS_NOTICE"

        # Determine Overall Procedural Viability
        has_fatal = any(g.severity in ["JURISDICTIONAL_FATALITY", "SUBSTANTIVE_FATALITY"] for g in grounds)
        if has_fatal:
            viability = "FATALLY_DEFECTIVE_CHALLENGEABLE"
        elif grounds:
            viability = "IRREGULARITY_OBSERVED"
        else:
            viability = "PRIMA_FACIE_REGULAR"

        # Generate Court Pleading Draft
        draft_petition = cls._generate_court_pleading(
            req=req,
            grounds=grounds,
            petition_type=petition_type,
            is_farhana=is_farhana_triggered,
            is_ramji=is_ramji_triggered
        )

        return RegionalActsAuditResponse(
            case_id=req.case_id,
            statute_applied=req.statute_applied,
            procedural_viability=viability,
            is_farhana_collapse_triggered=is_farhana_triggered,
            is_ramji_pandey_defect_triggered=is_ramji_triggered,
            grounds_of_challenge=grounds,
            recommended_forum=rec_forum,
            draft_petition_type=petition_type,
            draft_petition_hindi=draft_petition,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_court_pleading(
        cls,
        req: RegionalActsAuditRequest,
        grounds: List[GroundOfChallengeItem],
        petition_type: str,
        is_farhana: bool,
        is_ramji: bool
    ) -> str:
        date_str = datetime.now().strftime("%d-%m-%Y")
        bench_str = "लखनऊ खंडपीठ" if req.district.lower() in ["lucknow", "ayodhya", "barabanki", "sitapur", "rae bareli", "unnao", "hardoi", "lakhimpur"] else "इलाहाबाद (प्रधान पीठ)"

        if "GANG_CHART" in petition_type:
            return f"""माननीय उच्च न्यायालय, इलाहाबाद, {bench_str}

दांडिक प्रकीर्ण रिट याचिका (अंतर्गत अनुच्छेद 226, भारत का संविधान)
जिला: {req.district}

{req.accused_name}
...याची (Petitioner)
बनाम
1. उत्तर प्रदेश राज्य द्वारा प्रमुख सचिव (गृह), सिविल सचिवालय, लखनऊ।
2. जिला मजिस्ट्रेट, {req.district}।
3. वरिष्ठ पुलिस अधीक्षक / पुलिस अधीक्षक, {req.district}।
4. थानाध्यक्ष / प्रभारी निरीक्षक, थाना {req.police_station}, जिला {req.district}।
...विपक्षीगण (Respondents)

विषय: प्रथम सूचना रिपोर्ट संख्या {req.case_id}, अंतर्गत धारा 2/3 उत्तर प्रदेश गिरोहबंद एवं समाज विरोधी क्रियाकलाप (निवारण) अधिनियम, 1986, थाना {req.police_station}, जिला {req.district} एवं तत्संबंधी गैंग चार्ट को उत्प्रेषण रिट (Certiorari) द्वारा निरस्त (Quash) किए जाने बाबत याचिका।

महोदय,
    याची की ओर से आक्षेपित प्रथम सूचना रिपोर्ट व अनुमोदित गैंग चार्ट के विरुद्ध निम्नलिखित विधिक आधार प्रस्तुत हैं:-

1. यह कि विपक्षी संख्या 2 (जिला मजिस्ट्रेट) द्वारा याची के विरुद्ध तैयार किए गए गैंग चार्ट का अनुमोदन उत्तर प्रदेश गिरोहबंद एवं समाज विरोधी क्रियाकलाप (निवारण) नियमावली, 2021 के आज्ञापक विधिक उपबंधों का खुला उल्लंघन करके पारित किया गया है।

2. यह कि नियमावली 2021 के नियम 5(3)(a) के अनुसार गैंग चार्ट के अनुमोदन से पूर्व जिला मजिस्ट्रेट तथा पुलिस अधीक्षक के मध्य औपचारिक संयुक्त बैठक संपन्न होना तथा उसके कार्यवृत्त अभिलिखित होना विधि की अनिवार्य पूर्व-शर्त है, जिसका प्रस्तुत मामले में पूर्णतः अभाव है।
""" + "".join([f"\n3.{idx}. {g.rule_or_statute}: {g.argument_hindi} ({g.doctrine})" for idx, g in enumerate(grounds)]) + f"""

4. यह कि माननीय उच्चतम न्यायालय ने 'फरहाना बनाम उत्तर प्रदेश राज्य (2024) 4 SCC 685' में स्पष्ट रूप से अभिनिर्धारित किया है कि जब आधारभूत मुकदमों का अस्तित्व समाप्त हो चुका हो, तो उन पर आधारित गैंगस्टर एक्ट की संपूर्ण कार्यवाही टिक नहीं सकती।

5. यह कि विपक्षी संख्या 2 ने नियम 16 के आज्ञापक प्रावधानों की उपेक्षा करते हुए बिना किसी स्वतंत्र न्यायिक विवेक के प्रयोग के मात्र रबर-स्टाम्प द्वारा अनुमोदन प्रदान किया है, जो 'राधा बनाम उत्तर प्रदेश राज्य' के अनुसार प्रथम दृष्टया अवैध है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि माननीय न्यायालय आक्षेपित प्रथम सूचना रिपोर्ट संख्या {req.case_id}, अंतर्गत धारा 2/3 उत्तर प्रदेश गिरोहबंद अधिनियम, थाना {req.police_station}, जिला {req.district} एवं संबंधित गैंग चार्ट को उत्प्रेषण रिट जारी कर निरस्त फरमाने की कृपा करे।

दिनांक: {date_str}
स्थान: {bench_str}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
""".strip()

        else:
            return f"""माननीय उच्च न्यायालय, इलाहाबाद, {bench_str}

सिविल प्रकीर्ण रिट याचिका (अंतर्गत अनुच्छेद 226, भारत का संविधान)
जिला: {req.district}

{req.accused_name}
...याची
बनाम
1. उत्तर प्रदेश राज्य द्वारा जिलाधिकारी, {req.district}।
2. पुलिस अधीक्षक, {req.district}।
...विपक्षीगण

विषय: उत्तर प्रदेश गुंडा नियंत्रण अधिनियम, 1970 की धारा 3 के अंतर्गत पारित आक्षेपित कारण बताओ नोटिस दिनांकित को निरस्त किए जाने बाबत।

महोदय,
    याची की ओर से निम्नलिखित विधिक आधार प्रस्तुत हैं:-

1. यह कि विद्वान जिला मजिस्ट्रेट द्वारा याची को जारी आक्षेपित कारण बताओ नोटिस इलाहाबाद उच्च न्यायालय की पूर्ण पीठ के ऐतिहासिक निर्णय 'रामजी पांडेय बनाम उत्तर प्रदेश राज्य (AIR 1981 All 226 FB)' के सिद्धांतों के सर्वथा विपरीत है।

2. यह कि आक्षेपित नोटिस में मात्र आपराधिक मुकदमों के अपराध संख्या दर्ज कर दिए गए हैं, किंतु जनता में भय, आतंक अथवा गवाहों के साक्ष्य देने से डरने के भौतिक आरोपों का सामान्य विवरण (General nature of material allegations) पूर्ण रूप से गायब है।

प्रार्थना:
    अतः आक्षेपित कारण बताओ नोटिस को अधिकारिताविहीन (Void ab initio) घोषित करते हुए निरस्त करने की कृपा की जाए।

दिनांक: {date_str}
स्थान: {bench_str}

द्वारा अधिवक्ता
""".strip()
