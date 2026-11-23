import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';

final class ProductModel extends BaseModel {
  final String name;
  final String category;
  final String eanCode;
  final int unitWeightGrams;
  final int defaultBoxCapacity;
  final int defaultCoolingSeconds;
  final bool isActive;

  ProductModel({
    super.id,
    required this.name,
    this.category = 'geral',
    this.eanCode = '',
    required this.unitWeightGrams,
    int? defaultBoxCapacity,
    this.defaultCoolingSeconds = 480,
    this.isActive = true,
  }) : defaultBoxCapacity =
           (defaultBoxCapacity != null && defaultBoxCapacity > 0)
           ? defaultBoxCapacity
           : (unitWeightGrams >= 500 ? 40 : 50);

  /// Extrai gramatura a partir do nome (ex: "Ovo Ao Leite 250g" -> 250, "Barra 1kg" -> 1000).
  static int inferWeightGramsFromName(String name, {int fallback = 250}) {
    final gramsMatch = RegExp(
      r'(\d+)\s*g\b',
      caseSensitive: false,
    ).firstMatch(name);
    if (gramsMatch != null) {
      final parsed = int.tryParse(gramsMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }

    final kgMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*kg\b',
      caseSensitive: false,
    ).firstMatch(name);
    if (kgMatch != null) {
      final raw = (kgMatch.group(1) ?? '').replaceAll(',', '.');
      final parsedKg = double.tryParse(raw);
      if (parsedKg != null && parsedKg > 0) {
        return (parsedKg * 1000).round();
      }
    }
    return fallback;
  }

  factory ProductModel.fromSupabaseMap(Map<String, dynamic> map) {
    final name = (map['name'] as String?)?.trim() ?? 'Produto';
    final rawWeight = (map['unit_weight_grams'] as num?)?.toInt();
    final resolvedWeight = (rawWeight != null && rawWeight > 0)
        ? rawWeight
        : inferWeightGramsFromName(name);
    final rawBoxCap = (map['default_box_capacity'] as num?)?.toInt();
    final resolvedBoxCap = (rawBoxCap != null && rawBoxCap > 0)
        ? rawBoxCap
        : (resolvedWeight >= 500 ? 40 : 50);
    final rawCooling = (map['default_cooling_seconds'] as num?)?.toInt();
    final resolvedCooling = (rawCooling != null && rawCooling >= 60)
        ? rawCooling
        : 480;

    return ProductModel(
      id: map['id'] as String,
      name: name,
      category: (map['category'] as String?)?.trim() ?? 'geral',
      eanCode: (map['ean_code'] as String?)?.trim() ?? '',
      unitWeightGrams: resolvedWeight,
      defaultBoxCapacity: resolvedBoxCap,
      defaultCoolingSeconds: resolvedCooling,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    String? eanCode,
    int? unitWeightGrams,
    int? defaultBoxCapacity,
    int? defaultCoolingSeconds,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      eanCode: eanCode ?? this.eanCode,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
      defaultCoolingSeconds:
          defaultCoolingSeconds ?? this.defaultCoolingSeconds,
      isActive: isActive ?? this.isActive,
    );
  }
}
