import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Inicializa o cliente Supabase no Kiosk e realiza login automático
/// caso `SUPABASE_KIOSK_EMAIL` e `SUPABASE_KIOSK_PASSWORD` estejam definidos.
Future<bool> bootstrapSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    debugPrint('Supabase não configurado no Kiosk.');
    return false;
  }

  try {
    final instance = await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );

    final client = instance.client;
    if (client.auth.currentSession == null &&
        SupabaseConfig.hasAutoLoginCredentials) {
      try {
        await client.auth.signInWithPassword(
          email: SupabaseConfig.kioskEmail.trim(),
          password: SupabaseConfig.kioskPassword,
        );
      } catch (e) {
        debugPrint('Falha no auto-login do Kiosk Supabase: $e');
      }
    }

    return instance.isInitialized;
  } catch (e) {
    debugPrint('Erro ao inicializar Supabase no Kiosk: $e');
    return false;
  }
}

SupabaseClient? get supabaseOrNull {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}
