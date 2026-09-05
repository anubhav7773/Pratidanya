DOC_02_SUPABASE_INTEGRATION_REFERENCE.mdPlaintext================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-02
MODULE         : SUPABASE DATABASE, RLS & FIREBASE AUTHENTICATION BRIDGE
TARGET RUNTIME : supabase_flutter ^2.5.6 / PostgreSQL 15+ (AWS ap-south-1 Mumbai)
AUTH PROVIDER  : Firebase Auth (Spark Free Plan — Google Sign-In + Email/Password)
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. ARCHITECTURAL OVERVIEW: FIREBASE AUTH & SUPABASE POSTGREST BRIDGEPratidnya mein zero credit-card liability aur 100% free authentications enforce karne ke liye Firebase Auth (Spark Plan) client identity handle karta hai, jabki Supabase application database, pgvector store aur chamber isolation execute karta hai.  Identity Propagation Flow┌────────────────────────────────────────────────────────┐
│               FLUTTER CLIENT (PRATIDNYA)               │
│  1. User logs in via Google Sign-In or Email/Password  │
│  2. Firebase Auth issues JWT ID Token (containing UID) │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ Bearer <Firebase_ID_Token>
                            ▼
┌────────────────────────────────────────────────────────┐
│             SUPABASE POSTGREST API GATEWAY             │
│  - Supabase validates Firebase JWT via Third-Party Auth│
│  - Sets SQL session: auth.uid() == Firebase User UID   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│           POSTGRESQL 15+ ROW LEVEL SECURITY            │
│  - Checks: advocate_id == auth.uid()                   │
│  - Strictly isolates chamber cases from other lawyers  │
└────────────────────────────────────────────────────────┘
Supabase Configuration Rule: Supabase Dashboard -> Authentication -> Third-Party Auth mein Firebase Project ID configure kiya jaayega taaki Supabase PostgREST Gateway Firebase ke RS256 JWT tokens ko natively decode karke auth.uid() context inject kar sake.2. PRODUCTION DATABASE DDL SPECIFICATION (POSTGRESQL 15+)Niche di gayi SQL DDL script Antigravity ko Supabase migrations mein execute karni hai. Yeh Subordinate / District Court Criminal Practice ke liye fully optimized hai:SQL-- ============================================================================
-- 1. EXTENSIONS & SCHEMAS
-- ============================================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================================
-- 2. ADVOCATE PROFILES TABLE
-- Mapped to Firebase Auth UID as Primary Key
-- ============================================================================
create table public.advocate_profiles (
    id text primary key, -- Firebase UID (String format)
    email text unique not null,
    full_name text not null,
    bar_council_number text unique not null, -- e.g., 'UP/1234/2018'
    enrolled_state text not null default 'Uttar Pradesh',
    primary_court_name text not null, -- e.g., 'District & Sessions Court, Lucknow'
    court_type text not null default 'DISTRICT_SUBORDINATE',
    chamber_address text,
    dpdp_consent_accepted boolean default false not null,
    dpdp_consent_timestamp timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.advocate_profiles is 'Licensed criminal advocates enrolled with State Bar Councils.';

-- ============================================================================
-- 3. DISTRICT COURT CRIMINAL CASES TABLE
-- Core operational docket for Subordinate Court litigation
-- ============================================================================
create table public.cases (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Police Administration & Registration Details
    fir_number text not null,                       -- e.g., '124/2026'
    police_station text not null,                   -- e.g., 'Kotwali Nagar'
    district text not null,                         -- e.g., 'Lucknow'
    state text not null default 'Uttar Pradesh',
    
    -- Litigant Details
    accused_name text not null,
    accused_custody_status text not null default 'JUDICIAL_CUSTODY', -- 'IN_JAIL', 'ON_BAIL', 'ANTICIPATORY'
    complainant_name text,
    
    -- Substantive & Procedural Law Mapping
    statute_system text not null default 'HYBRID',  -- 'BNS_BNSS', 'IPC_CRPC', 'HYBRID'
    under_sections text[] not null,                 -- Array: ARRAY['379 IPC', '411 IPC'] or ARRAY['303 BNS']
    
    -- Subordinate Judicial Hierarchy
    court_designation text not null,                -- 'CJM', 'ACJM-I', 'JMFC', 'Special Judge POCSO', 'Sessions Judge'
    case_number text,                               -- e.g., 'Bail App No. 450/2026'
    cnr_number text,                                -- 16-character eCourts CNR
    
    -- Docket State & Diary
    stage_of_case text not null,                    -- 'REMAND', 'BAIL_HEARING', 'CHARGESHEET_FILED', 'FRAMING_OF_CHARGES', 'EVIDENCE'
    next_hearing_date date,
    last_court_order text,
    
    -- Archival & Soft Delete Flag
    is_archived boolean default false not null,
    
    -- Audit Timestamps
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Optimization B-Tree Indexes for District Court Docket Lists
create index idx_cases_advocate_active on public.cases(advocate_id) where is_archived = false;
create index idx_cases_next_hearing on public.cases(advocate_id, next_hearing_date asc);
create index idx_cases_sections_gin on public.cases using gin(under_sections);

-- ============================================================================
-- 4. CASE DIARY & PROCEEDINGS LOG
-- Historical track of adjournments, bail rejections & hearing notes
-- ============================================================================
create table public.case_proceedings (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    proceeding_date date not null,
    court_coram text,                               -- Presiding Judge Designation
    business_recorded text not null,                -- 'Advocate present, IO sought time for Case Diary'
    next_date date,
    purpose_of_next_date text,                      -- 'For Arguments on Bail'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ============================================================================
-- 5. DPDP STATUTORY AUDIT LOGS (IMMUTABLE LOGS)
-- Section 5, 6 & 8 Data Protection Act 2023 Compliance
-- ============================================================================
create table public.dpdp_audit_logs (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    action_type text not null,                      -- 'CONSENT_GRANTED', 'CONSENT_WITHDRAWN', 'CASE_EXPORTED', 'HARD_ERASURE_REQUEST'
    ip_address text,
    user_agent text,
    metadata jsonb default '{}'::jsonb,
    recorded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Prevent any manual mutation or update to legal audit logs
create or replace function prevent_audit_log_mutation()
returns trigger as $$ begin     raise exception 'DPDP Audit Logs are strictly immutable and cannot be updated or deleted.'; end; $$ language plpgsql;

create trigger trg_protect_dpdp_audit_logs
before update or delete on public.dpdp_audit_logs
for each row execute function prevent_audit_log_mutation();
3. ROW LEVEL SECURITY (RLS) POLICIES SPECIFICATIONPratidnya mein chamber confidentiality sarvopari hai. RLS policies ensures karti hain ki Inspector General ya doosra advocate kisi aur ke criminal defense strategy ya case diary ko query na kar sake:  SQL-- Enable RLS across all application tables
alter table public.advocate_profiles enable row level security;
alter table public.cases enable row level security;
alter table public.case_proceedings enable row level security;
alter table public.dpdp_audit_logs enable row level security;

-- ============================================================================
-- RLS: ADVOCATE PROFILES
-- ============================================================================
create policy "Advocate can view own profile"
    on public.advocate_profiles
    for select
    using (id = auth.uid()::text or id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocate can update own profile"
    on public.advocate_profiles
    for update
    using (id = auth.uid()::text or id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (id = auth.uid()::text or id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocate can insert own profile upon onboarding"
    on public.advocate_profiles
    for insert
    with check (id = auth.uid()::text or id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

-- ============================================================================
-- RLS: CASES (CHAMBER ISOLATION MANDATE)
-- ============================================================================
create policy "Advocate has exclusive access to own cases"
    on public.cases
    for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

-- ============================================================================
-- RLS: CASE PROCEEDINGS
-- ============================================================================
create policy "Advocate has exclusive access to own case proceedings"
    on public.case_proceedings
    for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

-- ============================================================================
-- RLS: DPDP AUDIT LOGS
-- ============================================================================
create policy "Advocate can read own audit logs"
    on public.dpdp_audit_logs
    for select
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocate can insert audit trail entries"
    on public.dpdp_audit_logs
    for insert
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
4. DART IMPLEMENTATION: AUTHENTICATION REPOSITORYFirebase Auth (Google Sign-In + Email/Password) se login karke Supabase client ke sath session propagate karne ka exact code:Dart// lib/src/features/01_onboarding/data/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: fb_auth.FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(scopes: ['email']),
    supabaseClient: supa.Supabase.instance.client,
  );
});

class AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final supa.SupabaseClient _supabaseClient;

  AuthRepository({
    required fb_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required supa.SupabaseClient supabaseClient,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _supabaseClient = supabaseClient;

  fb_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  Stream<fb_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// 1. Synchronize Firebase Token with Supabase PostgREST Gateway
  Future<void> _injectFirebaseTokenToSupabase(fb_auth.User user) async {
    final String? idToken = await user.getIdToken();
    if (idToken != null) {
      // Injects Bearer Token directly into Supabase REST Client
      _supabaseClient.rest.headers['Authorization'] = 'Bearer $idToken';
    }
  }

  /// 2. Google Sign-In (100% Free - Spark Plan)
  Future<fb_auth.UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw PratidnyaAuthException(message: 'Google लॉगिन प्रक्रिया रद्द कर दी गई।');
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final fb_auth.OAuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _injectFirebaseTokenToSupabase(userCredential.user!);
      }
      return userCredential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    } catch (e) {
      throw PratidnyaAuthException(message: 'Google प्रमाणीकरण त्रुटि: $e');
    }
  }

  /// 3. Email/Password Login (Chamber Account)
  Future<fb_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _injectFirebaseTokenToSupabase(credential.user!);
      }
      return credential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  /// 4. Email/Password Registration
  Future<fb_auth.UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _injectFirebaseTokenToSupabase(credential.user!);
      }
      return credential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  /// 5. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _supabaseClient.rest.headers.remove('Authorization');
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'इस ईमेल के साथ कोई अधिवक्ता खाता पंजीकृत नहीं है।';
      case 'wrong-password':
        return 'दर्ज किया गया पासवर्ड अमान्य है। कृपया पुनः प्रयास करें।';
      case 'email-already-in-use':
        return 'यह ईमेल पहले से पंजीकृत है। कृपया लॉगिन करें।';
      case 'invalid-email':
        return 'अमान्य ईमेल प्रारूप। कृपया सही पता दर्ज करें।';
      case 'weak-password':
        return 'पासवर्ड कमजोर है। कम से कम 6 अक्षरों का पासवर्ड बनाएं।';
      case 'network-request-failed':
        return 'नेटवर्क कनेक्शन विफल। कृपया इंटरनेट जांचें।';
      default:
        return 'प्रमाणीकरण त्रुटि ($code)। कृपया पुनः प्रयास करें।';
    }
  }
}

