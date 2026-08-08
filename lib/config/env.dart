/// Compile-time environment configuration, overridable via --dart-define.
///
/// Defaults point at the project's `dev` Supabase instance so `flutter run`
/// works out of the box. The anon/publishable key is safe to ship in the
/// client by design -- it only grants what RLS policies allow.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gaarpeebmixvruxeetks.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhYXJwZWVibWl4dnJ1eGVldGtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMTA2MjgsImV4cCI6MjEwMTY4NjYyOH0.3Q0dCOiNKroh-2HvLXUqeYCvA_ib1UlpoLB4F6Qm6CE',
  );

  static const String environmentName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static bool get isProduction => environmentName == 'prod';
}
