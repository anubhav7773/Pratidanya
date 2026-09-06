from datetime import date
from typing import Dict, Any, List
from app.schemas.limitation_and_stay_schema import (
    GenerateSection5DelayRequest,
    LimitationEvaluationResponse,
    Section5DelayApplicationResponse
)

class DelayCondonationBuilder:
    """
    Constructs high-standard High Court Section 5 Limitation Act Applications
    and Supporting Pairokar Affidavits in authentic legal Devanagari.
    Adheres strictly to the principles of Collector Land Acquisition v. Katiji (1987) 2 SCC 107
    and Ramlal v. Rewa Coalfields Ltd (AIR 1962 SC 361) (Substantial Justice over Technicalities).
    """

    REASON_NARRATIVES: Dict[str, str] = {
        "POVERTY_AND_JAIL_COMMUNICATION": (
            "यह कि अपीलार्थी निर्णय सुनाए जाने के उपरांत से ही जिला कारागार में निरुद्ध है। "
            "अपीलार्थी अत्यंत निर्धन श्रमिक वर्ग से संबंधित है तथा उसके परिवार में कोई अन्य वयस्क पुरुष सदस्य नहीं था। "
            "कारागार से विधिक संवाद स्थापित करने तथा आवश्यक विधिक व्यय एवं कोर्ट फीस की व्यवस्था करने में अप्रत्याशित समय लगा।"
        ),
        "APPELLANT_ILLNESS": (
            "यह कि निर्णय सुनाए जाने के उपरांत अपीलार्थी के पैरोकार/अभिभावक गंभीर रूप से अस्वस्थ हो गए तथा निरंतर "
            "चिकित्सीय देखरेख में रहे, जिसके कारण वे उच्च न्यायालय के अधिवक्ता से समय पर संपर्क नहीं कर सके।"
        ),
        "COUNSEL_ADVICE_DELAY": (
            "यह कि अवर न्यायालय के स्थानीय अधिवक्ता द्वारा अपीलार्थी को यह विधिक परामर्श दिया गया था कि "
            "सत्र न्यायालय में ही पुनरीक्षण पोषणीय होगा। कालांतर में सही विधिक स्थिति का ज्ञान होने पर तत्काल उच्च न्यायालय की शरण ली गई।"
        ),
        "FINANCIAL_DISTRESS": (
            "यह कि अपीलार्थी की आर्थिक स्थिति अत्यंत दयनीय होने के कारण अपील का मेमो तैयार कराने, "
            "प्रमाणित प्रतिलिपि प्राप्त करने तथा निर्धारित न्यायशुल्क (Court Fee) की व्यवस्था में विलंब कारित हुआ।"
        )
    }

    @classmethod
    def build_section_5_suite(
        cls,
        req: GenerateSection5DelayRequest,
        limitation_eval: LimitationEvaluationResponse,
        pleading: Dict[str, Any]
    ) -> Section5DelayApplicationResponse:
        bench_text = "लखनऊ खंडपीठ" if pleading.get("high_court_bench") == "LUCKNOW_BENCH" else "इलाहाबाद"
        court_header = f"माननीय उच्च न्यायालय, इलाहाबाद, {bench_text}"
        cause_title = f"{pleading['case_title']} (दांडिक वाद)"

        statutory_act = "धारा 374(2) दं.प्र.सं." if pleading["pleading_type"] == "CRIMINAL_APPEAL" else "धारा 397 दं.प्र.सं."
        app_title = f"प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम (Limitation Act, 1963)"

        # 1. Synthesize Delay Grounds
        grounds: List[str] = [
            (
                f"यह कि वर्तमान {pleading['pleading_type']} विद्वान {pleading['trial_court_name']} द्वारा पारित आक्षेपित निर्णय "
                f"दिनांकित {pleading['trial_judgment_date']} के विरुद्ध इस माननीय उच्च न्यायालय के समक्ष प्रस्तुत की जा रही है।"
            ),
            (
                f"यह कि आक्षेपित निर्णय के उपरांत नियमानुसार नकल हेतु आवेदन किया गया, जिसे प्राप्त करने में "
                f"{limitation_eval.certified_copy_excluded_days} दिन का समय लगा, जो धारा 12 मियाद अधिनियम के अंतर्गत विधिक रूप से घटाए जाने योग्य है।"
            ),
            (
                f"यह कि नकल अवधि को घटाने के उपरांत भी अपील दाखिल करने में {limitation_eval.delay_days} दिन का विलंब कारित हुआ है, "
                f"जो सर्वथा सद्भाविक (Bona fide) है और किसी उपेक्षा या जानबूझकर की गई शिथिलता का परिणाम नहीं है।"
            ),
            cls.REASON_NARRATIVES.get(req.primary_delay_reason, cls.REASON_NARRATIVES["POVERTY_AND_JAIL_COMMUNICATION"])
        ]

        if req.custom_narrative and req.custom_narrative.strip():
            grounds.append(f"यह कि विशेष तथ्यात्मक परिस्थिति: {req.custom_narrative.strip()}")

        grounds.append(
            "यह कि उच्चतम न्यायालय द्वारा 'कलेक्टर, भूमि अधिग्रहण बनाम कातीजी' (1987) में प्रतिपादित विधि के अनुसार "
            "तकनीकी आधारों की तुलना में पर्याप्त और सारवान न्याय (Substantial Justice) को प्राथमिकता दी जानी चाहिए। "
            "विलंब माफ न किए जाने पर अपीलार्थी को अपूरणीय क्षति होगी।"
        )

        prayer_text = (
            f"अतः माननीय न्यायालय से सादर प्रार्थना है कि न्यायहित में {limitation_eval.delay_days} दिन के विलंब को "
            f"माफ फरमाते हुए वर्तमान {pleading['pleading_type']} को नियमित सुनवाई हेतु स्वीकार (Admit) करने की कृपा की जाए।"
        )

        # 2. Accompanying Affidavit Block
        affidavit_header = f"शपथ पत्र के समर्थन में प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम"
        deponent_block = (
            f"शपथकर्ता: {req.pairokar_name}, पुत्र/पुत्री: श्री अज्ञात, आयु लगभग: {req.pairokar_age} वर्ष, "
            f"निवासी: {req.pairokar_address}। (संबद्धता: अपीलार्थी का {req.pairokar_relation})"
        )

        affidavit_paras = [
            f"1. यह कि शपथकर्ता अपीलार्थी का {req.pairokar_relation} है और मामले के सभी तथ्यों एवं परिस्थितियों से पूर्णतः परिचित है।",
            f"2. यह कि वर्तमान अपील में प्रयुक्त तथ्यात्मक कथन शपथकर्ता के निजी ज्ञान एवं अभिलेखों के अवलोकन के आधार पर सत्य हैं।",
            f"3. यह कि संलग्न प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम के प्रस्तर 1 से {len(grounds)} तक के कथन शपथकर्ता की जानकारी में सत्य हैं।",
            f"4. यह कि अपीलार्थी कारागार में होने के कारण स्वयं शपथ पत्र निष्पादित करने में असमर्थ है, अतः शपथकर्ता द्वारा यह शपथ पत्र निष्पादित किया जा रहा है।"
        ]

        verification = (
            f"सत्यापन: मैं, उपरोक्त शपथकर्ता, आज दिनांक {date.today().strftime('%d-%m-%Y')} को सत्यापित करता हूँ कि "
            f"इस शपथ पत्र की अंतर्वस्तु मेरे निजी ज्ञान और विधिक अभिलेखों के आधार पर सत्य एवं सही है। इसमें कुछ भी असत्य नहीं है। "
            f"ईश्वर मेरी सहायता करे। स्थान: {bench_text}।"
        )

        return Section5DelayApplicationResponse(
            pleading_id=req.pleading_id,
            court_header=court_header,
            cause_title=cause_title,
            application_title_hindi=app_title,
            delay_grounds=grounds,
            prayer_text_hindi=prayer_text,
            affidavit_header=affidavit_header,
            affidavit_deponent_block=deponent_block,
            affidavit_paragraphs=affidavit_paras,
            affidavit_verification_clause=verification
        )