class PratidnyaAuthException implements Exception {
  final String message;
  PratidnyaAuthException({required this.message});
  @override
  String toString() => message;
}
5. DART IMPLEMENTATION: ADVOCATE PROFILE REPOSITORYDart// lib/src/features/01_onboarding/data/profile_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/advocate_profile.dart';

final profileRepositoryProvider = Provider<AdvocateProfileRepository>((ref) {
  return AdvocateProfileRepository(Supabase.instance.client);
});

class AdvocateProfileRepository {
  final SupabaseClient _supabase;

  AdvocateProfileRepository(this._supabase);

  /// Fetch profile by Firebase UID
  Future<AdvocateProfile?> getProfile(String firebaseUid) async {
    try {
      final data = await _supabase
          .from('advocate_profiles')
          .select()
          .eq('id', firebaseUid)
          .maybeSingle();

      if (data == null) return null;
      return AdvocateProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception('प्रोफाइल डेटा लोड करने में त्रुटि: ${e.message} [Code:${e.code}]');
    }
  }

  /// Complete Bar Enrollment & Record DPDP Statutory Consent
  Future<void> saveAdvocateOnboarding({
    required String firebaseUid,
    required String email,
    required String fullName,
    required String barCouncilNumber,
    required String primaryCourtName,
    required String enrolledState,
    required bool dpdpConsentAccepted,
    String? chamberAddress,
  }) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      // Upsert into advocate_profiles
      await _supabase.from('advocate_profiles').upsert({
        'id': firebaseUid,
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'bar_council_number': barCouncilNumber.trim().toUpperCase(),
        'enrolled_state': enrolledState.trim(),
        'primary_court_name': primaryCourtName.trim(),
        'chamber_address': chamberAddress?.trim(),
        'dpdp_consent_accepted': dpdpConsentAccepted,
        'dpdp_consent_timestamp': dpdpConsentAccepted ? nowUtc : null,
        'updated_at': nowUtc,
      });

