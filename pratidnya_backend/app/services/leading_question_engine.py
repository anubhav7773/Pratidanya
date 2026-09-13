from datetime import datetime
from typing import List, Dict, Any
from app.schemas.leading_question_schema import (
    LeadingQuestionRequest,
    LeadingQuestionResponse,
    QuestionStepItem
)

class LeadingQuestionEngine:
    """
    Hostile Witness & Leading Question Tree Generator:
    - Enforces Section 147 BSA 2023 / Section 143 IEA 1872 permission for leading questions in cross-examination.
    - Implements Sat Paul (1976) and Neeraj Dutta (2023) to salvage favorable admissions.
    - Generates strictly closed, non-narrative binary (Yes/No) decision trees.
    - Provides trap-mitigation follow-ups and documentary exhibit confrontation pivots.
    """

    PRECEDENTS = [
        {
            "case_title": "सत पाल बनाम दिल्ली प्रशासन (1976) 1 SCC 727",
            "citation": "AIR 1976 SC 294",
            "ratio_hindi": "पक्षद्रोही (Hostile) घोषित गवाह का साक्ष्य अभिलेख से पूरी तरह नहीं मिटता। जिरह के दौरान बचाव पक्ष के समर्थन में निकाले गए अनुकूल कथन पूर्णतः ग्राह्य हैं और अभियुक्त के बचाव में उन पर भरोसा किया जा सकता है।",
            "source_url": "https://main.sci.gov.in/judgment/judis/5412.pdf"
        },
        {
            "case_title": "नीरज दत्ता बनाम राज्य (एन.सी.टी. दिल्ली) (2023) 4 SCC 731",
            "citation": "2022 INSC 1283",
            "ratio_hindi": "संविधान पीठ के अनुसार जिरह का मुख्य उद्देश्य सत्य को उजागर करना और गवाह की साख को खंडित करना है। सूचक प्रश्नों (Leading Questions) द्वारा गवाह के विरोधाभास स्थापित किए जा सकते हैं।",
            "source_url": "https://main.sci.gov.in/judgment/judis/49912.pdf"
        },
        {
            "case_title": "गुणवंतलाल बनाम मध्य प्रदेश राज्य (1972) 2 SCC 194",
            "citation": "AIR 1972 SC 1756",
            "ratio_hindi": "आयुध अधिनियम की धारा 25 अथवा बरामदगी के मामलों में मात्र खुले स्थान से बरामदगी अभियुक्त का अनन्य सचेत आधिपत्य (Conscious Exclusive Possession) सिद्ध नहीं करती।",
            "source_url": "https://main.sci.gov.in/judgment/judis/4891.pdf"
        }
    ]

    @classmethod
    def generate_question_trees(cls, req: LeadingQuestionRequest) -> LeadingQuestionResponse:
        theory = req.defense_theory
        facts = req.case_facts

        if theory == "PLANTED_RECOVERY_STOCK_WITNESS":
            trees, strategy, tactics = cls._build_planted_recovery_trees(req, facts)
        elif theory == "ALIBI_AND_ABSENCE":
            trees, strategy, tactics = cls._build_alibi_trees(req, facts)
        elif theory == "CONSENSUAL_RELATION_SEC_69_BNS":
            trees, strategy, tactics = cls._build_consensual_bns_trees(req, facts)
        elif theory == "MISTAKEN_IDENTITY_TIP_FAILURE":
            trees, strategy, tactics = cls._build_mistaken_identity_trees(req, facts)
        else:
            trees, strategy, tactics = cls._build_generic_credibility_trees(req, facts)

        return LeadingQuestionResponse(
            case_id=req.case_id,
            witness_name=req.witness_name,
            defense_theory=theory,
            questionnaire_strategy_hindi=strategy,
            question_trees=trees,
            trial_tactics_summary_hindi=tactics,
            cited_precedents=cls.PRECEDENTS
        )

    @classmethod
    def _build_planted_recovery_trees(cls, req: LeadingQuestionRequest, facts: Dict[str, Any]):
        dist = facts.get("witness_residence_distance_km", 12)
        appearances = facts.get("prior_appearances_count", 3)
        place = facts.get("recovery_place", "खुला खेत / सुनसान स्थान")
        weap = facts.get("weapon_type", "अवैध असलहा")

        strategy = (
            "स्टॉक साक्षी (Pocket Witness) का संबंध व अनन्य आधिपत्य का अभाव सिद्ध करना: "
            "गवाह के निवास स्थल की दूरी, थाने से पूर्व संलिप्तता, और खुले सार्वजनिक स्थल से बरामदगी स्थापित करना।"
        )

        tactics = (
            "अधिवक्ता हेतु विधिक चेतावनी: गवाह से 'क्यों' या 'कैसे' जैसे विवरणात्मक प्रश्न कदापि न पूछें। "
            "केवल वही प्रश्न पूछें जिनका उत्तर 'हाँ' या 'ना' में बाध्यकारी हो। प्रतिकूल उत्तर देने पर पूर्व मुकदमों के जब्ती मेमो से तुरंत खंडन करें।"
        )

        trees = [
            QuestionStepItem(
                step_number=1,
                objective_hindi="आकस्मिक उपस्थिति की असंभावना व दूरी स्थापित करना",
                leading_question_hindi=f"क्या यह सही है कि आपका स्थायी निवास स्थान ग्राम/मोहल्ला, कथित बरामदगी स्थल ({place}) से लगभग {dist} किलोमीटर की दूरी पर स्थित है?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह कहे कि वह किसी निजी कार्य से आया था, तो तुरंत पूछें: 'क्या आपने उस दिन वहां उपस्थित होने का कोई भी दस्तावेजी साक्ष्य या बिल आई.ओ. को दिया था?'",
                pivot_tactic_hindi="यदि गवाह दूरी से इंकार करे, तो निर्वाचन नामावली अथवा आधार पते से दूरी सिद्ध कराएं।",
                statutory_basis="धारा 147 बी.एस.ए. (सूचक प्रश्न) व धारा 103 बी.एन.एस.एस. (स्वतंत्र स्थानीय साक्षी)"
            ),
            QuestionStepItem(
                step_number=2,
                objective_hindi="थाने का पेशेवर पॉकेट साक्षी (Stock Witness) सिद्ध करना",
                leading_question_hindi=f"क्या यह सत्य है कि आप इसी थाने ({req.police_station}) के पूर्ववर्ती आपराधिक मुकदमों में भी पुलिस की ओर से बरामदगी फर्द के साक्षी रह चुके हैं?",
                expected_answer="NO OR DENIAL",
                trap_mitigation_hindi="यदि गवाह इंकार करे, तो पुराने मुकदमों के अपराध संख्या दर्ज कराते हुए प्रमाणित प्रतियों को पत्रावली पर प्रस्तुत करने की घोषणा करें।",
                pivot_tactic_hindi=f"पूर्व मुकदमों (मु.अ.सं. 102/2022, 45/2023) के जब्ती पंचनामों की प्रमाणित प्रतियों (Ex. D-12, D-13) से गवाह का तुरंत सामना कराएं।",
                statutory_basis="धारा 148 एवं 158 बी.एस.ए. (गवाह की निष्पक्षता व साख पर प्रहार)"
            ),
            QuestionStepItem(
                step_number=3,
                objective_hindi="खुले सार्वजनिक स्थल से बरामदगी व अनन्य आधिपत्य का खंडन",
                leading_question_hindi=f"क्या यह सही है कि जिस स्थान से {weap} की बरामदगी दर्शाई गई है, वह चारों तरफ से खुली जगह है और वहां आम जनता व ग्रामीणों की आवाजाही निरंतर बनी रहती है?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह कहे कि झाड़ी में छिपा था, तो पूछें: 'क्या वह झाड़ी आम रास्ते के किनारे सार्वजनिक भूमि पर स्थित थी?'",
                pivot_tactic_hindi="नजरी नक्शा (Site Plan) दिखाकर पुष्टि कराएं कि स्थल किसी बाउंड्री वॉल या ताले में बंद नहीं था (गुणवंतलाल सिद्धांत)।",
                statutory_basis="धारा 23 बी.एस.ए. (समतुल्य 27 साक्ष्य अधिनियम) - सचेत अनन्य आधिपत्य का अभाव"
            ),
            QuestionStepItem(
                step_number=4,
                objective_hindi="धारा 103 बी.एन.एस.एस. / धारा 100(4) दं.प्र.सं. के आज्ञापक प्रावधानों का उल्लंघन",
                leading_question_hindi="क्या यह सत्य है कि पुलिस ने तलाशी व जब्ती से पूर्व मौके पर उपस्थित आसपास के स्थानीय दुकानदारों या पड़ोसियों को साक्षी बनने हेतु कोई लिखित नोटिस नहीं दिया था?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह कहे कि लोग मना कर दिए, तो पूछें: 'क्या पुलिस ने किसी भी व्यक्ति का नाम या इंकार करने की बात फर्द पर दर्ज की थी?'",
                pivot_tactic_hindi="जब्ती फर्द पर स्थानीय गवाहों के नाम न होने को रेखांकित करवाएं।",
                statutory_basis="धारा 103(4) बी.एन.एस.एस. (स्वतंत्र गवाहों की अनिवार्यता)"
            )
        ]
        return trees, strategy, tactics

    @classmethod
    def _build_alibi_trees(cls, req: LeadingQuestionRequest, facts: Dict[str, Any]):
        dist_km = facts.get("alibi_distance_km", 150)
        loc = facts.get("alibi_location", "अन्य शहर / कार्यस्थल")

        strategy = "अन्यत्रता (Alibi) की अकाट्यता व भौतिक असंभावना सिद्ध करना: अपराध स्थल से भारी दूरी और उपस्थिति का आधिकारिक साक्ष्य स्थापित करना।"

        tactics = "गवाह को समय और दूरी के चक्रव्यूह में बांधें ताकि यह सिद्ध हो सके कि उसी समय अभियुक्त का कथित घटना स्थल पर होना भौतिक रूप से असंभव था।"

        trees = [
            QuestionStepItem(
                step_number=1,
                objective_hindi="घटना का निश्चित समय व स्थल संकुचित करना",
                leading_question_hindi="क्या यह सही है कि आपके अनुसार घटना ठीक सायं 06:30 बजे आपके गांव के मुख्य चौराहे पर घटित हुई थी?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह समय में हेरफेर करे, तो उसकी मुख्य परीक्षा और धारा 161 के बयान से समय का मिलान कराएं।",
                pivot_tactic_hindi="एफआईआर में दर्ज निश्चित समय को गवाह के मुंह से स्वीकार कराएं।",
                statutory_basis="धारा 9 बी.एस.ए. (समतुल्य धारा 11 साक्ष्य अधिनियम - सुसंगत तथ्य)"
            ),
            QuestionStepItem(
                step_number=2,
                objective_hindi="अन्यत्र उपस्थिति स्थल की भौगोलिक दूरी",
                leading_question_hindi=f"क्या आप जानते हैं कि {loc} आपके गांव से लगभग {dist_km} किलोमीटर की दूरी पर स्थित है?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह अनभिज्ञता जताए, तो गूगल मैप अथवा राज्य सड़क परिवहन दूरी चार्ट न्यायालय के अवलोकनार्थ प्रस्तुत करें।",
                pivot_tactic_hindi="सरकारी बस/ट्रेन समय सारणी से दूरी सिद्ध करें।",
                statutory_basis="धारा 11 साक्ष्य अधिनियम / धारा 9 बी.एस.ए. (अन्यत्रता का विधिक सिद्धांत)"
            ),
            QuestionStepItem(
                step_number=3,
                objective_hindi="बायोमेट्रिक अथवा संस्थागत उपस्थिति का अकाट्य साक्ष्य",
                leading_question_hindi="क्या यह सत्य है कि घटना के समय अभियुक्त अपने कार्यालय/संस्थान में बायोमेट्रिक उपस्थिति व सीसीटीवी कैमरों में उपस्थित दर्ज था?",
                expected_answer="NO OR UNKNOWN",
                trap_mitigation_hindi="गवाह के इंकार पर तुरंत कहें: 'क्या आपके पास इसका कोई खंडन है कि वह वहां उपस्थित नहीं था?'",
                pivot_tactic_hindi="बचाव साक्ष्य के रूप में प्रस्तुत प्रमाणित उपस्थिति पंजिका (Ex. DW-1) पत्रावली पर दर्ज कराएं।",
                statutory_basis="धारा 63 बी.एस.ए. (इलेक्ट्रॉनिक बायोमेट्रिक उपस्थिति अभिलेख)"
            )
        ]
        return trees, strategy, tactics

    @classmethod
    def _build_consensual_bns_trees(cls, req: LeadingQuestionRequest, facts: Dict[str, Any]):
        duration_months = facts.get("relationship_duration_months", 24)
        age = facts.get("prosecutrix_age", 22)

        strategy = "सहमतिजन्य वयस्क संबंध व वैवाहिक विफलता सिद्ध करना (धारा 69 BNS / 376 IPC): प्रथम दृष्टया कपटपूर्ण आशय का अभाव व दीर्घकालिक सहमति सिद्ध करना।"

        tactics = "संबंध की दीर्घकालिक प्रकृति, स्वतंत्र आवाजाही, और सार्वजनिक होटलों/स्थानों पर बिना किसी विरोध के साथ रहने के तथ्य को 'हाँ/ना' में स्वीकार कराएं।"

        trees = [
            QuestionStepItem(
                step_number=1,
                objective_hindi="पीड़िता की पूर्ण वयस्कता व समझदारी सिद्ध करना",
                leading_question_hindi=f"क्या यह सही है कि घटना के कथित प्रारंभ के समय आपकी आयु {age} वर्ष से अधिक थी और आप शिक्षित व निर्णय लेने में सक्षम थीं?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि पीड़िता आयु कम बताए, तो उसकी हाईस्कूल अंकतालिका से जन्मतिथि की पुष्टि कराएं।",
                pivot_tactic_hindi="शैक्षणिक प्रमाण पत्र से वयस्कता सिद्ध करें।",
                statutory_basis="धारा 94 जे.जे. एक्ट व वयस्कता साक्ष्य"
            ),
            QuestionStepItem(
                step_number=2,
                objective_hindi="दीर्घकालिक स्वैच्छिक साहचर्य व सहमति",
                leading_question_hindi=f"क्या यह सत्य है कि आप और अभियुक्त विगत {duration_months} माह से निरंतर एक-दूसरे के संपर्क में थे और विभिन्न स्थानों व होटलों में स्वेच्छा से साथ रहे थे?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि पीड़िता कहे कि शादी के झांसे में गई थी, तो पूछें: 'क्या आपने उन 2 वर्षों में कभी भी किसी होटल कर्मचारी, पुलिस या परिजन से कोई शिकायत की थी?'",
                pivot_tactic_hindi="होटल चेक-इन रजिस्टर व आईडी प्रमाण पत्रों (Ex. D-8) से संयुक्त उपस्थिति सिद्ध कराएं।",
                statutory_basis="धारा 69 बी.एन.एस. (विवाह के झूठे वादे का खंडन - दीर्घकालिक सहमति)"
            ),
            QuestionStepItem(
                step_number=3,
                objective_hindi="विवाह का प्रस्ताव पारिवारिक विरोध के कारण टूटना (कपट का अभाव)",
                leading_question_hindi="क्या यह सही है कि संबंध की शुरुआत में अभियुक्त का इरादा आपको धोखा देने का नहीं था, बल्कि बाद में दोनों परिवारों के मतभेद के कारण विवाह संभव नहीं हो सका?",
                expected_answer="NO OR UNKNOWN",
                trap_mitigation_hindi="पीड़िता के व्हाट्सएप चैट मैसेजेस दिखाकर पूछें: 'क्या इस संदेश में आपने स्वयं पारिवारिक असहमति की बात नहीं लिखी थी?'",
                pivot_tactic_hindi="व्हाट्सएप चैट व पारिवारिक संवादों के प्रमाणित स्क्रीनशॉट्स (धारा 63 BSA) से जिरह का रुख मोड़ें।",
                statutory_basis="प्रमोद सूर्यभान पवार बनाम महाराष्ट्र राज्य (2019) 9 SCC 608 सिद्धांत"
            )
        ]
        return trees, strategy, tactics

    @classmethod
    def _build_mistaken_identity_trees(cls, req: LeadingQuestionRequest, facts: Dict[str, Any]):
        strategy = "पहचान परेड (TIP) की विफलता व प्रकाश स्रोत का अभाव: घने अंधेरे में पहचान की असंभवता व थाने में पूर्व दर्शन स्थापित करना।"
        tactics = "घटना के समय दृश्यता की कमी और एफआईआर में हुलिया दर्ज न होने को गवाह से सीधे स्वीकार कराएं।"

        trees = [
            QuestionStepItem(
                step_number=1,
                objective_hindi="घटना स्थल पर प्रकाश स्रोत का पूर्ण अभाव",
                leading_question_hindi="क्या यह सत्य है कि घटना अमावस्या की रात लगभग 11:30 बजे घटी थी और उस सुनसान रास्ते पर बिजली का कोई खंभा अथवा प्रकाश व्यवस्था नहीं थी?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह कहे कि टार्च या मोबाइल की रोशनी थी, तो पूछें: 'क्या वह टार्च आपने पुलिस को जांच हेतु सौंपी और क्या वह फर्द में दर्ज है?'",
                pivot_tactic_hindi="नजरी नक्शे (Site Plan) में प्रकाश स्रोत अनुपस्थित होना दिखाएं।",
                statutory_basis="धारा 7 बी.एस.ए. (पहचान का अवसर व प्रकाश स्रोत)"
            ),
            QuestionStepItem(
                step_number=2,
                objective_hindi="एफआईआर में शारीरिक पहचान चिह्नों (Huliya) का लोप",
                leading_question_hindi="क्या यह सही है कि पुलिस को दी गई अपनी प्रथम सूचना में आपने अभियुक्त की लंबाई, रंग, चेहरे के किसी निशान अथवा विशिष्ट हुलिए का कोई विवरण नहीं लिखाया था?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह कहे कि बताया था, तो एफआईआर की मूल प्रति पढ़कर सुनाएं और लोप सिद्ध कराएं।",
                pivot_tactic_hindi="एफआईआर प्रदर्श से हुलिया का अभाव सिद्ध कराएं।",
                statutory_basis="धारा 148 बी.एस.ए. (पूर्व बयान से खंडन)"
            ),
            QuestionStepItem(
                step_number=3,
                objective_hindi="न्यायालय में प्रथम बार पहचान (Dock Identification) का दूषित होना",
                leading_question_hindi="क्या यह सत्य है कि मजिस्ट्रेट के समक्ष औपचारिक पहचान परेड (TIP) कराने से पूर्व पुलिस ने अभियुक्त को थाने में आपको प्रत्यक्ष रूप से दिखा दिया था?",
                expected_answer="NO",
                trap_mitigation_hindi="पूछें: 'क्या पहचान परेड से पूर्व समाचार पत्रों अथवा सोशल मीडिया पर अभियुक्त का फोटो प्रसारित हो चुका था?'",
                pivot_tactic_hindi="समाचार पत्र की कतरनें दिखाकर पहचान परेड की विधिक शून्यता सिद्ध करें।",
                statutory_basis="धारा 54 बी.एन.एस.एस. (पहचान परेड की पवित्रता)"
            )
        ]
        return trees, strategy, tactics

    @classmethod
    def _build_generic_credibility_trees(cls, req: LeadingQuestionRequest, facts: Dict[str, Any]):
        strategy = "साक्षी की सत्यवादिता व साख का परीक्षण (Section 146 IEA / Section 149 BSA)।"
        tactics = "गवाह के परस्पर विरोधी बयानों और पूर्वाग्रह को उजागर करने हेतु संक्षिप्त सूचक प्रश्न पूछें।"

        trees = [
            QuestionStepItem(
                step_number=1,
                objective_hindi="पारिवारिक रंजिश अथवा पूर्व वैमनस्य सिद्ध करना",
                leading_question_hindi="क्या यह सत्य है कि अभियुक्त के परिवार और आपके परिवार के मध्य पूर्व से दीवानी व भूमि विवाद का मुकदमा न्यायालय में विचाराधीन है?",
                expected_answer="YES",
                trap_mitigation_hindi="यदि गवाह इंकार करे, तो लंबित वाद की वाद संख्या व तारीख पेशी पत्रावली पर प्रस्तुत करें।",
                pivot_tactic_hindi="दीवानी वाद के आदेश पत्र की प्रमाणित प्रति से खंडन कराएं।",
                statutory_basis="धारा 149 बी.एस.ए. (गवाह की साख व शत्रुता का परीक्षण)"
            )
        ]
        return trees, strategy, tactics
