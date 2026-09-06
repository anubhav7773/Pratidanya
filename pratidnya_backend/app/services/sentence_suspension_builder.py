from datetime import date
from typing import Dict, Any, List
from app.schemas.limitation_and_stay_schema import (
    GenerateSuspensionBailRequest,
    SuspensionBailApplicationResponse
)

class SentenceSuspensionBuilder:
    """
    Constructs High Court Sentence Suspension & Interim Bail Applications
    under Section 389(1) CrPC (or Section 430(1) BNSS) / Section 397(1) CrPC.
    Integrates leading constitutional and appellate authorities:
    1. Bhagwan Rama Shinde Gosai v. State of Gujarat (1999) 4 SCC 421 (Fixed term suspension norm).
    2. Saudan Singh v. State of U.P. (2022) SCC OnLine SC 697 (Undue delay in hearing appeals).
    3. Babu Singh v. State of U.P. (1978) 1 SCC 579 (Bail jurisprudence pending appeal).
    """

    PRECEDENT_RATIOS = [
        {
            "case_title": "भगवान राम शिंदे गोसाई बनाम गुजरात राज्य (1999) 4 SCC 421",
            "verbatim_quote": "जब किसी दोषी व्यक्ति को सीमित अवधि के कारावास की सजा सुनाई गई हो और उसकी अपील विचारार्थ स्वीकार कर ली गई हो, तो सामान्य नियम यह होना चाहिए कि अपील के लंबित रहने के दौरान सजा का क्रियान्वयन स्थगित कर उसे जमानत पर रिहा किया जाए, जब तक कि कोई असाधारण परिस्थिति न हो।",
            "statutory_relevance": "Section 389(1) CrPC / Section 430(1) BNSS"
        },
        {
            "case_title": "सौदान सिंह बनाम उत्तर प्रदेश राज्य (2022) SC",
            "verbatim_quote": "उच्च न्यायालयों में अपीलों के भारी लंबित रहने के दृष्टिगत यदि अपीलार्थी ने अपनी सजा का एक बड़ा हिस्सा हिरासत में काट लिया है और निकट भविष्य में अपील की अंतिम सुनवाई की कोई संभावना नहीं है, तो सजा स्थगित की जानी चाहिए।",
            "statutory_relevance": "Undue Appellate Delay / Article 21"
        }
    ]

    @classmethod
    def build_suspension_suite(
        cls,
        req: GenerateSuspensionBailRequest,
        pleading: Dict[str, Any]
    ) -> SuspensionBailApplicationResponse:
        bench_text = "लखनऊ खंडपीठ" if pleading.get("high_court_bench") == "LUCKNOW_BENCH" else "इलाहाबाद"
        is_crpc = req.statute_system == "IPC_CRPC"

        if pleading["pleading_type"] == "CRIMINAL_APPEAL":
            provision = "धारा 389(1) दंड प्रक्रिया संहिता" if is_crpc else "धारा 430(1) भारतीय नागरिक सुरक्षा संहिता"
            app_title = f"प्रार्थना पत्र अंतर्गत {provision} (दंडादेश के स्थगन एवं अंतरिम जमानत हेतु)"
        else:
            provision = "धारा 397(1) दंड प्रक्रिया संहिता" if is_crpc else "धारा 438(1) भारतीय नागरिक सुरक्षा संहिता"
            app_title = f"प्रार्थना पत्र अंतर्गत {provision} (आक्षेपित आदेश के क्रियान्वयन के स्थगन एवं जमानत हेतु)"

        # Synthesize Grounded Arguments for Appellate Bail
        grounds: List[str] = [
            (
                f"यह कि अपीलार्थी को अवर न्यायालय द्वारा {pleading['trial_case_number']} में पारित निर्णय दिनांकित "
                f"{pleading['trial_judgment_date']} द्वारा {', '.join(pleading['convicted_sections'])} के अधीन "
                f"दोषसिद्ध करते हुए '{pleading['quantum_of_sentence']}' के दंडादेश से दंडित किया गया है।"
            ),
            (
                "यह कि अपीलार्थी के विरुद्ध अवर न्यायालय का दोषसिद्धि निर्णय अभिलेख पर उपलब्ध साक्ष्यों के विकृत मूल्यांकन "
                "पर आधारित है और अपीलार्थी के पास अपील में सफलता का अत्यधिक सुदृढ़ और प्रथम दृष्टया विचारणीय मामला (Arguable Case) है।"
            ),
            (
                "यह कि वर्तमान दंडादेश एक सीमित अवधि (Fixed Term) का कारावास है। उच्चतम न्यायालय द्वारा 'भगवान राम शिंदे गोसाई' "
                "(1999) में स्थापित विधि के अनुसार सीमित अवधि की सजा में अपील लंबित रहने के दौरान सजा का स्थगन सामान्य नियम है।"
            )
        ]

        # Trial Bail Liberty Ground
        if req.trial_bail_status == "ON_BAIL_NEVER_MISUSED":
            grounds.append(
                "यह कि अपीलार्थी संपूर्ण विचारण के दौरान जमानत पर था और उसने अपनी विधिक स्वतंत्रता का कभी कोई दुरुपयोग नहीं किया। "
                "निर्णय सुनाए जाने के समय भी वह न्यायालय के समक्ष शांतिपूर्वक उपस्थित रहा।"
            )
        else:
            grounds.append(
                f"यह कि अपीलार्थी ने अब तक कुल {pleading.get('days_in_custody', 0)} दिन कारागार में व्यतीत कर लिए हैं, "
                "जो अधिरोपित दंडादेश का एक महत्वपूर्ण भाग है।"
            )

        # Fine Undertaking Ground
        if req.fine_deposit_status == "ALREADY_DEPOSITED":
            grounds.append("यह कि अवर न्यायालय द्वारा अधिरोपित संपूर्ण अर्थदंड की धनराशि अपीलार्थी द्वारा विधिवत जमा की जा चुकी है।")
        elif req.fine_deposit_status == "READY_TO_DEPOSIT":
            grounds.append("यह कि अपीलार्थी अवर न्यायालय द्वारा अधिरोपित अर्थदंड की धनराशि इस माननीय न्यायालय के निर्देशानुसार जमा करने को तत्पर है।")
        else:
            grounds.append("यह कि अपीलार्थी की घोर निर्धनता के दृष्टिगत अर्थदंड की वसूली को भी अपील के निस्तारण तक स्थगित रखा जाना न्यायसंगत है।")

        grounds.append(
            f"यह कि इस माननीय उच्च न्यायालय में अपीलों के भारी कार्यभार के कारण निकट भविष्य में वर्तमान अपील की "
            f"अंतिम सुनवाई संभव नहीं है। यदि दंडादेश स्थगित नहीं किया गया तो अपीलार्थी बिना अंतिम निर्णय के ही अपनी सजा भुगत लेगा, "
            f"जिससे प्रस्तुत अपील पूर्णतः निष्प्रभावी (Infructuous) हो जाएगी।"
        )

        interim_prayer = (
            f"अतः माननीय न्यायालय से सादर प्रार्थना है कि न्यायहित में अपील के अंतिम निस्तारण तक विद्वान {pleading['trial_court_name']} "
            f"द्वारा पारित दंडादेश दिनांकित {pleading['trial_judgment_date']} के क्रियान्वयन को स्थगित (Suspend) रखने तथा अपीलार्थी को "
            f"सक्षम न्यायालय की संतुष्टि के बंधपत्र दाखिल करने पर अंतरिम जमानत पर रिहा फरमाने की कृपा की जाए।"
        )

        affidavit_text = (
            f"शपथ पत्र के प्रस्तर:\n"
            f"1. मैं, {req.pairokar_name}, आयु {req.pairokar_age} वर्ष, निवासी {req.pairokar_address}, शपथपूर्वक बयान करता हूँ कि "
            f"मैं अपीलार्थी का {req.pairokar_relation} हूँ और मामले के तथ्यों से भलीभांति अवगत हूँ।\n"
            f"2. यह कि सजा स्थगन प्रार्थना पत्र के सभी प्रस्तर मेरे ज्ञान में सत्य हैं। यदि अपीलार्थी को जमानत पर रिहा किया जाता है, "
            f"तो वह न्यायालय द्वारा नियत प्रत्येक तिथि पर उपस्थित रहेगा और न्याय से पलायन नहीं करेगा।"
        )

        return SuspensionBailApplicationResponse(
            pleading_id=req.pleading_id,
            statutory_provision=provision,
            application_title_hindi=app_title,
            grounds_for_suspension=grounds,
            interim_bail_prayer=interim_prayer,
            affidavit_text_hindi=affidavit_text,
            cited_precedents=cls.PRECEDENT_RATIOS
        )
