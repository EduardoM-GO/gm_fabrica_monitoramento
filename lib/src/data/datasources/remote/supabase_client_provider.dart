import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> initialize({
    required String url,
    required String anonKey,
  }) async {
    final cleanUrl = url.trim();
    final cleanKey = anonKey.trim();

    if (cleanUrl.isEmpty || cleanKey.isEmpty) {
      debugPrint('Supabase: Credenciais não fornecidas. Operando em modo offline estrito.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: cleanUrl,
        publishableKey: cleanKey,
      );
      _isInitialized = true;
      debugPrint('Supabase: Inicializado com sucesso em $cleanUrl');
      return true;
    } catch (e) {
      debugPrint('Supabase: Falha ao inicializar ($e). Operando em modo offline.');
      _isInitialized = false;
      return false;
    }
  }
}
