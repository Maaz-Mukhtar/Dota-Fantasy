/// Environment configuration
///
/// Replace these values with your actual Supabase credentials
/// before running the app.
class Env {
  Env._();

  /// Supabase project URL
  static const String supabaseUrl = 'https://nldmewkuarzptlksqhxz.supabase.co';

  /// Supabase anonymous key (safe to include in client)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sZG1ld2t1YXJ6cHRsa3NxaHh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMjU4ODcsImV4cCI6MjA4MzgwMTg4N30.Tjl_QjiuWmaw_OEVErWouWhzNKX4X25zLEX3tv4G2EY';

  /// API base URL for the backend
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  /// Whether the app is in debug mode
  static const bool isDebug = true;
}
