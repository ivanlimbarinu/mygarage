import 'package:supabase_flutter/supabase_flutter.dart';

class Backend {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get configured => url.isNotEmpty && key.isNotEmpty;
  static SupabaseClient get client => Supabase.instance.client;
  static Future<void> initialize() async {
    if (configured) {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          detectSessionInUri: true,
        ),
      );
    }
  }
}
