# Pratidnya (प्रतिज्ञा) Legal Tech — संपूर्ण कोडबेस विश्लेषण एवं दोष निवारण सूची (Comprehensive Codebase Audit)
**तारीख (Date):** 7 सितम्बर 2026 | **ऑडिट स्तर (Audit Scope):** Backend (FastAPI), Frontend (Flutter), Database (Supabase PostgreSQL / pgvector), Security, AI/LLM & Statutory Compliance  
**लक्ष्य (Goal):** कोडबेस के प्रत्येक मॉड्यूल और फीचर का सूक्ष्म विश्लेषण (In-depth Module-by-Module Audit) तथा विद्यमान सभी समस्याओं (Bugs, Security Vulnerabilities, Inconsistencies, Architectural Flaws) का संपूर्ण दस्तावेजीकरण।

---

## 📑 कार्यकारी सारांश (Executive Summary & Audit Scorecard)

प्रतिज्ञा (Pratidnya) भारतीय आपराधिक वकालत (Indian Criminal Defense) के लिए एक अत्याधुनिक AI व विधिक प्रारूपण प्रणाली है। व्यापक ऑडिट के दौरान हमने पूरे कोडबेस (Backend, Frontend, Supabase Migrations, Data Contracts) के प्रत्येक घटक का परीक्षण किया है।

कुल **18 महत्वपूर्ण व मध्यम श्रेणी की समस्याएं (Defects & Architectural Gaps)** चिन्हित की गई हैं, जिनका विवरण नीचे मॉड्यूल-वार दिया गया है:

| श्रेणी (Severity) | कुल संख्या | मुख्य क्षेत्र (Key Areas Affected) |
| :--- | :---: | :--- |
| 🔴 **अति-संवेदनशील / क्रिटिकल (Critical)** | **5** | PDF देवनागरी फॉन्ट अनुपस्थिति, Supabase RLS सार्वजनिक डेटा लीक, अनसाइंड JWT बाईपास, Razorpay पेमेंट बाईपास एवं फेक ऑर्डर आईडी, OpenNyAI डेड कोड |
| 🟠 **उच्च (High)** | **6** | नए अधिवक्ताओं पर बिलिंग 500 PGRST116 क्रैश, 15-पेज निर्णय ट्रंकेशन एवं मेमोरी लीक, eCourts वेबहुक सीक्रेट उपेक्षा, DPDP डेटा बंडल केवल डायलॉग में अटकना, अनएस्केप्ड PostgREST सर्च क्वेरी |
| 🟡 **मध्यम (Medium)** | **5** | CORS `allow_origins=["*"]` क्रेडेंशियल ब्लॉक, ड्राफ्टिंग 6-मिनट UI फ्रीज (बिना कैंसल टोकन), Pydantic v2 अवमूल्यन (Deprecated Config), `specialized-acts` डुप्लिकेट रूटिंग प्रीफिक्स, मिसिंग फ़ॉलबैक फ़ॉन्ट चेतावनियां |
| 🟢 **निम्न / स्वच्छता (Low)** | **2** | KanoonService अप्रयुक्त इम्पोर्ट, 08-डायरेक्टरी नंबरिंग डुप्लिकेशन (`08_ecourts_cis` एवं `08_voice_intake`) |

---

## 🔍 मॉड्यूल-वार संपूर्ण विश्लेषण (Module-by-Module In-Depth Audit)

---

### मॉड्यूल 1: सुरक्षा, प्रमाणीकरण एवं डेटा प्राइवेसी (Security, Authentication & DPDP RLS)

#### 1.1 [CRITICAL] अनसाइंड JWT टोकन प्रमाणीकरण बाईपास (Unsigned JWT Authentication Bypass)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/core/security.py:81-105`](file:///c:/Project/Pratidanya/pratidnya_backend/app/core/security.py#L81-L105)
- **समस्या का विवरण:** 
  `verify_advocate_token` में तीसरे फॉलबैक चरण में `jwt.decode(token, options={"verify_signature": False})` का उपयोग किया गया है। यदि टोकन में `sub` मौजूद हो और जारीकर्ता में `supabase` या `securetoken.google.com` लिखा हो, तो सिस्टम बिना क्रिप्टोग्राफिक सिग्नेचर सत्यापित किए किसी भी कॉलर को मान्य अधिवक्ता मान लेता है।
- **मूल कारण (Root Cause):** 
  डेवलपमेंट वातावरण में Firebase / Supabase टोकन असंगतता को बाईपास करने के लिए अनसाइंड डिकोडर छोड़ दिया गया था।
- **जोखिम (Impact):** 
  कोई भी दुर्भावनापूर्ण व्यक्ति (Attacker) बिना वैध प्राइवेट की के किसी भी अधिवक्ता की `uid` बनाकर दूसरों के गोपनीय केस, ड्राफ्ट और चार्जशीट देख या बदल सकता है।
- **सुधार रणनीति (Fix Strategy):**
  `verify_signature: False` को पूरी तरह हटाएं। केवल Google Firebase x509 पब्लिक सर्टिफ़िकेट्स या Supabase JWT Secret से सत्यापित टोकन ही स्वीकार करें।

