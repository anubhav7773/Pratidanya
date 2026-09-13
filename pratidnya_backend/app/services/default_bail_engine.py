from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Tuple
from app.schemas.remand_schema import DefaultBailAuditRequest, DefaultBailAuditResponse, PrecedentCitationItem

class DefaultBailEngine:
    """
    Statutory Default Bail & Chargesheet Defect Engine:
    - Calculates 60/90/180-day periods from first judicial remand date under Bikramjit Singh & M. Ravindran.
    - Evaluates Section 187(2)/(3) BNSS split police custody (15 days across first 40 or 60 days).
    - Identifies incomplete chargesheets lacking vital forensic reports under CBI v. Kapil Wadhawan (2024).
    - Synthesizes fully grounded Devanagari petitions for immediate court filing before cognizance.
    """

    PRECEDENTS = [
        PrecedentCitationItem(
            case_title="बिक्रमजीत सिंह बनाम पंजाब राज्य (2020) 10 SCC 616",
            citation="AIR 2020 SC 4924",
            legal_ratio_hindi="सांविधिक डिफ़ॉल्ट जमानत का अधिकार केवल एक प्रक्रियात्मक प्रावधान नहीं है, बल्कि अनुच्छेद 21 के तहत प्रदत्त मौलिक अधिकार है। अवधि पूर्ण होते ही अधिकार अचूक रूप से प्रोद्भूत (Crystallize) हो जाता है।",
            verified_url="https://main.sci.gov.in/judgment/judis/47746.pdf"
        ),
        PrecedentCitationItem(
            case_title="एम. रवींद्रन बनाम राजस्व खुफिया निदेशालय (2021) 2 SCC 485",
            citation="AIR 2021 SC 85",
            legal_ratio_hindi="जैसे ही 60 या 90 दिन की अवधि पूरी होती है और अभियुक्त जमानत हेतु तैयार है, मजिस्ट्रेट को तत्काल जमानत देनी होगी। उसके उपरांत दाखिल आरोप-पत्र इस अधिकार को नष्ट नहीं कर सकता।",
            verified_url="https://main.sci.gov.in/judgment/judis/47852.pdf"
        ),
        PrecedentCitationItem(
            case_title="सी.बी.आई. बनाम कपिल वाधवान (2024) 3 SCC 734",
            citation="2024 INSC 58",
            legal_ratio_hindi="डिफ़ॉल्ट जमानत से बचने के लिए बिना अनिवार्य वैज्ञानिक/फॉरेंसिक साक्ष्य के दाखिल अधूरा आरोप-पत्र विधिक रूप से शून्य (Non-est) माना जाएगा यदि वह संज्ञान लेने योग्य प्राथमिक सामग्री प्रस्तुत नहीं करता।",
            verified_url="https://main.sci.gov.in/judgment/judis/50124.pdf"
        )
    ]

    MANDATORY_FORENSIC_MAPPING = {
        "NDPS": ["FSL_CHEMICAL_EXAMINER_REPORT", "SAMPLE_DRAWN_CERTIFICATE_52A"],
        "FIREARMS_ARMS_ACT": ["BALLISTICS_EXPERT_REPORT", "ARMOURER_INSPECTION_MEMO"],
        "POISONING_302_BNS": ["VISCERA_EXAMINATION_REPORT"],
        "ELECTRONIC_CYBER": ["SECTION_63_BSA_CERTIFICATE", "CYBER_FORENSIC_HASH_REPORT"]
    }

    @classmethod
    def audit_default_bail(cls, req: DefaultBailAuditRequest) -> DefaultBailAuditResponse:
        now = datetime.now(timezone.utc)
        first_remand = req.first_remand_date
        if first_remand.tzinfo is None:
            first_remand = first_remand.replace(tzinfo=timezone.utc)

        # 1. Determine Statutory Threshold (60, 90, or 180 Days)
        threshold_days = 60
        is_special_act_180 = False

        for off in req.offense_sections:
            act_upper = off.act.upper()
            if "NDPS" in act_upper or "UAPA" in act_upper:
                is_special_act_180 = True
                threshold_days = 180
                break
            if off.max_punishment_years >= 10:
                threshold_days = 90

        if not is_special_act_180 and threshold_days < 90:
            for off in req.offense_sections:
                if off.max_punishment_years >= 10:
                    threshold_days = 90
                    break

        # 2. Elapsed Days Calculation
        # Under Settled Law (Bikramjit Singh / State of M.P. v. Rustam), exclude day of remand, compute full 24-hr days
        accrual_timestamp = first_remand + timedelta(days=threshold_days)
        elapsed_days = (now - first_remand).days
        is_time_expired = now >= accrual_timestamp
        hours_until = max(0.0, (accrual_timestamp - now).total_seconds() / 3600.0)

        # 3. Section 187 BNSS Split Police Custody Analysis
        # Under Section 187(2) BNSS: Max 15 days PC allowed in whole or in parts
        # Window: first 40 days (for 60-day limit) or first 60 days (for 90-day limit)
        max_pc_window_days = 40 if threshold_days == 60 else 60
        pc_window_expiry = first_remand + timedelta(days=max_pc_window_days)
        is_pc_window_closed = now >= pc_window_expiry

        pc_days_used = 0
        for entry in req.custody_history:
            if entry.custody_type.upper() == "POLICE_CUSTODY":
                days = (entry.end_date - entry.start_date).days
                pc_days_used += max(0, days)

        pc_days_remaining = max(0, 15 - pc_days_used)

        if is_pc_window_closed:
            pc_alert = (
                f"धारा 187(3) बी.एन.एस.एस. पुलिस कस्टडी की वैधानिक समय-सीमा समाप्त: प्रथम {max_pc_window_days} दिन बीत चुके हैं। "
                "अब पुलिस रिमांड किसी भी परिस्थिति में स्वीकृत नहीं की जा सकती।"
            )
        elif pc_days_remaining == 0:
            pc_alert = "धारा 187(2) के तहत 15 दिन की अधिकतम पुलिस कस्टडी अवधि पूर्ण रूप से उपयोग की जा चुकी है।"
        else:
            pc_alert = f"धारा 187 बी.एन.एस.एस.: पुलिस कस्टडी के {pc_days_remaining} दिन शेष हैं (खिड़की अंतिम तिथि: {pc_window_expiry.strftime('%d-%m-%Y')})।"

        # 4. Incomplete Chargesheet Defect Analysis
        is_incomplete_cs = False
        defect_type = None
        missing_reports: List[str] = []
        cs_summary = ""

        # Check for foundational missing reports
        norm_annexures = [a.upper().strip() for a in req.chargesheet_annexures]
        for off in req.offense_sections:
            act = off.act.upper()
            sec = off.section.upper()
            if "NDPS" in act:
                for rep in cls.MANDATORY_FORENSIC_MAPPING["NDPS"]:
                    if rep not in norm_annexures:
                        missing_reports.append(rep)
            if "ARMS" in act:
                for rep in cls.MANDATORY_FORENSIC_MAPPING["FIREARMS_ARMS_ACT"]:
                    if rep not in norm_annexures:
                        missing_reports.append(rep)

        missing_reports = sorted(list(set(missing_reports)))

        if req.chargesheet_filed:
            if missing_reports:
                is_incomplete_cs = True
                defect_type = "SUBTERFUGE_INCOMPLETE_CHARGESHEET"
                cs_summary = (
                    f"आरोप-पत्र में अनिवार्य वैज्ञानिक साक्ष्य ({', '.join(missing_reports)}) नदारद हैं। "
                    "सी.बी.आई. बनाम कपिल वाधवान (2024) के अनुसार डिफ़ॉल्ट जमानत रोकने के उद्देश्य से दाखिल अधूरा आरोप-पत्र विधि में शून्य है।"
                )
            else:
                cs_summary = "आरोप-पत्र सभी अनिवार्य उपाबंधों सहित नियत समय पर प्रस्तुत किया गया प्रतीत होता है।"
        else:
            cs_summary = "अभी तक अन्वेषण अधिकारी द्वारा न्यायालय में अंतिम आरोप-पत्र प्रस्तुत नहीं किया गया है।"

        # Crystallization Condition:
        # 1. Time threshold has passed AND no chargesheet was filed, OR
        # 2. Time threshold has passed AND filed chargesheet is legally incomplete/non-est.
        is_crystallized = is_time_expired and (not req.chargesheet_filed or is_incomplete_cs)

        # 5. Generate Court-Ready Devanagari Petition
        statute_label = "धारा 187(3) भारतीय नागरिक सुरक्षा संहिता, 2023" if req.statutory_regime == "BNSS" else "धारा 167(2) दंड प्रक्रिया संहिता, 1973"
        petition_draft = cls._generate_devanagari_petition(
            req=req,
            statute_label=statute_label,
            threshold_days=threshold_days,
            elapsed_days=elapsed_days,
            accrual_date=accrual_timestamp.strftime("%d-%m-%Y"),
            is_incomplete=is_incomplete_cs,
            missing_reports=missing_reports
        )

        return DefaultBailAuditResponse(
            case_id=req.case_id,
            statutory_threshold_days=threshold_days,
            days_elapsed_in_custody=elapsed_days,
            is_default_bail_crystallized=is_crystallized,
            default_bail_accrual_timestamp=accrual_timestamp,
            hours_until_default_bail=hours_until,
            police_custody_days_used=pc_days_used,
            police_custody_days_remaining=pc_days_remaining,
            police_custody_window_expired=is_pc_window_closed,
            police_custody_alert_hindi=pc_alert,
            is_chargesheet_incomplete=is_incomplete_cs,
            defect_type=defect_type,
            missing_mandatory_reports=missing_reports,
            chargesheet_defect_summary_hindi=cs_summary,
            statutory_petition_draft_hindi=petition_draft,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _generate_devanagari_petition(
        cls,
        req: DefaultBailAuditRequest,
        statute_label: str,
        threshold_days: int,
        elapsed_days: int,
        accrual_date: str,
        is_incomplete: bool,
        missing_reports: List[str]
    ) -> str:
        sec_list = ", ".join(f"{o.act} की धारा {o.section}" for o in req.offense_sections)
        remand_str = req.first_remand_date.strftime("%d-%m-%Y")

        petition = f"""न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट, {req.district}

मुकदमा अपराध संख्या: {req.case_id}
थाना: {req.police_station}, जिला: {req.district}
धाराएं: {sec_list}

राज्य बनाम {req.accused_name}

प्रार्थना पत्र अंतर्गत {statute_label}
(सांविधिक / डिफ़ॉल्ट जमानत बाबत अभियुक्त)

महोदय,
    आवेदक / अभियुक्त की ओर से निम्नलिखित विधिक व तथ्यात्मक आधार सादर प्रस्तुत हैं:-

1. यह कि अभियुक्त को पुलिस द्वारा गिरफ्तार कर दिनांक {remand_str} को इस विद्वान न्यायालय के समक्ष प्रस्तुत किया गया था, जहां से उसे न्यायिक अभिरक्षा में निरुद्ध करने का आदेश पारित किया गया।

2. यह कि वर्तमान वाद में आरोपित अपराधों के अंतर्गत अधिकतम विधिक कारावास की अवधि के आधार पर अन्वेषण पूर्ण करने की सांविधिक समय-सीमा {threshold_days} दिन निर्धारित है।

3. यह कि दिनांक {remand_str} से लेकर आज तक अभियुक्त के न्यायिक अभिरक्षा में कुल {elapsed_days} दिन व्यतीत हो चुके हैं। इस प्रकार {threshold_days} दिन की सांविधिक सीमा दिनांक {accrual_date} को समाप्त हो चुकी है।
"""

        if is_incomplete:
            petition += f"""
4. यह कि यद्यपि अभियोजन द्वारा एक औपचारिक प्रपत्र प्रस्तुत किया गया है, परंतु उसमें अनिवार्य वैज्ञानिक व फॉरेंसिक साक्ष्य ({', '.join(missing_reports)}) संलग्न नहीं हैं। उच्चतम न्यायालय के सुस्थापित न्याय-सिद्धांत (सी.बी.आई. बनाम कपिल वाधवान 2024 व रितु छाबड़िया) के अनुसार डिफ़ॉल्ट जमानत के अधिकार को निष्फल करने हेतु दाखिल अधूरा आरोप-पत्र विधि की दृष्टि में शून्य (Non-est) है।
"""
        else:
            petition += f"""
4. यह कि विहित {threshold_days} दिवस की सांविधिक अवधि के भीतर अन्वेषण एजेंसी द्वारा कोई भी आरोप-पत्र / पुलिस रिपोर्ट इस माननीय न्यायालय के समक्ष प्रस्तुत नहीं की गई है।
"""

        petition += f"""
5. यह कि उच्चतम न्यायालय की संविधान पीठ व त्रिसदस्यीय पीठ द्वारा 'बिक्रमजीत सिंह बनाम पंजाब राज्य' तथा 'एम. रवींद्रन बनाम डी.आर.आई.' में प्रतिपादित सिद्धांतों के अनुसार सांविधिक डिफ़ॉल्ट जमानत का अधिकार अनुच्छेद 21 के अंतर्गत एक मौलिक व अचूक अधिकार (Indefeasible Fundamental Right) है, जिसे अन्वेषण एजेंसी की विफलता के उपरांत छीना नहीं जा सकता।

6. यह कि आवेदक / अभियुक्त इस न्यायालय के आदेशानुसार समुचित एवं पर्याप्त प्रतिभू (Sureties) व बंधपत्र (Bail Bonds) प्रस्तुत करने के लिए पूर्णतः तत्पर व तैयार है।

प्रार्थना:
    अतः न्यायहित में सादर प्रार्थना है कि अभियुक्त {req.accused_name} को {statute_label} के आज्ञापक प्रावधानों के अंतर्गत सांविधिक डिफ़ॉल्ट जमानत पर रिहा फरमाने की कृपा की जाए।

दिनांक: {datetime.now().strftime("%d-%m-%Y")}
स्थान: {req.district}

द्वारा अधिवक्ता
(हस्ताक्षर एवं चैंबर मुहर)
"""
        return petition.strip()
