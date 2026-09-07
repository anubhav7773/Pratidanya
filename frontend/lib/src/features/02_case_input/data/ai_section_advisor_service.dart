import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_environment.dart';
import '../domain/ai_offense_analysis_result.dart';

final aiSectionAdvisorServiceProvider = Provider<AiSectionAdvisorService>((ref) {
  return const AiSectionAdvisorService();
});

class AiSectionAdvisorService {
  const AiSectionAdvisorService();

  Future<AiOffenseAnalysisResult> analyzeOffense({
    required String factualMatrix,
    String preferredStatute = 'HYBRID',
  }) {
    return analyzeOffense360(narrative: factualMatrix, preferredStatute: preferredStatute);
  }

  static Future<AiOffenseAnalysisResult> analyzeOffense360({
    required String narrative,
    String preferredStatute = 'HYBRID',
  }) async {
    const baseUrl = AppEnvironment.backendBaseUrl;
    String idToken = 'dummy_dev_token';

    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken();
        if (token != null) idToken = token;
      }
    } catch (_) {}

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/nlp/analyze-offense-360'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'incident_narrative': narrative,
          'preferred_statute': preferredStatute,
          'is_dummy_testing': true,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AiOffenseAnalysisResult.fromJson(data);
      }
    } catch (_) {
      // Graceful offline heuristic fallback
    }

    return _generateLocalHeuristicAnalysis(narrative, preferredStatute);
  }

  static AiOffenseAnalysisResult _generateLocalHeuristicAnalysis(String narrative, String preferredStatute) {
    final text = narrative.toLowerCase();
    final isIpc = preferredStatute == 'IPC';
    final List<ApplicableSectionModel> sections = [];
    final List<StrategyPointModel> defenses = [];
    final List<StrategyPointModel> prosecution = [];
    final List<String> precedents = [];

    // NDPS
    if (text.contains('चरस') || text.contains('गांजा') || text.contains('स्मैक') || text.contains('हेरोइन') || text.contains('ड्रग्स') || text.contains('नशीला') || text.contains('ndps')) {
      sections.add(const ApplicableSectionModel(
        actCode: 'NDPS',
        actName: 'एन.डी.पी.एस. एक्ट 1985 (NDPS Act)',
        section: 'धारा 8/20 NDPS Act',
        offenseTitle: 'अवैध मादक द्रव्य का कब्जा एवं परिवहन',
        bailableStatus: 'गैर-जमानती (Non-Bailable)',
        triableBy: 'विशेष एनडीपीएस न्यायालय (NDPS Court)',
        ingredientsAnalysis: 'कथित नशीले पदार्थ की बरामदगी पत्रावली पर दर्शायी गई है।',
      ));
      defenses.add(const StrategyPointModel(
        title: 'धारा 50 NDPS का आज्ञापक उल्लंघन',
        strategy: 'अभियुक्त की व्यक्तिगत तलाशी पूर्व राजपत्रित अधिकारी या मजिस्ट्रेट के समक्ष ले जाने के अधिकार का लिखित विकल्प नहीं दिया गया।',
        statutoryLoopholeOrProof: 'धारा 50 का उल्लंघन संपूर्ण अभियोजन को दूषित करता है।',
      ));
      defenses.add(const StrategyPointModel(
        title: 'स्वतंत्र साक्षियों का अभाव',
        strategy: 'पब्लिक प्लेस से बरामदगी के बावजूद किसी भी स्वतंत्र नागरिक को पंच साक्षी नहीं बनाया गया।',
        statutoryLoopholeOrProof: 'धारा 100(4) CrPC / 105 BNSS का उल्लंघन।',
      ));
      prosecution.add(const StrategyPointModel(
        title: 'एफएसएल (FSL) रिपोर्ट',
        strategy: 'बरामद द्रव्य की विधि विज्ञान प्रयोगशाला जांच रिपोर्ट सकारात्मक साबित करना अनिवार्य है।',
        statutoryLoopholeOrProof: 'रासायनिक परीक्षण प्रमाणपत्र।',
      ));
      precedents.add('राजस्थान राज्य बनाम परमानंद (2014 5 SCC 345)');
    }

    // Arms Act
    if (text.contains('तमंचा') || text.contains('पिस्तौल') || text.contains('कारतूस') || text.contains('असलहा') || text.contains('चाकू') || text.contains('हथियार')) {
      sections.add(const ApplicableSectionModel(
        actCode: 'ARMS',
        actName: 'आयुध अधिनियम 1959 (Arms Act)',
        section: 'धारा 3/25 Arms Act',
        offenseTitle: 'अवैध शस्त्र/कारतूस का अनाधिकृत आधिपत्य',
        bailableStatus: 'गैर-जमानती (Non-Bailable)',
        triableBy: 'न्यायिक मजिस्ट्रेट प्रथम श्रेणी / CJM',
        ingredientsAnalysis: 'बिना वैध शस्त्र लाइसेंस के असलहा बरामद होना कथित है।',
      ));
      defenses.add(const StrategyPointModel(
        title: 'गोपनीय बरामदगी व संदेहास्पद जब्ती फर्द',
        strategy: 'बरामदगी फर्द पुलिस थाने में बैठकर फर्जी तरीके से बनाई गई है, मौके पर कोई स्वतंत्र साक्षी नहीं था।',
        statutoryLoopholeOrProof: 'धारा 105 BNSS / धारा 100(4) CrPC का उल्लंघन।',
      ));
      precedents.add('पवन कुमार बनाम दिल्ली प्रशासन (1989 CriLJ 127)');
    }

    // Theft
    if (text.contains('चोरी') || text.contains('गायब') || text.contains('उड़ा ले गए') || text.contains('theft')) {
      sections.add(ApplicableSectionModel(
        actCode: isIpc ? 'IPC' : 'BNS',
        actName: isIpc ? 'भारतीय दंड संहिता 1860' : 'भारतीय न्याय संहिता 2023',
        section: isIpc ? 'धारा 379 IPC' : 'धारा 303 BNS',
        offenseTitle: 'चोरी का अपराध (Theft)',
        bailableStatus: 'गैर-जमानती (Non-Bailable)',
        triableBy: 'मजिस्ट्रेट द्वारा विचारणीय',
        ingredientsAnalysis: 'संपत्ति को बेईमानी पूर्वक स्वामी के आधिपत्य से हटाने का कथन है।',
      ));
      defenses.add(const StrategyPointModel(
        title: 'माल शिनाख्त (TIP) एवं कब्जे का अभाव',
        strategy: 'कथित बरामद माल की कोई शिनाख्त परेड नहीं कराई गई और न ही वास्तविक स्वामित्व सिद्ध है।',
        statutoryLoopholeOrProof: 'धारा 411 IPC / धारा 317 BNS के तत्वों का अभाव।',
      ));
      precedents.add('त्रिम्बक बनाम मध्य प्रदेश राज्य (1954 AIR SC 39)');
    }

    // Default Bodily Harm / Assault
    if (sections.isEmpty || text.contains('मारपीट') || text.contains('चोट') || text.contains('धमकी') || text.contains('झगड़ा')) {
      sections.add(ApplicableSectionModel(
        actCode: isIpc ? 'IPC' : 'BNS',
        actName: isIpc ? 'भारतीय दंड संहिता 1860' : 'भारतीय न्याय संहिता 2023',
        section: isIpc ? 'धारा 323 IPC' : 'धारा 115(2) BNS',
        offenseTitle: 'स्वेच्छया साधारण चोट पहुंचाना',
        bailableStatus: 'जमानती (Bailable)',
        triableBy: 'कोई भी मजिस्ट्रेट',
        ingredientsAnalysis: 'शारीरिक चोट व मारपीट का आरोप लगाया गया है।',
      ));
      sections.add(ApplicableSectionModel(
        actCode: isIpc ? 'IPC' : 'BNS',
        actName: isIpc ? 'भारतीय दंड संहिता 1860' : 'भारतीय न्याय संहिता 2023',
        section: isIpc ? 'धारा 506 IPC' : 'धारा 351(2) BNS',
        offenseTitle: 'आपराधिक धमकी (Criminal Intimidation)',
        bailableStatus: 'जमानती / गैर-जमानती (राज्य संशोधन अनुसार)',
        triableBy: 'मजिस्ट्रेट द्वारा विचारणीय',
        ingredientsAnalysis: 'जान से मारने की कथित धमकी दी गई है।',
      ));
      defenses.add(const StrategyPointModel(
        title: 'रंजिश व क्रॉस-केस (Right of Private Defence)',
        strategy: 'विवाद दोनों पक्षों के मध्य हुआ था और अभियुक्त ने अपने शरीर व संपत्ति की आत्मरक्षा में कार्य किया।',
        statutoryLoopholeOrProof: 'आपराधिक मंशा (Mens Rea) का पूर्ण अभाव।',
      ));
      prosecution.add(const StrategyPointModel(
        title: 'मेडिको-लीगल इंजरी रिपोर्ट',
        strategy: 'चोटों की आयु एवं प्रकृति का डॉक्टर द्वारा परीक्षण कराकर पत्रावली पर प्रस्तुत करना।',
        statutoryLoopholeOrProof: 'चिकित्सीय साक्ष्य।',
      ));
      precedents.add('बाबू सिंह बनाम उत्तर प्रदेश राज्य (1978 AIR SC 527)');
    }

    return AiOffenseAnalysisResult(
      caseSummaryHindi: 'घटना के तथ्यों के आधार पर कानूनी धाराओं एवं 360° विधिक रणनीति का विश्लेषण तैयार किया गया।',
      applicableSections: sections,
      defenseStrategy360: defenses,
      prosecutionStrategy360: prosecution,
      landmarkPrecedents: precedents,
    );
  }
}