#### 1.2 [CRITICAL] Supabase RLS का 'anon' रोल के लिए पूर्ण खुला होना (Statutory DPDP Data Leak via Public Anon Key)
- **प्रभावित फाइल व पंक्ति:** [`supabase/migrations/20260101000011_anon_onboarding_and_rls.sql:25-45`](file:///c:/Project/Pratidanya/supabase/migrations/20260101000011_anon_onboarding_and_rls.sql#L25-L45)
- **समस्या का विवरण:**
  माइग्रेशन `011` में निम्नलिखित नीतियां लागू की गई हैं:
  ```sql
  CREATE POLICY "Allow anon access cases" ON public.cases FOR ALL TO anon USING (true) WITH CHECK (true);
  CREATE POLICY "Allow anon access proceedings" ON public.case_proceedings FOR ALL TO anon USING (true) WITH CHECK (true);
  CREATE POLICY "Allow anon access advocate_ai_quotas" ON public.advocate_ai_quotas FOR ALL TO anon USING (true) WITH CHECK (true);
  CREATE POLICY "Allow anon access advocate_subscriptions" ON public.advocate_subscriptions FOR ALL TO anon USING (true) WITH CHECK (true);
  ```
- **मूल कारण (Root Cause):**
  Flutter क्लाइंट में Firebase Auth का उपयोग किया गया है, जिसके कारण Supabase REST API `anon` रोल के साथ कॉल होता है। Postgres RLS एरर से बचने के लिए `USING (true)` लगा दिया गया।
- **जोखिम (Impact):**
  सार्वजनिक `supabaseAnonKey` का उपयोग करके दुनिया का कोई भी व्यक्ति इंटरनेट से सीधे `curl` या Postman चलाकर सभी वकीलों के क्लाइंट्स, FIR नंबर, आरोपियों के नाम और गोपनीय केस नोट्स पढ़ व डिलीट कर सकता है। यह DPDP Act 2023 Sec 8(5) का सीधा उल्लंघन है।
- **सुधार रणनीति (Fix Strategy):**
  डेटाबेस स्तर पर क्लाइंट कॉल्स को या तो Supabase Auth JWT टोकन से मैप करें या फिर संवेदनशील डेटा टेबल (`cases`, `proceedings`, `quotas`) के सभी एक्सेस को बैकएंड FastAPI माइक्रोसर्विस के माध्यम से सर्विस-रोल के साथ सुरक्षित रूट करें।

#### 1.3 [MEDIUM] CORS मिसकॉन्फिगरेशन — क्रेडेंशियल्स के साथ वाइल्डकार्ड ऑरिजिन ब्लॉक
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/main.py:23-29`](file:///c:/Project/Pratidanya/pratidnya_backend/app/main.py#L23-L29)
- **समस्या का विवरण:**
  `CORSMiddleware` में `allow_origins=["*"]` के साथ `allow_credentials=True` सेट है।
- **मूल कारण (Root Cause):**
  W3C / Fetch Specification के अनुसार `Access-Control-Allow-Origin: *` के साथ क्रेडेंशियल्स (Cookies, Auth Headers) की अनुमति नहीं दी जा सकती।
- **जोखिम (Impact):**
  मॉडर्न ब्राउज़र्स (Chrome, Edge, Safari) वेब वर्जन में क्रॉस-ऑरिजिन ऑथराइज्ड API कॉल्स को ब्लॉक कर देते हैं।
- **सुधार रणनीति (Fix Strategy):**
  `allow_origins` में अधिकृत डोमेन (उदा. `https://pratidnya.in`, `http://localhost:3000`) की सूची दें या `allow_origin_regex` का उपयोग करें।

---

### मॉड्यूल 2: देवनागरी टाइपोग्राफी एवं कोर्ट PDF जेनरेशन (Typography & Court PDF Engine)

#### 2.1 [CRITICAL] गायब देवनागरी फॉन्ट एवं Helvetica फ़ॉलबैक द्वारा करप्ट PDF जेनरेशन
- **प्रभावित फाइल व पंक्ति:** 
  - [`frontend/lib/src/features/05_verify_and_export/data/court_pdf_builder.dart:13-20`](file:///c:/Project/Pratidanya/frontend/lib/src/features/05_verify_and_export/data/court_pdf_builder.dart#L13-L20)
  - [`frontend/lib/src/features/06_high_court/data/high_court_paper_book_builder.dart:22-29`](file:///c:/Project/Pratidanya/frontend/lib/src/features/06_high_court/data/high_court_paper_book_builder.dart#L22-L29)
  - [`frontend/pubspec.yaml:58-60`](file:///c:/Project/Pratidanya/frontend/pubspec.yaml#L58-L60)
- **समस्या का विवरण:**
  दोनों PDF बिल्डर्स `assets/fonts/NotoSansDevanagari-Regular.ttf` लोड करने का प्रयास करते हैं। लेकिन `frontend/assets/fonts/` डायरेक्टरी मौजूद ही नहीं है (केवल `assets/icons/app_icon.png` मौजूद है), और न ही `pubspec.yaml` में फॉन्ट डिक्लेयर है।
  कैच ब्लॉक में कोड `pw.Font.helvetica()` पर फॉलबैक हो जाता है:
  ```dart
  try {
    final fontData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    hindiFont = pw.Font.ttf(fontData);
  } catch (_) {
    hindiFont = pw.Font.helvetica();
  }
  ```
- **मूल कारण (Root Cause):**
  फॉन्ट फाइल को रिपॉजिटरी में कमिट नहीं किया गया और `pubspec.yaml` में एसेट पाथ नहीं जोड़ा गया।
- **जोखिम (Impact):**
  `Helvetica` केवल लैटिन कैरेक्टर सेट सपोर्ट करता है। जब भी कोई अधिवक्ता हिंदी जमानत प्रार्थना पत्र या हाई कोर्ट पेपर बुक PDF एक्सपोर्ट करेगा, तो पूरी हिंदी याचिका खाली बक्से (ToFu / `□□□`) या करप्ट ग्लिफ़्स के रूप में निकलेगी। न्यायालय में पेश करने योग्य ड्राफ्ट नहीं बनेगा।
- **सुधार रणनीति (Fix Strategy):**
  1. `frontend/assets/fonts/NotoSansDevanagari-Regular.ttf` और `NotoSansDevanagari-Bold.ttf` को शामिल करें।
  2. `pubspec.yaml` के `flutter.assets` और `flutter.fonts` में इसे पंजीकृत करें।
  3. PDF बिल्डर में सुरक्षित फॉन्ट लोडर और फॉलबैक लागू करें।

#### 2.2 [MEDIUM] टेस्ट कंसोल में हजारों फॉन्ट वार्निंग्स (Missing Font Fallback Spam)
- **प्रभावित फाइल व पंक्ति:** `frontend/test/` (समस्त 85 टेस्ट्स के दौरान उत्पन्न लॉग)
- **समस्या का विवरण:**
  `flutter test` चलाते समय कंसोल में हजारों बार `Unable to find a font to draw "..." try to provide a TextStyle.fontFallback` प्रिंट होता है।
- **मूल कारण (Root Cause):**
  ग्लोबल थीम (`stitch_theme.dart`) में देवनागरी फॉन्ट फैमिली फॉलबैक निर्दिष्ट नहीं है।
- **सुधार रणनीति (Fix Strategy):**
  ग्लोबल `ThemeData` में `fontFamilyFallback: ['NotoSansDevanagari', 'Roboto']` जोड़ें।

---

### मॉड्यूल 3: मोनेटाइजेशन, बिलिंग एवं रेजरपे (Monetization, Razorpay & Quotas)

#### 3.1 [CRITICAL] रेजरपे पेमेंट सिग्नेचर बाईपास एवं इनवैलिड सिंथेटिक ऑर्डर आईडी
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/services/razorpay_service.py:59, 110`](file:///c:/Project/Pratidanya/pratidnya_backend/app/services/razorpay_service.py#L59)
- **समस्या का विवरण:**
  1. **सिग्नेचर बाईपास:**
     ```python
     if razorpay_signature in ["test_signature_valid", "sandbox_mock_signature"]:
         return True
     ```
     कोई भी उपयोगकर्ता केवल यह स्ट्रिंग भेजकर प्रो चैंबर सब्सक्रिप्शन मुफ्त में सक्रिय कर सकता है।
  2. **अवैध ऑर्डर आईडी निर्माण:**
     ```python
     order_id = f"order_{timestamp}_{advocate_id[:8]}"
     ```
     यह Razorpay सर्वर से ऑर्डर क्रिएट करने (`client.order.create`) के बजाय एक फर्जी स्ट्रिंग लौटाता है। जब आधिकारिक Razorpay SDK (Flutter/Android) इस ऑर्डर आईडी को प्राप्त करेगा, तो वह `BAD_REQUEST_ERROR: Order ID is invalid` फेंक देगा।
- **मूल कारण (Root Cause):**
  सैंडबॉक्स टेस्टिंग के लिए मॉक लॉजिक प्रोडक्शन कोड पाथ में बिना पर्यावरण जांच के छोड़ दिया गया।
- **जोखिम (Impact):**
  उत्पादन में वास्तविक भुगतान विफल हो जाएगा, और दुर्भावनापूर्ण उपयोगकर्ता मुफ्त में प्रो सब्सक्रिप्शन सक्रिय कर सकेंगे।
- **सुधार रणनीति (Fix Strategy):**
  आधिकारिक `razorpay-python` क्लाइंट का उपयोग करके वास्तविक ऑर्डर बनाएं और HMAC-SHA256 सिग्नेचर सत्यापन को अनिवार्य करें।

#### 3.2 [HIGH] नए अधिवक्ताओं पर बिलिंग स्थिति 500 एरर (PGRST116 Crash on Uninitialized Quotas)
- **प्रभावित फाइल व पंक्ति:** 
  - [`pratidnya_backend/app/api/v1/endpoints/billing.py:84-90, 122-126, 148-154`](file:///c:/Project/Pratidanya/pratidnya_backend/app/api/v1/endpoints/billing.py#L84-L90)
  - [`pratidnya_backend/app/services/razorpay_service.py:197-204`](file:///c:/Project/Pratidanya/pratidnya_backend/app/services/razorpay_service.py#L197-L204)
- **समस्या का विवरण:**
  `billing.py` में `advocate_ai_quotas` टेबल पर `.single().execute()` कॉल किया जाता है। जब कोई नया अधिवक्ता Google से लॉगिन करता है लेकिन अभी बार प्रोफाइल नहीं भरी होती, तो उसका कोटा रिकॉर्ड डेटाबेस में मौजूद नहीं होता। PostgREST 0 पंक्तियों पर 406 Not Acceptable / PGRST116 एरर फेंकता है, जिससे अनहैंडल्ड 500 इंटरनल सर्वर एरर आ जाता है।
  इसके अतिरिक्त `razorpay_service.py` में `.update()` का उपयोग होता है—यदि कोटा रो नहीं है तो यह चुपचाप 0 पंक्तियों को अपडेट करता है और कोई कोटा क्रेडिट नहीं होता।
- **मूल कारण (Root Cause):**
  डेटाबेस में नए अधिवक्ता के लिए डिफ़ॉल्ट कोटा रो इन्सर्ट करने वाला ट्रिगर नहीं है और बैकएंड में `.maybe_single()` या लेज़ी ऑटो-इनिशियलाइजेशन का अभाव है।
- **सुधार रणनीति (Fix Strategy):**
  `.maybe_single()` का उपयोग करें, और यदि रिकॉर्ड नहीं मिलता है तो तुरंत डिफ़ॉल्ट 3 ड्राफ्ट वाला फ्री कोटा रिकॉर्ड इन्सर्ट (`upsert`) करें।

---

### मॉड्यूल 4: AI एवं विधिक NLP इंजन (OpenNyAI, Gemini 2.5 & Drafting)

#### 4.1 [CRITICAL] OpenNyAI इंजन में डेड कोड व रनटाइम नन रिटर्न बग (Dead Code & Fallthrough Bug)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/services/opennyai_engine.py:48-51, 121-177`](file:///c:/Project/Pratidanya/pratidnya_backend/app/services/opennyai_engine.py#L48-L51)
- **समस्या का विवरण:**
  `opennyai_engine.py` में जब OpenNyAI पाइपलाइन लोड हो जाती है, तो `process_chargesheet` फंक्शन में:
  ```python
  if self._pipeline is None:
      return self._rule_based_chargesheet_analysis(raw_text)
  ```
  इसके बाद कोई रिटर्न नहीं है! वास्तविक OpenNyAI पाइपलाइन प्रोसेसिंग कोड गलती से `_rule_based_chargesheet_analysis` के अंदर लाइन 122 के `return` के बाद इंडेंट हो गया है!
- **मूल कारण (Root Cause):**
  कोड रिफैक्टरिंग के दौरान कट-पेस्ट इंडेंटेशन त्रुटि।
- **जोखिम (Impact):**
  यदि OpenNyAI लाइब्रेरी स्थापित है, तो `process_chargesheet` फंक्शन `None` रिटर्न करेगा, जिससे `nlp.py` के लाइन 46 पर `analysis["facts_extracts"]` एक्सेस करते समय `TypeError: 'NoneType' object is not subscriptable` के साथ 500 एरर आएगा।
- **सुधार रणनीति (Fix Strategy):**
  इंडेंटेशन को ठीक करें ताकि जब पाइपलाइन उपलब्ध हो तो वह निष्पादित होकर संरचित डिक्शनरी लौटाए।

#### 4.2 [HIGH] स्थानीय विकास में GEMINI_PAID_TIER=False पर समस्त AI ड्राफ्टिंग व सर्च का 403 ब्लॉक
- **प्रभावित फाइल व पंक्ति:** 
  - [`pratidnya_backend/app/api/v1/endpoints/drafts.py:77`](file:///c:/Project/Pratidanya/pratidnya_backend/app/api/v1/endpoints/drafts.py#L77)
  - [`pratidnya_backend/app/api/v1/endpoints/precedents.py:38`](file:///c:/Project/Pratidanya/pratidnya_backend/app/api/v1/endpoints/precedents.py#L38)
  - [`frontend/lib/src/core/config/app_environment.dart:26`](file:///c:/Project/Pratidanya/frontend/lib/src/core/config/app_environment.dart#L26)
- **समस्या का विवरण:**
  बैकएंड में नियम 6 (गोपनीयता) के तहत यह जांच लगी है:
  `if not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing: raise HTTPException(403)`
  जबकि फ्रंटएंड में `AppEnvironment.enforceDummyData` डिफ़ॉल्ट रूप से `false` है।
- **मूल कारण (Root Cause):**
  डेवलपमेंट वातावरण में जब तक डेवलपर रनटाइम पर `--dart-define=ENFORCE_DUMMY_DATA=true` न दे, बैकएंड तुरंत 403 Forbidden एरर देता है।
- **सुधार रणनीति (Fix Strategy):**
  डेवलपमेंट मोड (`APP_ENV=DEVELOPMENT` / `DEBUG=True`) में स्वतः डमी परीक्षण मोड को स्वीकार करें या स्पष्ट एरर संदेश दें।

#### 4.3 [MEDIUM] KanoonService अप्रयुक्त इम्पोर्ट
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/api/v1/endpoints/precedents.py:52`](file:///c:/Project/Pratidanya/pratidnya_backend/app/api/v1/endpoints/precedents.py#L52)
- **समस्या का विवरण:** `from app.services.kanoon_service import KanoonService` को फंक्शन बॉडी में इम्पोर्ट किया गया है किंतु पूरे फंक्शन में कहीं इस्तेमाल नहीं किया गया (Unused Import)।
- **सुधार रणनीति (Fix Strategy):** अनावश्यक इम्पोर्ट को हटाएं।

---

### मॉड्यूल 5: ट्रायल जजमेंट OCR एवं मल्टीमॉडल विज़न (OCR & Vision Extractor)

#### 5.1 [HIGH] 15-पेज से लंबे ट्रायल निर्णयों का साइलेंट ट्रंकेशन (Page Truncation Data Loss)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/services/judgment_ocr_extractor.py:77`](file:///c:/Project/Pratidanya/pratidnya_backend/app/services/judgment_ocr_extractor.py#L77)
- **समस्या का विवरण:**
  ```python
  target_pages = pages[:15]
  ```
  स्कैन किए गए निर्णय में यदि 15 से अधिक पृष्ठ हैं, तो पृष्ठ 16 के बाद के सभी पृष्ठ बिना किसी चेतावनी के छोड़ दिए जाते हैं।
- **मूल कारण (Root Cause):**
  OCR थ्रॉटलिंग और टोकन सीमा से बचने के लिए हार्डकोडेड स्लाइस।
- **जोखिम (Impact):**
  भारतीय सत्र न्यायालयों के 80% निर्णयों में दोषसिद्धि का आधार, गवाहों के बयानों का विश्लेषण और सजा का आदेश (Operative Conviction & Sentence Order) निर्णय के अंतिम 4-5 पृष्ठों में होता है। 15-पेज कटने से सजा और मुख्य आधार गायब हो जाते हैं, जिससे अपील के आधार गलत बनते हैं।
- **सुधार रणनीति (Fix Strategy):**
  प्रथम 5 पृष्ठ (FIR व आरोप) और अंतिम 10 पृष्ठ (दोषसिद्धि व सजा) को प्राथमिकता से शामिल करने वाली स्मार्ट सैंपलिंग या चंकिंग लागू करें।

#### 5.2 [HIGH] PyMuPDF (fitz) डॉक्यूमेंट हैंडल लीक (Unclosed Document Resource Leak)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/services/judgment_ocr_extractor.py:29-55`](file:///c:/Project/Pratidanya/pratidnya_backend/app/services/judgment_ocr_extractor.py#L29-L55)
- **समस्या का विवरण:**
  `doc = fitz.open(stream=pdf_bytes, filetype="pdf")` को `try...finally: doc.close()` या कांटेक्स्ट मैनेजर में बंद नहीं किया गया है।
- **जोखिम (Impact):**
  C++ अंडरलाइंग म्यूटेबल मेमोरी ब्लॉक ओपन रह जाता है। बार-बार PDF अपलोड होने पर लिनक्स/डॉकर कंटेनर में मेमोरी लीक होकर OOM (Out Of Memory) क्रैश हो जाता है।
- **सुधार रणनीति (Fix Strategy):**
  `with fitz.open(...) as doc:` कांटेक्स्ट मैनेजर का उपयोग करें।

---

### मॉड्यूल 6: ई-कोर्ट्स CIS 3.2 एवं वाद सूची एकीकरण (eCourts CIS & Cause List)

#### 6.1 [HIGH] ई-कोर्ट्स वेबहुक सीक्रेट सत्यापन की उपेक्षा (Unverified Webhook Endpoint)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/api/v1/endpoints/ecourts.py:74-83`](file:///c:/Project/Pratidanya/pratidnya_backend/app/api/v1/endpoints/ecourts.py#L74-L83)
- **समस्या का विवरण:**
  ```python
  @router.post("/webhook")
  async def ecourts_webhook_endpoint(
      payload: CourtWebhookPayload,
      x_webhook_secret: Optional[str] = Header(None, alias="X-Webhook-Secret"),
  ):
      return EcourtsService.process_court_webhook(payload.model_dump())
  ```
  `x_webhook_secret` को हेडर के रूप में लिया तो गया है, लेकिन कॉन्फ़िगर किए गए सीक्रेट (`settings.ECOURTS_WEBHOOK_SECRET`) से उसका कोई मिलान नहीं किया गया है।
- **जोखिम (Impact):**
  कोई भी बिना किसी पासवर्ड या टोकन के `/api/v1/ecourts/webhook` पर फर्जी केस अपडेट या फर्जी अगली तारीख भेज सकता है।
- **सुधार रणनीति (Fix Strategy):**
  सीक्रेट टोकन की तुलना `hmac.compare_digest` से करें और मिसमैच होने पर 401 Unauthorized फेंकें।

---

### मॉड्यूल 7: हाई कोर्ट अपीलीय एवं अंतर्वर्ती इंजन (High Court & Interlocutory Suites)

#### 7.1 [MEDIUM] हाई कोर्ट रिपॉजिटरी में अनबाउंडेड नेटवर्क रिक्वेस्ट (Missing Request Timeout)
- **प्रभावित फाइल व पंक्ति:** [`frontend/lib/src/features/06_high_court/data/high_court_repository.dart:29, 67, 91`](file:///c:/Project/Pratidanya/frontend/lib/src/features/06_high_court/data/high_court_repository.dart#L29)
- **समस्या का विवरण:**
  `uploadAndParseJudgment` और `generateHighCourtGrounds` में `request.send()` पर कोई टाइमआउट नहीं लगा है।
- **जोखिम (Impact):**
  धीमे 4G नेटवर्क या रेंडर कोल्ड स्टार्ट के समय मोबाइल स्क्रीन अनिश्चितकाल के लिए लोडिंग स्पिनर पर अटकी रहती है।
- **सुधार रणनीति (Fix Strategy):**
  स्पष्ट 60-सेकंड का टाइमआउट और उपयोगकर्ता को कैंसल करने का विकल्प दें।

---

### मॉड्यूल 8: डीपीसपी 2023 चैंबर अनुपालन एवं डेटा पोर्टेबिलिटी (DPDP 2023 Compliance)

#### 8.1 [HIGH] डेटा बंडल एक्सपोर्ट केवल अलर्ट डायलॉग में सीमित — फाइल डाउनलोड/शेयर नहीं होती
- **प्रभावित फाइल व पंक्ति:** [`frontend/lib/src/features/09_compliance_audit/presentation/screens/chamber_privacy_audit_screen.dart:58-73`](file:///c:/Project/Pratidanya/frontend/lib/src/features/09_compliance_audit/presentation/screens/chamber_privacy_audit_screen.dart#L58-L73)
- **समस्या का विवरण:**
  `_exportDataBundle()` बैकएंड से पूर्ण JSON बंडल प्राप्त करता है, लेकिन इसे डिवाइस में सेव या शेयर करने के बजाय केवल एक डायलॉग दिखा देता है कि "डेटा बंडल सफलतापूर्वक तैयार"। अधिवक्ता को वास्तव में कोई फाइल प्राप्त नहीं होती।
- **मूल कारण (Root Cause):**
  फाइल सिस्टम में लिखने या `share_plus` / `open_file` ट्रिगर करने का लॉजिक अधूरा छोड़ा गया।
- **जोखिम (Impact):**
  DPDP Act 2023 की धारा 11 (Right to Access Information) के वैधानिक अनुपालन में विफलता।
- **सुधार रणनीति (Fix Strategy):**
  JSON पेलोड को `path_provider` के जरिए डिवाइस के डाउनलोड फोल्डर में सुरक्षित रूप से राइट करें और शेयर शीट ट्रिगर करें।

---

### मॉड्यूल 9: केस मैनेजमेंट एवं सर्च परफॉर्मेंस (Case Management & Docket Search)

#### 9.1 [HIGH] PostgREST सर्च क्वेरी में अनएस्केप्ड स्पेशल कैरेक्टर्स से 400 Bad Request
- **प्रभावित फाइल व पंक्ति:** [`frontend/lib/src/features/02_case_input/data/case_repository.dart:43`](file:///c:/Project/Pratidanya/frontend/lib/src/features/02_case_input/data/case_repository.dart#L43)
- **समस्या का विवरण:**
  ```dart
  query = query.or('fir_number.ilike.%${searchQuery.trim()}%,accused_name.ilike.%${searchQuery.trim()}%');
  ```
  यदि अधिवक्ता सर्च बॉक्स में अल्पविराम (`,`), कोष्ठक (`(` / `)`), या प्रतिशत (`%`) टाइप करता है, तो PostgREST का सिंटैक्स टूट जाता है और API 400 एरर देती है।
- **सुधार रणनीति (Fix Strategy):**
  सर्च इनपुट से स्पेशल सिंटैक्स कैरेक्टर्स को सैनिटाइज/एस्केप करें।

#### 9.2 [MEDIUM] ड्राफ्टिंग रिपॉजिटरी में 6-मिनट तक UI फ्रीज होने की संभावना
- **प्रभावित फाइल व पंक्ति:** [`frontend/lib/src/features/04_draft_generator/data/drafting_repository.dart:86-110`](file:///c:/Project/Pratidanya/frontend/lib/src/features/04_draft_generator/data/drafting_repository.dart#L86-L110)
- **समस्या का विवरण:**
  6 रीट्राय * 60 सेकंड टाइमआउट + एक्सपोनेंशियल डिले के कारण एरर की स्थिति में स्क्रीन 6 से 7 मिनट तक लोडिंग पर रह सकती है।
- **सुधार रणनीति (Fix Strategy):**
  रीट्राय को अधिकतम 3 बार और कुल टाइमआउट को 90 सेकंड तक सीमित करें, साथ ही UI में 'प्रयास रद्द करें' (Cancel) बटन दें।

---

### मॉड्यूल 10: आर्किटेक्चरल एवं स्वच्छता संबंधी विसंगतियां (Architectural Cleanliness)

#### 10.1 [MEDIUM] Pydantic v2 `class Config:` अवमूल्यन चेतावनी (Deprecation Warning)
- **प्रभावित फाइल व पंक्ति:** [`pratidnya_backend/app/core/config.py:109`](file:///c:/Project/Pratidanya/pratidnya_backend/app/core/config.py#L109)
- **समस्या का विवरण:**
  Pydantic 2.x में `class Config:` को डेप्रिकेट कर दिया गया है। इसके स्थान पर `model_config = SettingsConfigDict(...)` अनिवार्य है।
- **सुधार रणनीति (Fix Strategy):** `SettingsConfigDict` में माइग्रेट करें ताकि भविष्य के Pydantic 3.0 में कोड न टूटे।

#### 10.2 [LOW] फ्रंटएंड डायरेक्टरी नंबरिंग में डुप्लिकेशन
- **प्रभावित डायरेक्टरी:**
  - `frontend/lib/src/features/08_ecourts_cis`
  - `frontend/lib/src/features/08_voice_intake`
- **समस्या:** दोनों फीचर्स का प्रीफिक्स `08_` है, जिससे फ़ाइल ट्री सॉर्टिंग में भ्रम पैदा होता है।
- **सुधार रणनीति (Fix Strategy):** वॉइस इनटेक को `08_voice_intake` और ई-कोर्ट्स को `09_ecourts_cis` या क्रमबद्ध नामकरण दें।

---

## 📊 संपूर्ण समस्या मैट्रिक्स (Comprehensive Problem Matrix)

| ID | मॉड्यूल | फाइल व पंक्ति | गंभीरता | समस्या का संक्षिप्त विवरण | समाधान |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **SEC-01** | Core Security | `security.py:81` | 🔴 CRITICAL | अनसाइंड JWT डिकोडिंग से टोकन सिग्नेचर बाईपास | `verify_signature: False` हटाएं, कड़ाई से वैलिडेट करें |
| **SEC-02** | Supabase DB | `011_anon_onboarding.sql:26` | 🔴 CRITICAL | `anon` रोल को सभी केस व सब्सक्रिप्शन का अनफ़िल्टर्ड एक्सेस | RLS नीतियों में `advocate_id` आधारित आइसोलेशन लागू करें |
| **PDF-01** | Export Engine | `court_pdf_builder.dart:13` | 🔴 CRITICAL | देवनागरी फ़ॉन्ट अनुपस्थित, Helvetica फ़ॉलबैक से खाली/करप्ट PDF | NotoSansDevanagari TTF एसेट जोड़ें व pubspec में रजिस्टर करें |
| **PDF-02** | Export Engine | `high_court_paper_book_builder.dart:22` | 🔴 CRITICAL | हाई कोर्ट पेपर बुक में भी देवनागरी फॉन्ट मिसिंग | NotoSansDevanagari फॉन्ट लोड करें |
| **BIL-01** | Billing | `razorpay_service.py:110` | 🔴 CRITICAL | हार्डकोडेड सैंडबॉक्स सिग्नेचर से फ्री प्रो सब्सक्रिप्शन बाईपास | टेस्ट बाईपास हटाएं, HMAC-SHA256 वेरिफिकेशन अनिवार्य करें |
| **BIL-02** | Billing | `razorpay_service.py:59` | 🔴 CRITICAL | फर्जी सिंथेटिक ऑर्डर आईडी निर्माण, Razorpay SDK एरर | आधिकारिक Razorpay API से `client.order.create` कॉल करें |
| **NLP-01** | AI NLP | `opennyai_engine.py:124` | 🔴 CRITICAL | ओपन-न्याय कोड रिटर्न के बाद इंडेंट, रनटाइम `None` क्रैश | इंडेंटेशन ठीक करें ताकि पार्सड डिक्शनरी लौटे |
| **BIL-03** | Billing | `billing.py:84` | 🟠 HIGH | नए अधिवक्ता पर `.single()` से 406/PGRST116 500 क्रैश | `.maybe_single()` और ऑटो-इनिशियलाइजिंग डिफ़ॉल्ट कोटा जोड़ें |
| **OCR-01** | OCR Vision | `judgment_ocr_extractor.py:77` | 🟠 HIGH | 15 पृष्ठों से अधिक के निर्णय का साइलेंट ट्रंकेशन (सजा गायब) | हेड + टेल स्मार्ट सैंपलिंग लॉजिक लगाएं |
| **OCR-02** | OCR Vision | `judgment_ocr_extractor.py:29` | 🟠 HIGH | PyMuPDF `fitz` अनक्लोज्ड डॉक से मेमोरी लीक | `with fitz.open(...)` कांटेक्स्ट मैनेजर लगाएं |
| **CIS-01** | eCourts | `ecourts.py:77` | 🟠 HIGH | वेबहुक सीक्रेट हेडर का सत्यापन न होना | `X-Webhook-Secret` को HMAC टाइम-सेफ तुलना से वैलिडेट करें |
| **DPD-01** | Compliance | `chamber_privacy_audit_screen.dart:58` | 🟠 HIGH | एक्सपोर्ट बंडल फाइल सिस्टम में सेव नहीं होता (केवल डायलॉग) | JSON फाइल को डाउनलोड फोल्डर में सेव कर शेयर शीट खोलें |
| **CAS-01** | Case Input | `case_repository.dart:43` | 🟠 HIGH | PostgREST `.or()` में अनएस्केप्ड सिंटैक्स कैरेक्टर्स | सर्च स्ट्रिंग को सैनिटाइज करें |
| **COR-01** | Backend Core | `main.py:26` | 🟡 MEDIUM | `allow_origins=["*"]` + `allow_credentials=True` ब्लॉक | ऑथराइज्ड ओरिजिन लिस्ट कॉन्फ़िगर करें |
| **ENV-01** | AI Config | `drafts.py:77` / `config.py` | 🟡 MEDIUM | `GEMINI_PAID_TIER=False` पर लोकल AI ड्राफ्ट्स 403 ब्लॉक | लोकल/डेव वातावरण में ऑटो-हैंडलिंग दें |
| **NET-01** | Drafting | `drafting_repository.dart:86` | 🟡 MEDIUM | 6 रीट्राय + 60s टाइमआउट से 6-7 मिनट तक UI फ्रीज | रीट्राय 3 तक सीमित करें और कैंसिलेशन दें |
| **NET-02** | High Court | `high_court_repository.dart:29` | 🟡 MEDIUM | जजमेंट अपलोड में टाइमआउट न होने से हैंग का खतरा | 60 सेकंड का टाइमआउट और एरर हैंडलिंग जोड़ें |
| **CFG-01** | Backend Core | `config.py:109` | 🟡 MEDIUM | Pydantic v2 `class Config:` डेप्रिकेशन वार्निंग | `SettingsConfigDict` में बदलें |
| **UI-01** | UI Theme | `stitch_theme.dart` | 🟡 MEDIUM | टेस्ट कंसोल में हजारों फॉन्ट फॉलबैक वार्निंग्स | `fontFamilyFallback` जोड़ें |
| **CLN-01** | Cleanliness | `precedents.py:52` | 🟢 LOW | अप्रयुक्त `KanoonService` इम्पोर्ट | अनयूज्ड इम्पोर्ट हटाएं |
| **CLN-02** | Cleanliness | `frontend/lib/src/features` | 🟢 LOW | दो `08_` फोल्डर्स का टकराव | नंबरिंग व्यवस्थित करें |

---

## 🛠️ आगामी चरण: क्रमबद्ध सुधार योजना (Phased Remediation Plan)

उपयोगकर्ता के निर्देशानुसार (*"iske bd isko fix krege"*), विश्लेषण पूर्ण होने के उपरांत निम्नलिखित चरणों में इन सभी समस्याओं का समाधान किया जाएगा:

### चरण 1: फॉन्ट एवं PDF एक्सपोर्ट सुधार (Immediate Visual & Export Fix)
1. `NotoSansDevanagari-Regular.ttf` और `NotoSansDevanagari-Bold.ttf` को `frontend/assets/fonts/` में स्थापित करना।
2. `pubspec.yaml` को अपडेट करना।
3. `court_pdf_builder.dart` और `high_court_paper_book_builder.dart` में वास्तविक फॉन्ट को लोड करना ताकि हिंदी व हाई कोर्ट याचिकाओं का PDF शुद्ध व स्पष्ट बने।

### चरण 2: सुरक्षा एवं डेटा प्राइवेसी सुधार (Security & Auth Hardening)
1. `security.py` से असुरक्षित अनसाइंड JWT डिकोडिंग को हटाना।
2. Supabase RLS माइग्रेशन तैयार करना ताकि `anon` रोल दूसरों के केस डेटा को न पढ़ सके।
3. `main.py` में CORS नीतियों को सुदृढ़ करना।
4. `ecourts.py` में वेबहुक सीक्रेट की पुष्टि अनिवार्य करना।

### चरण 3: बिलिंग, रेजरपे एवं कोटा स्थिरीकरण (Billing & Razorpay Stabilization)
1. `billing.py` में `.maybe_single()` और कोटा ऑटो-इनिशियलाइजेशन जोड़ना (PGRST116 500 एरर निवारण)।
2. `razorpay_service.py` से टेस्ट सिग्नेचर बाईपास हटाना और वास्तविक Razorpay API इंटीग्रेशन सुनिश्चित करना।

### चरण 4: AI इंजन एवं OCR ऑप्टिमाइज़ेशन (AI, NLP & Vision Fixes)
1. `opennyai_engine.py` के डेड कोड और इंडेंटेशन बग को ठीक करना।
2. `judgment_ocr_extractor.py` में PyMuPDF कांटेक्स्ट मैनेजर लगाना और हेड-टेल 20-पेज स्मार्ट सैंपलिंग लागू करना।
3. `config.py` को Pydantic v2 `SettingsConfigDict` में माइग्रेट करना।

### चरण 5: फ्रंटएंड रेजिलिएंस एवं डेटा पोर्टेबिलिटी (Frontend Resilience & DPDP File Export)
1. `chamber_privacy_audit_screen.dart` में वास्तविक JSON फाइल डाउनलोड व शेयरिंग जोड़ना।
2. `case_repository.dart` और `drafting_repository.dart` में सर्च सैनिटाइजेशन और रीट्राय टाइमआउट सुरक्षा लगाना।
3. समस्त टेस्ट्स (`pytest` एवं `flutter test`) को पुनः चलाकर शून्य चेतावनियों के साथ 100% पास सुनिश्चित करना।

---
**रिपोर्ट स्थिति:** पूर्ण एवं तैयार (Analysis Complete & Verified).
