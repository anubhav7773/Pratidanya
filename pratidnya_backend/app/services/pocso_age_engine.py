from datetime import date
from typing import Dict, Any, List, Optional
from app.schemas.specialized_acts_schema import PocsoAgeAuditRequest, PocsoAgeEvaluation

class PocsoAgeEngine:
    """
    Statutory Age Determination Engine under Section 94 of Juvenile Justice Act, 2015
    applied to POCSO Act 2012 proceedings (*Jarnail Singh v. State of Haryana* (2013) 7 SCC 263):
    1. Tier 1: Matriculation / First Attended School Certificate.
    2. Tier 2: Municipal Authority Birth Certificate.
    3. Tier 3: Ossification Test (+/- 1-2 years margin of error favoring the accused).
    4. Presumption Rebuttal for Sections 29 & 30 of POCSO Act.
    """

    PRECEDENTS = [
        {
            "case_title": "जरनैल सिंह बनाम हरियाणा राज्य (2013) 7 SCC 263",
            "ratio": "पॉक्सो अधिनियम के अंतर्गत पीड़िता की आयु निर्धारण में किशोर न्याय नियमावली की सांविधिक वरीयता आज्ञापक है। विद्यालय के प्रथम प्रवेश रजिस्टर अथवा जन्म प्रमाण पत्र की उपस्थिति में अन्य साक्ष्य ग्राह्य नहीं हैं।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/40523.pdf"
        },
        {
            "case_title": "ऋषिपाल सिंह सोलंकी बनाम उत्तर प्रदेश राज्य (2021) 12 SCC 540",
            "ratio": "अस्थि परीक्षण (Ossification Test) में 2 वर्ष का विचलन (Margin of error) मान्य है। संदेह की स्थिति में यह विधिक लाभ अभियुक्त को दिया जाना चाहिए कि पीड़िता घटना के समय वयस्क थी।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/48731.pdf"
        }
    ]

    @classmethod
    def evaluate(cls, req: PocsoAgeAuditRequest) -> PocsoAgeEvaluation:
        incident_date = req.alleged_incident_date
        tier_applicable = "NO_VALID_DOCUMENT"
        computed_age: Optional[float] = None
        is_majority_probable = False
        analysis_points: List[str] = []
        rebuttal_strategy: List[str] = []
        bail_grounds: List[str] = []

        # Step 1: Evaluate Statutory Document Hierarchy (Sec 94 JJ Act)
        if req.has_matriculation_certificate and req.matriculation_dob:
            tier_applicable = "TIER_1_MATRICULATION"
            dob = req.matriculation_dob
            computed_age = (incident_date - dob).days / 365.25
            analysis_points.append(f"धारा 94(2)(i) के तहत प्रथम वरीयता: मैट्रिकुलेशन प्रमाण पत्र के अनुसार घटना के समय पीड़िता की आयु {computed_age:.1f} वर्ष थी।")
        elif req.has_first_attended_school_certificate and req.school_dob:
            tier_applicable = "TIER_1_FIRST_SCHOOL"
            dob = req.school_dob
            computed_age = (incident_date - dob).days / 365.25
            analysis_points.append(f"धारा 94(2)(i) के तहत प्रथम वरीयता: प्राथमिक विद्यालय प्रवेश रजिस्टर के अनुसार घटना के समय आयु {computed_age:.1f} वर्ष थी।")
        elif req.has_municipal_birth_certificate and req.municipal_dob:
            tier_applicable = "TIER_2_MUNICIPAL"
            dob = req.municipal_dob
            computed_age = (incident_date - dob).days / 365.25
            analysis_points.append(f"धारा 94(2)(ii) के तहत द्वितीय वरीयता: नगर निगम जन्म प्रमाण पत्र के अनुसार घटना के समय आयु {computed_age:.1f} वर्ष थी।")
        elif req.ossification_test_conducted and req.radiological_age_lower and req.radiological_age_upper:
            tier_applicable = "TIER_3_OSSIFICATION"
            # Apply 2-year margin of error benefit to accused
            effective_upper_age = req.radiological_age_upper + (2.0 if req.two_year_margin_benefit_applied else 0.0)
            computed_age = effective_upper_age
            if effective_upper_age >= 18.0:
                is_majority_probable = True
                analysis_points.append(
                    f"धारा 94(2)(iii) मेडिकल बोर्ड अस्थि परीक्षण: रेडियोलॉजिकल आयु {req.radiological_age_lower}-{req.radiological_age_upper} वर्ष पाई गई। "
                    f"उच्चतम न्यायालय (ऋषिपाल सिंह सोलंकी) के अनुसार 2 वर्ष के विचलन का लाभ देने पर पीड़िता की आयु 18 वर्ष से अधिक (वयस्क) संभावित है।"
                )
        else:
            analysis_points.append(
                f"पत्रावली पर पीड़िता की आयु का कोई प्राथमिक सांविधिक प्रमाण उपलब्ध नहीं है। केवल एफ.आई.आर. में दर्ज आयु ({req.fir_stated_age_years} वर्ष) "
                f"बिना दस्तावेजी साक्ष्य के मान्य नहीं है।"
            )

        if computed_age and computed_age >= 18.0:
            is_majority_probable = True

        # Step 2: POCSO Sections 29 & 30 Presumption Rebuttal Strategy
        if req.evidence_of_prior_romantic_relationship:
            rebuttal_strategy.append(
                "पारस्परिक सहमति एवं प्रेम प्रसंग: अभियुक्त और पीड़िता के मध्य पूर्व से प्रेम संबंध था। "
                "विवाह से इनकार अथवा पारिवारिक दबाव के कारण पॉक्सो की कठोर धाराओं में मिथ्या अभियोग पंजीकृत कराया गया।"
            )
        if req.unexplained_delay_in_fir_days >= 3:
            rebuttal_strategy.append(
                f"एफ.आई.आर. में {req.unexplained_delay_in_fir_days} दिन का अकारण विलंब: घटना की तत्काल सूचना न देना "
                f"सोच-समझकर परामर्श के उपरांत झूठी कहानी गढ़ने (Concoction) की संभावना को सिद्ध करता है।"
            )
        if req.no_injuries_found:
            rebuttal_strategy.append(
                "चिकित्सीय साक्ष्य में किसी प्रकार की आंतरिक अथवा बाह्य चोट का अभाव: जबरन शारीरिक संबंध के आरोप का खंडन करता है।"
            )

        # Step 3: Bail Grounds Formulation
        if is_majority_probable:
            bail_grounds.append(
                "यह कि धारा 94 किशोर न्याय अधिनियम एवं मेडिकल बोर्ड की अस्थि परीक्षण रिपोर्ट के आधार पर 2 वर्ष के स्थापित विचलन का लाभ "
                "देने पर पीड़िता घटना के समय पूर्णतः वयस्क (18 वर्ष से अधिक) सिद्ध होती है, अतः सहमति संबंध होने पर पॉक्सो अधिनियम के कठोर प्रावधान आकर्षित नहीं होते।"
            )
        else:
            bail_grounds.append(
                "यह कि अभियोजन पक्ष पीड़िता के अवयस्क होने का कोई ठोस एवं प्रामाणिक सांविधिक प्रमाण पत्र (धारा 94 जे.जे. एक्ट) "
                "प्रस्तुत करने में विफल रहा है; मात्र मौखिक कथन के आधार पर पॉक्सो अधिनियम लागू नहीं किया जा सकता।"
            )

        if req.evidence_of_prior_romantic_relationship:
            bail_grounds.append(
                "यह कि दोनों पक्षों के मध्य प्रेम संबंध थे और यह मामला वस्तुतः सहमति का है, जिसे पारिवारिक असहमति के कारण "
                "आपराधिक रंग देकर धारा 29/30 की सांविधिक उपधारणा का दुरुपयोग किया गया है।"
            )

        if req.unexplained_delay_in_fir_days > 0:
            bail_grounds.append(
                f"यह कि प्रथम सूचना रिपोर्ट में {req.unexplained_delay_in_fir_days} दिन का भारी एवं अस्पष्टीकृत विलंब है, "
                f"जो संपूर्ण अभियोजन कथानक को अत्यधिक संदेहास्पद बनाता है।"
            )

        return PocsoAgeEvaluation(
            case_id=req.case_id,
            statutory_tier_applicable=tier_applicable,
            computed_age_at_incident_years=round(computed_age, 1) if computed_age else None,
            is_majority_probable=is_majority_probable,
            age_determination_analysis_hindi="\n".join(analysis_points),
            presumption_rebuttal_strategy=rebuttal_strategy,
            bail_grounds_pocso=bail_grounds,
            cited_precedents=cls.PRECEDENTS
        )
