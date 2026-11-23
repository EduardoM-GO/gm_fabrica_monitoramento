/// Configuração do backend Supabase para o Kiosk G&M Chocolates.
///
/// Suporta override via `--dart-define` e possui fallback padrão para o
/// projeto Supabase do ERP (`gm_chocolates_sistema`).
abstract final class SupabaseConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Credenciais opcionais para login automático do Kiosk em chão de fábrica.
  static const kioskEmail = String.fromEnvironment('SUPABASE_KIOSK_EMAIL');
  static const kioskPassword = String.fromEnvironment(
    'SUPABASE_KIOSK_PASSWORD',
  );

  static String get url => _envUrl;

  static String get publishableKey => _envPublishableKey;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool get hasAutoLoginCredentials =>
      kioskEmail.trim().isNotEmpty && kioskPassword.isNotEmpty;
}
