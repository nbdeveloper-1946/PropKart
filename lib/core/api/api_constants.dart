import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String primaryBaseUrl = "https://prop-kart-backend.vercel.app/api/v1";
  static const String backupBaseUrl = "https://prop-kart-backend.vercel.app/api/v1";

  /// Connect directly to backend subdomain for cross-site cookie authentication.
  static String get baseUrl => primaryBaseUrl;

  /// Prefer compile-time defines in CI:
  /// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  /// Anon key is public-by-design for Supabase; security depends on RLS.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sopbhhpvyorspvtcwkxb.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvcGJoaHB2eW9yc3B2dGN3a3hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MjY0MDgsImV4cCI6MjA5OTUwMjQwOH0.O_mQkMfmkP4E3NwYjxpAdL080TevKA8qFtGhV6rFEqo',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const refresh = "/auth/refresh";
  static const logout = "/auth/logout";
  static const health = "/health";

  static void assertConfig() {
    if (kDebugMode && !hasSupabaseConfig) {
      debugPrint('ApiConstants: Supabase URL/anon key missing — realtime disabled.');
    }
  }
}