      // Statutory DPDP Section 5/6 Audit Entry
      if (dpdpConsentAccepted) {
        await _supabase.from('dpdp_audit_logs').insert({
          'advocate_id': firebaseUid,
          'action_type': 'CONSENT_GRANTED',
          'metadata': {
            'bar_council_number': barCouncilNumber.trim().toUpperCase(),
            'consent_version': 'DPDP_2023_V1.0',
            'timestamp': nowUtc,
          }
        });
      }
    } on PostgrestException catch (e) {
      throw Exception('पंजीकरण विवरण सहेजने में विफल: ${e.message} [Code:${e.code}]');
    }
  }
}
6. DART IMPLEMENTATION: CRIMINAL CASES REPOSITORY (CRUD)District court criminal cases ko create, fetch, paginate, aur archive karne ka exact implementation:Dart// lib/src/features/02_case_input/data/case_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/criminal_case.dart';

final caseRepositoryProvider = Provider<CriminalCaseRepository>((ref) {
  return CriminalCaseRepository(Supabase.instance.client);
});

class CriminalCaseRepository {
  final SupabaseClient _supabase;

  CriminalCaseRepository(this._supabase);

  /// 1. Fetch Paginated Active Cases Sorted by Upcoming Hearing
  Future<List<CriminalCase>> fetchUpcomingHearingCases({
    required String advocateId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> response = await _supabase
          .from('cases')
          .select('''
            id,
            advocate_id,
            fir_number,
            police_station,
            district,
            state,
            accused_name,
            accused_custody_status,
            complainant_name,
            statute_system,
            under_sections,
            court_designation,
            case_number,
            cnr_number,
            stage_of_case,
            next_hearing_date,
            last_court_order,
            is_archived,
            created_at,
            updated_at
          ''')
          .eq('advocate_id', advocateId)
          .eq('is_archived', false)
          .order('next_hearing_date', ascending: true, nullsFirst: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => CriminalCase.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('केस सूची लोड करने में विफल: ${e.message} [Code: ${e.code}]');
    }
  }

  /// 2. Search Cases by Substantive Law Sections (e.g. ['411 IPC'] or ['317 BNS'])
  Future<List<CriminalCase>> searchCasesBySection({
    required String advocateId,
    required String sectionQuery,
  }) async {
    try {
      // Uses PostgreSQL GIN array contains operator: under_sections @> ARRAY['sectionQuery']
      final List<dynamic> response = await _supabase
          .from('cases')
          .select()
          .eq('advocate_id', advocateId)
          .eq('is_archived', false)
          .contains('under_sections', [sectionQuery]);

      return response.map((json) => CriminalCase.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('धारा आधारित खोज विफल: ${e.message}');
    }
  }

  /// 3. Create New District Court Criminal Case
  Future<CriminalCase> createCriminalCase({
    required String advocateId,
    required String firNumber,
    required String policeStation,
    required String district,
    required String accusedName,
    required String accusedCustodyStatus,
    required List<String> underSections,
    required String courtDesignation,
    required String stageOfCase,
    String? complainantName,
    String? caseNumber,
    DateTime? nextHearingDate,
  }) async {
    try {
      final response = await _supabase
          .from('cases')
          .insert({
            'advocate_id': advocateId,
            'fir_number': firNumber.trim(),
            'police_station': policeStation.trim(),
            'district': district.trim(),
            'accused_name': accusedName.trim(),
            'accused_custody_status': accusedCustodyStatus,
            'complainant_name': complainantName?.trim(),
            'under_sections': underSections,
            'court_designation': courtDesignation.trim(),
            'case_number': caseNumber?.trim(),
            'stage_of_case': stageOfCase,
            'next_hearing_date': nextHearingDate?.toIso8601String().split('T').first,
            'is_archived': false,
          })
          .select()
          .single();

      return CriminalCase.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('नया केस दर्ज करने में विफल: ${e.message} [Code: ${e.code}]');
    }
  }

  /// 4. Record Case Proceeding & Adjourn Next Date
  Future<void> recordProceedingAndAdjourn({
    required String caseId,
    required String advocateId,
    required DateTime proceedingDate,
    required String businessRecorded,
    required DateTime nextDate,
    required String purposeOfNextDate,
    String? courtCoram,
  }) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      // Step A: Insert proceeding log
      await _supabase.from('case_proceedings').insert({
        'case_id': caseId,
        'advocate_id': advocateId,
        'proceeding_date': proceedingDate.toIso8601String().split('T').first,
        'court_coram': courtCoram?.trim(),
        'business_recorded': businessRecorded.trim(),
        'next_date': nextDate.toIso8601String().split('T').first,
        'purpose_of_next_date': purposeOfNextDate.trim(),
      });

      // Step B: Update master case docket
      await _supabase.from('cases').update({
        'next_hearing_date': nextDate.toIso8601String().split('T').first,
        'stage_of_case': purposeOfNextDate.trim(),
        'last_court_order': businessRecorded.trim(),
        'updated_at': nowUtc,
      }).eq('id', caseId);

    } on PostgrestException catch (e) {
      throw Exception('कार्यवाही दर्ज करने में विफल: ${e.message} [Code:${e.code}]');
    }
  }

