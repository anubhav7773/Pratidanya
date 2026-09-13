from datetime import date
from typing import List, Tuple, Optional
from app.schemas.undertrial_schema import (
    UndertrialReliefAuditRequest,
    UndertrialReliefAuditResponse,
    OffenseSentenceInput
)

class UndertrialReliefEngine:
    """
    Statutory Undertrial Relief Engine under Section 479 BNSS, 2023 / Section 436A CrPC:
    - Implements the 1/3rd detention threshold for first-time offenders.
    - Implements the 1/2 detention threshold for repeat offenders.
    - Enforces retrospective application under Supreme Court Order dt. 23.08.2024
      in Re: Inhuman Conditions in 1382 Prisons (Kohli & Mehta, JJ.).
    - Enforces statutory disqualifications under Section 479(1) (capital/life exclusion)
      and Section 479(2) (bar on multiple pending cases).
    - Generates dual statutory applications:
        1. Court Petition for immediate bail / personal bond release.
        2. Section 479(3) Requisition Notice to the Jail Superintendent.
    """

    PRECEDENTS = [
        {
            "case_title": "इन री: 1382 जेलों में अमानवीय स्थितियां (सुप्रीम कोर्ट आदेश दि. 23.08.2024)",
            "citation": "2024 INSC 628 / WP (Civil) No. 406/2013",
            "ratio_hindi": "उच्चतम न्यायालय की खंडपीठ ने स्पष्ट आदेश दिया है कि बी.एन.एस.एस. की धारा 479 के उदार उपबंध (1/3 कारावास पर रिहाई) देश के सभी लंबित मामलों एवं विचाराधीन बंदियों पर भूतलक्षी (Retrospective) प्रभाव से लागू होंगे, चाहे एफ.आई.आर. 1 जुलाई 2024 से पूर्व की हो।",
            "source_url": "https://main.sci.gov.in/judgment/judis/50891.pdf"
        },
        {
            "case_title": "भीम सिंह बनाम भारत संघ (2015) 13 SCC 605",
            "citation": "AIR 2015 SC 3072",
            "ratio_hindi": "सांविधिक सीमा (धारा 436A / 479) पूर्ण करने वाले विचाराधीन बंदियों को बिना अनुचित विलंब व्यक्तिगत बंधपत्र पर रिहा किया जाना चाहिए। विधिक प्रक्रिया के अभाव में सतत निरुद्धि अनुच्छेद 21 का उल्लंघन है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/42812.pdf"
        }
    ]

    @classmethod
    def audit_undertrial_relief(cls, req: UndertrialReliefAuditRequest) -> UndertrialReliefAuditResponse:
        calc_date = req.calculation_date or date.today()
        
        # 1. Compute Actual Detention Duration
        days_served = (calc_date - req.custody_start_date).days
        actual_months_served = round(days_served / 30.4375, 2)

        # 2. Extract Max Prescribed Term
        max_term = max(c.max_term_months for c in req.charges)

        # 3. Check Statutory Disqualifications
        is_disqualified = False
        disqualification_reason: Optional[str] = None

        # Disqualification A: Capital Punishment or Life Imprisonment (Section 479(1))
        has_life_or_death = any(c.is_capital_or_life or c.max_term_months >= 1188 for c in req.charges)  # >= 99 years
        if has_life_or_death:
            is_disqualified = True
            disqualification_reason = "धारा 479(1) अपवाद: यह राहत मृत्युदंड अथवा आजीवन कारावास से दंडनीय अपराधों पर लागू नहीं होती।"

        # Disqualification B: Multiple Cases Pending (Section 479(2))
        if not is_disqualified and req.multiple_cases_pending:
            is_disqualified = True
            disqualification_reason = "धारा 479(2) सांविधिक रोक: बंदी के विरुद्ध एक से अधिक मामलों में अन्वेषण, जांच अथवा विचारण लंबित होने पर यह धारा लागू नहीं होगी।"

        # 4. Determine Applicable Threshold Fraction (1/3 vs 1/2)
        if req.is_first_time_offender:
            fraction_str = "1/3"
            fraction_val = 1.0 / 3.0
            governing_statute = "धारा 479(1) प्रथम परंतुक, भारतीय नागरिक सुरक्षा संहिता, 2023 (प्रथम अपराधी 1/3 नियम)"
        else:
            fraction_str = "1/2"
            fraction_val = 0.5
            governing_statute = "धारा 479(1) मुख्य भाग, भारतीय नागरिक सुरक्षा संहिता, 2023 (समतुल्य 436A दं.प्र.सं. 1/2 नियम)"

        threshold_months = round(max_term * fraction_val, 2)
        overstay_months = max(0.0, round(actual_months_served - threshold_months, 2))
        is_eligible = (actual_months_served >= threshold_months) and not is_disqualified

        retrospective_text = (
            "उच्चतम न्यायालय आदेश दि. 23.08.2024 (Re: Inhuman Conditions in 1382 Prisons): "
            "धारा 479 बी.एन.एस.एस. पूर्व प्रभाव से सभी विचाराधीन बंदियों पर लागू है।"
        )

        superintendent_mandate = (
            "धारा 479(3) बी.एन.एस.एस. आज्ञापक दायित्व: 1/3 अवधि पूर्ण होते ही जेल अधीक्षक का यह वैधानिक कर्तव्य है "
            "कि वह बंदी की रिहाई हेतु संबंधित न्यायालय में स्वतः लिखित आवेदन प्रस्तुत करे।"
        )

        # 5. Synthesize Devanagari Court Petition
        court_petition = cls._generate_court_petition(
            req=req,
            governing_statute=governing_statute,
            fraction_str=fraction_str,
            max_term=max_term,
            threshold_months=threshold_months,
            actual_months_served=actual_months_served,
            overstay_months=overstay_months
        )

        # 6. Synthesize Section 479(3) Requisition Notice to Jail Superintendent
        jail_notice = cls._generate_jail_superintendent_notice(
            req=req,
            fraction_str=fraction_str,
            max_term=max_term,
            threshold_months=threshold_months,
            actual_months_served=actual_months_served
        )

        return UndertrialReliefAuditResponse(
            case_id=req.case_id,
            is_relief_applicable=is_eligible,
            governing_statute=governing_statute,
            statutory_threshold_fraction=fraction_str,
            max_prescribed_term_months=max_term,
            threshold_months=threshold_months,
            actual_detention_served_months=actual_months_served,
            overstay_months=overstay_months,
            is_disqualified=is_disqualified,
            disqualification_reason=disqualification_reason,
            retrospective_mandate_text_hindi=retrospective_text,
            jail_superintendent_mandate_sec_479_3=superintendent_mandate,
            court_application_draft_hindi=court_petition,
            jail_superintendent_notice_draft_hindi=jail_notice,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_court_petition(
        cls,
        req: UndertrialReliefAuditRequest,
        governing_statute: str,
        fraction_str: str,
        max_term: int,
        threshold_months: float,
        actual_months_served: float,
        overstay_months: float
    ) -> str:
        charges_str = ", ".join(f"{c.act} की धारा {c.section}" for c in req.charges)
        remand_str = req.custody_start_date.strftime("%d-%m-%Y")
        max_years_str = f"{max_term // 12} वर्ष" if max_term % 12 == 0 else f"{max_term} माह"

        return f"""न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट / सत्र न्यायाधीश, {req.district}

मुकदमा अपराध संख्या: {req.fir_number}
थाना: {req.police_station}, जिला: {req.district}
धाराएं: {charges_str}

राज्य बनाम {req.accused_name}
(वर्तमान में निरुद्ध: {req.jail_name})

प्रार्थना पत्र अंतर्गत {governing_statute}
(अधिकतम कारावास की {fraction_str} सांविधिक अवधि पूर्ण करने के आधार पर जमानत / रिहाई बाबत)

महोदय,
    आवेदक / विचाराधीन बंदी {req.accused_name} की ओर से निम्नलिखित विधिक व तथ्यात्मक आधार प्रस्तुत हैं:-

1. यह कि आवेदक / बंदी को पुलिस द्वारा गिरफ्तार कर दिनांक {remand_str} को न्यायिक अभिरक्षा में भेजा गया था, और तब से वह निरंतर {req.jail_name} में निरुद्ध है।

2. यह कि वर्तमान वाद में आरोपित अपराधों के अंतर्गत अधिकतम विहित कारावास की अवधि {max_years_str} ({max_term} माह) है।

3. यह कि आवेदक एक प्रथम अपराधी (First-time Offender) है और पूर्व में कभी भी किसी भी न्यायालय द्वारा किसी अपराध में सिद्धदोष नहीं ठहराया गया है। इसके अतिरिक्त, आवेदक के विरुद्ध कोई अन्य आपराधिक वाद अथवा विचारण लंबित नहीं है, जिसके फलस्वरूप धारा 479(2) की कोई रोक लागू नहीं होती।

4. यह कि भारतीय नागरिक सुरक्षा संहिता, 2023 की धारा 479(1) के प्रथम परंतुक के अनुसार यदि कोई प्रथम अपराधी अधिकतम निर्धारित दंड की एक-तिहाई (1/3) अवधि अभिरक्षा में पूर्ण कर लेता है, तो उसे न्यायालय द्वारा बंधपत्र (Bond) पर रिहा किया जाना अनिवार्य है।

5. यह कि माननीय उच्चतम न्यायालय ने रिट याचिका (सिविल) संख्या 406/2013 (Re: Inhuman Conditions in 1382 Prisons) में दिनांक 23 अगस्त 2024 को पारित आदेश द्वारा यह स्पष्ट घोषित किया है कि बी.एन.एस.एस. की धारा 479 के उपबंध पूर्व प्रभाव (Retrospectively) से सभी लंबित मामलों पर लागू होंगे, चाहे एफ.आई.आर. 1 जुलाई 2024 से पूर्व दर्ज की गई हो।

6. यह कि आवेदक द्वारा अभिरक्षा में पूर्ण की जाने वाली 1/3 सांविधिक अवधि {threshold_months} माह थी, जबकि आवेदक आज की तिथि तक कुल {actual_months_served} माह की वास्तविक अभिरक्षा भुगत चुका है। इस प्रकार आवेदक सांविधिक समय-सीमा से {overstay_months} माह का अतिरिक्त समय जेल में बिता चुका है।

7. यह कि आवेदक न्यायालय के आदेशानुसार समुचित व्यक्तिगत बंधपत्र व प्रतिभू प्रस्तुत करने हेतु तैयार है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि आवेदक {req.accused_name} को धारा 479(1) प्रथम परंतुक बी.एन.एस.एस. के आज्ञापक प्रावधानों तथा उच्चतम न्यायालय के आदेश दिनांक 23.08.2024 के आलोक में व्यक्तिगत बंधपत्र पर तत्काल रिहा फरमाने की कृपा की जाए।

दिनांक: {date.today().strftime("%d-%m-%Y")}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
""".strip()

    @classmethod
    def _generate_jail_superintendent_notice(
        cls,
        req: UndertrialReliefAuditRequest,
        fraction_str: str,
        max_term: int,
        threshold_months: float,
        actual_months_served: float
    ) -> str:
        charges_str = ", ".join(f"{c.act} की धारा {c.section}" for c in req.charges)
        remand_str = req.custody_start_date.strftime("%d-%m-%Y")

        return f"""सेवा में,
वरिष्ठ जेल अधीक्षक / जेलर महोदय,
{req.jail_name}, {req.district}

विषय: धारा 479(3) भारतीय नागरिक सुरक्षा संहिता, 2023 के अंतर्गत सांविधिक कर्तव्य अनुपालन एवं बंदी {req.accused_name} (मु.अ.सं. {req.fir_number}) के संबंध में न्यायालय में आवेदन प्रेषित करने बाबत विधिक सूचना।

महोदय,
    उपरोक्त विषयांतर्गत आपको सूचित किया जाता है कि विचाराधीन बंदी {req.accused_name}, पुत्र/पत्नी, निवासी {req.district}, आपके कारागार में दिनांक {remand_str} से मुकदमा अपराध संख्या {req.fir_number}, थाना {req.police_station}, अंतर्गत धाराएं {charges_str} में न्यायिक अभिरक्षा में निरुद्ध है।

1. बंदी एक प्रथम अपराधी है और आरोपित धाराओं में अधिकतम विहित कारावास की अवधि {max_term} माह है, जिसकी एक-तिहाई (1/3) सांविधिक अवधि {threshold_months} माह बनती है।

2. बंदी आज दिनांक तक कुल {actual_months_served} माह की वास्तविक अभिरक्षा आपके कारागार में पूर्ण कर चुका है।

3. बी.एन.एस.एस. 2023 की धारा 479 की उपधारा (3) के अंतर्गत जेल अधीक्षक पर यह सकारात्मक वैधानिक कर्तव्य अधिरोपित किया गया है कि:-
   "Where the accused has undergone detention for the period specified in sub-section (1), the Superintendent of the jail where the accused person is detained shall forthwith make an application in writing to the Court to proceed under sub-section (1)."

4. उच्चतम न्यायालय द्वारा दिनांक 23.08.2024 (Re: Inhuman Conditions in 1382 Prisons) में दिए गए स्पष्ट आदेशानुसार यह प्रावधान सभी विचाराधीन बंदियों पर तत्काल प्रभाव से लागू है।

अतः आपसे सादर अनुरोध है कि अपने सांविधिक दायित्व का निर्वहन करते हुए बंदी {req.accused_name} की रिहाई बाबत लिखित आवेदन तत्काल सक्षम न्यायालय ({req.court_name}, {req.district}) के समक्ष प्रेषित करने का कष्ट करें।

दिनांक: {date.today().strftime("%d-%m-%Y")}

भवदीय,
(अधिवक्ता / पैरोकार बंदी)
""".strip()
