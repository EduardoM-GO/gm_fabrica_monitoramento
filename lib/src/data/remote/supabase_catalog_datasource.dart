import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gm_fabrica_monitoramento/src/core/supabase/supabase_bootstrap.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contrato de busca e sincronização de Produtos (`public.products`) e
/// Equipamentos (`public.cost_centers` + `public.freezer_sensor_bindings`) no Supabase.
abstract interface class CatalogRemoteDatasource {
  bool get isAuthenticated;
  String? get currentUserEmail;

  Future<List<ProductModel>> fetchActiveProducts();
  Future<List<EquipmentModel>> fetchEquipments();
  Future<List<FreezerSensorBindingModel>> fetchFreezerSensorBindings();

  Future<void> upsertFreezerSensorBinding(FreezerSensorBindingModel binding);

  void subscribeRealtime({
    VoidCallback? onProductsChanged,
    VoidCallback? onEquipmentsChanged,
    VoidCallback? onBindingsChanged,
  });

  void dispose();
}

/// Implementação real conectada ao Supabase do ERP (`gm_chocolates_sistema`).
final class SupabaseCatalogDatasource implements CatalogRemoteDatasource {
  final SupabaseClient? _injectedClient;
  RealtimeChannel? _channel;

  SupabaseCatalogDatasource({SupabaseClient? client})
    : _injectedClient = client;

  SupabaseClient? get _client => _injectedClient ?? supabaseOrNull;

  @override
  bool get isAuthenticated => _client?.auth.currentSession != null;

  @override
  String? get currentUserEmail => _client?.auth.currentUser?.email;

  @override
  Future<List<ProductModel>> fetchActiveProducts() async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('name');

    return [
      for (final row in rows as List)
        ProductModel.fromSupabaseMap(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<List<EquipmentModel>> fetchEquipments() async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('cost_centers')
        .select()
        .eq('type', 'equipamento')
        .eq('is_active', true)
        .order('name');

    return [
      for (final row in rows as List)
        EquipmentModel.fromSupabaseMap(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<List<FreezerSensorBindingModel>> fetchFreezerSensorBindings() async {
    final client = _client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('freezer_sensor_bindings')
          .select('*, cost_centers(id, name, type)')
          .order('sensor_index');

      return [
        for (final row in rows as List)
          FreezerSensorBindingModel.fromSupabaseMap(
            Map<String, dynamic>.from(row as Map),
          ),
      ];
    } catch (e) {
      debugPrint('Aviso ao buscar freezer_sensor_bindings no Supabase: $e');
      return const [];
    }
  }

  @override
  Future<void> upsertFreezerSensorBinding(
    FreezerSensorBindingModel binding,
  ) async {
    final client = _client;
    if (client == null) return;

    await client.from('freezer_sensor_bindings').upsert({
      'sensor_key': binding.sensorKey,
      'sensor_index': binding.sensorIndex,
      'cost_center_id': binding.costCenterId,
      'custom_label': binding.customLabel,
      'target_temperature': binding.targetTemperature,
      'critical_temperature': binding.criticalTemperature,
      'default_cooling_seconds': binding.defaultCoolingSeconds,
      'unload_min_seconds': binding.unloadMinSeconds,
      'reload_min_seconds': binding.reloadMinSeconds,
      'inspection_threshold_seconds': binding.inspectionThresholdSeconds,
      'max_door_open_seconds': binding.maxDoorOpenSeconds,
    });
  }

  @override
  void subscribeRealtime({
    VoidCallback? onProductsChanged,
    VoidCallback? onEquipmentsChanged,
    VoidCallback? onBindingsChanged,
  }) {
    final client = _client;
    if (client == null) return;

    _channel?.unsubscribe();
    final ch = client.channel('kiosk_catalog_sync');

    if (onProductsChanged != null) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (_) => onProductsChanged(),
      );
    }

    if (onEquipmentsChanged != null) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'cost_centers',
        callback: (_) => onEquipmentsChanged(),
      );
    }

    if (onBindingsChanged != null) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'freezer_sensor_bindings',
        callback: (_) => onBindingsChanged(),
      );
    }

    ch.subscribe();
    _channel = ch;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
