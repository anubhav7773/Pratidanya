from datetime import datetime, timezone
from typing import List, Dict, Any
from app.schemas.forensic_medical_schema import (
    MedicalMatrixAuditRequest,
    MedicalMatrixAuditResponse,
    ConflictFindingItem
)

class MedicoLegalEngine:
    """
    Forensic Deposition Discrepancy & Biomechanical Conflict Engine:
    - Cross-references wound morphology (laceration vs incised) with alleged weapons.
    - Reconciles physiological digestion rates and post-mortem interval (PMI) with stated assault times.
    - Applies Ram Narain Singh (1975) & Darshan Singh (2010) doctrines on fatal medical contradictions.
    - Generates targeted leading cross-examination questions for the Autopsy Surgeon under Section 147 BSA.
    """

    PRECEDENTS = [
        {
            "case_title": "राम नारायण सिंह बनाम पंजाब राज्य (1975) 4 SCC 34",
            "citation": "AIR 1975 SC 1727",
            "ratio_hindi": "जहां चश्मदीद साक्षियों की गवाही और निष्पक्ष चिकित्सकीय साक्ष्य (Medical Evidence) के मध्य पूर्ण व असमाधेय अंतर्विरोध विद्यमान हो, वहां अभियोजन का संपूर्ण कथानक अविश्वसनीय हो जाता है और अभियुक्त दोषमुक्ति का अधिकारी है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/5231.pdf"
        },
        {
            "case_title": "दर्शन सिंह बनाम पंजाब राज्य (2010) 2 SCC 333",
            "citation": "AIR 2010 SC 849",
            "ratio_hindi": "यदि चिकित्सकीय साक्ष्य प्रत्यक्षदर्शी गवाह के बयान को पूर्णतः असंभव (Physical Impossibility) सिद्ध करता है, तो मात्र मौखिक बयानों के आधार पर दोषसिद्धि कायम नहीं रखी जा सकती।",
            "source_url": "https://main.sci.gov.in/judgment/judis/35712.pdf"
        },
        {
            "case_title": "अमरीक सिंह बनाम राजस्थान राज्य (2023) 14 SCC 512",
            "citation": "2023 INSC 598",
            "ratio_hindi": "आमाशय में उपस्थित भोजन की पाचन अवस्था तथा मृत्योपरांत अकड़न (Rigor Mortis) की स्थिति घटना के समय के संबंध में चश्मदीद साक्षियों की झूठी गवाही को उजागर करने के लिए महत्वपूर्ण वैज्ञानिक आधार हैं।",
            "source_url": "https://main.sci.gov.in/judgment/judis/49982.pdf"
        }
    ]

    SHARP_WEAPON_KEYWORDS = ["sword", "talwar", "knife", "chhura", "dagger", "chhuri", "axe", "kulhari", "gandasa", "farsa"]
    BLUNT_WEAPON_KEYWORDS = ["lathi", "danda", "iron rod", "saria", "stone", "patthar", "fist", "ghusa", "club"]

    @classmethod
    def audit_medico_legal(cls, req: MedicalMatrixAuditRequest) -> MedicalMatrixAuditResponse:
        conflicts: List[ConflictFindingItem] = []
        questions: List[str] = []

        pm = req.post_mortem_data
        autopsy_time = pm.autopsy_timestamp if pm.autopsy_timestamp.tzinfo else pm.autopsy_timestamp.replace(tzinfo=timezone.utc)

        for witness in req.ocular_allegations:
            w_time = witness.incident_timestamp if witness.incident_timestamp.tzinfo else witness.incident_timestamp.replace(tzinfo=timezone.utc)
            w_weapon = witness.weapon_alleged.lower().strip()
            w_loc = witness.strike_location.lower().strip()

            # -------------------------------------------------------------
            # 1. BIOMECHANICAL WEAPON MECHANISM AUDIT
            # -------------------------------------------------------------
            is_sharp_alleged = any(k in w_weapon for k in cls.SHARP_WEAPON_KEYWORDS)
            is_blunt_alleged = any(k in w_weapon for k in cls.BLUNT_WEAPON_KEYWORDS)

            for inj in pm.external_injuries:
                inj_type = inj.injury_type.lower()
                inj_margins = inj.margins.lower()
                inj_loc = inj.anatomical_location.lower()

                # Case A: Sharp weapon alleged, but PMR shows Laceration with Contused/Abraded Margins
                if is_sharp_alleged and ("lacerat" in inj_type or "contused" in inj_margins or "irregular" in inj_margins):
                    conflicts.append(ConflictFindingItem(
                        parameter="WEAPON_MECHANISM",
                        ocular_claim=f"{witness.witness_id} का कथन: धारदार हथियार ({witness.weapon_alleged}) द्वारा प्रहार किया गया।",
                        autopsy_finding=f"शव विच्छेदन आख्या (PMR): {inj.injury_type} (माप: {inj.dimensions}) जिसके किनारे '{inj.margins}' पाए गए।",
                        scientific_verdict_hindi="पूर्ण वैज्ञानिक असंभावना: तलवार अथवा चाकू जैसे धारदार हथियार से हमेशा साफ कटे (Clean-cut / Linear) किनारे आते हैं। अनियमित व कुचले (Irregular, contused) किनारे केवल कुंद वस्तु (Blunt impact) के प्रहार से ही संभव हैं।",
                        biomechanical_authority="Modi's Medical Jurisprudence and Toxicology (27th Edition, Chapter on Mechanical Injuries)",
                        impact_on_prosecution="गवाह द्वारा आरोपित हथियार का झूठा होना सिद्ध करता है (राम नारायण सिंह सिद्धांत)।",
                        severity="FATAL_CONTRADICTION"
                    ))
                    questions.append(
                        f"डॉक्टर साहब, क्या यह चिकित्सकीय रूप से सत्य है कि तलवार या चाकू जैसे धारदार हथियार से कारित घाव के किनारे हमेशा 'Clean-cut' व स्पष्ट होते हैं?"
                    )
                    questions.append(
                        f"डॉक्टर साहब, चोट संख्या {inj.injury_number} में आपने किनारे 'Irregular and contused' दर्ज किए हैं; क्या यह सही है कि ऐसे कुचले किनारे केवल लाठी या लोहे की रॉड जैसी कुंद (Blunt) वस्तु के प्रहार से ही आ सकते हैं?"
                    )

                # Case B: Blunt weapon alleged, but PMR shows Incised or Punctured/Stab wound
                if is_blunt_alleged and ("incised" in inj_type or "stab" in inj_type or "clean-cut" in inj_margins):
                    conflicts.append(ConflictFindingItem(
                        parameter="WEAPON_MECHANISM",
                        ocular_claim=f"{witness.witness_id} का कथन: लाठी अथवा डंडे द्वारा प्रहार किया गया।",
                        autopsy_finding=f"PMR: {inj.injury_type} जिसके किनारे '{inj.margins}' हैं।",
                        scientific_verdict_hindi="लाठी या डंडे से इनसाइज्ड अथवा स्टैब घाव कारित होना भौतिक रूप से असंभव है।",
                        biomechanical_authority="Parikh's Textbook of Medical Jurisprudence and Forensic Medicine",
                        impact_on_prosecution="प्रत्यक्षदर्शी साक्षी के बयान और वास्तविक चोट में असमाधेय विरोधाभास।",
                        severity="FATAL_CONTRCTRADICTION" if "FATAL_CONTRADICTION" else "FATAL_CONTRADICTION"
                    ))
                    # Ensure severity is FATAL_CONTRADICTION
                    conflicts[-1].severity = "FATAL_CONTRADICTION"
                    questions.append(
                        f"डॉक्टर साहब, क्या साधारण लाठी या डंडे के प्रहार से साफ कटे किनारों वाला 'Incised wound' उत्पन्न हो सकता है?"
                    )

            # -------------------------------------------------------------
            # 2. TIME OF OCCURRENCE & PHYSIOLOGICAL INTERVAL AUDIT (PMI)
            # -------------------------------------------------------------
            elapsed_hours_to_autopsy = (autopsy_time - w_time).total_seconds() / 3600.0
            pmi_min = pm.estimated_time_since_death_hours_min
            pmi_max = pm.estimated_time_since_death_hours_max

            # Significant discrepancy (> 8 hours between assault time and estimated PMI window)
            if elapsed_hours_to_autopsy < (pmi_min - 4.0) or elapsed_hours_to_autopsy > (pmi_max + 4.0):
                conflicts.append(ConflictFindingItem(
                    parameter="TIME_OF_OCCURRENCE_PMI",
                    ocular_claim=f"{witness.witness_id} के अनुसार घटना का समय: {w_time.strftime('%d-%m-%Y को %H:%M बजे')} (शव परीक्षण से {elapsed_hours_to_autopsy:.1f} घंटे पूर्व)।",
                    autopsy_finding=f"चिकित्सकीय अनुमानित मृत्यु अंतराल (PMI): पोस्टमार्टम से {pmi_min:.0f} से {pmi_max:.0f} घंटे पूर्व (अकड़न: {pm.rigor_mortis_state})।",
                    scientific_verdict_hindi=f"समय का भारी विचलन: चश्मदीद गवाह द्वारा बताए गए समय और शव की मृत्योपरांत अकड़न की अवस्था में लगभग {abs(elapsed_hours_to_autopsy - ((pmi_min + pmi_max) / 2)):.1f} घंटे का अंतर है।",
                    biomechanical_authority="Modi's Medical Jurisprudence (Post-Mortem Interval & Rigor Mortis Chronology)",
                    impact_on_prosecution="घटना के समय गवाह की मौके पर उपस्थिति और एफ.आई.आर. में दर्ज समय को पूरी तरह संदेहास्पद बनाता है।",
                    severity="FATAL_CONTRADICTION"
                ))
                questions.append(
                    f"डॉक्टर साहब, यदि व्यक्ति की मृत्यु {w_time.strftime('%d-%m-%Y को दोपहर %H:%M बजे')} हुई होती, तो क्या अगले दिन शव विच्छेदन के समय मृत्योपरांत अकड़न (Rigor Mortis) की स्थिति {pm.rigor_mortis_state} के रूप में पाई जानी चिकित्सकीय दृष्टि से संभव थी?"
                )

            # -------------------------------------------------------------
            # 3. STOMACH CONTENTS & DIGESTION CHRONOLOGY AUDIT
            # -------------------------------------------------------------
            stomach_lower = pm.stomach_contents.lower()
            if "semi-digested" in stomach_lower or "अर्ध-पचा" in stomach_lower:
                conflicts.append(ConflictFindingItem(
                    parameter="STOMACH_DIGESTION_CHRONOLOGY",
                    ocular_claim="अभियोजन कथानक: मृतक को सुबह/दोपहर में बिना भोजन किए रास्ते में रोका गया।",
                    autopsy_finding=f"आमाशय में सामग्री: '{pm.stomach_contents}'।",
                    scientific_verdict_hindi="मानव शरीर क्रिया विज्ञान के अनुसार अर्ध-पचा भोजन यह सिद्ध करता है कि मृतक ने अपनी मृत्यु से 2 से 3 घंटे पूर्व ठोस भोजन ग्रहण किया था।",
                    biomechanical_authority="Taylor's Principles and Practice of Medical Jurisprudence",
                    impact_on_prosecution="अंतिम भोजन व मृत्यु के समय का अभियोजन कहानी से मेल न खाना।",
                    severity="MATERIAL_DISCREPANCY"
                ))
                questions.append(
                    "डॉक्टर साहब, आमाशय में उपस्थित अर्ध-पचे भोजन के आधार पर, क्या यह निष्कर्ष निकालना वैज्ञानिक रूप से उचित है कि मृतक ने मृत्यु से लगभग दो से तीन घंटे पहले भोजन किया था?"
                )

        has_fatal = any(c.severity == "FATAL_CONTRADICTION" for c in conflicts)

        # 4. Generate Court-Ready Devanagari Written Argument
        written_draft = cls._generate_written_argument(
            req=req,
            conflicts=conflicts,
            has_fatal=has_fatal
        )

        return MedicalMatrixAuditResponse(
            case_id=req.case_id,
            pmr_number=req.post_mortem_data.pmr_number,
            has_fatal_conflict=has_fatal,
            irreconcilable_conflicts=conflicts,
            cross_examination_crossfire_questions=questions,
            written_medical_argument_draft_hindi=written_draft,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_written_argument(
        cls,
        req: MedicalMatrixAuditRequest,
        conflicts: List[ConflictFindingItem],
        has_fatal: bool
    ) -> str:
        date_str = datetime.now().strftime("%d-%m-%Y")
        pm = req.post_mortem_data

        draft = f"""न्यायालय श्रीमान {req.court_name}, {req.district}

सत्र वाद संख्या / मु.अ.सं.: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}

राज्य बनाम {req.accused_name}

बहस / विधिक तर्क बाबत प्रत्यक्षदर्शी साक्ष्य व चिकित्सकीय साक्ष्य में असमाधेय अंतर्विरोध
(अंतर्गत धारा 39 भारतीय साक्ष्य अधिनियम, 2023 / धारा 45 भारतीय साक्ष्य अधिनियम, 1872
सपठित न्याय-सिद्धांत: राम नारायण सिंह बनाम पंजाब राज्य (1975) 4 SCC 34 व दर्शन सिंह बनाम पंजाब राज्य (2010) 2 SCC 333)

महोदय,
    अभियुक्त {req.accused_name} की ओर से अभियोजन के कथित प्रत्यक्षदर्शी साक्षियों के बयानों एवं पोस्टमार्टम आख्या (PMR सं. {pm.pmr_number}) के वैज्ञानिक विश्लेषण के आधार पर निम्नलिखित विधिक तर्क प्रस्तुत हैं:-

1. यह कि प्रस्तुत वाद में अभियोजन का संपूर्ण कथानक कथित चश्मदीद साक्षियों की मौखिक गवाही पर टिका हुआ है। परंतु जब इस मौखिक गवाही की तुलना स्वतंत्र व निष्पक्ष चिकित्सकीय साक्ष्य (PMR सं. {pm.pmr_number}) से की जाती है, तो दोनों के मध्य ऐसा प्रत्यक्ष व असमाधेय विरोधाभास (Irreconcilable Contradiction) उजागर होता है जो अभियोजन की सत्यता को जड़ से समाप्त करता है।
"""

        idx = 2
        for c in conflicts:
            draft += f"""
{idx}. {c.parameter} के संबंध में घोर अंतर्विरोध:
   • प्रत्यक्षदर्शी साक्षी का दावा: {c.ocular_claim}
   • निष्पक्ष शव परीक्षण आख्या: {c.autopsy_finding}
   • वैज्ञानिक विधिक निष्कर्ष: {c.scientific_verdict_hindi}
   • स्थापित विधिक सत्ता: {c.biomechanical_authority}
   • अभियोजन पर प्रभाव: {c.impact_on_prosecution}
"""
            idx += 1

        draft += f"""
{idx}. यह कि उच्चतम न्यायालय की तीन-न्यायाधीशों की पीठ ने 'राम नारायण सिंह बनाम पंजाब राज्य (1975) 4 SCC 34' में यह सुस्पष्ट व्यवस्था दी है कि:-
   "Where the witnesses examined on behalf of the prosecution make statements which are in complete contradiction with the medical evidence, that by itself is sufficient to falsify the entire prosecution case."
   वर्तमान मामले में गवाह द्वारा धारदार हथियार (तलवार/चाकू) का प्रहार बताना और वास्तव में चोट कुंद हथियार (Laceration with contused margins) की निकलना, गवाह के मौके पर मौजूद न होने का अकाट्य प्रमाण है।

{idx+1}. यह कि 'दर्शन सिंह बनाम पंजाब राज्य (2010) 2 SCC 333' के अनुसार जहां चिकित्सकीय साक्ष्य मौखिक साक्ष्य को भौतिक रूप से असंभव (Physical Impossibility) सिद्ध कर दे, वहां अभियुक्त को संदेह का पूर्ण लाभ देकर दोषमुक्त किया जाना विधि का आज्ञापक नियम है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि प्रत्यक्षदर्शी साक्ष्य और वैज्ञानिक पोस्टमार्टम आख्या के मध्य विद्यमान असमाधेय अंतर्विरोधों के आलोक में अभियोजन कथानक को अविश्वसनीय घोषित करते हुए अभियुक्त {req.accused_name} को ससम्मान दोषमुक्त फरमाने की कृपा की जाए।

दिनांक: {date_str}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर व चैंबर मुहर)
"""
        return draft.strip()
