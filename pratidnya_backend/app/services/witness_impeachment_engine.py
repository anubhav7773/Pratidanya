import re
from datetime import datetime
from typing import List, Dict, Any, Tuple
from app.schemas.witness_impeachment_schema import (
    WitnessImpeachmentAuditRequest,
    WitnessImpeachmentAuditResponse,
    ContradictionGridItem
)

class WitnessImpeachmentEngine:
    """
    Trial Strategy & Witness Impeachment Engine:
    - Confronts witness under Section 148 & 149 BSA 2023 (Section 145 & 146 IEA 1872).
    - Implements Tahsildar Singh v. State of U.P. (1959) and V.K. Mishra (2015).
    - Compares Police Statement (Sec 161 CrPC / 183 BNSS), Magistrate Statement (Sec 164 CrPC / 186 BNSS),
      and in-court Examination-in-Chief.
    - Isolates material improvements and omissions amounting to contradictions.
    - Generates statutory confrontation dialogue and Investigating Officer cross-examination Exhibit D alerts.
    """

    PRECEDENTS = [
        {
            "case_title": "तहसीलदार सिंह बनाम उत्तर प्रदेश राज्य (1959) Supp (2) SCR 875",
            "citation": "AIR 1959 SC 1012",
            "ratio_hindi": "साक्ष्य अधिनियम की धारा 145 (समतुल्य धारा 148 बी.एस.ए.) के तहत गवाह का उसके पूर्व बयान से खंडन कराने हेतु पूर्व बयान का विशिष्ट अंश गवाह को पढ़कर सुनाना अनिवार्य है। यदि गवाह इंकार करता है, तो उस अंश पर प्रदर्श (Ex. D) अंकित कर बाद में अन्वेषण अधिकारी से साबित कराया जाना चाहिए।",
            "source_url": "https://main.sci.gov.in/judgment/judis/154.pdf"
        },
        {
            "case_title": "वी.के. मिश्रा बनाम उत्तराखंड राज्य (2015) 9 SCC 588",
            "citation": "AIR 2015 SC 3043",
            "ratio_hindi": "दंड प्रक्रिया संहिता की धारा 162 के स्पष्टीकरण (समतुल्य धारा 183 बी.एन.एस.एस.) के अनुसार महत्वपूर्ण तथ्यों का लोप (Material Omission) जो न्यायालय में पहली बार गढ़ा गया हो, विधिक रूप से अंतर्विरोध (Contradiction) माना जाएगा।",
            "source_url": "https://main.sci.gov.in/judgment/judis/42798.pdf"
        },
        {
            "case_title": "रामकुमार पांडे बनाम मध्य प्रदेश राज्य (1975) 3 SCC 815",
            "citation": "AIR 1975 SC 1026",
            "ratio_hindi": "प्राथमिक सूचना रिपोर्ट अथवा धारा 161 के बयान में प्रमुख अभियुक्तों के नामों या हथियारों का उल्लेख न होना और न्यायालय में पहली बार विशिष्ट भूमिका निर्दिष्ट करना एक ऐसा गंभीर सुधार है जो गवाही को अविश्वसनीय बना देता है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/5234.pdf"
        }
    ]

    @classmethod
    def audit_witness_testimony(cls, req: WitnessImpeachmentAuditRequest) -> WitnessImpeachmentAuditResponse:
        grid_items: List[ContradictionGridItem] = []
        marked_exhibits: List[Dict[str, str]] = []
        io_reminders: List[str] = []

        norm_161 = req.sec_161_crpc_statement.strip()
        norm_164 = (req.sec_164_crpc_statement or "").strip()
        norm_chief = req.court_deposition_chief.strip()

        # Split court deposition into discrete factual sentences/clauses
        sentences = [s.strip() for s in re.split(r"[।\.\n]+", norm_chief) if len(s.strip()) > 15]

        exhibit_counter = 1

        for sentence in sentences:
            # Check presence or variation in 161 statement
            is_present_in_161, segment_161 = cls._find_semantic_match(sentence, norm_161)
            is_present_in_164, segment_164 = cls._find_semantic_match(sentence, norm_164) if norm_164 else (False, None)

            # Scenario 1: Material Improvement (Absent in 161, introduced for first time in court)
            if not is_present_in_161:
                # Key weapon or direct role indicators
                is_critical_fact = any(kw in sentence for kw in ["गोली", "पिस्तौल", "चाकू", "तलवार", "प्रहार", "ललकारा", "मार डाला", "पहचान", "रुपये छीने"])
                severity = "FATAL" if is_critical_fact else "MATERIAL"
                classification = "MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION"
                
                ex_id = f"Ex. D-{exhibit_counter}"
                exhibit_counter += 1

                tahsildar_ratio = (
                    "तहसीलदार सिंह बनाम उत्तर प्रदेश राज्य (1959): धारा 161 में यह तथ्य पूर्णतः लुप्त (Omission) था "
                    "और न्यायालय में पहली बार गढ़ा गया महत्वपूर्ण सुधार (Material Improvement) है जो विधिक रूप से खंडन योग्य है।"
                )

                confrontation_script = (
                    f"गवाह से जिरह प्रश्न: 'मैं आपको सूचित करता हूं कि दिनांक को पुलिस द्वारा लिए गए आपके धारा 161 के बयान में "
                    f"यह कथन कि \"{sentence}\" बिल्कुल दर्ज नहीं है। क्या आप बता सकते हैं कि यह महत्वपूर्ण बात आपने पुलिस को क्यों नहीं बताई थी?' "
                    f"[यदि गवाह कहे कि बताई थी, तो बयान पर {ex_id} अंकित कराएं]। "
                )

                marked_exhibits.append({
                    "exhibit_id": ex_id,
                    "passage": sentence,
                    "type": "OMISSION_IMPROVEMENT"
                })

                io_reminders.append(
                    f"अन्वेषण अधिकारी (I.O.) से जिरह प्रश्न: '{req.witness_code} ({req.witness_name}) ने धारा 161 के बयान में "
                    f"कथन \"{sentence}\" दर्ज कराया था या नहीं?' (अन्वेषण अधिकारी से इंकार कराकर प्रदर्श {ex_id} को साबित कराएं)।"
                )

                grid_items.append(ContradictionGridItem(
                    statement_segment=sentence,
                    statement_161="[पूर्ण लोप / ABSENT IN 161 STATEMENT]",
                    statement_164=segment_164 or ("[उल्लेख नहीं]" if norm_164 else None),
                    chief_deposition=sentence,
                    classification=classification,
                    severity=severity,
                    tahsildar_singh_applicability_hindi=tahsildar_ratio,
                    statutory_confrontation_script_hindi=confrontation_script,
                    marked_exhibit_identifier=ex_id
                ))

            # Scenario 2: Direct Contradiction (Present in 161 with opposite/conflicting factual stance)
            elif cls._detect_direct_conflict(sentence, segment_161):
                ex_id = f"Ex. D-{exhibit_counter}"
                exhibit_counter += 1

                tahsildar_ratio = (
                    "धारा 148 बी.एस.ए. / धारा 145 आई.ई.ए.: पूर्व बयान (161 CrPC) और न्यायालयीन मुख्य परीक्षा में "
                    "प्रत्यक्ष तथ्यात्मक अंतर्विरोध (Direct Substantive Contradiction)।"
                )

                confrontation_script = (
                    f"गवाह से जिरह प्रश्न: 'क्या यह सही है कि पुलिस को दिए बयान में आपने कहा था: \"{segment_161}\", "
                    f"जबकि आज न्यायालय में आप सर्वथा विपरीत कह रहे हैं कि: \"{sentence}\"? कौन सा बयान झूठा है?' "
                    f"[गवाह के बयान के विवादित अंश पर {ex_id} अंकित कराएं]। "
                )

                marked_exhibits.append({
                    "exhibit_id": ex_id,
                    "passage": f"Court: {sentence} vs 161: {segment_161}",
                    "type": "DIRECT_CONTRADICTION"
                })

                io_reminders.append(
                    f"अन्वेषण अधिकारी से: '{req.witness_code} ने धारा 161 में स्पष्ट रूप से \"{segment_161}\" लिखाया था?' "
                    f"अन्वेषण अधिकारी से पुष्टि कराकर प्रदर्श {ex_id} सिद्ध कराएं।"
                )

                grid_items.append(ContradictionGridItem(
                    statement_segment=sentence,
                    statement_161=segment_161,
                    statement_164=segment_164,
                    chief_deposition=sentence,
                    classification="DIRECT_SUBSTANTIVE_CONTRADICTION",
                    severity="FATAL",
                    tahsildar_singh_applicability_hindi=tahsildar_ratio,
                    statutory_confrontation_script_hindi=confrontation_script,
                    marked_exhibit_identifier=ex_id
                ))

        # Fallback if no glaring contradiction detected: insert standard check
        if not grid_items:
            grid_items.append(ContradictionGridItem(
                statement_segment="सामान्य कथानक",
                statement_161=norm_161[:150] + "...",
                statement_164=norm_164[:150] + "..." if norm_164 else None,
                chief_deposition=norm_chief[:150] + "...",
                classification="CORROBORATING_PASSAGE",
                severity="TRIVIAL",
                tahsildar_singh_applicability_hindi="प्रथम दृष्टया कोई गंभीर विधिक सुधार अथवा अंतर्विरोध चिन्हित नहीं हुआ।",
                statutory_confrontation_script_hindi="गवाह के पूर्व बयानों में प्रथम दृष्टया सामंजस्य है। घटना स्थल व प्रकाश स्रोत पर जिरह केंद्रित करें।",
                marked_exhibit_identifier="N/A"
            ))

        has_fatal = any(item.severity == "FATAL" for item in grid_items)

        # Synthesize Complete Devanagari Master Confrontation Script
        master_script = cls._generate_master_confrontation_script(
            req=req,
            grid_items=grid_items,
            marked_exhibits=marked_exhibits,
            io_reminders=io_reminders
        )

        return WitnessImpeachmentAuditResponse(
            case_id=req.case_id,
            witness_code=req.witness_code,
            witness_name=req.witness_name,
            has_fatal_contradictions=has_fatal,
            grid_analysis=grid_items,
            marked_exhibits_summary=marked_exhibits,
            io_cross_examination_reminders=io_reminders,
            confrontation_master_script_hindi=master_script,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _find_semantic_match(cls, sentence: str, target_corpus: str) -> Tuple[bool, str]:
        """Simple keyword density overlap test to detect presence vs omission."""
        words = [w for w in re.findall(r"\b[\w\u0900-\u097F]+\b", sentence) if len(w) > 3]
        if not words:
            return False, ""

        matches = sum(1 for w in words if w in target_corpus)
        ratio = matches / len(words)

        if ratio >= 0.55:
            # Extract surrounding context from target corpus
            for segment in re.split(r"[।\.\n]+", target_corpus):
                if any(w in segment for w in words[:3]):
                    return True, segment.strip()
            return True, target_corpus[:100].strip()

        return False, ""

    @classmethod
    def _detect_direct_conflict(cls, s1: str, s2: str) -> bool:
        """Detects negative vs affirmative contradictions between statements."""
        negation_markers = ["नहीं", "न", "असमर्थ", "पहचान नहीं", "देखा नहीं"]
        s1_has_neg = any(m in s1 for m in negation_markers)
        s2_has_neg = any(m in s2 for m in negation_markers)
        return s1_has_neg != s2_has_neg

    @classmethod
    def _generate_master_confrontation_script(
        cls,
        req: WitnessImpeachmentAuditRequest,
        grid_items: List[ContradictionGridItem],
        marked_exhibits: List[Dict[str, str]],
        io_reminders: List[str]
    ) -> str:
        date_str = datetime.now().strftime("%d-%m-%Y")

        script = f"""न्यायालय श्रीमान {req.court_name}, {req.district}

सत्र वाद संख्या / मु.अ.सं.: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}
साक्षी कोड: {req.witness_code} ({req.witness_name})

साक्षी जिरह व अंतर्विरोध खंडन विधिक स्क्रिप्ट (Witness Impeachment Protocol)
(अंतर्गत धारा 148 एवं 149 भारतीय साक्ष्य अधिनियम, 2023 / धारा 145 एवं 146 भारतीय साक्ष्य अधिनियम, 1872
सपठित सिद्धांत: तहसीलदार सिंह बनाम उत्तर प्रदेश राज्य (1959) व वी.के. मिश्रा बनाम उत्तराखंड राज्य (2015))

अधिवक्ता हेतु न्यायालयीन कार्यप्रणाली निर्देश:
१. गवाह की मुख्य परीक्षा (Examination-in-Chief) के दौरान नीचे दिए गए प्रश्नों को सीधे गवाह के समक्ष रखें।
२. यदि गवाह कहता है कि उसने पुलिस को यह बात बताई थी, तो तत्कालीन पीठासीन अधिकारी से धारा 161 के बयान में उस अंश को 'प्रदर्श डी' (Exhibit D) के रूप में अंकित करवाएं।
३. बाद में जब विवेचक / अन्वेषण अधिकारी (I.O.) गवाही में आए, तो उससे जिरह कर इन प्रदर्शों को औपचारिक रूप से साबित करवाएं।

--------------------------------------------------------------------------------
भाग १: गवाह {req.witness_code} ({req.witness_name}) से प्रत्यक्ष जिरह प्रश्न
--------------------------------------------------------------------------------
"""

        idx = 1
        for item in grid_items:
            if item.classification != "CORROBORATING_PASSAGE":
                script += f"""
प्रश्न {idx} बाबत [{item.marked_exhibit_identifier}]:
• न्यायालय में दिया गया नया बयान: "{item.chief_deposition}"
• पुलिस बयान (161 CrPC): "{item.statement_161}"
• विधिक वर्गीकरण: {item.classification}
• जिरह संवाद:
  {item.statutory_confrontation_script_hindi}
"""
                idx += 1

        script += f"""
--------------------------------------------------------------------------------
भाग २: अन्वेषण अधिकारी (I.O.) की गवाही के समय पूछे जाने वाले आवश्यक प्रश्न
--------------------------------------------------------------------------------
(तहसीलदार सिंह निर्णय के अनुसार प्रदर्श साबित कराने की विधिक प्रक्रिया)
"""
        for r_idx, reminder in enumerate(io_reminders, start=1):
            script += f"\n{r_idx}. {reminder}"

        script += f"""

दिनांक: {date_str}
स्थान: {req.district}

द्वारा अधिवक्ता
(प्रतिज्ञा लीगल टेक विधिक कार्यप्रणाली)
"""
        return script.strip()
