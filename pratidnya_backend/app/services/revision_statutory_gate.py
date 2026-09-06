from typing import List, Dict, Any, Tuple

class RevisionStatutoryGate:
    """
    Statutory Guard for Criminal Revisions under Section 397/401 CrPC (Sec 438/442 BNSS).
    Enforces procedural bars before LLM generation:
    1. Sec 397(2) CrPC / Sec 438(2) BNSS: Absolute bar against interlocutory orders.
    2. Sec 401(3) CrPC / Sec 442(3) BNSS: High Court cannot convert acquittal into conviction in revision.
    3. Prohibition on re-appreciating pure factual evidence (must frame into patent illegality or perversity).
    """

    INTERLOCUTORY_KEYWORDS = [
        "तलब आदेश", "समन", "तारीख पेशी", "चार्ज विरचन", "आरोप तय",
        "हर्जाना", "दस्तावेज तलब", "एनबीडब्ल्यू", "गैर जमानती वारंट", "NBW"
    ]

    @classmethod
    def evaluate_revision_admissibility(
        cls,
        impugned_order_summary: str,
        is_interlocutory_flag: bool,
        seeks_acquittal_conversion: bool
    ) -> Tuple[bool, List[str]]:
        warnings: List[str] = []
        is_admissible = True

        # Rule 1: Sec 401(3) CrPC Bar on converting Acquittal to Conviction
        if seeks_acquittal_conversion:
            is_admissible = False
            warnings.append(
                "विधिक अवरोध (धारा 401(3) दं.प्र.सं. / धारा 442(3) बी.एन.एस.एस.): "
                "उच्च न्यायालय को पुनरीक्षण (Revision) में दोषमुक्ति (Acquittal) को दोषसिद्धि (Conviction) "
                "में परिवर्तित करने का अधिकार नहीं है। इसके विरुद्ध धारा 378 दं.प्र.सं. के अधीन अपील ही पोषणीय है।"
            )

        # Rule 2: Sec 397(2) CrPC Interlocutory Order Bar
        if is_interlocutory_flag:
            is_admissible = False
            warnings.append(
                "विधिक अवरोध (धारा 397(2) दं.प्र.सं. / धारा 438(2) बी.एन.एस.एस.): "
                "अधीनस्थ न्यायालय के किसी अंतर्वर्ती आदेश (Interlocutory Order) के विरुद्ध दांडिक पुनरीक्षण पूर्णतः वर्जित है। "
                "उपयुक्त उपचार धारा 482 दं.प्र.सं. (समतुल्य BNSS धारा 528) के अंतर्गत याचिका है।"
            )

        # Keyword Heuristic Scan on Trial Summary
        summary_lower = impugned_order_summary.lower()
        for kw in cls.INTERLOCUTORY_KEYWORDS:
            if kw.lower() in summary_lower:
                warnings.append(
                    f"सतर्कता संकेत: आदेश में '{kw}' का उल्लेख है। यदि यह आदेश वाद को अंतिम रूप से समाप्त नहीं करता, "
                    f"तो धारा 397(2) के तहत आक्षेप उठाया जा सकता है (एशियन रिसर्फेसिंग / अमर नाथ सिद्धांत)।"
                )
                break

        return is_admissible, warnings

    @classmethod
    def sanitize_revision_grounds(cls, raw_grounds: List[str]) -> List[str]:
        """
        Transforms pure factual dissatisfaction ('गवाह झूठ बोल रहा है') into
        proper revisional grounds ('अवर न्यायालय द्वारा साक्ष्य की घोर विकृति एवं अवैधानिकता').
        """
        sanitized = []
        for g in raw_grounds:
            # Check if ground merely complains about evidence weight
            if any(k in g for k in ["गवाह अविश्वसनीय", "झूठा बयान", "गवाही गलत", "साक्ष्य पर्याप्त नहीं"]):
                g_recast = (
                    "यह कि अवर न्यायालय ने पत्रावली पर उपलब्ध साक्ष्य का ऐसा मूल्यांकन किया है जो कोई भी "
                    "प्रबुद्ध न्यायिक मस्तिष्क नहीं कर सकता (Perversity), जिससे अभिलेख पर प्रत्यक्ष विधिक अवैधता "
                    "(Patent Illegality apparent on the face of the record) कारित हुई है।"
                )
                sanitized.append(g_recast)
            else:
                sanitized.append(g)
        return sanitized
