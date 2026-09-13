from datetime import datetime, timezone
from typing import List, Dict, Any
from app.schemas.malkhana_schema import (
    MalkhanaAuditRequest,
    MalkhanaAuditResponse,
    CustodyVulnerabilityItem
)

class MalkhanaEngine:
    """
    Forensic Chain of Custody & Malkhana Register No. 19 Integrity Auditor:
    - Audits UP Police Regulations Chapter XVIII (Register No. 19 deposit entries).
    - Evaluates NCB Standing Order No. 1/88 (Mandatory 72-hour dispatch rule).
    - Applies State of Rajasthan v. Gurmail Singh (2005) on unbroken custodial seals.
    - Checks Namuna Mohar (Specimen Seal) preservation and Road Certificate (RC) documentation.
    - Formulates Section 254 BNSS / Section 233 CrPC record summoning applications.
    - Synthesizes targeted cross-examination questions for Malkhana Moharrir and Carrier Constable.
    """

    PRECEDENTS = [
        {
            "case_title": "राजस्थान राज्य बनाम गुरमैल सिंह (2005) 3 SCC 59",
            "citation": "AIR 2005 SC 1578",
            "ratio_hindi": "यदि मालखाना रजिस्टर संख्या 19 में प्रविष्टियां अधूरी हैं, नमूना मुहर मालखाने में जमा नहीं की गई, अथवा मालखाने से प्रयोगशाला तक सुरक्षित अभिरक्षा की कड़ी टूटी हुई है, तो साक्ष्य में छेड़छाड़ (Tampering) की प्रबल संभावना उत्पन्न होती है और अभियुक्त दोषमुक्ति का अधिकारी है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/26812.pdf"
        },
        {
            "case_title": "नूर आगा बनाम पंजाब राज्य (2008) 16 SCC 417",
            "citation": "AIR 2008 SC 2581",
            "ratio_hindi": "एन.डी.पी.एस. अधिनियम के तहत कठोर दंड के कारण अभियोजन पर सुरक्षित अभिरक्षा (Safe Custody) साबित करने का अत्यधिक कड़ा भार होता है। 72 घंटे के भीतर विधि विज्ञान प्रयोगशाला में माल न भेजा जाना अभियोजन कथानक को संदेहास्पद बनाता है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/31894.pdf"
        },
        {
            "case_title": "गुजरात राज्य बनाम इस्माइल उसमाल पटेल (2004) 13 SCC 672",
            "citation": "2004 AIR SCW 5431",
            "ratio_hindi": "जब्ती के समय की मुहर और प्रयोगशाला में प्राप्त मुहर के विवरण में किसी भी प्रकार का अंतर या पठनीयता का अभाव संपूर्ण बरामदगी को अविश्वसनीय बना देता है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/26421.pdf"
        }
    ]

    @classmethod
    def audit_malkhana_chain(cls, req: MalkhanaAuditRequest) -> MalkhanaAuditResponse:
        vulnerabilities: List[CustodyVulnerabilityItem] = []
        questions: List[str] = []

        seizure_dt = req.seizure_date if req.seizure_date.tzinfo else req.seizure_date.replace(tzinfo=timezone.utc)
        deposit_dt = req.malkhana_deposit_date if req.malkhana_deposit_date.tzinfo else req.malkhana_deposit_date.replace(tzinfo=timezone.utc)
        dispatch_dt = req.fsl_dispatch_date if req.fsl_dispatch_date.tzinfo else req.fsl_dispatch_date.replace(tzinfo=timezone.utc)
        received_dt = req.fsl_received_date if req.fsl_received_date.tzinfo else req.fsl_received_date.replace(tzinfo=timezone.utc)

        # -----------------------------------------------------------------
        # 1. AUDIT FSL DISPATCH TIMELINE (NCB Standing Order 1/88: 72 Hours)
        # -----------------------------------------------------------------
        delay_days = (dispatch_dt - seizure_dt).days

        if req.act_type == "NDPS" and delay_days > 3:
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="DELAYED_FSL_DISPATCH",
                severity="FATAL_CHAIN_BREAK",
                statutory_violation_hindi=f"एन.सी.बी. स्थायी आदेश संख्या 1/88 का घोर उल्लंघन: जब्ती के 72 घंटे (3 दिन) के भीतर प्रयोगशाला भेजना अनिवार्य था, जबकि इसे {delay_days} दिन बाद भेजा गया।",
                impact_analysis_hindi="मालखाने में अकारण दीर्घकालिक निरुद्धि से नमूने में छेड़छाड़ और फेरबदल की अकाट्य संभावना उत्पन्न होती है (नूर आगा बनाम पंजाब राज्य)।",
                precedent_authority="NCB Standing Order 1/88 read with Noor Aga (2008) 16 SCC 417"
            ))
            questions.append(
                f"मालखाना मोहर्रिर से: क्या यह सत्य है कि जब्ती दिनांक {seizure_dt.strftime('%d-%m-%Y')} को हुई थी और आपने इसे {delay_days} दिनों तक बिना किसी न्यायिक आदेश के मालखाने में रोके रखा?"
            )
            questions.append(
                "कांस्टेबल वाहक से: क्या केस डायरी अथवा जीडी में इन अतिरिक्त दिनों के विलंब का कोई वैधानिक कारण दर्ज है?"
            )
        elif delay_days > 14:
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="DELAYED_FSL_DISPATCH",
                severity="MATERIAL_TAMPERING_RISK",
                statutory_violation_hindi=f"विधि विज्ञान प्रयोगशाला में प्रेषण में अत्यधिक विलंब: माल {delay_days} दिनों के उपरांत FSL भेजा गया।",
                impact_analysis_hindi="जैविक अथवा रासायनिक साक्ष्य के अपघटन (Decomposition) तथा छेड़छाड़ की आशंका।",
                precedent_authority="State of Rajasthan v. Gurmail Singh (2005)"
            ))

        # -----------------------------------------------------------------
        # 2. AUDIT SPECIMEN SEAL (NAMUNA MOHAR) INGESTION
        # -----------------------------------------------------------------
        if not req.specimen_seal_deposited:
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="SPECIMEN_SEAL_ABSENT",
                severity="FATAL_CHAIN_BREAK",
                statutory_violation_hindi="उत्तर प्रदेश पुलिस रेगुलेशन अध्याय XVIII नियम 19 का उल्लंघन: मालखाना रजिस्टर संख्या 19 में नमूना मुहर (Specimen Seal Impression) जमा नहीं की गई।",
                impact_analysis_hindi="प्रयोगशाला के वैज्ञानिक के पास तुलना हेतु मूल सील का नमूना न होना यह सिद्ध करता है कि पैकेट पर लगी मुहर की प्रामाणिकता संदेहास्पद है (गुरमैल सिंह सिद्धांत)।",
                precedent_authority="State of Rajasthan v. Gurmail Singh (2005) 3 SCC 59"
            ))
            questions.append(
                "मालखाना मोहर्रिर से: क्या रजिस्टर संख्या 19 के कॉलम में जब्ती के समय प्रयुक्त मुहर का 'नमूना' (Namuna Mohar) चिपकाया अथवा अंकित किया गया था?"
            )
            questions.append(
                "मालखाना मोहर्रिर से: यदि नमूना मुहर रजिस्टर में संरक्षित नहीं थी, तो FSL रसीद पर दर्ज मुहर का मिलान किस आधार पर किया गया?"
            )

        # -----------------------------------------------------------------
        # 3. AUDIT ROAD CERTIFICATE (रवानगी रसीद / RC) DOCUMENTATION
        # -----------------------------------------------------------------
        if not req.road_certificate_annexed:
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="ROAD_CERTIFICATE_MISSING",
                severity="FATAL_CHAIN_BREAK",
                statutory_violation_hindi="मार्ग प्रमाण पत्र (Road Certificate / RC) का अभाव: थाने के मालखाने से FSL तक माल ले जाने का आधिकारिक रवानगी प्रमाण पत्र पत्रावली पर संलग्न नहीं है।",
                impact_analysis_hindi="थाने से प्रयोगशाला तक भौतिक संचलन (Transit) के दौरान सुरक्षित अभिरक्षा की विधिक कड़ी टूट जाती है। यह प्रमाणित नहीं होता कि माल रास्ते में सुरक्षित था।",
                precedent_authority="State of Gujarat v. Ismail Usmal Patel (2004)"
            ))
            questions.append(
                "कांस्टेबल वाहक से: क्या आपके पास थाने से FSL तक माल ले जाने का मूल रोड सर्टिफिकेट (RC) अथवा उसकी प्रति मौजूद है?"
            )
            questions.append(
                f"कांस्टेबल वाहक से: दिनांक {dispatch_dt.strftime('%d-%m-%Y')} को रवानगी और दिनांक {received_dt.strftime('%d-%m-%Y')} को प्राप्ति के मध्य माल रात में कहां रखा गया था, क्या इसकी कोई जीडी प्रविष्टि है?"
            )

        # -----------------------------------------------------------------
        # 4. AUDIT SEAL IMPRESSION INTEGRITY & TAMPERING MATCH
        # -----------------------------------------------------------------
        s_seal = req.seizure_seal_impression.lower().strip()
        f_seal = req.fsl_receipt_seal_impression.lower().strip()

        if "illegible" in f_seal or "अपठनीय" in f_seal or "broken" in f_seal or "टूटी" in f_seal:
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="SEAL_TAMPERING_MISMATCH",
                severity="FATAL_CHAIN_BREAK",
                statutory_violation_hindi=f"मुहर की विकृति: जब्ती फर्द पर सील '{req.seizure_seal_impression}' थी, जबकि FSL रसीद पर सील '{req.fsl_receipt_seal_impression}' दर्ज है।",
                impact_analysis_hindi="कंटेनर की सील अपठनीय अथवा क्षतिग्रस्त होना नमूने के बदले जाने (Substitution of Sample) का साक्षात प्रमाण है।",
                precedent_authority="State of Gujarat v. Ismail Usmal Patel (2004) 13 SCC 672"
            ))
            questions.append(
                f"कांस्टेबल वाहक से: क्या FSL में माल जमा कराते समय वैज्ञानिक ने रसीद पर सील को '{req.fsl_receipt_seal_impression}' के रूप में अंकित किया था?"
            )
        elif s_seal != f_seal and ("none" not in f_seal and len(f_seal) > 3):
            vulnerabilities.append(CustodyVulnerabilityItem(
                issue_code="SEAL_TAMPERING_MISMATCH",
                severity="FATAL_CHAIN_BREAK",
                statutory_violation_hindi=f"मुहरों में असंगति: जब्ती फर्द की मुहर ({req.seizure_seal_impression}) और FSL में प्राप्त मुहर ({req.fsl_receipt_seal_impression}) भिन्न हैं।",
                impact_analysis_hindi="मुहरों का मिलान न होना साक्ष्य की संपूर्ण सत्यनिष्ठा को विधिक रूप से ध्वस्त करता है।",
                precedent_authority="Gurmail Singh (2005) 3 SCC 59"
            ))

        has_fatal = any(v.severity == "FATAL_CHAIN_BREAK" for v in vulnerabilities)
        is_intact = len(vulnerabilities) == 0

        # 5. Formulate Courtroom Defense Strategy
        if has_fatal:
            strategy = (
                "अभिरक्षा की सुरक्षित कड़ी (Chain of Custody) पूर्णतः खंडित हो चुकी है। धारा 254 BNSS / धारा 233 CrPC के तहत "
                "मालखाना मोहर्रिर, कांस्टेबल वाहक तथा रजिस्टर संख्या 19 को मूल रूप में न्यायालय में तलब कराने का आवेदन प्रस्तुत करें, "
                "और गुरमैल सिंह (2005) व नूर आगा (2008) के आधार पर अभियुक्त की दोषमुक्ति का तर्क प्रस्तुत करें।"
            )
        elif vulnerabilities:
            strategy = (
                "अभिरक्षा शृंखला में प्रक्रियात्मक विधिक अनियमितताएं विद्यमान हैं। मुख्य परीक्षा के दौरान कांस्टेबल वाहक से "
                "पारगमन अवधि (Transit period) व जीडी रवानगी प्रविष्टियों पर कड़ी जिरह करें।"
            )
        else:
            strategy = "अभिरक्षा की विधिक कड़ी प्रथम दृष्टया नियमित प्रतीत होती है; जब्ती के स्वतंत्र गवाहों पर जिरह केंद्रित करें।"

        # 6. Generate Section 254 BNSS Record Summoning Application
        app_draft = cls._generate_sec_254_bnss_application(
            req=req,
            vulnerabilities=vulnerabilities,
            delay_days=delay_days
        )

        return MalkhanaAuditResponse(
            case_id=req.case_id,
            is_chain_of_custody_intact=is_intact,
            has_fatal_tampering_risk=has_fatal,
            fsl_dispatch_delay_days=delay_days,
            fatal_vulnerabilities=vulnerabilities,
            actionable_defense_strategy_hindi=strategy,
            application_sec_254_bnss_draft_hindi=app_draft,
            cross_examination_carrier_questions=questions,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_sec_254_bnss_application(
        cls,
        req: MalkhanaAuditRequest,
        vulnerabilities: List[CustodyVulnerabilityItem],
        delay_days: int
    ) -> str:
        date_str = datetime.now().strftime("%d-%m-%Y")

        draft = f"""न्यायालय श्रीमान {req.court_name}, {req.district}

मुकदमा अपराध संख्या: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}
अंतर्गत विधि: {req.act_type}

राज्य बनाम {req.accused_name}

प्रार्थना पत्र अंतर्गत धारा 254(2) भारतीय नागरिक सुरक्षा संहिता, 2023
(समतुल्य धारा 233(2) दंड प्रक्रिया संहिता, 1973)
बाबत तलब किए जाने मालखाना रजिस्टर संख्या 19, मूल रवानगी रसीद (RC) एवं संबंधित मालखाना मोहर्रिर व कांस्टेबल वाहक

महोदय,
    अभियुक्त {req.accused_name} की ओर से निम्नलिखित विधिक आधार सादर प्रस्तुत हैं:-

1. यह कि अभियोजन पक्ष द्वारा अभियुक्त के विरुद्ध कथित बरामदगी का झूठा वाद संस्थित किया गया है, जिसमें अभिरक्षा की सुरक्षित कड़ी (Chain of Safe Custody) प्रथम दृष्टया पूर्णतः खंडित पाई गई है।

2. यह कि कथित जब्ती दिनांक {req.seizure_date.strftime('%d-%m-%Y')} को दर्शाई गई है, जबकि माल को विधि विज्ञान प्रयोगशाला में {delay_days} दिनों के अत्यधिक विलंब के पश्चात दिनांक {req.fsl_dispatch_date.strftime('%d-%m-%Y')} को प्रेषित किया गया। यह नारकोटिक्स कंट्रोल ब्यूरो (NCB) के स्थायी आदेश संख्या 1/88 (72 घंटे के भीतर प्रेषण) का खुला उल्लंघन है।
"""

        idx = 3
        for v in vulnerabilities:
            draft += f"""
{idx}. यह कि {v.statutory_violation_hindi}
   • विधिक प्रभाव: {v.impact_analysis_hindi}
   • सुसंगत न्याय-सिद्धांत: {v.precedent_authority}
"""
            idx += 1

        draft += f"""
{idx}. यह कि उच्चतम न्यायालय ने 'राजस्थान राज्य बनाम गुरमैल सिंह (2005) 3 SCC 59' तथा 'नूर आगा बनाम पंजाब राज्य (2008) 16 SCC 417' में स्पष्ट प्रतिपादित किया है कि यदि जब्ती से लेकर प्रयोगशाला परीक्षण तक माल की सुरक्षित अभिरक्षा, नमूना मुहर व रजिस्टर प्रविष्टियों में कोई भी संशय उत्पन्न होता है, तो साक्ष्य के दूषित होने का लाभ अभियुक्त को मिलना अनिवार्य है।

{idx+1}. यह कि निष्पक्ष विचारण (Fair Trial) एवं न्यायहित में यह नितांत आवश्यक है कि थाना {req.police_station} के मूल मालखाना रजिस्टर संख्या 19, सामान्य दैनिकी (General Diary) की रवानगी प्रविष्टियां, मूल मार्ग प्रमाण पत्र (RC), तथा संबंधित मालखाना मोहर्रिर एवं वाहक {req.carrier_constable_name} को साक्ष्य हेतु तलब किया जाए।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि अभियुक्त के बचाव साक्ष्य (Defense Evidence) के क्रम में धारा 254(2) बी.एन.एस.एस. के अंतर्गत थाना {req.police_station} के मूल मालखाना रजिस्टर संख्या 19 (वर्ष {req.seizure_date.year}), संबंधित रवानगी रसीद, एवं तत्कालीन मालखाना मोहर्रिर व कांस्टेबल वाहक को आवश्यक अभिलेखों सहित तलब फरमाने की कृपा की जाए।

दिनांक: {date_str}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
"""
        return draft.strip()
