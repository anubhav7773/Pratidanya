from datetime import datetime, timezone
from typing import List, Tuple
from app.schemas.arrest_compliance_schema import (
    ArrestComplianceAuditRequest,
    ArrestComplianceAuditResponse,
    ProceduralViolationItem
)

class ArrestComplianceEngine:
    """
    Arrest & Remand Procedural Compliance Auditor:
    - Implements Satender Kumar Antil (2022) Guidelines (Categories A, B, C, D).
    - Audits Section 35(3) BNSS / Section 41A CrPC Notice compliance under Arnesh Kumar (2014).
    - Verifies D.K. Basu (1997) arrest memo attestations and Article 22(2) 24-hour limits.
    - Synthesizes ready-to-file Devanagari Objections to Remand & prayers for personal bond release.
    """

    PRECEDENTS = [
        {
            "case_title": "अर्नेश कुमार बनाम बिहार राज्य (2014) 8 SCC 273",
            "citation": "AIR 2014 SC 2756",
            "ratio_hindi": "7 वर्ष तक के कारावास वाले सभी मामलों में पुलिस द्वारा गिरफ्तारी एक अपवाद होनी चाहिए, नियम नहीं। धारा 41A (समतुल्य 35 BNSS) का नोटिस अनिवार्य है। बिना ठोस कारणों के यांत्रिक गिरफ्तारी अवैध है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/41731.pdf"
        },
        {
            "case_title": "सतेन्द्र कुमार अंतिल बनाम सी.बी.आई. (2022) 10 SCC 51",
            "citation": "AIR 2022 SC 3386",
            "ratio_hindi": "श्रेणी 'क' (7 वर्ष तक कारावास) के मामलों में यदि अन्वेषण के दौरान बिना गिरफ्तारी सहयोग किया गया है, तो न्यायालय द्वारा वारंट के स्थान पर समन जारी किया जाएगा। यांत्रिक रिमांड आदेश पारित करने वाले न्यायिक अधिकारी अनुशासनात्मक कार्रवाई के उत्तरदायी होंगे।",
            "source_url": "https://main.sci.gov.in/judgment/judis/49524.pdf"
        },
        {
            "case_title": "डी.के. बासु बनाम पश्चिम बंगाल राज्य (1997) 1 SCC 416",
            "citation": "AIR 1997 SC 610",
            "ratio_hindi": "गिरफ्तारी फर्द पर कम से कम एक स्थानीय स्वतंत्र साक्षी अथवा परिजन के हस्ताक्षर, गिरफ्तारी के कारणों की लिखित सूचना और अनिवार्य चिकित्सीय परीक्षण मौलिक अधिकार हैं।",
            "source_url": "https://main.sci.gov.in/judgment/judis/15012.pdf"
        }
    ]

    @classmethod
    def audit_arrest(cls, req: ArrestComplianceAuditRequest) -> ArrestComplianceAuditResponse:
        violations: List[ProceduralViolationItem] = []

        # 1. Determine Satender Kumar Antil Category
        antil_category = cls._classify_antil_category(req)

        # 2. Audit 24-Hour Production Limit (Article 22(2) / Section 58 BNSS)
        arr_time = req.arrest_timestamp if req.arrest_timestamp.tzinfo else req.arrest_timestamp.replace(tzinfo=timezone.utc)
        prod_time = req.remand_production_timestamp if req.remand_production_timestamp.tzinfo else req.remand_production_timestamp.replace(tzinfo=timezone.utc)
        
        hours_to_prod = (prod_time - arr_time).total_seconds() / 3600.0
        is_over_24h = hours_to_prod > 24.0

        if is_over_24h:
            violations.append(ProceduralViolationItem(
                statutory_provision="अनुच्छेद 22(2) संविधान व धारा 58 बी.एन.एस.एस. (समतुल्य 57 दं.प्र.सं.)",
                governing_doctrine="डी.के. बासु दिशा-निर्देश (1997)",
                severity="FATAL",
                finding_hindi=f"अभियुक्त को गिरफ्तारी के {hours_to_prod:.1f} घंटे बाद न्यायालय के समक्ष प्रस्तुत किया गया (24 घंटे की अधिकतम संवैधानिक सीमा का स्पष्ट उल्लंघन)।",
                actionable_remedy="अनुच्छेद 22(2) के उल्लंघन के आधार पर अभिरक्षा को अवैध घोषित करते हुए तत्काल रिहाई की मांग।"
            ))

        # 3. Audit Section 35(3) BNSS / Section 41A CrPC (Arnesh Kumar Compliance)
        if antil_category == "CATEGORY_A":
            if not req.notice_issued_sec_35_bnss:
                violations.append(ProceduralViolationItem(
                    statutory_provision="धारा 35(3) बी.एन.एस.एस. / धारा 41A दं.प्र.सं.",
                    governing_doctrine="अर्नेश कुमार बनाम बिहार राज्य (2014) व सतेन्द्र कुमार अंतिल (2022)",
                    severity="FATAL",
                    finding_hindi="7 वर्ष से कम दंडनीय अपराध में पुलिस द्वारा गिरफ्तारी से पूर्व धारा 35(3) बी.एन.एस.एस. का कोई वैधानिक नोटिस नहीं दिया गया।",
                    actionable_remedy="यांत्रिक गिरफ्तारी को अवैध घोषित करते हुए सतेन्द्र कुमार अंतिल दिशानिर्देश श्रेणी 'क' के तहत व्यक्तिगत बंधपत्र पर रिहाई।"
                ))

            if not req.flight_or_tampering_risk_recorded:
                violations.append(ProceduralViolationItem(
                    statutory_provision="धारा 35(1)(b) बी.एन.एस.एस. / धारा 41(1)(b) दं.प्र.सं.",
                    governing_doctrine="अर्नेश कुमार चेकलिस्ट अनिवार्यता",
                    severity="FATAL",
                    finding_hindi="केस डायरी में गिरफ्तारी की अनिवार्य आवश्यकता (साक्ष्य मिटाने की आशंका अथवा फरार होने का जोखिम) के संबंध में कोई ठोस कारण अभिलिखित नहीं किए गए।",
                    actionable_remedy="रिमांड आवेदन को औचित्यहीन घोषित करते हुए पुलिस रिमांड निरस्त करने की प्रार्थना।"
                ))

        # 4. Audit D.K. Basu Arrest Memo Attestations
        if req.arrest_memo_witness_count < 1:
            violations.append(ProceduralViolationItem(
                statutory_provision="धारा 36 बी.एन.एस.एस. / धारा 41B दं.प्र.सं.",
                governing_doctrine="डी.के. बासु गिरफ्तारी प्रक्रिया",
                severity="MATERIAL",
                finding_hindi="गिरफ्तारी मेमो पर किसी भी स्वतंत्र स्थानीय साक्षी अथवा अभियुक्त के परिजन के हस्ताक्षर मौजूद नहीं हैं।",
                actionable_remedy="गिरफ्तारी पंचनामा के दोषपूर्ण होने के आधार पर रिमांड का विरोध।"
            ))

        if not req.family_intimation_recorded:
            violations.append(ProceduralViolationItem(
                statutory_provision="धारा 38 बी.एन.एस.एस. / धारा 41B(b) दं.प्र.सं.",
                governing_doctrine="डी.के. बासु निर्देश संख्या 2",
                severity="MATERIAL",
                finding_hindi="अभियुक्त की गिरफ्तारी व निरुद्धि स्थल की औपचारिक सूचना उसके द्वारा नामित किसी परिजन अथवा मित्र को नहीं दी गई।",
                actionable_remedy="प्रक्रियात्मक विधिक उल्लंघन को न्यायिक अभिलेख पर अंकित कराना।"
            ))

        if not req.medical_examination_conducted:
            violations.append(ProceduralViolationItem(
                statutory_provision="धारा 53 बी.एन.एस.एस. / धारा 54 दं.प्र.सं.",
                governing_doctrine="डी.के. बासु निर्देश संख्या 5 (चिकित्सीय जांच)",
                severity="MATERIAL",
                finding_hindi="गिरफ्तारी के उपरांत पंजीकृत चिकित्सक द्वारा अभियुक्त का अनिवार्य चिकित्सीय परीक्षण नहीं कराया गया।",
                actionable_remedy="न्यायालय से तत्काल स्वतंत्र मेडिकल बोर्ड द्वारा परीक्षण कराने का निर्देश मांगना।"
            ))

        # 5. Evaluate Overall Compliance Verdict
        has_fatal = any(v.severity == "FATAL" for v in violations)
        if has_fatal:
            verdict = "NON_COMPLIANT_VOID_ARREST"
            recommendation = (
                "विद्वान मजिस्ट्रेट द्वारा पुलिस रिमांड आवेदन को निरस्त किया जाए तथा सतेन्द्र कुमार अंतिल श्रेणी 'क' दिशानिर्देशों "
                "के अंतर्गत अभियुक्त को व्यक्तिगत बंधपत्र (Personal Bond) पर तत्काल रिहा किया जाए।"
            )
        elif violations:
            verdict = "SUBSTANTIAL_IRREGULARITY"
            recommendation = (
                "गिरफ्तारी की प्रक्रिया में गंभीर विधिक अनियमितताएं विद्यमान हैं। पुलिस कस्टडी रिमांड अस्वीकार कर केवल सामान्य न्यायिक अभिरक्षा "
                "अथवा अंतरिम जमानत पर विचार किया जाए।"
            )
        else:
            verdict = "COMPLIANT_PROCEDURE"
            recommendation = "पुलिस प्रक्रिया प्रथम दृष्टया नियमित है; नियमित जमानत के गुणावगुण पर बहस की जाए।"

        # 6. Generate Ready-to-File Devanagari Objection Draft
        draft_petition = cls._generate_devanagari_objection(
            req=req,
            antil_category=antil_category,
            violations=violations,
            hours_to_prod=hours_to_prod
        )

        return ArrestComplianceAuditResponse(
            case_id=req.case_id,
            antil_category=antil_category,
            compliance_verdict=verdict,
            hours_to_production=round(hours_to_prod, 1),
            is_constitutionally_time_barred=is_over_24h,
            violations=violations,
            magistrate_directive_recommendation=recommendation,
            instant_objection_petition_draft=draft_petition,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _classify_antil_category(cls, req: ArrestComplianceAuditRequest) -> str:
        """Categorizes offense under Satender Kumar Antil (2022) Category A, B, C, D."""
        has_special_act = any(c.is_special_act for c in req.charges)
        if has_special_act:
            return "CATEGORY_C"  # Special Acts with stringent bail bars (NDPS, PMLA, POCSO)

        has_economic = any(c.is_economic_offense for c in req.charges)
        max_sentence = max((c.max_punishment_years for c in req.charges), default=3)

        if has_economic and max_sentence > 7:
            return "CATEGORY_D"  # Economic Offenses not covered by Special Acts

        if max_sentence <= 7:
            return "CATEGORY_A"  # Offenses punishable with imprisonment of 7 years or less
        
        return "CATEGORY_B"  # Offenses punishable with death, life, or > 7 years imprisonment

    @classmethod
    def _generate_devanagari_objection(
        cls,
        req: ArrestComplianceAuditRequest,
        antil_category: str,
        violations: List[ProceduralViolationItem],
        hours_to_prod: float
    ) -> str:
        charges_str = ", ".join(f"{c.act} की धारा {c.section}" for c in req.charges)
        arrest_str = req.arrest_timestamp.strftime("%d-%m-%Y को समय %H:%M बजे")

        draft = f"""न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट / विशेष न्यायिक मजिस्ट्रेट, {req.district}

मुकदमा अपराध संख्या: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}
धाराएं: {charges_str}

राज्य बनाम {req.accused_name}

आपत्ति विरुद्ध पुलिस रिमांड प्रार्थना पत्र एवं आवेदन पत्र बाबत रिहाई अभियुक्त
(अंतर्गत सतेन्द्र कुमार अंतिल दिशानिर्देश श्रेणी 'क' व अर्नेश कुमार सिद्धांत)

महोदय,
    अभियुक्त {req.accused_name} की ओर से अभियोजन द्वारा प्रस्तुत रिमांड आवेदन पत्र के विरुद्ध निम्नलिखित विधिक आपत्तियां सादर प्रस्तुत हैं:-

1. यह कि अभियुक्त को पुलिस द्वारा दिनांक {arrest_str} को गिरफ्तार किया गया है। वर्तमान वाद में आरोपित अपराधों में विधिक कारावास की अधिकतम सीमा 7 वर्ष या उससे कम है, जिसके फलस्वरूप यह मामला उच्चतम न्यायालय के ऐतिहासिक निर्णय 'सतेन्द्र कुमार अंतिल बनाम सी.बी.आई. (2022)' की श्रेणी 'क' (Category A) के अंतर्गत आता है।

2. यह कि 'अर्नेश कुमार बनाम बिहार राज्य (2014)' में उच्चतम न्यायालय की दो-न्यायाधीशों की पीठ द्वारा स्पष्ट रूप से निर्देशित किया गया है कि 7 वर्ष तक के कारावास वाले अपराधों में पुलिस द्वारा यांत्रिक रूप से गिरफ्तारी नहीं की जाएगी। अभियुक्त को गिरफ्तार करने से पूर्व धारा 35(3) बी.एन.एस.एस. (समतुल्य धारा 41A दं.प्र.सं.) का विधिक नोटिस तामील कराना अनिवार्य था, जिसका वर्तमान मामले में घोर उल्लंघन किया गया है।
"""

        idx = 3
        for v in violations:
            draft += f"\n{idx}. यह कि {v.statutory_provision} का पूर्ण उल्लंघन हुआ है: {v.finding_hindi} उच्चतम न्यायालय के निर्णय ({v.governing_doctrine}) के अनुसार यह विधिक त्रुटि संपूर्ण गिरफ्तारी को दूषित करती है।"
            idx += 1

        draft += f"""
{idx}. यह कि 'सतेन्द्र कुमार अंतिल' में उच्चतम न्यायालय ने देश के सभी अधीनस्थ मजिस्ट्रेटों को स्पष्ट चेतावनी दी है कि वे पुलिस द्वारा प्रस्तुत रिमांड आवेदनों को यांत्रिक रूप से (Mechanically) स्वीकार न करें। ऐसा न करने पर संबंधित न्यायिक अधिकारी उच्च न्यायालय की अनुशासनात्मक कार्रवाई के भागी होंगे।

{idx+1}. यह कि अभियुक्त समाज का सम्मानित नागरिक है, उसके फरार होने अथवा साक्ष्य प्रभावित करने की रत्ती भर भी संभावना नहीं है, और वह विचारण में पूर्ण सहयोग करने हेतु तत्पर है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि पुलिस द्वारा प्रस्तुत रिमांड आवेदन पत्र को निरस्त फरमाने की कृपा की जाए, एवं अभियुक्त {req.accused_name} को सतेन्द्र कुमार अंतिल श्रेणी 'क' के अंतर्गत व्यक्तिगत बंधपत्र (Personal Bond) पर तत्काल रिहा करने की कृपा की जाए।

दिनांक: {datetime.now().strftime("%d-%m-%Y")}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
"""
        return draft.strip()
