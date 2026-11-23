import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';

/// Equipamento cadastrado na tabela `public.cost_centers` (`type = 'equipamento'`) do Supabase.
final class EquipmentModel extends BaseModel {
  final String name;
  final String typeCode;
  final String capacityUnit;
  final bool isActive;

  EquipmentModel({
    super.id,
    required this.name,
    this.typeCode = 'equipamento',
    this.capacityUnit = 'horas',
    this.isActive = true,
  });

  factory EquipmentModel.fromSupabaseMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? 'Equipamento',
      typeCode: (map['type'] as String?)?.trim() ?? 'equipamento',
      capacityUnit: (map['capacity_unit'] as String?)?.trim() ?? 'horas',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

/// Vínculo entre um sensor físico do ESP32 (`f1`, `f2`) e um equipamento (`cost_centers.id`).
final class FreezerSensorBindingModel {
  final String sensorKey;
  final int sensorIndex;
  final String? costCenterId;
  final String? costCenterName;
  final String? customLabel;
  final double targetTemperature;
  final double criticalTemperature;
  final int defaultCoolingSeconds;
  final int unloadMinSeconds;
  final int reloadMinSeconds;
  final int inspectionThresholdSeconds;
  final int maxDoorOpenSeconds;

  const FreezerSensorBindingModel({
    required this.sensorKey,
    required this.sensorIndex,
    this.costCenterId,
    this.costCenterName,
    this.customLabel,
    this.targetTemperature = 4.0,
    this.criticalTemperature = 8.0,
    this.defaultCoolingSeconds = 1200,
    this.unloadMinSeconds = 30,
    this.reloadMinSeconds = 60,
    this.inspectionThresholdSeconds = 12,
    this.maxDoorOpenSeconds = 60,
  });

  /// Nome efetivo do freezer: prioriza o nome do equipamento vinculado no Supabase (`cost_centers.name`).
  String get resolvedDisplayName {
    final eqName = costCenterName?.trim();
    if (eqName != null && eqName.isNotEmpty) {
      return eqName;
    }
    final custom = customLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return 'Sensor $sensorIndex (${sensorKey.toUpperCase()})';
  }

  factory FreezerSensorBindingModel.fromSupabaseMap(Map<String, dynamic> map) {
    final sensorKey = (map['sensor_key'] as String?)?.trim() ?? 'f1';
    final sensorIndex =
        (map['sensor_index'] as num?)?.toInt() ??
        (int.tryParse(sensorKey.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1);
    final ccMap = map['cost_centers'] as Map<String, dynamic>?;
    final ccId =
        (map['cost_center_id'] as String?) ?? (ccMap?['id'] as String?);
    final ccName =
        (ccMap?['name'] as String?) ?? (map['equipment_name'] as String?);

    return FreezerSensorBindingModel(
      sensorKey: sensorKey,
      sensorIndex: sensorIndex,
      costCenterId: ccId,
      costCenterName: ccName,
      customLabel: map['custom_label'] as String?,
      targetTemperature: (map['target_temperature'] as num?)?.toDouble() ?? 4.0,
      criticalTemperature:
          (map['critical_temperature'] as num?)?.toDouble() ?? 8.0,
      defaultCoolingSeconds:
          (map['default_cooling_seconds'] as num?)?.toInt() ?? 1200,
      unloadMinSeconds: (map['unload_min_seconds'] as num?)?.toInt() ?? 30,
      reloadMinSeconds: (map['reload_min_seconds'] as num?)?.toInt() ?? 60,
      inspectionThresholdSeconds:
          (map['inspection_threshold_seconds'] as num?)?.toInt() ?? 12,
      maxDoorOpenSeconds: (map['max_door_open_seconds'] as num?)?.toInt() ?? 60,
    );
  }
}

final class FreezerModel extends BaseModel {
  final int idSensor;
  final String name;
  final String description;
  final String? equipmentId;
  final String? equipmentName;

  FreezerModel({
    super.id,
    required this.idSensor,
    required this.name,
    required this.description,
    this.equipmentId,
    this.equipmentName,
  });
}
