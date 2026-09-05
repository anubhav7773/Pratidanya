DOC_01_FLUTTER_SETUP_REFERENCE.mdPlaintext================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-01
MODULE         : FLUTTER SYSTEM ARCHITECTURE & FOUNDATION SETUP
TARGET RUNTIME : Flutter >=3.19.0 / Dart SDK >=3.3.0 <4.0.0
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. STATE MANAGEMENT ARCHITECTURE: RIVERPOD 2.X (CODE GEN)Pratidnya mobile client ke liye flutter_riverpod (v2.5+) with riverpod_annotation standard state-management framework chuna gaya hai.Comparative Decision MatrixMetricProviderBLoC / CubitRiverpod 2.x (Code Gen) [CHOSEN]BuildContext DependencyTight coupling; widget tree context ke bina state modify ya read nahi hotiEvents/States ke dispatch ke liye context access lazmi haiZero Context Coupling: Background jobs, offline database syncing, aur auth callbacks bina context ke trigger hote hain.Async Operations (LLM / RAG)Manual isLoading, hasError, data variables track karne padte hainHeavy boilerplate classes (StateLoading, StateSuccess, StateError) har endpoint ke liye likhni padti hainAsyncValue<T> Native Pattern: Loading, Error, aur Data states compile-time safe pattern matching (when, maybeWhen) se handle hoti hain.Compile-Time SafetyRuntime ProviderNotFoundException ka risk rehta haiEvent handlers runtime par map hote hainCompile-Time Safe: Riverpod generator syntax errors aur uninitialized dependencies ko build time par hi pakad leta hai.Boilerplate & Antigravity GenerationLow boilerplate, high risk of architecture collapseExtreme boilerplate; AI code generator often forgets event mappingsOptimal: @riverpod annotation lagane se code deterministic rehta hai aur hallucination rate minimum hota hai.District Court Chamber Context RationaleDistrict courts ke bar rooms aur subordinate court chambers mein 4G/5G signal drops common hote hain. Advocate case drafts likhte waqt offline ja sakta hai. Riverpod ka global container architecture client ko internet disconnection ke dauran local cache update karne aur reconnection par automatically API state synchronize karne ki sahulat deta hai bina kisi UI freeze ke.2. PRODUCTION DEPENDENCY SPECIFICATION (pubspec.yaml)Antigravity ko bina kisi version mismatch ke strictly yahi pubspec.yaml scaffold generate karna hai. Koi speculative ya untested alpha package add nahi karna hai:YAMLname: pratidnya
description: "Hindi-First District Court Criminal Lawyer Assistant"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management & Code Generation Runtime
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Declarative Routing & Deep Linking
  go_router: ^14.2.0

  # Authentication: Firebase Spark Plan (100% Free - Zero Credit Card Required)
  firebase_core: ^2.30.0
  firebase_auth: ^4.19.4
  google_sign_in: ^6.2.1

  # Database, pgvector & Chamber Storage
  supabase_flutter: ^2.5.6

  # Typography & Hindi Script Rendering
  google_fonts: ^6.2.1

  # Secure Storage & Persistence
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3

  # Network & Communications
  http: ^1.2.1

  # Formatting & Localization
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
3. PROJECT TOPOLOGY (FEATURE-FIRST MODULAR SPECIFICATION)Antigravity ko files kisi monolithic pattern mein create nahi karni hain. Criminal law Phase-1 workflow ke mutabik ye folder taxonomy enforce ki jaani hai:Plaintextpratidnya_mobile/
├── android/
├── ios/
├── assets/
│   ├── icons/
│   │   ├── app_logo.png
│   │   └── verified_seal.png
│   └── images/
│       └── bci_emblem.png
├── lib/
│   ├── main.dart                               # Application Bootstrap Entry Point
│   ├── src/
│   │   ├── app.dart                            # MaterialApp.router Setup
│   │   │
│   │   ├── core/                               # Cross-Cutting Infrastructure
│   │   │   ├── config/
│   │   │   │   ├── app_constants.dart          # Statutes: BNS/IPC, BNSS/CrPC mappings
│   │   │   │   └── app_environment.dart        # Compile-time ENV bindings & Assertions
│   │   │   ├── network/
│   │   │   │   ├── api_client.dart             # HTTP Client with Firebase Token Interceptors
│   │   │   │   └── api_endpoints.dart          # Backend Proxy Endpoints
│   │   │   ├── router/
│   │   │   │   ├── app_router.dart             # go_router configuration
│   │   │   │   └── route_guards.dart           # Multi-stage security redirect rules
│   │   │   ├── theme/
│   │   │   │   ├── app_colors.dart             # Court-Ready Stitch Design Tokens
│   │   │   │   └── app_typography.dart         # Devanagari Line-Height & Fallback Config
│   │   │   └── utils/
│   │   │       ├── court_date_parser.dart      # Handling Subordinate Court Cause-list Dates
│   │   │       └── text_sanitizer.dart         # Hindi Input Cleaning & Normalization
│   │   │
│   │   ├── features/
│   │   │   │
│   │   │   ├── 01_onboarding/                  # Module 1: Auth & Advocate Enrollment
│   │   │   │   ├── data/
│   │   │   │   │   ├── auth_repository.dart    # Firebase Auth + Google Sign-In
│   │   │   │   │   └── profile_repository.dart # Supabase advocate_profiles CRUD
│   │   │   │   ├── domain/
│   │   │   │   │   ├── advocate_profile.dart   # Model: Bar No, Enrolled State, Court
│   │   │   │   │   └── consent_log.dart        # DPDP Section 5/6 Audit Record
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── auth_controller.dart
│   │   │   │       └── screens/
│   │   │   │           ├── login_screen.dart   # Email/Password + Google One-Tap
│   │   │   │           ├── dpdp_consent_screen.dart # Statutory Bilingual Notice
│   │   │   │           └── bar_profile_screen.dart # Bar Enrollment Validation
│   │   │   │
│   │   │   ├── 02_case_input/                  # Module 2: Criminal Case Matrix Form
│   │   │   │   ├── data/
│   │   │   │   │   └── case_repository.dart    # Supabase Postgres 'cases' table operations
│   │   │   │   ├── domain/
│   │   │   │   │   ├── criminal_case.dart      # Model: FIR, Police Station, Sections
│   │   │   │   │   └── case_stage.dart         # Enum: Bail, Remand, Framing of Charges
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── case_controller.dart
│   │   │   │       └── screens/
│   │   │   │           ├── case_list_screen.dart
│   │   │   │           └── new_case_form_screen.dart # Hindi-First Criminal Form
│   │   │   │
│   │   │   ├── 03_precedent_search/            # Module 3: Grounded Precedent Retrieval
│   │   │   │   ├── data/
│   │   │   │   │   └── precedent_repository.dart # pgvector RPC + kanoon.dev bridge
│   │   │   │   ├── domain/
│   │   │   │   │   └── precedent_citation.dart # Model: Case Title, Court, Para, URL
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── precedent_controller.dart
│   │   │   │       └── screens/
│   │   │   │           ├── precedent_search_screen.dart
│   │   │   │           └── precedent_detail_screen.dart
│   │   │   │
│   │   │   ├── 04_draft_generator/             # Module 4: 360° Bail & Defense Studio
│   │   │   │   ├── data/
│   │   │   │   │   └── drafting_repository.dart  # Python Backend Proxy Caller
│   │   │   │   ├── domain/
│   │   │   │   │   ├── case_analysis_draft.dart # 360-degree Analysis Matrix
│   │   │   │   │   └── legal_argument.dart     # Verbatim Extractive Grounding Unit
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── drafting_controller.dart
│   │   │   │       └── screens/
│   │   │   │           └── draft_studio_screen.dart # Multi-tab 360° Studio UI
│   │   │   │
│   │   │   └── 05_verify_and_export/           # Module 5: Verification Gate & Exporter
│   │   │       ├── data/
│   │   │       │   └── export_service.dart       # Formatted PDF Builder
│   │   │       ├── domain/
│   │   │       │   └── verification_checklist.dart # State model tracking manual checks
│   │   │       └── presentation/
│   │   │           ├── controllers/
│   │   │           │   └── export_controller.dart
│   │   │           └── screens/
│   │   │               └── verification_gate_screen.dart # Non-bypassable Gate
│   │   │
│   │   └── shared/                             # Reusable Legal Components
│   │       ├── components/
│   │       │   ├── bci_disclaimer_banner.dart  # Section 30 / Rule 5 Guardrail Notice
│   │       │   ├── devanagari_text_field.dart  # Configured for complex conjuncts
│   │       │   ├── legal_status_badge.dart
│   │       │   └── locked_action_button.dart
│   │       └── dialogs/
│   │           └── error_dialog.dart
│   └── pubspec.yaml
4. DEVANAGARI (HINDI-FIRST) TYPOGRAPHY & RENDERING ENGINEDistrict Court legal drafting mein Devanagari script ke complex conjuncts (संयुक्त अक्षर जैसे: "प्रत्यार्थी", "साक्ष्य", "दण्ड प्रक्रिया संहिता", "अन्वेषण") aur vertical diacritics (मात्राएं जैसे: ि, ी, ु, ू, ्) standard system fonts par aksar cut (clip) ho jaati hain.Technical Mitigation Requirements:Vertical Line Height: Base height ko 1.4 se 1.5 ke beech explicitly set karna mandatory hai taaki Top Matra aur Bottom Halant/Vowel signs boundary par truncate na hon.Font Fallback Chain: Agar offline chamber ya network latency ki wajah se Google CDN se Noto Sans Devanagari load na ho, toh OS native Devanagari Unicode renderers par fall-back transparently hona chahiye.Dart// lib/src/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PratidnyaTypography {
  // Ordered fallback chain for Indian District Court devices
  static const List<String> devanagariFallbacks = [
    'Noto Sans Devanagari',
    'NotoSansDevanagari',
    'Mangal',
    'Arial Unicode MS',
    'sans-serif',
  ];

  static TextTheme get devanagariTextTheme {
    final baseTextTheme = GoogleFonts.notoSansDevanagariTextTheme();

    return baseTextTheme.copyWith(
      // Primary Titles: Case Titles, Court Bench Names
      displayLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        height: 1.45,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      displayMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.40,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      // Section Headers: 'अभियोजन के कमजोर बिंदु', 'जमानत के आधार'
      titleLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.40,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      titleMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.35,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      // Body Text: Legal Drafts, Extractive Facts, Chargesheet Paragraphs
      bodyLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.50, // Critical for preventing matra overlap in long paragraphs
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      bodyMedium: GoogleFonts.notoSansDevanagari(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.45,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),

      // Badges, Citations, and Verification Checkboxes
      labelLarge: GoogleFonts.notoSansDevanagari(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.35,
      ).copyWith(fontFamilyFallback: devanagariFallbacks),
    );
  }
}
5. DESIGN TOKENS & COURT-READY PALETTE (STITCH UI FOUNDATION)Advocates dim chambers ya bright sunny court corridors mein mobile use karte hain. Contrast ratio strictly WCAG AAA standards (7:1 contrast for text) meet karna chahiye:Dart// lib/src/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Institutional Court Palette
  static const Color courtNavy = Color(0xFF0A192F);       // Primary AppBars & Surfaces
  static const Color chamberSlate = Color(0xFF1E293B);   // Card Backgrounds (High Contrast)
  static const Color parchmentWhite = Color(0xFFF8FAFC); // Clean Canvas Background

  // Statutory Verification Gate Tokens
  static const Color verifiedGreen = Color(0xFF15803D);  // Precedent Verified in Database
  static const Color unverifiedAmber = Color(0xFFB45309);// Verification Pending Gate
  static const Color alertCrimson = Color(0xFFB91C1C);   // Hallucination Warning / Rejection

  // Functional Neutrals
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color borderSubtle = Color(0xFFCBD5E1);
  static const Color dividerGray = Color(0xFFE2E8F0);
}
Dart// lib/src/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class PratidnyaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.parchmentWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.courtNavy,
        primary: AppColors.courtNavy,
        secondary: AppColors.chamberSlate,
        error: AppColors.alertCrimson,
      ),
      textTheme: PratidnyaTypography.devanagariTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.courtNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: AppColors.courtNavy, width: 1.8),
        ),
      ),
    );
  }
}
6. ENVIRONMENT CONFIGURATION & SAFETY ASSERTIONSPratidnya mein development phase ke dauran Free Tier testing synthetic data ke saath hogi, aur production phase paid tier par chalega. Is gatekeeping ko codebase ke initialization phase mein enforce karna anivarya hai:  Dart// lib/src/core/config/app_environment.dart
class AppEnvironment {
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'DEV');
  
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Python Backend Proxy (Hosted on Render)
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Localhost mapping for Android Emulator
  );

  // Billing & Legal Tiers
  static const bool isGeminiPaidTier = bool.fromEnvironment('GEMINI_PAID_TIER', defaultValue: false);
  static const bool enforceDummyData = bool.fromEnvironment('ENFORCE_DUMMY_DATA', defaultValue: true);

  /// Statutory Privacy Guard Assertion
  static void validateEnvironmentSecurity() {
    if (appEnv == 'PRODUCTION') {
      if (!isGeminiPaidTier) {
        throw StateError(
          'FATAL SECURITY VIOLATION: Production build cannot run without GEMINI_PAID_TIER=true. '
          'Client confidentiality under DPDP Act 2023 and Advocates Act 1961 will be violated.'
        );
      }
      if (enforceDummyData) {
        throw StateError(
          'CONFIGURATION ERROR: Production build cannot have ENFORCE_DUMMY_DATA set to true.'
        );
      }
    }
  }
}
7. DECLARATIVE ROUTING & MULTI-STAGE AUTH GUARDS (go_router)Pratidnya ka routing system three mandatory gates cross karwata hai:Gate 1 (Identity Gate): Firebase Auth session valid hona chahiye (Google Login ya Email/Password).Gate 2 (Statutory DPDP Gate): User ko Section 5 & 6 Bilingual Notice accept karna hoga (Supabase dpdp_consent_accepted == true).  Gate 3 (BCI Enrolled Gate): Advocate ko apna valid State Bar Council enrollment number enter karna hoga (Civilian unauthorized use block karne ke liye).  Dart// lib/src/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../features/01_onboarding/presentation/screens/login_screen.dart';
import '../../features/01_onboarding/presentation/screens/dpdp_consent_screen.dart';
import '../../features/01_onboarding/presentation/screens/bar_profile_screen.dart';
import '../../features/02_case_input/presentation/screens/case_list_screen.dart';
import '../../features/02_case_input/presentation/screens/new_case_form_screen.dart';
import '../../features/04_draft_generator/presentation/screens/draft_studio_screen.dart';
import '../../features/05_verify_and_export/presentation/screens/verification_gate_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/cases',
    redirect: (BuildContext context, GoRouterState state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final currentPath = state.matchedLocation;

      final isLoggingIn = currentPath == '/login';
      final isConsentScreen = currentPath == '/dpdp-consent';
      final isBarEnrollmentScreen = currentPath == '/bar-enrollment';

      // Gate 1: Check Authentication
      if (firebaseUser == null) {
        return isLoggingIn ? null : '/login';
      }

      // Query Supabase for Advocate Profile & Consent Metadata using Firebase UID
      try {
        final profileResponse = await supa.Supabase.instance.client
            .from('advocate_profiles')
            .select('dpdp_consent_accepted, bar_council_number')
            .eq('id', firebaseUser.uid)
            .maybeSingle();

        final bool hasConsented = profileResponse?['dpdp_consent_accepted'] == true;
        final String? barNumber = profileResponse?['bar_council_number'];

        // Gate 2: Mandatory DPDP Statutory Consent
        if (!hasConsented) {
          return isConsentScreen ? null : '/dpdp-consent';
        }

        // Gate 3: Advocates Act Enrolled Verification Gate
        if (barNumber == null || barNumber.trim().isEmpty) {
          return isBarEnrollmentScreen ? null : '/bar-enrollment';
        }

        // If authenticated and verified, redirect away from onboarding
        if (isLoggingIn || isConsentScreen || isBarEnrollmentScreen) {
          return '/cases';
        }
      } catch (e) {
        // Network timeout / drop in court corridor: allow access to cached cases
        debugPrint('Router sync warning: $e');
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dpdp-consent',
        builder: (context, state) => const DpdpConsentScreen(),
      ),
      GoRoute(
        path: '/bar-enrollment',
        builder: (context, state) => const BarProfileScreen(),
      ),
      GoRoute(
        path: '/cases',
        builder: (context, state) => const CaseListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewCaseFormScreen(),
          ),
          GoRoute(
            path: ':caseId/draft-studio',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              return DraftStudioScreen(caseId: caseId);
            },
          ),
          GoRoute(
            path: ':caseId/verify-gate',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              return VerificationGateScreen(caseId: caseId);
            },
          ),
        ],
      ),
    ],
  );
});
8. APPLICATION BOOTSTRAP INITIALIZER (main.dart)Dart// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_environment.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Enforce Statutory Environment Checks
  AppEnvironment.validateEnvironmentSecurity();

  // 2. Initialize Firebase (Spark Plan / Google Sign-In & Email Auth)
  await Firebase.initializeApp();

  // 3. Initialize Supabase (PostgreSQL & pgvector Chamber Store)
  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    anonKey: AppEnvironment.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 2,
    ),
  );

  runApp(
    const ProviderScope(
      child: PratidnyaApplication(),
    ),
  );
}
Dart// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class PratidnyaApplication extends ConsumerWidget {
  const PratidnyaApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pratidnya Legal Assistant',
      theme: PratidnyaTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
9. NON-NEGOTIABLE ANTIGRAVITY CODING RULES (DOC-01 COMPLIANCE)Antigravity jab bhi Dart/Flutter code generate karega, in strict rules ko adhere karega:No Speculative Third-Party Libraries: Upar pubspec.yaml mein list kiye gaye packages ke alawa koi arbitrary library import nahi karni hai.Strict Typographical Enforcement: Kisi bhi raw TextStyle mein font size badhate waqt height: 1.4 se kam nahi hona chahiye taaki Devanagari matras render ho saken.No Direct Gemini/External API Calls in Flutter: UI layer direct Google Gemini ya OpenNyAI ko call nahi karegi; routing strictly FastAPI microservice proxy ke zariye authenticate hogi.Zero Bypass on Route Guards: Security Gate 1, 2, aur 3 ko bypass karne ka koi hidden debug-flag route logic mein inject nahi kiya jayega.