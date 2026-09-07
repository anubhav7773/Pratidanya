from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.concurrency import acquire_nlp_slot, release_nlp_slot
from app.services.opennyai_engine import OpenNyAIEngine
from app.services.llm_gateway import LLMGateway

router = APIRouter(prefix="/nlp", tags=["Legal NLP & Chargesheet Parsing"])

class ChargesheetDeconstructRequest(BaseModel):
    case_id: str = Field(..., description="Target Case UUID")
    chargesheet_text: str = Field(..., min_length=50, description="Raw chargesheet / FIR text in Hindi or English")
    is_dummy_testing: bool = Field(default=True, description="Strictly True during local development")

class ChargesheetDeconstructResponse(BaseModel):
    case_id: str
    facts_extracts: List[str]
    prosecution_arguments: List[str]
    statutes_detected: List[str]
    provisions_detected: List[str]
    witnesses_detected: List[str]
    persons_detected: List[str]
    total_sentences_processed: int

@router.post("/process-chargesheet", response_model=ChargesheetDeconstructResponse)
async def process_chargesheet_endpoint(
    payload: ChargesheetDeconstructRequest,
    current_user: dict = Security(verify_advocate_token)
):
    # Statutory Privacy Gate Check (Rule 6)
    if not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing:
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता सुरक्षा निषेध: जब तक पेड-टियर सक्रिय न हो, वास्तविक अभियोग पत्र का प्रसंस्करण प्रतिबंधित है।"
        )

    # Throttling to prevent OOM crash on container
    await acquire_nlp_slot()
    try:
        engine = OpenNyAIEngine.get_instance()
        analysis = engine.process_chargesheet(payload.chargesheet_text)

        return ChargesheetDeconstructResponse(
            case_id=payload.case_id,
            facts_extracts=analysis["facts_extracts"],
            prosecution_arguments=analysis["prosecution_arguments"],
            statutes_detected=analysis["statutes_detected"],
            provisions_detected=analysis["provisions_detected"],
            witnesses_detected=analysis["witnesses_detected"],
            persons_detected=analysis["persons_detected"],
            total_sentences_processed=analysis["total_sentences_processed"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"अभियोग पत्र विश्लेषण विफलता: {str(e)}")
    finally:
        release_nlp_slot()


# =========================================================================
# 360-DEGREE AI OFFENSE, STATUTE & STRATEGY ADVISOR
# =========================================================================

class ApplicableSectionItem(BaseModel):
    act_code: str
    act_name: str
    section: str
    offense_title: str
    bailable_status: str
    triable_by: str
    ingredients_analysis: str

class StrategyPoint(BaseModel):
    title: str
    strategy: str
    statutory_loophole_or_proof: str

class AnalyzeOffense360Request(BaseModel):
    incident_narrative: str = Field(..., min_length=10, description="Incident narrative / facts described by advocate in Hindi or English")
    preferred_statute: Optional[str] = Field(default="HYBRID", description="BNS, IPC, or HYBRID")
    is_dummy_testing: bool = Field(default=True, description="Privacy toggle")

class AnalyzeOffense360Response(BaseModel):
    case_summary_hindi: str
    applicable_sections: List[ApplicableSectionItem]
    defense_strategy_360: List[StrategyPoint]
    prosecution_strategy_360: List[StrategyPoint]
    landmark_precedents: List[str]


def _rule_based_fallback_analysis(narrative: str, preferred_statute: str) -> Dict[str, Any]:
    text = narrative.lower()
    sections: List[Dict[str, Any]] = []
    defenses: List[Dict[str, Any]] = []
    prosecution: List[Dict[str, Any]] = []
    citations: List[str] = []

    is_ipc = preferred_statute == "IPC"
    is_bns = preferred_statute == "BNS"

    # NDPS Detection
    if any(k in text for k in ["चरस", "गांजा", "स्मैक", "हेरोइन", "ड्रग्स", "नशीला", "ndps", "narcotic", "charas", "ganja"]):
        sections.append({
            "act_code": "NDPS",
            "act_name": "स्वापक औषधि एवं मनःप्रभावी पदार्थ अधिनियम 1985 (NDPS Act)",
            "section": "धारा 8/20 NDPS Act",
            "offense_title": "अवैध मादक द्रव्य का कब्जा एवं परिवहन",
            "bailable_status": "गैर-जमानती (Non-Bailable)",
            "triable_by": "विशेष एनडीपीएस न्यायालय (NDPS Court)",
            "ingredients_analysis": "कथित मादक पदार्थ की बरामदगी फर्द तैयार की गई है।"
        })
        defenses.append({
            "title": "धारा 50 NDPS का आज्ञापक उल्लंघन",
            "strategy": "व्यक्तिगत तलाशी से पूर्व राजपत्रित अधिकारी या मजिस्ट्रेट के समक्ष ले जाने के अधिकार का लिखित नोटिस नहीं दिया गया।",
            "statutory_loophole_or_proof": "धारा 50 NDPS का उल्लंघन संपूर्ण अभियोजन को दूषित करता है।"
        })
        defenses.append({
            "title": "स्वतंत्र पंच साक्षियों का अभाव",
            "strategy": "सार्वजनिक स्थान से कथित बरामदगी के बावजूद कोई स्वतंत्र लोक साक्षी फर्द में शामिल नहीं किया गया।",
            "statutory_loophole_or_proof": "धारा 100(4) CrPC / धारा 105 BNSS का उल्लंघन।"
        })
        prosecution.append({
            "title": "एफएसएल (FSL) रासायनिक जांच रिपोर्ट",
            "strategy": "बरामद माल की रासायनिक जांच रिपोर्ट सकारात्मक सिद्ध की जानी आवश्यक है।",
            "statutory_loophole_or_proof": "विधि विज्ञान प्रयोगशाला रिपोर्ट।"
        })
        citations.append("राजस्थान राज्य बनाम परमानंद एवं अन्य (2014) 5 SCC 345")

    # Arms Act Detection
    if any(k in text for k in ["तमंचा", "पिस्तौल", "कारतूस", "असलहा", "चाकू", "firearm", "arms", "pistol"]):
        sections.append({
            "act_code": "ARMS",
            "act_name": "आयुध अधिनियम 1959 (Arms Act)",
            "section": "धारा 3/25 Arms Act",
            "offense_title": "अवैध असलहे का अनाधिकृत कब्जा",
            "bailable_status": "गैर-जमानती (Non-Bailable)",
            "triable_by": "न्यायिक मजिस्ट्रेट प्रथम श्रेणी / CJM",
            "ingredients_analysis": "बिना वैध लाइसेंस के हथियार की बरामदगी दर्शायी गई है।"
        })
        defenses.append({
            "title": "कथित बरामदगी की गोपनीयता व स्वतंत्र साक्षी अभाव",
            "strategy": "कथित असलहे की जब्ती पुलिस द्वारा रंजिशन गढ़ी गई है, मौके का कोई स्वतंत्र गवाह नहीं है।",
            "statutory_loophole_or_proof": "धारा 100(4) CrPC / 105 BNSS।"
        })
        citations.append("पवन कुमार बनाम दिल्ली प्रशासन (1989 CriLJ 127)")

    # Theft Detection
    if any(k in text for k in ["चोरी", "गायब", "सामान ले गए", "theft", "stolen"]):
        sections.append({
            "act_code": "BNS" if not is_ipc else "IPC",
            "act_name": "भारतीय न्याय संहिता 2023" if not is_ipc else "भारतीय दंड संहिता 1860",
            "section": "धारा 303 BNS" if not is_ipc else "धारा 379 IPC",
            "offense_title": "चोरी का अपराध (Theft)",
            "bailable_status": "गैर-जमानती (Non-Bailable)",
            "triable_by": "मजिस्ट्रेट द्वारा विचारणीय",
            "ingredients_analysis": "कब्जे से बेईमानी पूर्वक संपत्ति को हटाने का आरोप है।"
        })
        defenses.append({
            "title": "चोरी की संपत्ति की प्रत्यक्ष पहचान का अभाव",
            "strategy": "कथित बरामद माल की कोई शिनाख्त परेड (TIP) नहीं कराई गई एवं स्वामित्व साबित नहीं है।",
            "statutory_loophole_or_proof": "धारा 411 IPC / धारा 317 BNS के आवश्यक तत्वों का अभाव।"
        })
        citations.append("त्रिम्बक बनाम मध्य प्रदेश राज्य (1954 AIR SC 39)")

    # Default Bodily injury / altercation
    if not sections or any(k in text for k in ["मारपीट", "चोट", "धमकी", "झगड़ा", "fight", "assault"]):
        sections.append({
            "act_code": "BNS" if not is_ipc else "IPC",
            "act_name": "भारतीय न्याय संहिता 2023" if not is_ipc else "भारतीय दंड संहिता 1860",
            "section": "धारा 115(2) BNS" if not is_ipc else "धारा 323 IPC",
            "offense_title": "स्वेच्छया साधारण चोट पहुंचाना",
            "bailable_status": "जमानती (Bailable)",
            "triable_by": "कोई भी मजिस्ट्रेट",
            "ingredients_analysis": "शारीरिक चोट पहुंचाने का कथन पत्रावली पर उपस्थित है।"
        })
        sections.append({
            "act_code": "BNS" if not is_ipc else "IPC",
            "act_name": "भारतीय न्याय संहिता 2023" if not is_ipc else "भारतीय दंड संहिता 1860",
            "section": "धारा 351(2) BNS" if not is_ipc else "धारा 506 IPC",
            "offense_title": "आपराधिक धमकी (Criminal Intimidation)",
            "bailable_status": "जमानती / गैर-जमानती (UP संशोधन)",
            "triable_by": "मजिस्ट्रेट द्वारा विचारणीय",
            "ingredients_analysis": "जान से मारने की कथित धमकी दी गई है।"
        })
        defenses.append({
            "title": "मेडिकल साक्ष्य एवं प्रत्यक्ष कथनों में गंभीर विसंगति",
            "strategy": "चोटों की प्रकृति साधारण है तथा घटना में आत्मरक्षा (Right of Private Defence) का अधिकार उपलब्ध है।",
            "statutory_loophole_or_proof": "मेडिकल रिपोर्ट में गंभीर चोटों का पूर्ण अभाव।"
        })
        prosecution.append({
            "title": "मेडिको-लीगल प्रमाण पत्र (MLC)",
            "strategy": "डॉक्टर द्वारा चोटों की समयावधि एवं प्रयुक्त हथियार से संगति साबित करना अनिवार्य है।",
            "statutory_loophole_or_proof": "चिकित्सक बयान एवं चोट पत्र।"
        })
        citations.append("बाबू सिंह बनाम उत्तर प्रदेश राज्य (1978 AIR SC 527)")

    if not defenses:
        defenses.append({
            "title": "रंजिशन मिथ्या नामजदगी",
            "strategy": "पूर्व रंजिश के कारण निर्दोष अभियुक्त को झूठा फंसाया गया है।",
            "statutory_loophole_or_proof": "आपराधिक मंशा (Mens Rea) का अभाव।"
        })

    if not prosecution:
        prosecution.append({
            "title": "घटना का प्रत्यक्ष साक्ष्य",
            "strategy": "घटना स्थल पर चश्मदीद गवाहों की विश्वसनीय गवाही साबित करना।",
            "statutory_loophole_or_proof": "धारा 161 CrPC / 180 BNSS बयान।"
        })

    return {
        "case_summary_hindi": f"प्रस्तुत घटनाक्रम के विश्लेषण से स्पष्ट है कि मुख्य विवाद {narrative[:100]}... से संबंधित है।",
        "applicable_sections": sections,
        "defense_strategy_360": defenses,
        "prosecution_strategy_360": prosecution,
        "landmark_precedents": citations or ["अरणेश कुमार बनाम बिहार राज्य (2014) 8 SCC 273"]
    }


@router.post("/analyze-offense-360", response_model=AnalyzeOffense360Response)
async def analyze_offense_360_endpoint(
    payload: AnalyzeOffense360Request,
    current_user: dict = Security(verify_advocate_token)
):
    system_prompt = (
        "You are an expert Indian Criminal Law Senior Advocate and District Court Legal Specialist. "
        "Analyze the provided factual incident narrative. Identify ALL applicable sections under General Criminal Law "
        "(Bharatiya Nyaya Sanhita 2023 - BNS and/or IPC 1860) AND any applicable Indian Special & Local Acts "
        "(NDPS Act 1985, POCSO Act 2012, Arms Act 1959, UP Gangsters Act 1986, SC/ST Act 1989, UP Excise Act 1910, "
        "IT Act 2000, NI Act 1881, PMLA 2002, Motor Vehicles Act 1988, Prevention of Corruption Act 1988). "
        "Provide a 360-degree legal strategy with comprehensive Defending tactics and Prosecution counter-proofs.\n"
        "Output strictly valid JSON with this exact schema:\n"
        "{\n"
        '  "case_summary_hindi": "...",\n'
        '  "applicable_sections": [\n'
        '    {\n'
        '      "act_code": "BNS / IPC / NDPS / POCSO / ARMS / GANGSTERS / SC_ST / EXCISE / IT_ACT / NI_ACT / PMLA",\n'
        '      "act_name": "Full official name in Hindi",\n'
        '      "section": "Exact section (e.g. धारा 109 BNS / धारा 3/25 Arms Act)",\n'
        '      "offense_title": "Offense title in Hindi with English in brackets",\n'
        '      "bailable_status": "जमानती / गैर-जमानती",\n'
        '      "triable_by": "मजिस्ट्रेट / सत्र न्यायालय",\n'
        '      "ingredients_analysis": "Why this section applies"\n'
        '    }\n'
        '  ],\n'
        '  "defense_strategy_360": [\n'
        '    {\n'
        '      "title": "Defense point heading",\n'
        '      "strategy": "Detailed tactical defense argument",\n'
        '      "statutory_loophole_or_proof": "Specific legal procedural loophole"\n'
        '    }\n'
        '  ],\n'
        '  "prosecution_strategy_360": [\n'
        '    {\n'
        '      "title": "Prosecution point heading",\n'
        '      "strategy": "What the prosecution must establish beyond reasonable doubt",\n'
        '      "statutory_loophole_or_proof": "Essential proof or evidence required"\n'
        '    }\n'
        '  ],\n'
        '  "landmark_precedents": ["Case Name 1", "Case Name 2"]\n'
        "}\n"
    )

    user_prompt = (
        f"घटना का विवरण (Incident Narrative):\n{payload.incident_narrative}\n\n"
        f"प्राथमिकता विधिक संहिता: {payload.preferred_statute}\n"
        "कृपया इस घटना में लगने वाली सभी उपयुक्त धाराएं (BNS/IPC एवं विशेष अधिनियम), "
        "बचाव पक्ष की 360° व्यूहरचना तथा अभियोजन पक्ष के मुख्य साक्ष्य भार का विस्तृत विश्लेषण तैयार करें।"
    )

    try:
        raw_result = await LLMGateway.generate_structured_json(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            temperature=0.15,
            max_tokens=3000
        )

        if not raw_result.get("applicable_sections"):
            raw_result = _rule_based_fallback_analysis(payload.incident_narrative, payload.preferred_statute or "HYBRID")

        return AnalyzeOffense360Response(
            case_summary_hindi=raw_result.get("case_summary_hindi", "घटना का विधिक विश्लेषण तैयार किया गया।"),
            applicable_sections=[ApplicableSectionItem(**item) for item in raw_result.get("applicable_sections", [])],
            defense_strategy_360=[StrategyPoint(**item) for item in raw_result.get("defense_strategy_360", [])],
            prosecution_strategy_360=[StrategyPoint(**item) for item in raw_result.get("prosecution_strategy_360", [])],
            landmark_precedents=raw_result.get("landmark_precedents", [])
        )
    except Exception as e:
        fallback = _rule_based_fallback_analysis(payload.incident_narrative, payload.preferred_statute or "HYBRID")
        return AnalyzeOffense360Response(
            case_summary_hindi=fallback["case_summary_hindi"],
            applicable_sections=[ApplicableSectionItem(**item) for item in fallback["applicable_sections"]],
            defense_strategy_360=[StrategyPoint(**item) for item in fallback["defense_strategy_360"]],
            prosecution_strategy_360=[StrategyPoint(**item) for item in fallback["prosecution_strategy_360"]],
            landmark_precedents=fallback["landmark_precedents"]
        )

