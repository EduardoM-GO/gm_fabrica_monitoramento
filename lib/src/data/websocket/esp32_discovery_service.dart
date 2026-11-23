import 'dart:async';
import 'dart:io';

/// Serviço de descoberta automática (Auto-Discovery) ultra-rápida do ESP32 na rede local Wi-Fi (LAN).
/// Usa corrida paralela (first-hit) com timeout curto de LAN (150ms) para encontrar o ESP32 em poucos milissegundos.
final class Esp32DiscoveryService {
  const Esp32DiscoveryService();

  /// Tenta localizar o host do ESP32 respondendo na porta [port] (padrão 81).
  Future<String?> discoverHost({
    int port = 81,
    String? lastKnownHost,
    Duration probeTimeout = const Duration(milliseconds: 150),
  }) async {
    // 1. Testa em paralelo o último IP conhecido, padrão e mDNS — retorna no primeiro que responder
    final priorityCandidates = <String>{
      if (lastKnownHost != null && lastKnownHost.trim().isNotEmpty)
        lastKnownHost.trim(),
      '192.168.0.58',
      'esp32.local',
    }.toList();

    final priorityHit = await _firstReachableHost(
      priorityCandidates,
      port: port,
      timeout: probeTimeout,
    );
    if (priorityHit != null) {
      return priorityHit;
    }

    // 2. Descobre o prefixo IPv4 da interface Wi-Fi local (ex: "192.168.0") e varre em ondas largas
    final subnetPrefixes = await _getLocalIpv4Subnets();
    for (final prefix in subnetPrefixes) {
      final found = await _scanSubnet(
        prefix,
        port: port,
        timeout: probeTimeout,
      );
      if (found != null) {
        return found;
      }
    }

    return null;
  }

  /// Dispara probes TCP simultâneos e retorna imediatamente o primeiro host que aceitar conexão,
  /// sem esperar o timeout dos IPs inativos.
  Future<String?> _firstReachableHost(
    List<String> hosts, {
    required int port,
    required Duration timeout,
  }) async {
    if (hosts.isEmpty) return null;

    final completer = Completer<String?>();
    int remaining = hosts.length;

    for (final host in hosts) {
      _canConnectTcp(host, port, timeout: timeout).then((ok) {
        if (ok && !completer.isCompleted) {
          completer.complete(host);
          return;
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// Verifica se um host/IP aceita conexão TCP na porta do WebSocket
  Future<bool> _canConnectTcp(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Future<List<String>> _getLocalIpv4Subnets() async {
    final prefixes = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
    } catch (_) {}

    if (prefixes.isEmpty) {
      prefixes.add('192.168.0');
      prefixes.add('192.168.1');
    }
    return prefixes.toList();
  }

  Future<String?> _scanSubnet(
    String prefix, {
    required int port,
    required Duration timeout,
  }) async {
    // Ondas moderadas de 32 IPs com micro-yield ao event loop entre lotes para
    // nunca travar frames ou bloquear eventos de toque na UI thread.
    const batchSize = 32;
    for (int start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final candidates = <String>[
        for (int i = start; i <= end; i++) '$prefix.$i',
      ];

      final hit = await _firstReachableHost(
        candidates,
        port: port,
        timeout: timeout,
      );
      if (hit != null) {
        return hit;
      }
      // Cede tempo ao event loop do Flutter para processar gestos e frames pendentes
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
    return null;
  }
}

