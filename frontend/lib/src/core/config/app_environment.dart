import 'package:http/http.dart' as http;

class AppEnvironment {
  // Application Mode: 'DEVELOPMENT', 'STAGING', 'PRODUCTION'
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'PRODUCTION');

  // Production Supabase URL & Public Anon Key (AWS Mumbai ap-south-1)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://edekorlixzhqeavrhtbe.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkZWtvcmxpeHpocWVhdnJodGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1NTA3NzgsImV4cCI6MjEwNDEyNjc3OH0.4tQwyCC3SvBQWg_Wo9JamIaLeKmwoAn8KowXCWIwHHo',
  );

  // Production FastAPI Microservice URL (Deployed on Render Starter Plan)
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://pratidanya-backend.onrender.com',
  );

  // Production AI & Statutory Compliance Flags
  static const bool isGeminiPaidTier = bool.fromEnvironment('GEMINI_PAID_TIER', defaultValue: true);
  static const bool enforceDummyData = bool.fromEnvironment('ENFORCE_DUMMY_DATA', defaultValue: false);

  /// Production Runtime Assertions
  static void validateEnvironmentSecurity() {
    if (appEnv == 'PRODUCTION') {
      if (backendBaseUrl.contains('localhost') || backendBaseUrl.contains('10.0.2.2')) {
        throw StateError(
          'FATAL CONFIGURATION ERROR: Production build cannot point to localhost or emulator bridge ($backendBaseUrl).',
        );
      }
      if (!backendBaseUrl.startsWith('https://')) {
        throw StateError(
          'STATUTORY TLS VIOLATION: Production backend URL must strictly enforce HTTPS (TLS 1.3) under DPDP Act 2023 Sec 8(5).',
        );
      }
      if (!supabaseUrl.startsWith('https://')) {
        throw StateError('STATUTORY TLS VIOLATION: Supabase URL must strictly enforce HTTPS.');
      }
      if (!isGeminiPaidTier) {
        throw StateError(
          'PRIVACY BREACH: Real criminal case processing requires GEMINI_PAID_TIER=true to enforce zero-retention on Google Cloud.',
        );
      }
      if (enforceDummyData) {
        throw StateError(
          'SANDBOX MISCONFIGURATION: ENFORCE_DUMMY_DATA must be false in production environments.',
        );
      }
    }
  }

  static bool _isWarmingUp = false;

  /// Silently pings /healthz in the background to wake up Render from cold start
  static void warmupBackend() {
    if (_isWarmingUp) return;
    _isWarmingUp = true;
    Future.microtask(() async {
      try {
        final res = await http.get(Uri.parse('$backendBaseUrl/healthz')).timeout(
          const Duration(seconds: 40),
          onTimeout: () => http.Response('timeout', 408),
        ).catchError((_) => http.Response('error', 500));

        if (res.statusCode != 200) {
          await Future.delayed(const Duration(seconds: 6));
          await http.get(Uri.parse('$backendBaseUrl/healthz')).timeout(
            const Duration(seconds: 30),
            onTimeout: () => http.Response('timeout', 408),
          ).catchError((_) => http.Response('error', 500));
        }
      } catch (_) {
        // Ignored: silent background warmup
      } finally {
        _isWarmingUp = false;
      }
    });
  }
}
