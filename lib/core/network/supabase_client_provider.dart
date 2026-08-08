import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';

/// Thin wrapper around the Supabase singleton so repositories depend on an
/// injectable type rather than the global `Supabase.instance` directly.
class SupabaseClientProvider {
  SupabaseClientProvider(this.client);

  final SupabaseClient client;

  static Future<SupabaseClientProvider> initialize() async {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
    return SupabaseClientProvider(Supabase.instance.client);
  }
}
