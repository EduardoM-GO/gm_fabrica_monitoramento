class ProductEntity {
  final String id;
  final String name;
  final double unitWeightGrams; // Ex: 250.0 (Ovo Tradicional 250g)
  final int defaultBoxCapacity; // 40 ou 50
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.unitWeightGrams,
    this.defaultBoxCapacity = 50,
    this.isActive = true,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    double? unitWeightGrams,
    int? defaultBoxCapacity,
    bool? isActive,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
      isActive: isActive ?? this.isActive,
    );
  }
}