  /// 5. Soft Archive Case
  Future<void> archiveCase(String caseId) async {
    try {
      await _supabase
          .from('cases')
          .update({'is_archived': true, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', caseId);
    } on PostgrestException catch (e) {
      throw Exception('केस आर्काइव करने में विफल: ${e.message}');
    }
  }

  /// 6. Hard Erasure (DPDP Act 2023 Sec 8(7) Statutory Right to Erasure)
  Future<void> permanentlyDeleteCase({
    required String caseId,
    required String advocateId,
  }) async {
    try {
      // 1. Audit Log of erasure
      await _supabase.from('dpdp_audit_logs').insert({
        'advocate_id': advocateId,
        'action_type': 'HARD_ERASURE_REQUEST',
        'metadata': {
          'target_case_id': caseId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }
      });

      // 2. Cascade Delete in cases table (deletes associated proceedings & embeddings)
      await _supabase.from('cases').delete().eq('id', caseId);
    } on PostgrestException catch (e) {
      throw Exception('डेटा निष्कासन (Right to Erasure) विफल: ${e.message}');
    }
  }
}
7. DOMAIN DATA MODELS (WITH COMPLETE SERIALIZATION)Dart// lib/src/features/01_onboarding/domain/advocate_profile.dart
class AdvocateProfile {
  final String id;
  final String email;
  final String fullName;
  final String barCouncilNumber;
  final String enrolledState;
  final String primaryCourtName;
  final String courtType;
  final String? chamberAddress;
  final bool dpdpConsentAccepted;
  final DateTime? dpdpConsentTimestamp;

  AdvocateProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.barCouncilNumber,
    required this.enrolledState,
    required this.primaryCourtName,
    required this.courtType,
    this.chamberAddress,
    required this.dpdpConsentAccepted,
    this.dpdpConsentTimestamp,
  });

