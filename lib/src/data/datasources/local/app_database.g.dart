// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitWeightGramsMeta = const VerificationMeta(
    'unitWeightGrams',
  );
  @override
  late final GeneratedColumn<double> unitWeightGrams = GeneratedColumn<double>(
    'unit_weight_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultBoxCapacityMeta =
      const VerificationMeta('defaultBoxCapacity');
  @override
  late final GeneratedColumn<int> defaultBoxCapacity = GeneratedColumn<int>(
    'default_box_capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    unitWeightGrams,
    defaultBoxCapacity,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit_weight_grams')) {
      context.handle(
        _unitWeightGramsMeta,
        unitWeightGrams.isAcceptableOrUnknown(
          data['unit_weight_grams']!,
          _unitWeightGramsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitWeightGramsMeta);
    }
    if (data.containsKey('default_box_capacity')) {
      context.handle(
        _defaultBoxCapacityMeta,
        defaultBoxCapacity.isAcceptableOrUnknown(
          data['default_box_capacity']!,
          _defaultBoxCapacityMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unitWeightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_weight_grams'],
      )!,
      defaultBoxCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_box_capacity'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String name;
  final double unitWeightGrams;
  final int defaultBoxCapacity;
  final bool isActive;
  const ProductsTableData({
    required this.id,
    required this.name,
    required this.unitWeightGrams,
    required this.defaultBoxCapacity,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['unit_weight_grams'] = Variable<double>(unitWeightGrams);
    map['default_box_capacity'] = Variable<int>(defaultBoxCapacity);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      name: Value(name),
      unitWeightGrams: Value(unitWeightGrams),
      defaultBoxCapacity: Value(defaultBoxCapacity),
      isActive: Value(isActive),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unitWeightGrams: serializer.fromJson<double>(json['unitWeightGrams']),
      defaultBoxCapacity: serializer.fromJson<int>(json['defaultBoxCapacity']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'unitWeightGrams': serializer.toJson<double>(unitWeightGrams),
      'defaultBoxCapacity': serializer.toJson<int>(defaultBoxCapacity),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ProductsTableData copyWith({
    String? id,
    String? name,
    double? unitWeightGrams,
    int? defaultBoxCapacity,
    bool? isActive,
  }) => ProductsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
    defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
    isActive: isActive ?? this.isActive,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unitWeightGrams: data.unitWeightGrams.present
          ? data.unitWeightGrams.value
          : this.unitWeightGrams,
      defaultBoxCapacity: data.defaultBoxCapacity.present
          ? data.defaultBoxCapacity.value
          : this.defaultBoxCapacity,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unitWeightGrams: $unitWeightGrams, ')
          ..write('defaultBoxCapacity: $defaultBoxCapacity, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, unitWeightGrams, defaultBoxCapacity, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.unitWeightGrams == this.unitWeightGrams &&
          other.defaultBoxCapacity == this.defaultBoxCapacity &&
          other.isActive == this.isActive);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> unitWeightGrams;
  final Value<int> defaultBoxCapacity;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unitWeightGrams = const Value.absent(),
    this.defaultBoxCapacity = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String name,
    required double unitWeightGrams,
    this.defaultBoxCapacity = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       unitWeightGrams = Value(unitWeightGrams);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? unitWeightGrams,
    Expression<int>? defaultBoxCapacity,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unitWeightGrams != null) 'unit_weight_grams': unitWeightGrams,
      if (defaultBoxCapacity != null)
        'default_box_capacity': defaultBoxCapacity,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? unitWeightGrams,
    Value<int>? defaultBoxCapacity,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unitWeightGrams.present) {
      map['unit_weight_grams'] = Variable<double>(unitWeightGrams.value);
    }
    if (defaultBoxCapacity.present) {
      map['default_box_capacity'] = Variable<int>(defaultBoxCapacity.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unitWeightGrams: $unitWeightGrams, ')
          ..write('defaultBoxCapacity: $defaultBoxCapacity, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductionBatchesTableTable extends ProductionBatchesTable
    with TableInfo<$ProductionBatchesTableTable, ProductionBatchesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionBatchesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialHardwareCountMeta =
      const VerificationMeta('initialHardwareCount');
  @override
  late final GeneratedColumn<int> initialHardwareCount = GeneratedColumn<int>(
    'initial_hardware_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossProducedCountMeta =
      const VerificationMeta('grossProducedCount');
  @override
  late final GeneratedColumn<int> grossProducedCount = GeneratedColumn<int>(
    'gross_produced_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discardedCountMeta = const VerificationMeta(
    'discardedCount',
  );
  @override
  late final GeneratedColumn<int> discardedCount = GeneratedColumn<int>(
    'discarded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    startedAt,
    finishedAt,
    initialHardwareCount,
    grossProducedCount,
    discardedCount,
    status,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_batches_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionBatchesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('initial_hardware_count')) {
      context.handle(
        _initialHardwareCountMeta,
        initialHardwareCount.isAcceptableOrUnknown(
          data['initial_hardware_count']!,
          _initialHardwareCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialHardwareCountMeta);
    }
    if (data.containsKey('gross_produced_count')) {
      context.handle(
        _grossProducedCountMeta,
        grossProducedCount.isAcceptableOrUnknown(
          data['gross_produced_count']!,
          _grossProducedCountMeta,
        ),
      );
    }
    if (data.containsKey('discarded_count')) {
      context.handle(
        _discardedCountMeta,
        discardedCount.isAcceptableOrUnknown(
          data['discarded_count']!,
          _discardedCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionBatchesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionBatchesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      initialHardwareCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_hardware_count'],
      )!,
      grossProducedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_produced_count'],
      )!,
      discardedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discarded_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ProductionBatchesTableTable createAlias(String alias) {
    return $ProductionBatchesTableTable(attachedDatabase, alias);
  }
}

class ProductionBatchesTableData extends DataClass
    implements Insertable<ProductionBatchesTableData> {
  final String id;
  final String productId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int initialHardwareCount;
  final int grossProducedCount;
  final int discardedCount;
  final String status;
  final bool synced;
  const ProductionBatchesTableData({
    required this.id,
    required this.productId,
    required this.startedAt,
    this.finishedAt,
    required this.initialHardwareCount,
    required this.grossProducedCount,
    required this.discardedCount,
    required this.status,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['initial_hardware_count'] = Variable<int>(initialHardwareCount);
    map['gross_produced_count'] = Variable<int>(grossProducedCount);
    map['discarded_count'] = Variable<int>(discardedCount);
    map['status'] = Variable<String>(status);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ProductionBatchesTableCompanion toCompanion(bool nullToAbsent) {
    return ProductionBatchesTableCompanion(
      id: Value(id),
      productId: Value(productId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      initialHardwareCount: Value(initialHardwareCount),
      grossProducedCount: Value(grossProducedCount),
      discardedCount: Value(discardedCount),
      status: Value(status),
      synced: Value(synced),
    );
  }

  factory ProductionBatchesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionBatchesTableData(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      initialHardwareCount: serializer.fromJson<int>(
        json['initialHardwareCount'],
      ),
      grossProducedCount: serializer.fromJson<int>(json['grossProducedCount']),
      discardedCount: serializer.fromJson<int>(json['discardedCount']),
      status: serializer.fromJson<String>(json['status']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'initialHardwareCount': serializer.toJson<int>(initialHardwareCount),
      'grossProducedCount': serializer.toJson<int>(grossProducedCount),
      'discardedCount': serializer.toJson<int>(discardedCount),
      'status': serializer.toJson<String>(status),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ProductionBatchesTableData copyWith({
    String? id,
    String? productId,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    int? initialHardwareCount,
    int? grossProducedCount,
    int? discardedCount,
    String? status,
    bool? synced,
  }) => ProductionBatchesTableData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    initialHardwareCount: initialHardwareCount ?? this.initialHardwareCount,
    grossProducedCount: grossProducedCount ?? this.grossProducedCount,
    discardedCount: discardedCount ?? this.discardedCount,
    status: status ?? this.status,
    synced: synced ?? this.synced,
  );
  ProductionBatchesTableData copyWithCompanion(
    ProductionBatchesTableCompanion data,
  ) {
    return ProductionBatchesTableData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      initialHardwareCount: data.initialHardwareCount.present
          ? data.initialHardwareCount.value
          : this.initialHardwareCount,
      grossProducedCount: data.grossProducedCount.present
          ? data.grossProducedCount.value
          : this.grossProducedCount,
      discardedCount: data.discardedCount.present
          ? data.discardedCount.value
          : this.discardedCount,
      status: data.status.present ? data.status.value : this.status,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchesTableData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('initialHardwareCount: $initialHardwareCount, ')
          ..write('grossProducedCount: $grossProducedCount, ')
          ..write('discardedCount: $discardedCount, ')
          ..write('status: $status, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    startedAt,
    finishedAt,
    initialHardwareCount,
    grossProducedCount,
    discardedCount,
    status,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionBatchesTableData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.initialHardwareCount == this.initialHardwareCount &&
          other.grossProducedCount == this.grossProducedCount &&
          other.discardedCount == this.discardedCount &&
          other.status == this.status &&
          other.synced == this.synced);
}

class ProductionBatchesTableCompanion
    extends UpdateCompanion<ProductionBatchesTableData> {
  final Value<String> id;
  final Value<String> productId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> initialHardwareCount;
  final Value<int> grossProducedCount;
  final Value<int> discardedCount;
  final Value<String> status;
  final Value<bool> synced;
  final Value<int> rowid;
  const ProductionBatchesTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.initialHardwareCount = const Value.absent(),
    this.grossProducedCount = const Value.absent(),
    this.discardedCount = const Value.absent(),
    this.status = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductionBatchesTableCompanion.insert({
    required String id,
    required String productId,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    required int initialHardwareCount,
    this.grossProducedCount = const Value.absent(),
    this.discardedCount = const Value.absent(),
    required String status,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       startedAt = Value(startedAt),
       initialHardwareCount = Value(initialHardwareCount),
       status = Value(status);
  static Insertable<ProductionBatchesTableData> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? initialHardwareCount,
    Expression<int>? grossProducedCount,
    Expression<int>? discardedCount,
    Expression<String>? status,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (initialHardwareCount != null)
        'initial_hardware_count': initialHardwareCount,
      if (grossProducedCount != null)
        'gross_produced_count': grossProducedCount,
      if (discardedCount != null) 'discarded_count': discardedCount,
      if (status != null) 'status': status,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductionBatchesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? initialHardwareCount,
    Value<int>? grossProducedCount,
    Value<int>? discardedCount,
    Value<String>? status,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return ProductionBatchesTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      initialHardwareCount: initialHardwareCount ?? this.initialHardwareCount,
      grossProducedCount: grossProducedCount ?? this.grossProducedCount,
      discardedCount: discardedCount ?? this.discardedCount,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (initialHardwareCount.present) {
      map['initial_hardware_count'] = Variable<int>(initialHardwareCount.value);
    }
    if (grossProducedCount.present) {
      map['gross_produced_count'] = Variable<int>(grossProducedCount.value);
    }
    if (discardedCount.present) {
      map['discarded_count'] = Variable<int>(discardedCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchesTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('initialHardwareCount: $initialHardwareCount, ')
          ..write('grossProducedCount: $grossProducedCount, ')
          ..write('discardedCount: $discardedCount, ')
          ..write('status: $status, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchAdjustmentsTableTable extends BatchAdjustmentsTable
    with TableInfo<$BatchAdjustmentsTableTable, BatchAdjustmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchAdjustmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNoteMeta = const VerificationMeta(
    'customNote',
  );
  @override
  late final GeneratedColumn<String> customNote = GeneratedColumn<String>(
    'custom_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deltaQuantityMeta = const VerificationMeta(
    'deltaQuantity',
  );
  @override
  late final GeneratedColumn<int> deltaQuantity = GeneratedColumn<int>(
    'delta_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchId,
    reason,
    customNote,
    deltaQuantity,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_adjustments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchAdjustmentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('custom_note')) {
      context.handle(
        _customNoteMeta,
        customNote.isAcceptableOrUnknown(data['custom_note']!, _customNoteMeta),
      );
    }
    if (data.containsKey('delta_quantity')) {
      context.handle(
        _deltaQuantityMeta,
        deltaQuantity.isAcceptableOrUnknown(
          data['delta_quantity']!,
          _deltaQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deltaQuantityMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchAdjustmentsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchAdjustmentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      customNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_note'],
      ),
      deltaQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta_quantity'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $BatchAdjustmentsTableTable createAlias(String alias) {
    return $BatchAdjustmentsTableTable(attachedDatabase, alias);
  }
}

class BatchAdjustmentsTableData extends DataClass
    implements Insertable<BatchAdjustmentsTableData> {
  final String id;
  final String batchId;
  final String reason;
  final String? customNote;
  final int deltaQuantity;
  final DateTime createdAt;
  final bool synced;
  const BatchAdjustmentsTableData({
    required this.id,
    required this.batchId,
    required this.reason,
    this.customNote,
    required this.deltaQuantity,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['batch_id'] = Variable<String>(batchId);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || customNote != null) {
      map['custom_note'] = Variable<String>(customNote);
    }
    map['delta_quantity'] = Variable<int>(deltaQuantity);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  BatchAdjustmentsTableCompanion toCompanion(bool nullToAbsent) {
    return BatchAdjustmentsTableCompanion(
      id: Value(id),
      batchId: Value(batchId),
      reason: Value(reason),
      customNote: customNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customNote),
      deltaQuantity: Value(deltaQuantity),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory BatchAdjustmentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchAdjustmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      batchId: serializer.fromJson<String>(json['batchId']),
      reason: serializer.fromJson<String>(json['reason']),
      customNote: serializer.fromJson<String?>(json['customNote']),
      deltaQuantity: serializer.fromJson<int>(json['deltaQuantity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'batchId': serializer.toJson<String>(batchId),
      'reason': serializer.toJson<String>(reason),
      'customNote': serializer.toJson<String?>(customNote),
      'deltaQuantity': serializer.toJson<int>(deltaQuantity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  BatchAdjustmentsTableData copyWith({
    String? id,
    String? batchId,
    String? reason,
    Value<String?> customNote = const Value.absent(),
    int? deltaQuantity,
    DateTime? createdAt,
    bool? synced,
  }) => BatchAdjustmentsTableData(
    id: id ?? this.id,
    batchId: batchId ?? this.batchId,
    reason: reason ?? this.reason,
    customNote: customNote.present ? customNote.value : this.customNote,
    deltaQuantity: deltaQuantity ?? this.deltaQuantity,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  BatchAdjustmentsTableData copyWithCompanion(
    BatchAdjustmentsTableCompanion data,
  ) {
    return BatchAdjustmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      reason: data.reason.present ? data.reason.value : this.reason,
      customNote: data.customNote.present
          ? data.customNote.value
          : this.customNote,
      deltaQuantity: data.deltaQuantity.present
          ? data.deltaQuantity.value
          : this.deltaQuantity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchAdjustmentsTableData(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('reason: $reason, ')
          ..write('customNote: $customNote, ')
          ..write('deltaQuantity: $deltaQuantity, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    batchId,
    reason,
    customNote,
    deltaQuantity,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchAdjustmentsTableData &&
          other.id == this.id &&
          other.batchId == this.batchId &&
          other.reason == this.reason &&
          other.customNote == this.customNote &&
          other.deltaQuantity == this.deltaQuantity &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class BatchAdjustmentsTableCompanion
    extends UpdateCompanion<BatchAdjustmentsTableData> {
  final Value<String> id;
  final Value<String> batchId;
  final Value<String> reason;
  final Value<String?> customNote;
  final Value<int> deltaQuantity;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const BatchAdjustmentsTableCompanion({
    this.id = const Value.absent(),
    this.batchId = const Value.absent(),
    this.reason = const Value.absent(),
    this.customNote = const Value.absent(),
    this.deltaQuantity = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchAdjustmentsTableCompanion.insert({
    required String id,
    required String batchId,
    required String reason,
    this.customNote = const Value.absent(),
    required int deltaQuantity,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       reason = Value(reason),
       deltaQuantity = Value(deltaQuantity),
       createdAt = Value(createdAt);
  static Insertable<BatchAdjustmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? batchId,
    Expression<String>? reason,
    Expression<String>? customNote,
    Expression<int>? deltaQuantity,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchId != null) 'batch_id': batchId,
      if (reason != null) 'reason': reason,
      if (customNote != null) 'custom_note': customNote,
      if (deltaQuantity != null) 'delta_quantity': deltaQuantity,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchAdjustmentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? batchId,
    Value<String>? reason,
    Value<String?>? customNote,
    Value<int>? deltaQuantity,
    Value<DateTime>? createdAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return BatchAdjustmentsTableCompanion(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      reason: reason ?? this.reason,
      customNote: customNote ?? this.customNote,
      deltaQuantity: deltaQuantity ?? this.deltaQuantity,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (customNote.present) {
      map['custom_note'] = Variable<String>(customNote.value);
    }
    if (deltaQuantity.present) {
      map['delta_quantity'] = Variable<int>(deltaQuantity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchAdjustmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('reason: $reason, ')
          ..write('customNote: $customNote, ')
          ..write('deltaQuantity: $deltaQuantity, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreezerTelemetryLogsTableTable extends FreezerTelemetryLogsTable
    with
        TableInfo<
          $FreezerTelemetryLogsTableTable,
          FreezerTelemetryLogsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreezerTelemetryLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _freezerIdMeta = const VerificationMeta(
    'freezerId',
  );
  @override
  late final GeneratedColumn<String> freezerId = GeneratedColumn<String>(
    'freezer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoorOpenMeta = const VerificationMeta(
    'isDoorOpen',
  );
  @override
  late final GeneratedColumn<bool> isDoorOpen = GeneratedColumn<bool>(
    'is_door_open',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_door_open" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isSensorOkMeta = const VerificationMeta(
    'isSensorOk',
  );
  @override
  late final GeneratedColumn<bool> isSensorOk = GeneratedColumn<bool>(
    'is_sensor_ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sensor_ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerReasonMeta = const VerificationMeta(
    'triggerReason',
  );
  @override
  late final GeneratedColumn<String> triggerReason = GeneratedColumn<String>(
    'trigger_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    freezerId,
    temperature,
    isDoorOpen,
    isSensorOk,
    recordedAt,
    triggerReason,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freezer_telemetry_logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FreezerTelemetryLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('freezer_id')) {
      context.handle(
        _freezerIdMeta,
        freezerId.isAcceptableOrUnknown(data['freezer_id']!, _freezerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_freezerIdMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureMeta);
    }
    if (data.containsKey('is_door_open')) {
      context.handle(
        _isDoorOpenMeta,
        isDoorOpen.isAcceptableOrUnknown(
          data['is_door_open']!,
          _isDoorOpenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDoorOpenMeta);
    }
    if (data.containsKey('is_sensor_ok')) {
      context.handle(
        _isSensorOkMeta,
        isSensorOk.isAcceptableOrUnknown(
          data['is_sensor_ok']!,
          _isSensorOkMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSensorOkMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('trigger_reason')) {
      context.handle(
        _triggerReasonMeta,
        triggerReason.isAcceptableOrUnknown(
          data['trigger_reason']!,
          _triggerReasonMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FreezerTelemetryLogsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreezerTelemetryLogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freezer_id'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      isDoorOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_door_open'],
      )!,
      isSensorOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sensor_ok'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      triggerReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_reason'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $FreezerTelemetryLogsTableTable createAlias(String alias) {
    return $FreezerTelemetryLogsTableTable(attachedDatabase, alias);
  }
}

class FreezerTelemetryLogsTableData extends DataClass
    implements Insertable<FreezerTelemetryLogsTableData> {
  final String id;
  final String freezerId;
  final double temperature;
  final bool isDoorOpen;
  final bool isSensorOk;
  final DateTime recordedAt;
  final String? triggerReason;
  final bool synced;
  const FreezerTelemetryLogsTableData({
    required this.id,
    required this.freezerId,
    required this.temperature,
    required this.isDoorOpen,
    required this.isSensorOk,
    required this.recordedAt,
    this.triggerReason,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['freezer_id'] = Variable<String>(freezerId);
    map['temperature'] = Variable<double>(temperature);
    map['is_door_open'] = Variable<bool>(isDoorOpen);
    map['is_sensor_ok'] = Variable<bool>(isSensorOk);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || triggerReason != null) {
      map['trigger_reason'] = Variable<String>(triggerReason);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  FreezerTelemetryLogsTableCompanion toCompanion(bool nullToAbsent) {
    return FreezerTelemetryLogsTableCompanion(
      id: Value(id),
      freezerId: Value(freezerId),
      temperature: Value(temperature),
      isDoorOpen: Value(isDoorOpen),
      isSensorOk: Value(isSensorOk),
      recordedAt: Value(recordedAt),
      triggerReason: triggerReason == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerReason),
      synced: Value(synced),
    );
  }

  factory FreezerTelemetryLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreezerTelemetryLogsTableData(
      id: serializer.fromJson<String>(json['id']),
      freezerId: serializer.fromJson<String>(json['freezerId']),
      temperature: serializer.fromJson<double>(json['temperature']),
      isDoorOpen: serializer.fromJson<bool>(json['isDoorOpen']),
      isSensorOk: serializer.fromJson<bool>(json['isSensorOk']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      triggerReason: serializer.fromJson<String?>(json['triggerReason']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'freezerId': serializer.toJson<String>(freezerId),
      'temperature': serializer.toJson<double>(temperature),
      'isDoorOpen': serializer.toJson<bool>(isDoorOpen),
      'isSensorOk': serializer.toJson<bool>(isSensorOk),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'triggerReason': serializer.toJson<String?>(triggerReason),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  FreezerTelemetryLogsTableData copyWith({
    String? id,
    String? freezerId,
    double? temperature,
    bool? isDoorOpen,
    bool? isSensorOk,
    DateTime? recordedAt,
    Value<String?> triggerReason = const Value.absent(),
    bool? synced,
  }) => FreezerTelemetryLogsTableData(
    id: id ?? this.id,
    freezerId: freezerId ?? this.freezerId,
    temperature: temperature ?? this.temperature,
    isDoorOpen: isDoorOpen ?? this.isDoorOpen,
    isSensorOk: isSensorOk ?? this.isSensorOk,
    recordedAt: recordedAt ?? this.recordedAt,
    triggerReason: triggerReason.present
        ? triggerReason.value
        : this.triggerReason,
    synced: synced ?? this.synced,
  );
  FreezerTelemetryLogsTableData copyWithCompanion(
    FreezerTelemetryLogsTableCompanion data,
  ) {
    return FreezerTelemetryLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      isDoorOpen: data.isDoorOpen.present
          ? data.isDoorOpen.value
          : this.isDoorOpen,
      isSensorOk: data.isSensorOk.present
          ? data.isSensorOk.value
          : this.isSensorOk,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      triggerReason: data.triggerReason.present
          ? data.triggerReason.value
          : this.triggerReason,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreezerTelemetryLogsTableData(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('temperature: $temperature, ')
          ..write('isDoorOpen: $isDoorOpen, ')
          ..write('isSensorOk: $isSensorOk, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('triggerReason: $triggerReason, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    freezerId,
    temperature,
    isDoorOpen,
    isSensorOk,
    recordedAt,
    triggerReason,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreezerTelemetryLogsTableData &&
          other.id == this.id &&
          other.freezerId == this.freezerId &&
          other.temperature == this.temperature &&
          other.isDoorOpen == this.isDoorOpen &&
          other.isSensorOk == this.isSensorOk &&
          other.recordedAt == this.recordedAt &&
          other.triggerReason == this.triggerReason &&
          other.synced == this.synced);
}

class FreezerTelemetryLogsTableCompanion
    extends UpdateCompanion<FreezerTelemetryLogsTableData> {
  final Value<String> id;
  final Value<String> freezerId;
  final Value<double> temperature;
  final Value<bool> isDoorOpen;
  final Value<bool> isSensorOk;
  final Value<DateTime> recordedAt;
  final Value<String?> triggerReason;
  final Value<bool> synced;
  final Value<int> rowid;
  const FreezerTelemetryLogsTableCompanion({
    this.id = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.isDoorOpen = const Value.absent(),
    this.isSensorOk = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.triggerReason = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreezerTelemetryLogsTableCompanion.insert({
    required String id,
    required String freezerId,
    required double temperature,
    required bool isDoorOpen,
    required bool isSensorOk,
    required DateTime recordedAt,
    this.triggerReason = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       freezerId = Value(freezerId),
       temperature = Value(temperature),
       isDoorOpen = Value(isDoorOpen),
       isSensorOk = Value(isSensorOk),
       recordedAt = Value(recordedAt);
  static Insertable<FreezerTelemetryLogsTableData> custom({
    Expression<String>? id,
    Expression<String>? freezerId,
    Expression<double>? temperature,
    Expression<bool>? isDoorOpen,
    Expression<bool>? isSensorOk,
    Expression<DateTime>? recordedAt,
    Expression<String>? triggerReason,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (freezerId != null) 'freezer_id': freezerId,
      if (temperature != null) 'temperature': temperature,
      if (isDoorOpen != null) 'is_door_open': isDoorOpen,
      if (isSensorOk != null) 'is_sensor_ok': isSensorOk,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (triggerReason != null) 'trigger_reason': triggerReason,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreezerTelemetryLogsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? freezerId,
    Value<double>? temperature,
    Value<bool>? isDoorOpen,
    Value<bool>? isSensorOk,
    Value<DateTime>? recordedAt,
    Value<String?>? triggerReason,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return FreezerTelemetryLogsTableCompanion(
      id: id ?? this.id,
      freezerId: freezerId ?? this.freezerId,
      temperature: temperature ?? this.temperature,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      isSensorOk: isSensorOk ?? this.isSensorOk,
      recordedAt: recordedAt ?? this.recordedAt,
      triggerReason: triggerReason ?? this.triggerReason,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<String>(freezerId.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (isDoorOpen.present) {
      map['is_door_open'] = Variable<bool>(isDoorOpen.value);
    }
    if (isSensorOk.present) {
      map['is_sensor_ok'] = Variable<bool>(isSensorOk.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (triggerReason.present) {
      map['trigger_reason'] = Variable<String>(triggerReason.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreezerTelemetryLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('temperature: $temperature, ')
          ..write('isDoorOpen: $isDoorOpen, ')
          ..write('isSensorOk: $isSensorOk, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('triggerReason: $triggerReason, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    operation,
    payloadJson,
    queuedAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String targetTable;
  final String recordId;
  final String operation;
  final String payloadJson;
  final DateTime queuedAt;
  final int retryCount;
  final String? lastError;
  const SyncQueueTableData({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.payloadJson,
    required this.queuedAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      queuedAt: Value(queuedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? targetTable,
    String? recordId,
    String? operation,
    String? payloadJson,
    DateTime? queuedAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueTableData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    queuedAt: queuedAt ?? this.queuedAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    recordId,
    operation,
    payloadJson,
    queuedAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.queuedAt == this.queuedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> queuedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String recordId,
    required String operation,
    required String payloadJson,
    required DateTime queuedAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : targetTable = Value(targetTable),
       recordId = Value(recordId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       queuedAt = Value(queuedAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? queuedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? recordId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<DateTime>? queuedAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductionBatchesTableTable productionBatchesTable =
      $ProductionBatchesTableTable(this);
  late final $BatchAdjustmentsTableTable batchAdjustmentsTable =
      $BatchAdjustmentsTableTable(this);
  late final $FreezerTelemetryLogsTableTable freezerTelemetryLogsTable =
      $FreezerTelemetryLogsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final ProductionDao productionDao = ProductionDao(this as AppDatabase);
  late final FreezerDao freezerDao = FreezerDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productsTable,
    productionBatchesTable,
    batchAdjustmentsTable,
    freezerTelemetryLogsTable,
    syncQueueTable,
  ];
}

typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String name,
      required double unitWeightGrams,
      Value<int> defaultBoxCapacity,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> unitWeightGrams,
      Value<int> defaultBoxCapacity,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitWeightGrams => $composableBuilder(
    column: $table.unitWeightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitWeightGrams => $composableBuilder(
    column: $table.unitWeightGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get unitWeightGrams => $composableBuilder(
    column: $table.unitWeightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductsTableTable,
              ProductsTableData
            >,
          ),
          ProductsTableData,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> unitWeightGrams = const Value.absent(),
                Value<int> defaultBoxCapacity = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                name: name,
                unitWeightGrams: unitWeightGrams,
                defaultBoxCapacity: defaultBoxCapacity,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double unitWeightGrams,
                Value<int> defaultBoxCapacity = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                name: name,
                unitWeightGrams: unitWeightGrams,
                defaultBoxCapacity: defaultBoxCapacity,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductsTableData,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>,
      ),
      ProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductionBatchesTableTableCreateCompanionBuilder =
    ProductionBatchesTableCompanion Function({
      required String id,
      required String productId,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      required int initialHardwareCount,
      Value<int> grossProducedCount,
      Value<int> discardedCount,
      required String status,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$ProductionBatchesTableTableUpdateCompanionBuilder =
    ProductionBatchesTableCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> initialHardwareCount,
      Value<int> grossProducedCount,
      Value<int> discardedCount,
      Value<String> status,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$ProductionBatchesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTableTable> {
  $$ProductionBatchesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossProducedCount => $composableBuilder(
    column: $table.grossProducedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discardedCount => $composableBuilder(
    column: $table.discardedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductionBatchesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTableTable> {
  $$ProductionBatchesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossProducedCount => $composableBuilder(
    column: $table.grossProducedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discardedCount => $composableBuilder(
    column: $table.discardedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductionBatchesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTableTable> {
  $$ProductionBatchesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grossProducedCount => $composableBuilder(
    column: $table.grossProducedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discardedCount => $composableBuilder(
    column: $table.discardedCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ProductionBatchesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionBatchesTableTable,
          ProductionBatchesTableData,
          $$ProductionBatchesTableTableFilterComposer,
          $$ProductionBatchesTableTableOrderingComposer,
          $$ProductionBatchesTableTableAnnotationComposer,
          $$ProductionBatchesTableTableCreateCompanionBuilder,
          $$ProductionBatchesTableTableUpdateCompanionBuilder,
          (
            ProductionBatchesTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductionBatchesTableTable,
              ProductionBatchesTableData
            >,
          ),
          ProductionBatchesTableData,
          PrefetchHooks Function()
        > {
  $$ProductionBatchesTableTableTableManager(
    _$AppDatabase db,
    $ProductionBatchesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionBatchesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductionBatchesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductionBatchesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> initialHardwareCount = const Value.absent(),
                Value<int> grossProducedCount = const Value.absent(),
                Value<int> discardedCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductionBatchesTableCompanion(
                id: id,
                productId: productId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                initialHardwareCount: initialHardwareCount,
                grossProducedCount: grossProducedCount,
                discardedCount: discardedCount,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                required int initialHardwareCount,
                Value<int> grossProducedCount = const Value.absent(),
                Value<int> discardedCount = const Value.absent(),
                required String status,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductionBatchesTableCompanion.insert(
                id: id,
                productId: productId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                initialHardwareCount: initialHardwareCount,
                grossProducedCount: grossProducedCount,
                discardedCount: discardedCount,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductionBatchesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductionBatchesTableTable,
      ProductionBatchesTableData,
      $$ProductionBatchesTableTableFilterComposer,
      $$ProductionBatchesTableTableOrderingComposer,
      $$ProductionBatchesTableTableAnnotationComposer,
      $$ProductionBatchesTableTableCreateCompanionBuilder,
      $$ProductionBatchesTableTableUpdateCompanionBuilder,
      (
        ProductionBatchesTableData,
        BaseReferences<
          _$AppDatabase,
          $ProductionBatchesTableTable,
          ProductionBatchesTableData
        >,
      ),
      ProductionBatchesTableData,
      PrefetchHooks Function()
    >;
typedef $$BatchAdjustmentsTableTableCreateCompanionBuilder =
    BatchAdjustmentsTableCompanion Function({
      required String id,
      required String batchId,
      required String reason,
      Value<String?> customNote,
      required int deltaQuantity,
      required DateTime createdAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$BatchAdjustmentsTableTableUpdateCompanionBuilder =
    BatchAdjustmentsTableCompanion Function({
      Value<String> id,
      Value<String> batchId,
      Value<String> reason,
      Value<String?> customNote,
      Value<int> deltaQuantity,
      Value<DateTime> createdAt,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$BatchAdjustmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BatchAdjustmentsTableTable> {
  $$BatchAdjustmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deltaQuantity => $composableBuilder(
    column: $table.deltaQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchAdjustmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchAdjustmentsTableTable> {
  $$BatchAdjustmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deltaQuantity => $composableBuilder(
    column: $table.deltaQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchAdjustmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchAdjustmentsTableTable> {
  $$BatchAdjustmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deltaQuantity => $composableBuilder(
    column: $table.deltaQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BatchAdjustmentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchAdjustmentsTableTable,
          BatchAdjustmentsTableData,
          $$BatchAdjustmentsTableTableFilterComposer,
          $$BatchAdjustmentsTableTableOrderingComposer,
          $$BatchAdjustmentsTableTableAnnotationComposer,
          $$BatchAdjustmentsTableTableCreateCompanionBuilder,
          $$BatchAdjustmentsTableTableUpdateCompanionBuilder,
          (
            BatchAdjustmentsTableData,
            BaseReferences<
              _$AppDatabase,
              $BatchAdjustmentsTableTable,
              BatchAdjustmentsTableData
            >,
          ),
          BatchAdjustmentsTableData,
          PrefetchHooks Function()
        > {
  $$BatchAdjustmentsTableTableTableManager(
    _$AppDatabase db,
    $BatchAdjustmentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchAdjustmentsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BatchAdjustmentsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BatchAdjustmentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> customNote = const Value.absent(),
                Value<int> deltaQuantity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchAdjustmentsTableCompanion(
                id: id,
                batchId: batchId,
                reason: reason,
                customNote: customNote,
                deltaQuantity: deltaQuantity,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String batchId,
                required String reason,
                Value<String?> customNote = const Value.absent(),
                required int deltaQuantity,
                required DateTime createdAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchAdjustmentsTableCompanion.insert(
                id: id,
                batchId: batchId,
                reason: reason,
                customNote: customNote,
                deltaQuantity: deltaQuantity,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchAdjustmentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchAdjustmentsTableTable,
      BatchAdjustmentsTableData,
      $$BatchAdjustmentsTableTableFilterComposer,
      $$BatchAdjustmentsTableTableOrderingComposer,
      $$BatchAdjustmentsTableTableAnnotationComposer,
      $$BatchAdjustmentsTableTableCreateCompanionBuilder,
      $$BatchAdjustmentsTableTableUpdateCompanionBuilder,
      (
        BatchAdjustmentsTableData,
        BaseReferences<
          _$AppDatabase,
          $BatchAdjustmentsTableTable,
          BatchAdjustmentsTableData
        >,
      ),
      BatchAdjustmentsTableData,
      PrefetchHooks Function()
    >;
typedef $$FreezerTelemetryLogsTableTableCreateCompanionBuilder =
    FreezerTelemetryLogsTableCompanion Function({
      required String id,
      required String freezerId,
      required double temperature,
      required bool isDoorOpen,
      required bool isSensorOk,
      required DateTime recordedAt,
      Value<String?> triggerReason,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$FreezerTelemetryLogsTableTableUpdateCompanionBuilder =
    FreezerTelemetryLogsTableCompanion Function({
      Value<String> id,
      Value<String> freezerId,
      Value<double> temperature,
      Value<bool> isDoorOpen,
      Value<bool> isSensorOk,
      Value<DateTime> recordedAt,
      Value<String?> triggerReason,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$FreezerTelemetryLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FreezerTelemetryLogsTableTable> {
  $$FreezerTelemetryLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDoorOpen => $composableBuilder(
    column: $table.isDoorOpen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSensorOk => $composableBuilder(
    column: $table.isSensorOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerReason => $composableBuilder(
    column: $table.triggerReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FreezerTelemetryLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FreezerTelemetryLogsTableTable> {
  $$FreezerTelemetryLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDoorOpen => $composableBuilder(
    column: $table.isDoorOpen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSensorOk => $composableBuilder(
    column: $table.isSensorOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerReason => $composableBuilder(
    column: $table.triggerReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FreezerTelemetryLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreezerTelemetryLogsTableTable> {
  $$FreezerTelemetryLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get freezerId =>
      $composableBuilder(column: $table.freezerId, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDoorOpen => $composableBuilder(
    column: $table.isDoorOpen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSensorOk => $composableBuilder(
    column: $table.isSensorOk,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get triggerReason => $composableBuilder(
    column: $table.triggerReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$FreezerTelemetryLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FreezerTelemetryLogsTableTable,
          FreezerTelemetryLogsTableData,
          $$FreezerTelemetryLogsTableTableFilterComposer,
          $$FreezerTelemetryLogsTableTableOrderingComposer,
          $$FreezerTelemetryLogsTableTableAnnotationComposer,
          $$FreezerTelemetryLogsTableTableCreateCompanionBuilder,
          $$FreezerTelemetryLogsTableTableUpdateCompanionBuilder,
          (
            FreezerTelemetryLogsTableData,
            BaseReferences<
              _$AppDatabase,
              $FreezerTelemetryLogsTableTable,
              FreezerTelemetryLogsTableData
            >,
          ),
          FreezerTelemetryLogsTableData,
          PrefetchHooks Function()
        > {
  $$FreezerTelemetryLogsTableTableTableManager(
    _$AppDatabase db,
    $FreezerTelemetryLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreezerTelemetryLogsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FreezerTelemetryLogsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FreezerTelemetryLogsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> freezerId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<bool> isDoorOpen = const Value.absent(),
                Value<bool> isSensorOk = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> triggerReason = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezerTelemetryLogsTableCompanion(
                id: id,
                freezerId: freezerId,
                temperature: temperature,
                isDoorOpen: isDoorOpen,
                isSensorOk: isSensorOk,
                recordedAt: recordedAt,
                triggerReason: triggerReason,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String freezerId,
                required double temperature,
                required bool isDoorOpen,
                required bool isSensorOk,
                required DateTime recordedAt,
                Value<String?> triggerReason = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezerTelemetryLogsTableCompanion.insert(
                id: id,
                freezerId: freezerId,
                temperature: temperature,
                isDoorOpen: isDoorOpen,
                isSensorOk: isSensorOk,
                recordedAt: recordedAt,
                triggerReason: triggerReason,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FreezerTelemetryLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FreezerTelemetryLogsTableTable,
      FreezerTelemetryLogsTableData,
      $$FreezerTelemetryLogsTableTableFilterComposer,
      $$FreezerTelemetryLogsTableTableOrderingComposer,
      $$FreezerTelemetryLogsTableTableAnnotationComposer,
      $$FreezerTelemetryLogsTableTableCreateCompanionBuilder,
      $$FreezerTelemetryLogsTableTableUpdateCompanionBuilder,
      (
        FreezerTelemetryLogsTableData,
        BaseReferences<
          _$AppDatabase,
          $FreezerTelemetryLogsTableTable,
          FreezerTelemetryLogsTableData
        >,
      ),
      FreezerTelemetryLogsTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String targetTable,
      required String recordId,
      required String operation,
      required String payloadJson,
      required DateTime queuedAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<DateTime> queuedAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                payloadJson: payloadJson,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required String recordId,
                required String operation,
                required String payloadJson,
                required DateTime queuedAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                payloadJson: payloadJson,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductionBatchesTableTableTableManager get productionBatchesTable =>
      $$ProductionBatchesTableTableTableManager(
        _db,
        _db.productionBatchesTable,
      );
  $$BatchAdjustmentsTableTableTableManager get batchAdjustmentsTable =>
      $$BatchAdjustmentsTableTableTableManager(_db, _db.batchAdjustmentsTable);
  $$FreezerTelemetryLogsTableTableTableManager get freezerTelemetryLogsTable =>
      $$FreezerTelemetryLogsTableTableTableManager(
        _db,
        _db.freezerTelemetryLogsTable,
      );
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
