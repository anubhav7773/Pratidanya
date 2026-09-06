from datetime import date, timedelta
from typing import Dict, Any, List
from app.schemas.scst_and_ni_schema import NiActAuditRequest, NiActComplianceEvaluation

class NiActComplianceEngine:
    """
    Statutory Compliance & Defense Audit Engine for Section 138 of the Negotiable Instruments Act:
    1. Strict Statutory Timeline:
       - Dishonour Memo -> Statutory Notice dispatched within 30 Days (Sec 138(b)).
       - Notice Delivery -> 15 Days Cure Period for Drawer to pay (Sec 138(c)).
       - Cure Period Expiry -> Cause of Action arises; Complaint must be filed within 30 Days (Sec 142(1)(b)).
    2. Premature Complaint Fatal Defect:
       - *Yogendra Pratap Singh v. Savitri Pandey* (2014) 10 SCC 713: A complaint filed before the
         expiry of the 15-day cure period is non-est in the eyes of law; taking cognizance is illegal.
    3. Omnibus Demand Defect:
       - *K.R. Indira v. Dr. G. Adinarayana* (2003) 8 SCC 300: Notice must demand the specific cheque amount;
         amalgamating interest, damages or other claims without distinct apportionment vitiates the notice.
    4. Compounding Guidelines under Section 147:
       - *Damodar S. Prabhu v. Sayed Babalal H.* (2010) 5 SCC 663: Graded cost framework for compounding.
    """

    PRECEDENTS = [
        {
            "case_title": "योगेंद्र प्रताप सिंह बनाम सावित्री पांडे (2014) 10 SCC 713",
            "ratio": "धारा 138 के तहत अपराध तब तक गठित नहीं होता जब तक कि विधिक मांग नोटिस तामील होने के बाद 15 दिन की अवधि व्यतीत न हो जाए। 15 दिन पूरे होने से पूर्व दायर परिवाद अपरिपक्व (Premature) एवं शून्य है, जिस पर संज्ञान नहीं लिया जा सकता।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/41935.pdf"
        },
        {
            "case_title": "के.आर. इंदिरा बनाम डॉ. जी. आदिनारायण (2003) 8 SCC 300",
            "ratio": "धारा 138(b) के अंतर्गत नोटिस में अनादृत चेक की विशिष्ट धनराशि की मांग होना अनिवार्य है। यदि नोटिस में चेक राशि के अतिरिक्त अन्य दावों या ब्याज को एकमुश्त मिलाकर अस्पष्ट मांग की गई हो, तो ऐसा नोटिस दोषपूर्ण होने के कारण परिवाद निरस्त होने योग्य है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/25471.pdf"
        },
        {
            "case_title": "दामोदर एस. प्रभु बनाम सैयद बाबालाल एच. (2010) 5 SCC 663",
            "ratio": "धारा 147 के तहत धारा 138 का अपराध शमनीय (Compoundable) है। उच्चतम न्यायालय ने विभिन्न स्तरों (मजिस्ट्रेट न्यायालय, सत्र न्यायालय एवं उच्च न्यायालय) पर चेक राशि के क्रमशः 10%, 15% एवं 20% के लागत ढांचे के साथ समझौते की मार्गदर्शिका निर्धारित की है।",
            "citation_url": "https://main.sci.gov.in/judgment/judis/36284.pdf"
        }
    ]

    @classmethod
    def evaluate(cls, req: NiActAuditRequest) -> NiActComplianceEvaluation:
        fatal_defects: List[str] = []
        rebuttal_strategy: List[str] = []
        discharge_grounds: List[str] = []

        # 1. Scrutinize 30-Day Notice Dispatch Window (Sec 138(b))
        days_from_dishonour_to_dispatch = (req.demand_notice_dispatch_date - req.bank_return_memo_date).days
        dispatch_valid = days_from_dishonour_to_dispatch <= 30

        if not dispatch_valid:
            fatal_defects.append(
                f"धारा 138(b) का उल्लंघन: बैंक मेमो प्राप्त होने के {days_from_dishonour_to_dispatch} दिन बाद नोटिस भेजा गया (अधिकतम सीमा 30 दिन है)।"
            )

        # 2. Compute 15-Day Cure Period Expiry (Sec 138(c))
        cure_expiry = req.demand_notice_delivery_date + timedelta(days=15)

        # 3. Check Premature Complaint (Yogendra Pratap Singh)
        is_premature = req.complaint_filing_date <= cure_expiry
        if is_premature:
            days_early = (cure_expiry - req.complaint_filing_date).days + 1
            fatal_defects.append(
                f"अपरिपक्व परिवाद (Premature Complaint): 15 दिन की वैधानिक अवधि पूर्ण होने से {days_early} दिन पूर्व परिवाद दाखिल किया गया। "
                f"संज्ञान आदेश पूर्णतः अवैध है (योगेंद्र प्रताप सिंह संविधान पीठ उल्लंघन)।"
            )

        # 4. Check Limitation for Complaint Filing (Section 142(1)(b)) - 30 days post cure period
        complaint_limitation_expiry = cure_expiry + timedelta(days=30)
        is_time_barred = req.complaint_filing_date > complaint_limitation_expiry
        if is_time_barred:
            days_late = (req.complaint_filing_date - complaint_limitation_expiry).days
            fatal_defects.append(
                f"कालबाधित परिवाद: वाद-कारण उत्पन्न होने के 30 दिन बाद ({days_late} दिन विलंब) परिवाद दायर किया गया और धारा 142(1)(b) के परंतुक के तहत कोई विलंब माफी आदेश अभिलेख पर नहीं है।"
            )

        # 5. Check Omnibus Demand Defect (K.R. Indira)
        if req.is_omnibus_demand_defective:
            fatal_defects.append(
                "दोषपूर्ण एकमुश्त मांग नोटिस (Omnibus Demand): विधिक नोटिस में चेक की मूल राशि के स्थान पर ब्याज व अन्य दावों को मिलाकर एकमुश्त मांग की गई है, जो धारा 138(b) के तहत अमान्य है (के.आर. इंदिरा सिद्धांत)।"
            )

        # 6. Presumption Rebuttal Strategy (Section 139)
        if req.defense_category == "SECURITY_CHEQUE":
            rebuttal_strategy.append(
                "सुरक्षा चेक (Security Cheque) का दुरुपयोग: विवादित चेक किसी मौजूदा विधिक देयता (Enforceable Debt) के भुगतान हेतु नहीं, बल्कि पूर्व लेन-देन की सुरक्षा के रूप में दिया गया था, जिसे बिना सूचना के अनुचित रूप से बैंक में प्रस्तुत किया गया।"
            )
        elif req.defense_category == "FINANCIAL_INCAPACITY":
            rebuttal_strategy.append(
                "परिवादी की वित्तीय क्षमता का खंडन (बसंत बनाम धन्नंजय सिद्धांत): परिवादी चेक में उल्लिखित भारी धनराशि का स्रोत, बैंक विवरण अथवा आयकर विवरणी (ITR) प्रस्तुत करने में असमर्थ रहा है।"
            )

        # 7. Formulate Discharge / Quashing Grounds
        if is_premature or not dispatch_valid or req.is_omnibus_demand_defective:
            discharge_grounds.append(
                "यह कि वर्तमान परिवाद धारा 138 की अनिवार्य पूर्व-शर्तों को पूरा न करने के कारण प्रथम दृष्टया पोषणीय नहीं है और इस पर लिया गया संज्ञान विधि विरुद्ध होने के कारण निरस्त होने योग्य है।"
            )

        discharge_grounds.append(
            f"यह कि अभियुक्त विवादित चेक के संबंध में किसी विधिक दायित्व के अधीन नहीं था और धारा 139 की सांविधिक उपधारणा को "
            f"संभावनाओं की प्रबलता (Preponderance of Probabilities) के आधार पर सफलतापूर्वक खंडित किया गया है।"
        )

        # 8. Compounding Framework under Section 147 (Damodar S. Prabhu)
        compounding_info = None
        if req.seeks_compounding:
            compounding_info = (
                "धारा 147 एन.आई. एक्ट के तहत शमन (Compounding): उच्चतम न्यायालय (दामोदर एस. प्रभु) के अनुसार "
                "न्यायालय के समक्ष चेक राशि के भुगतान पर वाद का पूर्ण निस्तारण कराया जा सकता है। मजिस्ट्रेट स्तर पर कोई अतिरिक्त लागत देय नहीं है।"
            )

        return NiActComplianceEvaluation(
            case_id=req.case_id,
            dispatch_within_30_days=dispatch_valid,
            cure_period_15_days_expiry_date=cure_expiry,
            is_premature_complaint=is_premature,
            is_time_barred=is_time_barred,
            fatal_defects_detected=fatal_defects,
            defense_rebuttal_strategy=rebuttal_strategy,
            statutory_discharge_or_quashing_grounds=discharge_grounds,
            compounding_guidelines_under_147=compounding_info,
            cited_precedents=cls.PRECEDENTS
        )