  factory AdvocateProfile.fromJson(Map<String, dynamic> json) {
    return AdvocateProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      barCouncilNumber: json['bar_council_number'] as String,
      enrolledState: json['enrolled_state'] as String? ?? 'Uttar Pradesh',
      primaryCourtName: json['primary_court_name'] as String,
      courtType: json['court_type'] as String? ?? 'DISTRICT_SUBORDINATE',
      chamberAddress: json['chamber_address'] as String?,
      dpdpConsentAccepted: json['dpdp_consent_accepted'] as bool? ?? false,
      dpdpConsentTimestamp: json['dpdp_consent_timestamp'] != null
          ? DateTime.parse(json['dpdp_consent_timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'bar_council_number': barCouncilNumber,
        'enrolled_state': enrolledState,
        'primary_court_name': primaryCourtName,
        'court_type': courtType,
        'chamber_address': chamberAddress,
        'dpdp_consent_accepted': dpdpConsentAccepted,
        'dpdp_consent_timestamp': dpdpConsentTimestamp?.toIso8601String(),
      };
}
Dart// lib/src/features/02_case_input/domain/criminal_case.dart
class CriminalCase {
  final String id;
  final String advocateId;
  final String firNumber;
  final String policeStation;
  final String district;
  final String state;
  final String accusedName;
  final String accusedCustodyStatus;
  final String? complainantName;
  final String statuteSystem;
  final List<String> underSections;
  final String courtDesignation;
  final String? caseNumber;
  final String? cnrNumber;
  final String stageOfCase;
  final DateTime? nextHearingDate;
  final String? lastCourtOrder;
  final bool isArchived;
  final DateTime createdAt;

  CriminalCase({
    required this.id,
    required this.advocateId,
    required this.firNumber,
    required this.policeStation,
    required this.district,
    required this.state,
    required this.accusedName,
    required this.accusedCustodyStatus,
    this.complainantName,
    required this.statuteSystem,
    required this.underSections,
    required this.courtDesignation,
    this.caseNumber,
    this.cnrNumber,
    required this.stageOfCase,
    this.nextHearingDate,
    this.lastCourtOrder,
    required this.isArchived,
    required this.createdAt,
  });

  factory CriminalCase.fromJson(Map<String, dynamic> json) {
    return CriminalCase(
      id: json['id'] as String,
      advocateId: json['advocate_id'] as String,
      firNumber: json['fir_number'] as String,
      policeStation: json['police_station'] as String,
      district: json['district'] as String,
      state: json['state'] as String? ?? 'Uttar Pradesh',
      accusedName: json['accused_name'] as String,
      accusedCustodyStatus: json['accused_custody_status'] as String? ?? 'JUDICIAL_CUSTODY',
      complainantName: json['complainant_name'] as String?,
      statuteSystem: json['statute_system'] as String? ?? 'HYBRID',
      underSections: List<String>.from(json['under_sections'] ?? []),
      courtDesignation: json['court_designation'] as String,
      caseNumber: json['case_number'] as String?,
      cnrNumber: json['cnr_number'] as String?,
      stageOfCase: json['stage_of_case'] as String,
      nextHearingDate: json['next_hearing_date'] != null
          ? DateTime.parse(json['next_hearing_date'] as String)
          : null,
      lastCourtOrder: json['last_court_order'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
8. POSTGREST ERROR LOCALIZATION MAPPERAntigravity ko PostgREST raw error codes ko seedha UI par display nahi karna hai. Niche di gayi deterministic mapping function follow karni hogi:Dart// lib/src/core/utils/postgrest_error_mapper.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PostgrestErrorMapper {
  static String toHindi(PostgrestException error) {
    switch (error.code) {
      case '23505': // Unique violation
        if (error.message.contains('bar_council_number')) {
          return 'यह बार काउंसिल पंजीकरण संख्या पहले से किसी अन्य खाते में दर्ज है।';
        }
        if (error.message.contains('email')) {
          return 'यह ईमेल पता पहले से पंजीकृत है।';
        }
        return 'डुप्लिकेट रिकॉर्ड: यह डेटाबेस में पहले से मौजूद है।';

      case '42501': // RLS Permission Denied
        return 'अनधिकृत पहुंच: आपको इस केस फ़ाइल या चैंबर रिकॉर्ड को देखने का अधिकार नहीं है।';

      case '23503': // Foreign Key Violation
        return 'अमान्य संदर्भ: संबंधित अधिवक्ता या केस रिकॉर्ड नहीं मिला।';

      case '22P02': // Invalid text representation (UUID mismatch)
        return 'अमान्य पहचानकर्ता (UUID) प्रारूप दर्ज किया गया है।';

      case 'PGRST116': // 0 rows returned for single()
        return 'वांछित विधिक रिकॉर्ड या केस फ़ाइल उपलब्ध नहीं है।';

      default:
        return 'डेटाबेस त्रुटि (${error.code ?? 'UNKNOWN'}): कृपया कुछ समय बाद पुनः प्रयास करें।';
    }
  }
}
9. ANTIGRAVITY NON-NEGOTIABLE VERIFICATION CHECKLIST (DOC-02)Antigravity code likhte waqt in exact safety conditions ko verify karega:[ ] Primary Key of advocate_profiles is text (matching Firebase UID), NOT auto-generated UUID.[ ] Every query on cases and case_proceedings must explicitly include or pass through RLS check against auth.uid().[ ] dpdp_audit_logs par update aur delete triggers active hain (Immutable audit trail under Section 8 DPDP Act 2023).  [ ] Case sections array column under_sections par B-Tree nahi, GIN index (gin(under_sections)) create hona chahiye.[ ] No hardcoded database credentials in Dart code; strictly read from AppEnvironment.supabaseUrl and AppEnvironment.supabaseAnonKey.