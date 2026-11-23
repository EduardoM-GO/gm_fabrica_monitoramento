import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/supabase/supabase_bootstrap.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de Login Kiosk Horizontal M3 (Paleta Cacau & Ouro) para autenticar
/// o tablet no Supabase (`authenticated`) e liberar o carregamento de
/// Produtos (`public.products`) e Equipamentos (`public.cost_centers`).
final class KioskLoginView extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const KioskLoginView({super.key, required this.onAuthenticated});

  @override
  State<KioskLoginView> createState() => _KioskLoginViewState();
}

class _KioskLoginViewState extends State<KioskLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final client = supabaseOrNull;
    if (client == null) {
      setState(() {
        _errorMessage = 'Cliente Supabase não inicializado.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onAuthenticated();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Credenciais inválidas. Verifique e-mail e senha.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Erro de conexão ao autenticar no Supabase. Verifique o Wi-Fi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card.outlined(
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusXl,
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: AppSpacing.borderRadiusMd,
                              ),
                              child: Icon(
                                Icons.factory_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'G&M CHOCOLATES • KIOSK',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: AppTheme.fontHeading,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Entre com sua conta do sistema para carregar produtos e freezers do Supabase',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const ValueKey('kiosk_login_email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'E-mail de acesso',
                            prefixIcon: Icon(Icons.email_outlined, size: 18),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o e-mail';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          key: const ValueKey('kiosk_login_password'),
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          key: const ValueKey('kiosk_login_submit'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 18),
                          label: Text(
                            _isLoading
                                ? 'Autenticando...'
                                : 'Entrar e Sincronizar Catálogo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
