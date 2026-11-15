import 'dart:async';
import 'dart:io';

/// Serviço de descoberta automática (Auto-Discovery) do ESP32 na rede local Wi-Fi.
/// Combina resolução mDNS/hostname, último IP conhecido e varredura paralela rápida na sub-rede.
final class Esp32DiscoveryService {
  const Esp32DiscoveryService();

  /// Tenta localizar o host do ESP32 respondendo na porta [port] (padrão 81).
  Future<String?> discoverHost({
    int port = 81,
    String? lastKnownHost,
    Duration probeTimeout = const Duration(milliseconds: 280),
  }) async {
    // 1. Tenta primeiro o último host válido conhecido ou esp32.local (mDNS)
    final priorityCandidates = <String>[
      if (lastKnownHost != null && lastKnownHost.trim().isNotEmpty)
        lastKnownHost.trim(),
      'esp32.local',
      '192.168.0.58',
    ];

    for (final host in priorityCandidates.toSet()) {
      if (await _canConnectTcp(host, port, timeout: probeTimeout)) {
        return host;
      }
    }

    // 2. Descobre o prefixo IPv4 da interface Wi-Fi local (ex: "192.168.0")
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
    const batchSize = 32;
    for (int start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final futures = <Future<String?>>[];

      for (int i = start; i <= end; i++) {
        final candidateIp = '$prefix.$i';
        futures.add(
          _canConnectTcp(candidateIp, port, timeout: timeout).then(
            (ok) => ok ? candidateIp : null,
          ),
        );
      }

      final results = await Future.wait(futures);
      for (final hit in results) {
        if (hit != null) {
          return hit;
        }
      }
    }
    return null;
  }
}

