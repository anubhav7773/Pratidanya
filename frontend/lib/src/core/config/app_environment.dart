class AppEnvironment {
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'DEV');

  // Supabase Configuration (AWS Mumbai ap-south-1)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mock.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'mock_anon_key',
  );

  // Python Backend Proxy (Hosted on Render Starter Plan)
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Localhost mapping for Android Emulator
  );

  // Billing, Privacy & Legal Tiers
  static const bool isGeminiPaidTier = bool.fromEnvironment('GEMINI_PAID_TIER', defaultValue: false);
  static const bool enforceDummyData = bool.fromEnvironment('ENFORCE_DUMMY_DATA', defaultValue: true);

  /// Statutory Privacy Guard Assertion
  static void validateEnvironmentSecurity() {
    if (appEnv == 'PRODUCTION') {
      if (!isGeminiPaidTier) {
        throw StateError(
          'FATAL SECURITY VIOLATION: Production build cannot run without GEMINI_PAID_TIER=true. '
          'Client confidentiality under DPDP Act 2023 and Advocates Act 1961 will be compromised.',
        );
      }
      if (enforceDummyData) {
        throw StateError(
          'CONFIGURATION ERROR: Production build cannot have ENFORCE_DUMMY_DATA set to true.',
        );
      }
    }
  }
}
