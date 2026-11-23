import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Serviço dedicado de quiosque que impede o sistema operacional de apagar
/// a tela ou suspender a CPU em qualquer tela do aplicativo.
///
/// É ativado imediatamente no `main()` e monitora o ciclo de vida do app
/// ([WidgetsBindingObserver]) para reforçar o WakeLock sempre que a janela
/// ganhar foco ou voltar ao primeiro plano.
final class KioskWakeLockService with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel(
    'com.gm_fabrica/kiosk_wakelock',
  );

  static final KioskWakeLockService instance = KioskWakeLockService._();

  bool _isObserving = false;

  KioskWakeLockService._();

  /// Ativa o bloqueio de tela permanentemente e registra o observer de ciclo de vida.
  static Future<void> ensureAlwaysAwake() async {
    if (!_instance._isObserving) {
      _instance._isObserving = true;
      WidgetsBinding.instance.addObserver(_instance);
    }
    await _instance._enableNativeWakeLock();
  }

  static KioskWakeLockService get _instance => instance;

  Future<void> _enableNativeWakeLock() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('enableWakeLock');
    } catch (_) {
      // No-op em ambiente de teste ou plataformas desktop sem handler
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      unawaited(_enableNativeWakeLock());
    }
  }
}
