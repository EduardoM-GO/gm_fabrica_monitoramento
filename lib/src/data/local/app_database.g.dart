// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BatchAdjustmentsTableTable extends BatchAdjustmentsTable
    with TableInfo<$BatchAdjustmentsTableTable, BatchAdjustment> {
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $BatchAdjustmentsTableTable.$convertersyncStatus,
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
  static const VerificationMeta _deltaQtyMeta = const VerificationMeta(
    'deltaQty',
  );
  @override
  late final GeneratedColumn<int> deltaQty = GeneratedColumn<int>(
    'delta_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AdjustmentReasonEnum, int>
  reason =
      GeneratedColumn<int>(
        'reason',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AdjustmentReasonEnum>(
        $BatchAdjustmentsTableTable.$converterreason,
      );
  static const VerificationMeta _observationMeta = const VerificationMeta(
    'observation',
  );
  @override
  late final GeneratedColumn<String> observation = GeneratedColumn<String>(
    'observation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    batchId,
    deltaQty,
    reason,
    observation,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_adjustments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchAdjustment> instance, {
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
    if (data.containsKey('delta_qty')) {
      context.handle(
        _deltaQtyMeta,
        deltaQty.isAcceptableOrUnknown(data['delta_qty']!, _deltaQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaQtyMeta);
    }
    if (data.containsKey('observation')) {
      context.handle(
        _observationMeta,
        observation.isAcceptableOrUnknown(
          data['observation']!,
          _observationMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchAdjustment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchAdjustment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $BatchAdjustmentsTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      deltaQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta_qty'],
      )!,
      reason: $BatchAdjustmentsTableTable.$converterreason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reason'],
        )!,
      ),
      observation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BatchAdjustmentsTableTable createAlias(String alias) {
    return $BatchAdjustmentsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
  static JsonTypeConverter2<AdjustmentReasonEnum, int, int> $converterreason =
      const EnumIndexConverter<AdjustmentReasonEnum>(
        AdjustmentReasonEnum.values,
      );
}

class BatchAdjustment extends DataClass implements Insertable<BatchAdjustment> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String batchId;
  final int deltaQty;
  final AdjustmentReasonEnum reason;
  final String? observation;
  final DateTime createdAt;
  const BatchAdjustment({
    required this.id,
    required this.syncStatus,
    required this.batchId,
    required this.deltaQty,
    required this.reason,
    this.observation,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $BatchAdjustmentsTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['batch_id'] = Variable<String>(batchId);
    map['delta_qty'] = Variable<int>(deltaQty);
    {
      map['reason'] = Variable<int>(
        $BatchAdjustmentsTableTable.$converterreason.toSql(reason),
      );
    }
    if (!nullToAbsent || observation != null) {
      map['observation'] = Variable<String>(observation);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BatchAdjustmentsTableCompanion toCompanion(bool nullToAbsent) {
    return BatchAdjustmentsTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      batchId: Value(batchId),
      deltaQty: Value(deltaQty),
      reason: Value(reason),
      observation: observation == null && nullToAbsent
          ? const Value.absent()
          : Value(observation),
      createdAt: Value(createdAt),
    );
  }

  factory BatchAdjustment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchAdjustment(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $BatchAdjustmentsTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      batchId: serializer.fromJson<String>(json['batchId']),
      deltaQty: serializer.fromJson<int>(json['deltaQty']),
      reason: $BatchAdjustmentsTableTable.$converterreason.fromJson(
        serializer.fromJson<int>(json['reason']),
      ),
      observation: serializer.fromJson<String?>(json['observation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $BatchAdjustmentsTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'batchId': serializer.toJson<String>(batchId),
      'deltaQty': serializer.toJson<int>(deltaQty),
      'reason': serializer.toJson<int>(
        $BatchAdjustmentsTableTable.$converterreason.toJson(reason),
      ),
      'observation': serializer.toJson<String?>(observation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BatchAdjustment copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? batchId,
    int? deltaQty,
    AdjustmentReasonEnum? reason,
    Value<String?> observation = const Value.absent(),
    DateTime? createdAt,
  }) => BatchAdjustment(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    batchId: batchId ?? this.batchId,
    deltaQty: deltaQty ?? this.deltaQty,
    reason: reason ?? this.reason,
    observation: observation.present ? observation.value : this.observation,
    createdAt: createdAt ?? this.createdAt,
  );
  BatchAdjustment copyWithCompanion(BatchAdjustmentsTableCompanion data) {
    return BatchAdjustment(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      deltaQty: data.deltaQty.present ? data.deltaQty.value : this.deltaQty,
      reason: data.reason.present ? data.reason.value : this.reason,
      observation: data.observation.present
          ? data.observation.value
          : this.observation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchAdjustment(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('deltaQty: $deltaQty, ')
          ..write('reason: $reason, ')
          ..write('observation: $observation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    batchId,
    deltaQty,
    reason,
    observation,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchAdjustment &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.batchId == this.batchId &&
          other.deltaQty == this.deltaQty &&
          other.reason == this.reason &&
          other.observation == this.observation &&
          other.createdAt == this.createdAt);
}

class BatchAdjustmentsTableCompanion extends UpdateCompanion<BatchAdjustment> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> batchId;
  final Value<int> deltaQty;
  final Value<AdjustmentReasonEnum> reason;
  final Value<String?> observation;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BatchAdjustmentsTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.deltaQty = const Value.absent(),
    this.reason = const Value.absent(),
    this.observation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchAdjustmentsTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    this.observation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       deltaQty = Value(deltaQty),
       reason = Value(reason);
  static Insertable<BatchAdjustment> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? batchId,
    Expression<int>? deltaQty,
    Expression<int>? reason,
    Expression<String>? observation,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (batchId != null) 'batch_id': batchId,
      if (deltaQty != null) 'delta_qty': deltaQty,
      if (reason != null) 'reason': reason,
      if (observation != null) 'observation': observation,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchAdjustmentsTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? batchId,
    Value<int>? deltaQty,
    Value<AdjustmentReasonEnum>? reason,
    Value<String?>? observation,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BatchAdjustmentsTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      batchId: batchId ?? this.batchId,
      deltaQty: deltaQty ?? this.deltaQty,
      reason: reason ?? this.reason,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $BatchAdjustmentsTableTable.$convertersyncStatus.toSql(
          syncStatus.value,
        ),
      );
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (deltaQty.present) {
      map['delta_qty'] = Variable<int>(deltaQty.value);
    }
    if (reason.present) {
      map['reason'] = Variable<int>(
        $BatchAdjustmentsTableTable.$converterreason.toSql(reason.value),
      );
    }
    if (observation.present) {
      map['observation'] = Variable<String>(observation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('deltaQty: $deltaQty, ')
          ..write('reason: $reason, ')
          ..write('observation: $observation, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreezerEventsTableTable extends FreezerEventsTable
    with TableInfo<$FreezerEventsTableTable, FreezerEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreezerEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $FreezerEventsTableTable.$convertersyncStatus,
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
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  late final GeneratedColumnWithTypeConverter<TriggerFreezerEnum, int>
  triggerReason =
      GeneratedColumn<int>(
        'trigger_reason',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TriggerFreezerEnum>(
        $FreezerEventsTableTable.$convertertriggerReason,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    freezerId,
    batchId,
    recordedAt,
    temperature,
    isDoorOpen,
    triggerReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freezer_events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FreezerEvent> instance, {
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
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FreezerEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreezerEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $FreezerEventsTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freezer_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      isDoorOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_door_open'],
      )!,
      triggerReason: $FreezerEventsTableTable.$convertertriggerReason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}trigger_reason'],
        )!,
      ),
    );
  }

  @override
  $FreezerEventsTableTable createAlias(String alias) {
    return $FreezerEventsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
  static JsonTypeConverter2<TriggerFreezerEnum, int, int>
  $convertertriggerReason = const EnumIndexConverter<TriggerFreezerEnum>(
    TriggerFreezerEnum.values,
  );
}

class FreezerEvent extends DataClass implements Insertable<FreezerEvent> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String freezerId;
  final String batchId;
  final DateTime recordedAt;
  final double temperature;
  final bool isDoorOpen;
  final TriggerFreezerEnum triggerReason;
  const FreezerEvent({
    required this.id,
    required this.syncStatus,
    required this.freezerId,
    required this.batchId,
    required this.recordedAt,
    required this.temperature,
    required this.isDoorOpen,
    required this.triggerReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $FreezerEventsTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['freezer_id'] = Variable<String>(freezerId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['temperature'] = Variable<double>(temperature);
    map['is_door_open'] = Variable<bool>(isDoorOpen);
    {
      map['trigger_reason'] = Variable<int>(
        $FreezerEventsTableTable.$convertertriggerReason.toSql(triggerReason),
      );
    }
    return map;
  }

  FreezerEventsTableCompanion toCompanion(bool nullToAbsent) {
    return FreezerEventsTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      freezerId: Value(freezerId),
      batchId: Value(batchId),
      recordedAt: Value(recordedAt),
      temperature: Value(temperature),
      isDoorOpen: Value(isDoorOpen),
      triggerReason: Value(triggerReason),
    );
  }

  factory FreezerEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreezerEvent(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $FreezerEventsTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      freezerId: serializer.fromJson<String>(json['freezerId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      temperature: serializer.fromJson<double>(json['temperature']),
      isDoorOpen: serializer.fromJson<bool>(json['isDoorOpen']),
      triggerReason: $FreezerEventsTableTable.$convertertriggerReason.fromJson(
        serializer.fromJson<int>(json['triggerReason']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $FreezerEventsTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'freezerId': serializer.toJson<String>(freezerId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'temperature': serializer.toJson<double>(temperature),
      'isDoorOpen': serializer.toJson<bool>(isDoorOpen),
      'triggerReason': serializer.toJson<int>(
        $FreezerEventsTableTable.$convertertriggerReason.toJson(triggerReason),
      ),
    };
  }

  FreezerEvent copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? freezerId,
    String? batchId,
    DateTime? recordedAt,
    double? temperature,
    bool? isDoorOpen,
    TriggerFreezerEnum? triggerReason,
  }) => FreezerEvent(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    freezerId: freezerId ?? this.freezerId,
    batchId: batchId ?? this.batchId,
    recordedAt: recordedAt ?? this.recordedAt,
    temperature: temperature ?? this.temperature,
    isDoorOpen: isDoorOpen ?? this.isDoorOpen,
    triggerReason: triggerReason ?? this.triggerReason,
  );
  FreezerEvent copyWithCompanion(FreezerEventsTableCompanion data) {
    return FreezerEvent(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      isDoorOpen: data.isDoorOpen.present
          ? data.isDoorOpen.value
          : this.isDoorOpen,
      triggerReason: data.triggerReason.present
          ? data.triggerReason.value
          : this.triggerReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreezerEvent(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('freezerId: $freezerId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('temperature: $temperature, ')
          ..write('isDoorOpen: $isDoorOpen, ')
          ..write('triggerReason: $triggerReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    freezerId,
    batchId,
    recordedAt,
    temperature,
    isDoorOpen,
    triggerReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreezerEvent &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.freezerId == this.freezerId &&
          other.batchId == this.batchId &&
          other.recordedAt == this.recordedAt &&
          other.temperature == this.temperature &&
          other.isDoorOpen == this.isDoorOpen &&
          other.triggerReason == this.triggerReason);
}

class FreezerEventsTableCompanion extends UpdateCompanion<FreezerEvent> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> freezerId;
  final Value<String> batchId;
  final Value<DateTime> recordedAt;
  final Value<double> temperature;
  final Value<bool> isDoorOpen;
  final Value<TriggerFreezerEnum> triggerReason;
  final Value<int> rowid;
  const FreezerEventsTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.temperature = const Value.absent(),
    this.isDoorOpen = const Value.absent(),
    this.triggerReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreezerEventsTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String freezerId,
    required String batchId,
    this.recordedAt = const Value.absent(),
    required double temperature,
    required bool isDoorOpen,
    required TriggerFreezerEnum triggerReason,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       freezerId = Value(freezerId),
       batchId = Value(batchId),
       temperature = Value(temperature),
       isDoorOpen = Value(isDoorOpen),
       triggerReason = Value(triggerReason);
  static Insertable<FreezerEvent> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? freezerId,
    Expression<String>? batchId,
    Expression<DateTime>? recordedAt,
    Expression<double>? temperature,
    Expression<bool>? isDoorOpen,
    Expression<int>? triggerReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (freezerId != null) 'freezer_id': freezerId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (temperature != null) 'temperature': temperature,
      if (isDoorOpen != null) 'is_door_open': isDoorOpen,
      if (triggerReason != null) 'trigger_reason': triggerReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreezerEventsTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? freezerId,
    Value<String>? batchId,
    Value<DateTime>? recordedAt,
    Value<double>? temperature,
    Value<bool>? isDoorOpen,
    Value<TriggerFreezerEnum>? triggerReason,
    Value<int>? rowid,
  }) {
    return FreezerEventsTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      freezerId: freezerId ?? this.freezerId,
      batchId: batchId ?? this.batchId,
      recordedAt: recordedAt ?? this.recordedAt,
      temperature: temperature ?? this.temperature,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      triggerReason: triggerReason ?? this.triggerReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $FreezerEventsTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<String>(freezerId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (isDoorOpen.present) {
      map['is_door_open'] = Variable<bool>(isDoorOpen.value);
    }
    if (triggerReason.present) {
      map['trigger_reason'] = Variable<int>(
        $FreezerEventsTableTable.$convertertriggerReason.toSql(
          triggerReason.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreezerEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('freezerId: $freezerId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('temperature: $temperature, ')
          ..write('isDoorOpen: $isDoorOpen, ')
          ..write('triggerReason: $triggerReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductionBatchesTableTable extends ProductionBatchesTable
    with TableInfo<$ProductionBatchesTableTable, ProductionBatch> {
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $ProductionBatchesTableTable.$convertersyncStatus,
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
  static const VerificationMeta _finalHardwareCountMeta =
      const VerificationMeta('finalHardwareCount');
  @override
  late final GeneratedColumn<int> finalHardwareCount = GeneratedColumn<int>(
    'final_hardware_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    productId,
    initialHardwareCount,
    finalHardwareCount,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_batches_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionBatch> instance, {
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
    if (data.containsKey('final_hardware_count')) {
      context.handle(
        _finalHardwareCountMeta,
        finalHardwareCount.isAcceptableOrUnknown(
          data['final_hardware_count']!,
          _finalHardwareCountMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionBatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionBatch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $ProductionBatchesTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      initialHardwareCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_hardware_count'],
      )!,
      finalHardwareCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_hardware_count'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $ProductionBatchesTableTable createAlias(String alias) {
    return $ProductionBatchesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class ProductionBatch extends DataClass implements Insertable<ProductionBatch> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String productId;
  final int initialHardwareCount;
  final int? finalHardwareCount;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const ProductionBatch({
    required this.id,
    required this.syncStatus,
    required this.productId,
    required this.initialHardwareCount,
    this.finalHardwareCount,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $ProductionBatchesTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['product_id'] = Variable<String>(productId);
    map['initial_hardware_count'] = Variable<int>(initialHardwareCount);
    if (!nullToAbsent || finalHardwareCount != null) {
      map['final_hardware_count'] = Variable<int>(finalHardwareCount);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  ProductionBatchesTableCompanion toCompanion(bool nullToAbsent) {
    return ProductionBatchesTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      productId: Value(productId),
      initialHardwareCount: Value(initialHardwareCount),
      finalHardwareCount: finalHardwareCount == null && nullToAbsent
          ? const Value.absent()
          : Value(finalHardwareCount),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory ProductionBatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionBatch(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $ProductionBatchesTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      productId: serializer.fromJson<String>(json['productId']),
      initialHardwareCount: serializer.fromJson<int>(
        json['initialHardwareCount'],
      ),
      finalHardwareCount: serializer.fromJson<int?>(json['finalHardwareCount']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $ProductionBatchesTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'productId': serializer.toJson<String>(productId),
      'initialHardwareCount': serializer.toJson<int>(initialHardwareCount),
      'finalHardwareCount': serializer.toJson<int?>(finalHardwareCount),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  ProductionBatch copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? productId,
    int? initialHardwareCount,
    Value<int?> finalHardwareCount = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => ProductionBatch(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    productId: productId ?? this.productId,
    initialHardwareCount: initialHardwareCount ?? this.initialHardwareCount,
    finalHardwareCount: finalHardwareCount.present
        ? finalHardwareCount.value
        : this.finalHardwareCount,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  ProductionBatch copyWithCompanion(ProductionBatchesTableCompanion data) {
    return ProductionBatch(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      productId: data.productId.present ? data.productId.value : this.productId,
      initialHardwareCount: data.initialHardwareCount.present
          ? data.initialHardwareCount.value
          : this.initialHardwareCount,
      finalHardwareCount: data.finalHardwareCount.present
          ? data.finalHardwareCount.value
          : this.finalHardwareCount,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatch(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('productId: $productId, ')
          ..write('initialHardwareCount: $initialHardwareCount, ')
          ..write('finalHardwareCount: $finalHardwareCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    productId,
    initialHardwareCount,
    finalHardwareCount,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionBatch &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.productId == this.productId &&
          other.initialHardwareCount == this.initialHardwareCount &&
          other.finalHardwareCount == this.finalHardwareCount &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class ProductionBatchesTableCompanion extends UpdateCompanion<ProductionBatch> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> productId;
  final Value<int> initialHardwareCount;
  final Value<int?> finalHardwareCount;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const ProductionBatchesTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.productId = const Value.absent(),
    this.initialHardwareCount = const Value.absent(),
    this.finalHardwareCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductionBatchesTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String productId,
    required int initialHardwareCount,
    this.finalHardwareCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       initialHardwareCount = Value(initialHardwareCount);
  static Insertable<ProductionBatch> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? productId,
    Expression<int>? initialHardwareCount,
    Expression<int>? finalHardwareCount,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (productId != null) 'product_id': productId,
      if (initialHardwareCount != null)
        'initial_hardware_count': initialHardwareCount,
      if (finalHardwareCount != null)
        'final_hardware_count': finalHardwareCount,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductionBatchesTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? productId,
    Value<int>? initialHardwareCount,
    Value<int?>? finalHardwareCount,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return ProductionBatchesTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      productId: productId ?? this.productId,
      initialHardwareCount: initialHardwareCount ?? this.initialHardwareCount,
      finalHardwareCount: finalHardwareCount ?? this.finalHardwareCount,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $ProductionBatchesTableTable.$convertersyncStatus.toSql(
          syncStatus.value,
        ),
      );
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (initialHardwareCount.present) {
      map['initial_hardware_count'] = Variable<int>(initialHardwareCount.value);
    }
    if (finalHardwareCount.present) {
      map['final_hardware_count'] = Variable<int>(finalHardwareCount.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
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
          ..write('syncStatus: $syncStatus, ')
          ..write('productId: $productId, ')
          ..write('initialHardwareCount: $initialHardwareCount, ')
          ..write('finalHardwareCount: $finalHardwareCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductionTimeLinesTableTable extends ProductionTimeLinesTable
    with TableInfo<$ProductionTimeLinesTableTable, ProductionTimeline> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionTimeLinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $ProductionTimeLinesTableTable.$convertersyncStatus,
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
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _currentHardwareCountMeta =
      const VerificationMeta('currentHardwareCount');
  @override
  late final GeneratedColumn<int> currentHardwareCount = GeneratedColumn<int>(
    'current_hardware_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    batchId,
    recordedAt,
    currentHardwareCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_time_lines_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionTimeline> instance, {
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
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('current_hardware_count')) {
      context.handle(
        _currentHardwareCountMeta,
        currentHardwareCount.isAcceptableOrUnknown(
          data['current_hardware_count']!,
          _currentHardwareCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentHardwareCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionTimeline map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionTimeline(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $ProductionTimeLinesTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      currentHardwareCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_hardware_count'],
      )!,
    );
  }

  @override
  $ProductionTimeLinesTableTable createAlias(String alias) {
    return $ProductionTimeLinesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class ProductionTimeline extends DataClass
    implements Insertable<ProductionTimeline> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String batchId;
  final DateTime recordedAt;
  final int currentHardwareCount;
  const ProductionTimeline({
    required this.id,
    required this.syncStatus,
    required this.batchId,
    required this.recordedAt,
    required this.currentHardwareCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $ProductionTimeLinesTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['current_hardware_count'] = Variable<int>(currentHardwareCount);
    return map;
  }

  ProductionTimeLinesTableCompanion toCompanion(bool nullToAbsent) {
    return ProductionTimeLinesTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      batchId: Value(batchId),
      recordedAt: Value(recordedAt),
      currentHardwareCount: Value(currentHardwareCount),
    );
  }

  factory ProductionTimeline.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionTimeline(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $ProductionTimeLinesTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      currentHardwareCount: serializer.fromJson<int>(
        json['currentHardwareCount'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $ProductionTimeLinesTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'batchId': serializer.toJson<String>(batchId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'currentHardwareCount': serializer.toJson<int>(currentHardwareCount),
    };
  }

  ProductionTimeline copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? batchId,
    DateTime? recordedAt,
    int? currentHardwareCount,
  }) => ProductionTimeline(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    batchId: batchId ?? this.batchId,
    recordedAt: recordedAt ?? this.recordedAt,
    currentHardwareCount: currentHardwareCount ?? this.currentHardwareCount,
  );
  ProductionTimeline copyWithCompanion(ProductionTimeLinesTableCompanion data) {
    return ProductionTimeline(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      currentHardwareCount: data.currentHardwareCount.present
          ? data.currentHardwareCount.value
          : this.currentHardwareCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionTimeline(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('currentHardwareCount: $currentHardwareCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, syncStatus, batchId, recordedAt, currentHardwareCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionTimeline &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.batchId == this.batchId &&
          other.recordedAt == this.recordedAt &&
          other.currentHardwareCount == this.currentHardwareCount);
}

class ProductionTimeLinesTableCompanion
    extends UpdateCompanion<ProductionTimeline> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> batchId;
  final Value<DateTime> recordedAt;
  final Value<int> currentHardwareCount;
  final Value<int> rowid;
  const ProductionTimeLinesTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.currentHardwareCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductionTimeLinesTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String batchId,
    this.recordedAt = const Value.absent(),
    required int currentHardwareCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       currentHardwareCount = Value(currentHardwareCount);
  static Insertable<ProductionTimeline> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? batchId,
    Expression<DateTime>? recordedAt,
    Expression<int>? currentHardwareCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (batchId != null) 'batch_id': batchId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (currentHardwareCount != null)
        'current_hardware_count': currentHardwareCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductionTimeLinesTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? batchId,
    Value<DateTime>? recordedAt,
    Value<int>? currentHardwareCount,
    Value<int>? rowid,
  }) {
    return ProductionTimeLinesTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      batchId: batchId ?? this.batchId,
      recordedAt: recordedAt ?? this.recordedAt,
      currentHardwareCount: currentHardwareCount ?? this.currentHardwareCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $ProductionTimeLinesTableTable.$convertersyncStatus.toSql(
          syncStatus.value,
        ),
      );
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (currentHardwareCount.present) {
      map['current_hardware_count'] = Variable<int>(currentHardwareCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionTimeLinesTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('currentHardwareCount: $currentHardwareCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, Product> {
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>($ProductsTableTable.$convertersyncStatus);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('geral'),
  );
  static const VerificationMeta _eanCodeMeta = const VerificationMeta(
    'eanCode',
  );
  @override
  late final GeneratedColumn<String> eanCode = GeneratedColumn<String>(
    'ean_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _defaultCoolingSecondsMeta =
      const VerificationMeta('defaultCoolingSeconds');
  @override
  late final GeneratedColumn<int> defaultCoolingSeconds = GeneratedColumn<int>(
    'default_cooling_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1200),
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
    syncStatus,
    name,
    unitWeightGrams,
    category,
    eanCode,
    defaultBoxCapacity,
    defaultCoolingSeconds,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('ean_code')) {
      context.handle(
        _eanCodeMeta,
        eanCode.isAcceptableOrUnknown(data['ean_code']!, _eanCodeMeta),
      );
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
    if (data.containsKey('default_cooling_seconds')) {
      context.handle(
        _defaultCoolingSecondsMeta,
        defaultCoolingSeconds.isAcceptableOrUnknown(
          data['default_cooling_seconds']!,
          _defaultCoolingSecondsMeta,
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
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $ProductsTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unitWeightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_weight_grams'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      eanCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ean_code'],
      ),
      defaultBoxCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_box_capacity'],
      )!,
      defaultCoolingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_cooling_seconds'],
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

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String name;
  final double unitWeightGrams;
  final String category;
  final String? eanCode;
  final int defaultBoxCapacity;
  final int defaultCoolingSeconds;
  final bool isActive;
  const Product({
    required this.id,
    required this.syncStatus,
    required this.name,
    required this.unitWeightGrams,
    required this.category,
    this.eanCode,
    required this.defaultBoxCapacity,
    required this.defaultCoolingSeconds,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $ProductsTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['name'] = Variable<String>(name);
    map['unit_weight_grams'] = Variable<double>(unitWeightGrams);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || eanCode != null) {
      map['ean_code'] = Variable<String>(eanCode);
    }
    map['default_box_capacity'] = Variable<int>(defaultBoxCapacity);
    map['default_cooling_seconds'] = Variable<int>(defaultCoolingSeconds);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      name: Value(name),
      unitWeightGrams: Value(unitWeightGrams),
      category: Value(category),
      eanCode: eanCode == null && nullToAbsent
          ? const Value.absent()
          : Value(eanCode),
      defaultBoxCapacity: Value(defaultBoxCapacity),
      defaultCoolingSeconds: Value(defaultCoolingSeconds),
      isActive: Value(isActive),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $ProductsTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      name: serializer.fromJson<String>(json['name']),
      unitWeightGrams: serializer.fromJson<double>(json['unitWeightGrams']),
      category: serializer.fromJson<String>(json['category']),
      eanCode: serializer.fromJson<String?>(json['eanCode']),
      defaultBoxCapacity: serializer.fromJson<int>(json['defaultBoxCapacity']),
      defaultCoolingSeconds: serializer.fromJson<int>(
        json['defaultCoolingSeconds'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $ProductsTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'name': serializer.toJson<String>(name),
      'unitWeightGrams': serializer.toJson<double>(unitWeightGrams),
      'category': serializer.toJson<String>(category),
      'eanCode': serializer.toJson<String?>(eanCode),
      'defaultBoxCapacity': serializer.toJson<int>(defaultBoxCapacity),
      'defaultCoolingSeconds': serializer.toJson<int>(defaultCoolingSeconds),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Product copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? name,
    double? unitWeightGrams,
    String? category,
    Value<String?> eanCode = const Value.absent(),
    int? defaultBoxCapacity,
    int? defaultCoolingSeconds,
    bool? isActive,
  }) => Product(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    name: name ?? this.name,
    unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
    category: category ?? this.category,
    eanCode: eanCode.present ? eanCode.value : this.eanCode,
    defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
    defaultCoolingSeconds: defaultCoolingSeconds ?? this.defaultCoolingSeconds,
    isActive: isActive ?? this.isActive,
  );
  Product copyWithCompanion(ProductsTableCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      name: data.name.present ? data.name.value : this.name,
      unitWeightGrams: data.unitWeightGrams.present
          ? data.unitWeightGrams.value
          : this.unitWeightGrams,
      category: data.category.present ? data.category.value : this.category,
      eanCode: data.eanCode.present ? data.eanCode.value : this.eanCode,
      defaultBoxCapacity: data.defaultBoxCapacity.present
          ? data.defaultBoxCapacity.value
          : this.defaultBoxCapacity,
      defaultCoolingSeconds: data.defaultCoolingSeconds.present
          ? data.defaultCoolingSeconds.value
          : this.defaultCoolingSeconds,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('name: $name, ')
          ..write('unitWeightGrams: $unitWeightGrams, ')
          ..write('category: $category, ')
          ..write('eanCode: $eanCode, ')
          ..write('defaultBoxCapacity: $defaultBoxCapacity, ')
          ..write('defaultCoolingSeconds: $defaultCoolingSeconds, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    name,
    unitWeightGrams,
    category,
    eanCode,
    defaultBoxCapacity,
    defaultCoolingSeconds,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.name == this.name &&
          other.unitWeightGrams == this.unitWeightGrams &&
          other.category == this.category &&
          other.eanCode == this.eanCode &&
          other.defaultBoxCapacity == this.defaultBoxCapacity &&
          other.defaultCoolingSeconds == this.defaultCoolingSeconds &&
          other.isActive == this.isActive);
}

class ProductsTableCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> name;
  final Value<double> unitWeightGrams;
  final Value<String> category;
  final Value<String?> eanCode;
  final Value<int> defaultBoxCapacity;
  final Value<int> defaultCoolingSeconds;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.name = const Value.absent(),
    this.unitWeightGrams = const Value.absent(),
    this.category = const Value.absent(),
    this.eanCode = const Value.absent(),
    this.defaultBoxCapacity = const Value.absent(),
    this.defaultCoolingSeconds = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String name,
    required double unitWeightGrams,
    this.category = const Value.absent(),
    this.eanCode = const Value.absent(),
    this.defaultBoxCapacity = const Value.absent(),
    this.defaultCoolingSeconds = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       unitWeightGrams = Value(unitWeightGrams);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? name,
    Expression<double>? unitWeightGrams,
    Expression<String>? category,
    Expression<String>? eanCode,
    Expression<int>? defaultBoxCapacity,
    Expression<int>? defaultCoolingSeconds,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (name != null) 'name': name,
      if (unitWeightGrams != null) 'unit_weight_grams': unitWeightGrams,
      if (category != null) 'category': category,
      if (eanCode != null) 'ean_code': eanCode,
      if (defaultBoxCapacity != null)
        'default_box_capacity': defaultBoxCapacity,
      if (defaultCoolingSeconds != null)
        'default_cooling_seconds': defaultCoolingSeconds,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? name,
    Value<double>? unitWeightGrams,
    Value<String>? category,
    Value<String?>? eanCode,
    Value<int>? defaultBoxCapacity,
    Value<int>? defaultCoolingSeconds,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      name: name ?? this.name,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      category: category ?? this.category,
      eanCode: eanCode ?? this.eanCode,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
      defaultCoolingSeconds:
          defaultCoolingSeconds ?? this.defaultCoolingSeconds,
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
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $ProductsTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unitWeightGrams.present) {
      map['unit_weight_grams'] = Variable<double>(unitWeightGrams.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (eanCode.present) {
      map['ean_code'] = Variable<String>(eanCode.value);
    }
    if (defaultBoxCapacity.present) {
      map['default_box_capacity'] = Variable<int>(defaultBoxCapacity.value);
    }
    if (defaultCoolingSeconds.present) {
      map['default_cooling_seconds'] = Variable<int>(
        defaultCoolingSeconds.value,
      );
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
          ..write('syncStatus: $syncStatus, ')
          ..write('name: $name, ')
          ..write('unitWeightGrams: $unitWeightGrams, ')
          ..write('category: $category, ')
          ..write('eanCode: $eanCode, ')
          ..write('defaultBoxCapacity: $defaultBoxCapacity, ')
          ..write('defaultCoolingSeconds: $defaultCoolingSeconds, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoolingCyclesTableTable extends CoolingCyclesTable
    with TableInfo<$CoolingCyclesTableTable, CoolingCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoolingCyclesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $CoolingCyclesTableTable.$convertersyncStatus,
      );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  static const VerificationMeta _baselineTempMeta = const VerificationMeta(
    'baselineTemp',
  );
  @override
  late final GeneratedColumn<double> baselineTemp = GeneratedColumn<double>(
    'baseline_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialPeakTempMeta = const VerificationMeta(
    'initialPeakTemp',
  );
  @override
  late final GeneratedColumn<double> initialPeakTemp = GeneratedColumn<double>(
    'initial_peak_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedDurationSecondsMeta =
      const VerificationMeta('expectedDurationSeconds');
  @override
  late final GeneratedColumn<int> expectedDurationSeconds =
      GeneratedColumn<int>(
        'expected_duration_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualDurationSecondsMeta =
      const VerificationMeta('actualDurationSeconds');
  @override
  late final GeneratedColumn<int> actualDurationSeconds = GeneratedColumn<int>(
    'actual_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accumulatedDoorOpenSecondsMeta =
      const VerificationMeta('accumulatedDoorOpenSeconds');
  @override
  late final GeneratedColumn<int> accumulatedDoorOpenSeconds =
      GeneratedColumn<int>(
        'accumulated_door_open_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _accumulatedPenaltySecondsMeta =
      const VerificationMeta('accumulatedPenaltySeconds');
  @override
  late final GeneratedColumn<int> accumulatedPenaltySeconds =
      GeneratedColumn<int>(
        'accumulated_penalty_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _doorOpenCountMeta = const VerificationMeta(
    'doorOpenCount',
  );
  @override
  late final GeneratedColumn<int> doorOpenCount = GeneratedColumn<int>(
    'door_open_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _feedbackMeta = const VerificationMeta(
    'feedback',
  );
  @override
  late final GeneratedColumn<String> feedback = GeneratedColumn<String>(
    'feedback',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    batchId,
    freezerId,
    startedAt,
    finishedAt,
    baselineTemp,
    initialPeakTemp,
    expectedDurationSeconds,
    actualDurationSeconds,
    accumulatedDoorOpenSeconds,
    accumulatedPenaltySeconds,
    doorOpenCount,
    feedback,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cooling_cycles_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoolingCycle> instance, {
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
    }
    if (data.containsKey('freezer_id')) {
      context.handle(
        _freezerIdMeta,
        freezerId.isAcceptableOrUnknown(data['freezer_id']!, _freezerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_freezerIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('baseline_temp')) {
      context.handle(
        _baselineTempMeta,
        baselineTemp.isAcceptableOrUnknown(
          data['baseline_temp']!,
          _baselineTempMeta,
        ),
      );
    }
    if (data.containsKey('initial_peak_temp')) {
      context.handle(
        _initialPeakTempMeta,
        initialPeakTemp.isAcceptableOrUnknown(
          data['initial_peak_temp']!,
          _initialPeakTempMeta,
        ),
      );
    }
    if (data.containsKey('expected_duration_seconds')) {
      context.handle(
        _expectedDurationSecondsMeta,
        expectedDurationSeconds.isAcceptableOrUnknown(
          data['expected_duration_seconds']!,
          _expectedDurationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedDurationSecondsMeta);
    }
    if (data.containsKey('actual_duration_seconds')) {
      context.handle(
        _actualDurationSecondsMeta,
        actualDurationSeconds.isAcceptableOrUnknown(
          data['actual_duration_seconds']!,
          _actualDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('accumulated_door_open_seconds')) {
      context.handle(
        _accumulatedDoorOpenSecondsMeta,
        accumulatedDoorOpenSeconds.isAcceptableOrUnknown(
          data['accumulated_door_open_seconds']!,
          _accumulatedDoorOpenSecondsMeta,
        ),
      );
    }
    if (data.containsKey('accumulated_penalty_seconds')) {
      context.handle(
        _accumulatedPenaltySecondsMeta,
        accumulatedPenaltySeconds.isAcceptableOrUnknown(
          data['accumulated_penalty_seconds']!,
          _accumulatedPenaltySecondsMeta,
        ),
      );
    }
    if (data.containsKey('door_open_count')) {
      context.handle(
        _doorOpenCountMeta,
        doorOpenCount.isAcceptableOrUnknown(
          data['door_open_count']!,
          _doorOpenCountMeta,
        ),
      );
    }
    if (data.containsKey('feedback')) {
      context.handle(
        _feedbackMeta,
        feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoolingCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoolingCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $CoolingCyclesTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freezer_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      baselineTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}baseline_temp'],
      ),
      initialPeakTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_peak_temp'],
      ),
      expectedDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_duration_seconds'],
      )!,
      actualDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration_seconds'],
      ),
      accumulatedDoorOpenSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accumulated_door_open_seconds'],
      )!,
      accumulatedPenaltySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accumulated_penalty_seconds'],
      )!,
      doorOpenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}door_open_count'],
      )!,
      feedback: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback'],
      ),
    );
  }

  @override
  $CoolingCyclesTableTable createAlias(String alias) {
    return $CoolingCyclesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class CoolingCycle extends DataClass implements Insertable<CoolingCycle> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String? batchId;
  final String freezerId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? baselineTemp;
  final double? initialPeakTemp;
  final int expectedDurationSeconds;
  final int? actualDurationSeconds;
  final int accumulatedDoorOpenSeconds;
  final int accumulatedPenaltySeconds;
  final int doorOpenCount;
  final String? feedback;
  const CoolingCycle({
    required this.id,
    required this.syncStatus,
    this.batchId,
    required this.freezerId,
    required this.startedAt,
    this.finishedAt,
    this.baselineTemp,
    this.initialPeakTemp,
    required this.expectedDurationSeconds,
    this.actualDurationSeconds,
    required this.accumulatedDoorOpenSeconds,
    required this.accumulatedPenaltySeconds,
    required this.doorOpenCount,
    this.feedback,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $CoolingCyclesTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['freezer_id'] = Variable<String>(freezerId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || baselineTemp != null) {
      map['baseline_temp'] = Variable<double>(baselineTemp);
    }
    if (!nullToAbsent || initialPeakTemp != null) {
      map['initial_peak_temp'] = Variable<double>(initialPeakTemp);
    }
    map['expected_duration_seconds'] = Variable<int>(expectedDurationSeconds);
    if (!nullToAbsent || actualDurationSeconds != null) {
      map['actual_duration_seconds'] = Variable<int>(actualDurationSeconds);
    }
    map['accumulated_door_open_seconds'] = Variable<int>(
      accumulatedDoorOpenSeconds,
    );
    map['accumulated_penalty_seconds'] = Variable<int>(
      accumulatedPenaltySeconds,
    );
    map['door_open_count'] = Variable<int>(doorOpenCount);
    if (!nullToAbsent || feedback != null) {
      map['feedback'] = Variable<String>(feedback);
    }
    return map;
  }

  CoolingCyclesTableCompanion toCompanion(bool nullToAbsent) {
    return CoolingCyclesTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      freezerId: Value(freezerId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      baselineTemp: baselineTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineTemp),
      initialPeakTemp: initialPeakTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(initialPeakTemp),
      expectedDurationSeconds: Value(expectedDurationSeconds),
      actualDurationSeconds: actualDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDurationSeconds),
      accumulatedDoorOpenSeconds: Value(accumulatedDoorOpenSeconds),
      accumulatedPenaltySeconds: Value(accumulatedPenaltySeconds),
      doorOpenCount: Value(doorOpenCount),
      feedback: feedback == null && nullToAbsent
          ? const Value.absent()
          : Value(feedback),
    );
  }

  factory CoolingCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoolingCycle(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $CoolingCyclesTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      batchId: serializer.fromJson<String?>(json['batchId']),
      freezerId: serializer.fromJson<String>(json['freezerId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      baselineTemp: serializer.fromJson<double?>(json['baselineTemp']),
      initialPeakTemp: serializer.fromJson<double?>(json['initialPeakTemp']),
      expectedDurationSeconds: serializer.fromJson<int>(
        json['expectedDurationSeconds'],
      ),
      actualDurationSeconds: serializer.fromJson<int?>(
        json['actualDurationSeconds'],
      ),
      accumulatedDoorOpenSeconds: serializer.fromJson<int>(
        json['accumulatedDoorOpenSeconds'],
      ),
      accumulatedPenaltySeconds: serializer.fromJson<int>(
        json['accumulatedPenaltySeconds'],
      ),
      doorOpenCount: serializer.fromJson<int>(json['doorOpenCount']),
      feedback: serializer.fromJson<String?>(json['feedback']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $CoolingCyclesTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'batchId': serializer.toJson<String?>(batchId),
      'freezerId': serializer.toJson<String>(freezerId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'baselineTemp': serializer.toJson<double?>(baselineTemp),
      'initialPeakTemp': serializer.toJson<double?>(initialPeakTemp),
      'expectedDurationSeconds': serializer.toJson<int>(
        expectedDurationSeconds,
      ),
      'actualDurationSeconds': serializer.toJson<int?>(actualDurationSeconds),
      'accumulatedDoorOpenSeconds': serializer.toJson<int>(
        accumulatedDoorOpenSeconds,
      ),
      'accumulatedPenaltySeconds': serializer.toJson<int>(
        accumulatedPenaltySeconds,
      ),
      'doorOpenCount': serializer.toJson<int>(doorOpenCount),
      'feedback': serializer.toJson<String?>(feedback),
    };
  }

  CoolingCycle copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    Value<String?> batchId = const Value.absent(),
    String? freezerId,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<double?> baselineTemp = const Value.absent(),
    Value<double?> initialPeakTemp = const Value.absent(),
    int? expectedDurationSeconds,
    Value<int?> actualDurationSeconds = const Value.absent(),
    int? accumulatedDoorOpenSeconds,
    int? accumulatedPenaltySeconds,
    int? doorOpenCount,
    Value<String?> feedback = const Value.absent(),
  }) => CoolingCycle(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    batchId: batchId.present ? batchId.value : this.batchId,
    freezerId: freezerId ?? this.freezerId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    baselineTemp: baselineTemp.present ? baselineTemp.value : this.baselineTemp,
    initialPeakTemp: initialPeakTemp.present
        ? initialPeakTemp.value
        : this.initialPeakTemp,
    expectedDurationSeconds:
        expectedDurationSeconds ?? this.expectedDurationSeconds,
    actualDurationSeconds: actualDurationSeconds.present
        ? actualDurationSeconds.value
        : this.actualDurationSeconds,
    accumulatedDoorOpenSeconds:
        accumulatedDoorOpenSeconds ?? this.accumulatedDoorOpenSeconds,
    accumulatedPenaltySeconds:
        accumulatedPenaltySeconds ?? this.accumulatedPenaltySeconds,
    doorOpenCount: doorOpenCount ?? this.doorOpenCount,
    feedback: feedback.present ? feedback.value : this.feedback,
  );
  CoolingCycle copyWithCompanion(CoolingCyclesTableCompanion data) {
    return CoolingCycle(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      baselineTemp: data.baselineTemp.present
          ? data.baselineTemp.value
          : this.baselineTemp,
      initialPeakTemp: data.initialPeakTemp.present
          ? data.initialPeakTemp.value
          : this.initialPeakTemp,
      expectedDurationSeconds: data.expectedDurationSeconds.present
          ? data.expectedDurationSeconds.value
          : this.expectedDurationSeconds,
      actualDurationSeconds: data.actualDurationSeconds.present
          ? data.actualDurationSeconds.value
          : this.actualDurationSeconds,
      accumulatedDoorOpenSeconds: data.accumulatedDoorOpenSeconds.present
          ? data.accumulatedDoorOpenSeconds.value
          : this.accumulatedDoorOpenSeconds,
      accumulatedPenaltySeconds: data.accumulatedPenaltySeconds.present
          ? data.accumulatedPenaltySeconds.value
          : this.accumulatedPenaltySeconds,
      doorOpenCount: data.doorOpenCount.present
          ? data.doorOpenCount.value
          : this.doorOpenCount,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoolingCycle(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('freezerId: $freezerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('baselineTemp: $baselineTemp, ')
          ..write('initialPeakTemp: $initialPeakTemp, ')
          ..write('expectedDurationSeconds: $expectedDurationSeconds, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('accumulatedDoorOpenSeconds: $accumulatedDoorOpenSeconds, ')
          ..write('accumulatedPenaltySeconds: $accumulatedPenaltySeconds, ')
          ..write('doorOpenCount: $doorOpenCount, ')
          ..write('feedback: $feedback')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    batchId,
    freezerId,
    startedAt,
    finishedAt,
    baselineTemp,
    initialPeakTemp,
    expectedDurationSeconds,
    actualDurationSeconds,
    accumulatedDoorOpenSeconds,
    accumulatedPenaltySeconds,
    doorOpenCount,
    feedback,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoolingCycle &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.batchId == this.batchId &&
          other.freezerId == this.freezerId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.baselineTemp == this.baselineTemp &&
          other.initialPeakTemp == this.initialPeakTemp &&
          other.expectedDurationSeconds == this.expectedDurationSeconds &&
          other.actualDurationSeconds == this.actualDurationSeconds &&
          other.accumulatedDoorOpenSeconds == this.accumulatedDoorOpenSeconds &&
          other.accumulatedPenaltySeconds == this.accumulatedPenaltySeconds &&
          other.doorOpenCount == this.doorOpenCount &&
          other.feedback == this.feedback);
}

class CoolingCyclesTableCompanion extends UpdateCompanion<CoolingCycle> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String?> batchId;
  final Value<String> freezerId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<double?> baselineTemp;
  final Value<double?> initialPeakTemp;
  final Value<int> expectedDurationSeconds;
  final Value<int?> actualDurationSeconds;
  final Value<int> accumulatedDoorOpenSeconds;
  final Value<int> accumulatedPenaltySeconds;
  final Value<int> doorOpenCount;
  final Value<String?> feedback;
  final Value<int> rowid;
  const CoolingCyclesTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.baselineTemp = const Value.absent(),
    this.initialPeakTemp = const Value.absent(),
    this.expectedDurationSeconds = const Value.absent(),
    this.actualDurationSeconds = const Value.absent(),
    this.accumulatedDoorOpenSeconds = const Value.absent(),
    this.accumulatedPenaltySeconds = const Value.absent(),
    this.doorOpenCount = const Value.absent(),
    this.feedback = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoolingCyclesTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    required String freezerId,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.baselineTemp = const Value.absent(),
    this.initialPeakTemp = const Value.absent(),
    required int expectedDurationSeconds,
    this.actualDurationSeconds = const Value.absent(),
    this.accumulatedDoorOpenSeconds = const Value.absent(),
    this.accumulatedPenaltySeconds = const Value.absent(),
    this.doorOpenCount = const Value.absent(),
    this.feedback = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       freezerId = Value(freezerId),
       expectedDurationSeconds = Value(expectedDurationSeconds);
  static Insertable<CoolingCycle> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? batchId,
    Expression<String>? freezerId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<double>? baselineTemp,
    Expression<double>? initialPeakTemp,
    Expression<int>? expectedDurationSeconds,
    Expression<int>? actualDurationSeconds,
    Expression<int>? accumulatedDoorOpenSeconds,
    Expression<int>? accumulatedPenaltySeconds,
    Expression<int>? doorOpenCount,
    Expression<String>? feedback,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (batchId != null) 'batch_id': batchId,
      if (freezerId != null) 'freezer_id': freezerId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (baselineTemp != null) 'baseline_temp': baselineTemp,
      if (initialPeakTemp != null) 'initial_peak_temp': initialPeakTemp,
      if (expectedDurationSeconds != null)
        'expected_duration_seconds': expectedDurationSeconds,
      if (actualDurationSeconds != null)
        'actual_duration_seconds': actualDurationSeconds,
      if (accumulatedDoorOpenSeconds != null)
        'accumulated_door_open_seconds': accumulatedDoorOpenSeconds,
      if (accumulatedPenaltySeconds != null)
        'accumulated_penalty_seconds': accumulatedPenaltySeconds,
      if (doorOpenCount != null) 'door_open_count': doorOpenCount,
      if (feedback != null) 'feedback': feedback,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoolingCyclesTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String?>? batchId,
    Value<String>? freezerId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<double?>? baselineTemp,
    Value<double?>? initialPeakTemp,
    Value<int>? expectedDurationSeconds,
    Value<int?>? actualDurationSeconds,
    Value<int>? accumulatedDoorOpenSeconds,
    Value<int>? accumulatedPenaltySeconds,
    Value<int>? doorOpenCount,
    Value<String?>? feedback,
    Value<int>? rowid,
  }) {
    return CoolingCyclesTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      batchId: batchId ?? this.batchId,
      freezerId: freezerId ?? this.freezerId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      baselineTemp: baselineTemp ?? this.baselineTemp,
      initialPeakTemp: initialPeakTemp ?? this.initialPeakTemp,
      expectedDurationSeconds:
          expectedDurationSeconds ?? this.expectedDurationSeconds,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      accumulatedDoorOpenSeconds:
          accumulatedDoorOpenSeconds ?? this.accumulatedDoorOpenSeconds,
      accumulatedPenaltySeconds:
          accumulatedPenaltySeconds ?? this.accumulatedPenaltySeconds,
      doorOpenCount: doorOpenCount ?? this.doorOpenCount,
      feedback: feedback ?? this.feedback,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $CoolingCyclesTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<String>(freezerId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (baselineTemp.present) {
      map['baseline_temp'] = Variable<double>(baselineTemp.value);
    }
    if (initialPeakTemp.present) {
      map['initial_peak_temp'] = Variable<double>(initialPeakTemp.value);
    }
    if (expectedDurationSeconds.present) {
      map['expected_duration_seconds'] = Variable<int>(
        expectedDurationSeconds.value,
      );
    }
    if (actualDurationSeconds.present) {
      map['actual_duration_seconds'] = Variable<int>(
        actualDurationSeconds.value,
      );
    }
    if (accumulatedDoorOpenSeconds.present) {
      map['accumulated_door_open_seconds'] = Variable<int>(
        accumulatedDoorOpenSeconds.value,
      );
    }
    if (accumulatedPenaltySeconds.present) {
      map['accumulated_penalty_seconds'] = Variable<int>(
        accumulatedPenaltySeconds.value,
      );
    }
    if (doorOpenCount.present) {
      map['door_open_count'] = Variable<int>(doorOpenCount.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<String>(feedback.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoolingCyclesTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('freezerId: $freezerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('baselineTemp: $baselineTemp, ')
          ..write('initialPeakTemp: $initialPeakTemp, ')
          ..write('expectedDurationSeconds: $expectedDurationSeconds, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('accumulatedDoorOpenSeconds: $accumulatedDoorOpenSeconds, ')
          ..write('accumulatedPenaltySeconds: $accumulatedPenaltySeconds, ')
          ..write('doorOpenCount: $doorOpenCount, ')
          ..write('feedback: $feedback, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreezerCalibrationsTableTable extends FreezerCalibrationsTable
    with TableInfo<$FreezerCalibrationsTableTable, FreezerCalibration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreezerCalibrationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $FreezerCalibrationsTableTable.$convertersyncStatus,
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
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calibratedDurationSecondsMeta =
      const VerificationMeta('calibratedDurationSeconds');
  @override
  late final GeneratedColumn<int> calibratedDurationSeconds =
      GeneratedColumn<int>(
        'calibrated_duration_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFeedbackMeta = const VerificationMeta(
    'lastFeedback',
  );
  @override
  late final GeneratedColumn<String> lastFeedback = GeneratedColumn<String>(
    'last_feedback',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    freezerId,
    productId,
    calibratedDurationSeconds,
    sampleCount,
    lastFeedback,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freezer_calibrations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FreezerCalibration> instance, {
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
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('calibrated_duration_seconds')) {
      context.handle(
        _calibratedDurationSecondsMeta,
        calibratedDurationSeconds.isAcceptableOrUnknown(
          data['calibrated_duration_seconds']!,
          _calibratedDurationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calibratedDurationSecondsMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('last_feedback')) {
      context.handle(
        _lastFeedbackMeta,
        lastFeedback.isAcceptableOrUnknown(
          data['last_feedback']!,
          _lastFeedbackMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FreezerCalibration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreezerCalibration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $FreezerCalibrationsTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freezer_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      calibratedDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calibrated_duration_seconds'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      lastFeedback: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_feedback'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FreezerCalibrationsTableTable createAlias(String alias) {
    return $FreezerCalibrationsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class FreezerCalibration extends DataClass
    implements Insertable<FreezerCalibration> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String freezerId;
  final String? productId;
  final int calibratedDurationSeconds;
  final int sampleCount;
  final String? lastFeedback;
  final DateTime updatedAt;
  const FreezerCalibration({
    required this.id,
    required this.syncStatus,
    required this.freezerId,
    this.productId,
    required this.calibratedDurationSeconds,
    required this.sampleCount,
    this.lastFeedback,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $FreezerCalibrationsTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['freezer_id'] = Variable<String>(freezerId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['calibrated_duration_seconds'] = Variable<int>(
      calibratedDurationSeconds,
    );
    map['sample_count'] = Variable<int>(sampleCount);
    if (!nullToAbsent || lastFeedback != null) {
      map['last_feedback'] = Variable<String>(lastFeedback);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FreezerCalibrationsTableCompanion toCompanion(bool nullToAbsent) {
    return FreezerCalibrationsTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      freezerId: Value(freezerId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      calibratedDurationSeconds: Value(calibratedDurationSeconds),
      sampleCount: Value(sampleCount),
      lastFeedback: lastFeedback == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFeedback),
      updatedAt: Value(updatedAt),
    );
  }

  factory FreezerCalibration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreezerCalibration(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $FreezerCalibrationsTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      freezerId: serializer.fromJson<String>(json['freezerId']),
      productId: serializer.fromJson<String?>(json['productId']),
      calibratedDurationSeconds: serializer.fromJson<int>(
        json['calibratedDurationSeconds'],
      ),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      lastFeedback: serializer.fromJson<String?>(json['lastFeedback']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $FreezerCalibrationsTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'freezerId': serializer.toJson<String>(freezerId),
      'productId': serializer.toJson<String?>(productId),
      'calibratedDurationSeconds': serializer.toJson<int>(
        calibratedDurationSeconds,
      ),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'lastFeedback': serializer.toJson<String?>(lastFeedback),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FreezerCalibration copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? freezerId,
    Value<String?> productId = const Value.absent(),
    int? calibratedDurationSeconds,
    int? sampleCount,
    Value<String?> lastFeedback = const Value.absent(),
    DateTime? updatedAt,
  }) => FreezerCalibration(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    freezerId: freezerId ?? this.freezerId,
    productId: productId.present ? productId.value : this.productId,
    calibratedDurationSeconds:
        calibratedDurationSeconds ?? this.calibratedDurationSeconds,
    sampleCount: sampleCount ?? this.sampleCount,
    lastFeedback: lastFeedback.present ? lastFeedback.value : this.lastFeedback,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FreezerCalibration copyWithCompanion(FreezerCalibrationsTableCompanion data) {
    return FreezerCalibration(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      productId: data.productId.present ? data.productId.value : this.productId,
      calibratedDurationSeconds: data.calibratedDurationSeconds.present
          ? data.calibratedDurationSeconds.value
          : this.calibratedDurationSeconds,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      lastFeedback: data.lastFeedback.present
          ? data.lastFeedback.value
          : this.lastFeedback,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreezerCalibration(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('freezerId: $freezerId, ')
          ..write('productId: $productId, ')
          ..write('calibratedDurationSeconds: $calibratedDurationSeconds, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastFeedback: $lastFeedback, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    freezerId,
    productId,
    calibratedDurationSeconds,
    sampleCount,
    lastFeedback,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreezerCalibration &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.freezerId == this.freezerId &&
          other.productId == this.productId &&
          other.calibratedDurationSeconds == this.calibratedDurationSeconds &&
          other.sampleCount == this.sampleCount &&
          other.lastFeedback == this.lastFeedback &&
          other.updatedAt == this.updatedAt);
}

class FreezerCalibrationsTableCompanion
    extends UpdateCompanion<FreezerCalibration> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> freezerId;
  final Value<String?> productId;
  final Value<int> calibratedDurationSeconds;
  final Value<int> sampleCount;
  final Value<String?> lastFeedback;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FreezerCalibrationsTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.productId = const Value.absent(),
    this.calibratedDurationSeconds = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.lastFeedback = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreezerCalibrationsTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String freezerId,
    this.productId = const Value.absent(),
    required int calibratedDurationSeconds,
    this.sampleCount = const Value.absent(),
    this.lastFeedback = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       freezerId = Value(freezerId),
       calibratedDurationSeconds = Value(calibratedDurationSeconds);
  static Insertable<FreezerCalibration> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? freezerId,
    Expression<String>? productId,
    Expression<int>? calibratedDurationSeconds,
    Expression<int>? sampleCount,
    Expression<String>? lastFeedback,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (freezerId != null) 'freezer_id': freezerId,
      if (productId != null) 'product_id': productId,
      if (calibratedDurationSeconds != null)
        'calibrated_duration_seconds': calibratedDurationSeconds,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (lastFeedback != null) 'last_feedback': lastFeedback,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreezerCalibrationsTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? freezerId,
    Value<String?>? productId,
    Value<int>? calibratedDurationSeconds,
    Value<int>? sampleCount,
    Value<String?>? lastFeedback,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FreezerCalibrationsTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      freezerId: freezerId ?? this.freezerId,
      productId: productId ?? this.productId,
      calibratedDurationSeconds:
          calibratedDurationSeconds ?? this.calibratedDurationSeconds,
      sampleCount: sampleCount ?? this.sampleCount,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $FreezerCalibrationsTableTable.$convertersyncStatus.toSql(
          syncStatus.value,
        ),
      );
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<String>(freezerId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (calibratedDurationSeconds.present) {
      map['calibrated_duration_seconds'] = Variable<int>(
        calibratedDurationSeconds.value,
      );
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (lastFeedback.present) {
      map['last_feedback'] = Variable<String>(lastFeedback.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreezerCalibrationsTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('freezerId: $freezerId, ')
          ..write('productId: $productId, ')
          ..write('calibratedDurationSeconds: $calibratedDurationSeconds, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('lastFeedback: $lastFeedback, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreezersTableTable extends FreezersTable
    with TableInfo<$FreezersTableTable, Freezer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreezersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>($FreezersTableTable.$convertersyncStatus);
  static const VerificationMeta _idSensorMeta = const VerificationMeta(
    'idSensor',
  );
  @override
  late final GeneratedColumn<int> idSensor = GeneratedColumn<int>(
    'id_sensor',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentNameMeta = const VerificationMeta(
    'equipmentName',
  );
  @override
  late final GeneratedColumn<String> equipmentName = GeneratedColumn<String>(
    'equipment_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetTemperatureMeta = const VerificationMeta(
    'targetTemperature',
  );
  @override
  late final GeneratedColumn<double> targetTemperature =
      GeneratedColumn<double>(
        'target_temperature',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(4.0),
      );
  static const VerificationMeta _defaultCoolingSecondsMeta =
      const VerificationMeta('defaultCoolingSeconds');
  @override
  late final GeneratedColumn<int> defaultCoolingSeconds = GeneratedColumn<int>(
    'default_cooling_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1200),
  );
  static const VerificationMeta _unloadMinSecondsMeta = const VerificationMeta(
    'unloadMinSeconds',
  );
  @override
  late final GeneratedColumn<int> unloadMinSeconds = GeneratedColumn<int>(
    'unload_min_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _reloadMinSecondsMeta = const VerificationMeta(
    'reloadMinSeconds',
  );
  @override
  late final GeneratedColumn<int> reloadMinSeconds = GeneratedColumn<int>(
    'reload_min_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    idSensor,
    name,
    description,
    equipmentId,
    equipmentName,
    targetTemperature,
    defaultCoolingSeconds,
    unloadMinSeconds,
    reloadMinSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freezers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<Freezer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('id_sensor')) {
      context.handle(
        _idSensorMeta,
        idSensor.isAcceptableOrUnknown(data['id_sensor']!, _idSensorMeta),
      );
    } else if (isInserting) {
      context.missing(_idSensorMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    }
    if (data.containsKey('equipment_name')) {
      context.handle(
        _equipmentNameMeta,
        equipmentName.isAcceptableOrUnknown(
          data['equipment_name']!,
          _equipmentNameMeta,
        ),
      );
    }
    if (data.containsKey('target_temperature')) {
      context.handle(
        _targetTemperatureMeta,
        targetTemperature.isAcceptableOrUnknown(
          data['target_temperature']!,
          _targetTemperatureMeta,
        ),
      );
    }
    if (data.containsKey('default_cooling_seconds')) {
      context.handle(
        _defaultCoolingSecondsMeta,
        defaultCoolingSeconds.isAcceptableOrUnknown(
          data['default_cooling_seconds']!,
          _defaultCoolingSecondsMeta,
        ),
      );
    }
    if (data.containsKey('unload_min_seconds')) {
      context.handle(
        _unloadMinSecondsMeta,
        unloadMinSeconds.isAcceptableOrUnknown(
          data['unload_min_seconds']!,
          _unloadMinSecondsMeta,
        ),
      );
    }
    if (data.containsKey('reload_min_seconds')) {
      context.handle(
        _reloadMinSecondsMeta,
        reloadMinSeconds.isAcceptableOrUnknown(
          data['reload_min_seconds']!,
          _reloadMinSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Freezer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Freezer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $FreezersTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      idSensor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_sensor'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      ),
      equipmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_name'],
      ),
      targetTemperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_temperature'],
      )!,
      defaultCoolingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_cooling_seconds'],
      )!,
      unloadMinSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unload_min_seconds'],
      )!,
      reloadMinSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reload_min_seconds'],
      )!,
    );
  }

  @override
  $FreezersTableTable createAlias(String alias) {
    return $FreezersTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class Freezer extends DataClass implements Insertable<Freezer> {
  final String id;
  final SyncStatusEnum syncStatus;
  final int idSensor;
  final String name;
  final String? description;

  /// UUID do equipamento vinculado na tabela `public.cost_centers` do Supabase.
  final String? equipmentId;

  /// Nome do equipamento vinculado na tabela `public.cost_centers` do Supabase.
  final String? equipmentName;
  final double targetTemperature;
  final int defaultCoolingSeconds;
  final int unloadMinSeconds;
  final int reloadMinSeconds;
  const Freezer({
    required this.id,
    required this.syncStatus,
    required this.idSensor,
    required this.name,
    this.description,
    this.equipmentId,
    this.equipmentName,
    required this.targetTemperature,
    required this.defaultCoolingSeconds,
    required this.unloadMinSeconds,
    required this.reloadMinSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $FreezersTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['id_sensor'] = Variable<int>(idSensor);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || equipmentId != null) {
      map['equipment_id'] = Variable<String>(equipmentId);
    }
    if (!nullToAbsent || equipmentName != null) {
      map['equipment_name'] = Variable<String>(equipmentName);
    }
    map['target_temperature'] = Variable<double>(targetTemperature);
    map['default_cooling_seconds'] = Variable<int>(defaultCoolingSeconds);
    map['unload_min_seconds'] = Variable<int>(unloadMinSeconds);
    map['reload_min_seconds'] = Variable<int>(reloadMinSeconds);
    return map;
  }

  FreezersTableCompanion toCompanion(bool nullToAbsent) {
    return FreezersTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      idSensor: Value(idSensor),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      equipmentId: equipmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentId),
      equipmentName: equipmentName == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentName),
      targetTemperature: Value(targetTemperature),
      defaultCoolingSeconds: Value(defaultCoolingSeconds),
      unloadMinSeconds: Value(unloadMinSeconds),
      reloadMinSeconds: Value(reloadMinSeconds),
    );
  }

  factory Freezer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Freezer(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $FreezersTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      idSensor: serializer.fromJson<int>(json['idSensor']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      equipmentId: serializer.fromJson<String?>(json['equipmentId']),
      equipmentName: serializer.fromJson<String?>(json['equipmentName']),
      targetTemperature: serializer.fromJson<double>(json['targetTemperature']),
      defaultCoolingSeconds: serializer.fromJson<int>(
        json['defaultCoolingSeconds'],
      ),
      unloadMinSeconds: serializer.fromJson<int>(json['unloadMinSeconds']),
      reloadMinSeconds: serializer.fromJson<int>(json['reloadMinSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $FreezersTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'idSensor': serializer.toJson<int>(idSensor),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'equipmentId': serializer.toJson<String?>(equipmentId),
      'equipmentName': serializer.toJson<String?>(equipmentName),
      'targetTemperature': serializer.toJson<double>(targetTemperature),
      'defaultCoolingSeconds': serializer.toJson<int>(defaultCoolingSeconds),
      'unloadMinSeconds': serializer.toJson<int>(unloadMinSeconds),
      'reloadMinSeconds': serializer.toJson<int>(reloadMinSeconds),
    };
  }

  Freezer copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    int? idSensor,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> equipmentId = const Value.absent(),
    Value<String?> equipmentName = const Value.absent(),
    double? targetTemperature,
    int? defaultCoolingSeconds,
    int? unloadMinSeconds,
    int? reloadMinSeconds,
  }) => Freezer(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    idSensor: idSensor ?? this.idSensor,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    equipmentId: equipmentId.present ? equipmentId.value : this.equipmentId,
    equipmentName: equipmentName.present
        ? equipmentName.value
        : this.equipmentName,
    targetTemperature: targetTemperature ?? this.targetTemperature,
    defaultCoolingSeconds: defaultCoolingSeconds ?? this.defaultCoolingSeconds,
    unloadMinSeconds: unloadMinSeconds ?? this.unloadMinSeconds,
    reloadMinSeconds: reloadMinSeconds ?? this.reloadMinSeconds,
  );
  Freezer copyWithCompanion(FreezersTableCompanion data) {
    return Freezer(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idSensor: data.idSensor.present ? data.idSensor.value : this.idSensor,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      equipmentName: data.equipmentName.present
          ? data.equipmentName.value
          : this.equipmentName,
      targetTemperature: data.targetTemperature.present
          ? data.targetTemperature.value
          : this.targetTemperature,
      defaultCoolingSeconds: data.defaultCoolingSeconds.present
          ? data.defaultCoolingSeconds.value
          : this.defaultCoolingSeconds,
      unloadMinSeconds: data.unloadMinSeconds.present
          ? data.unloadMinSeconds.value
          : this.unloadMinSeconds,
      reloadMinSeconds: data.reloadMinSeconds.present
          ? data.reloadMinSeconds.value
          : this.reloadMinSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Freezer(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idSensor: $idSensor, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('equipmentName: $equipmentName, ')
          ..write('targetTemperature: $targetTemperature, ')
          ..write('defaultCoolingSeconds: $defaultCoolingSeconds, ')
          ..write('unloadMinSeconds: $unloadMinSeconds, ')
          ..write('reloadMinSeconds: $reloadMinSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStatus,
    idSensor,
    name,
    description,
    equipmentId,
    equipmentName,
    targetTemperature,
    defaultCoolingSeconds,
    unloadMinSeconds,
    reloadMinSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Freezer &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.idSensor == this.idSensor &&
          other.name == this.name &&
          other.description == this.description &&
          other.equipmentId == this.equipmentId &&
          other.equipmentName == this.equipmentName &&
          other.targetTemperature == this.targetTemperature &&
          other.defaultCoolingSeconds == this.defaultCoolingSeconds &&
          other.unloadMinSeconds == this.unloadMinSeconds &&
          other.reloadMinSeconds == this.reloadMinSeconds);
}

class FreezersTableCompanion extends UpdateCompanion<Freezer> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<int> idSensor;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> equipmentId;
  final Value<String?> equipmentName;
  final Value<double> targetTemperature;
  final Value<int> defaultCoolingSeconds;
  final Value<int> unloadMinSeconds;
  final Value<int> reloadMinSeconds;
  final Value<int> rowid;
  const FreezersTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idSensor = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.equipmentName = const Value.absent(),
    this.targetTemperature = const Value.absent(),
    this.defaultCoolingSeconds = const Value.absent(),
    this.unloadMinSeconds = const Value.absent(),
    this.reloadMinSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreezersTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required int idSensor,
    required String name,
    this.description = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.equipmentName = const Value.absent(),
    this.targetTemperature = const Value.absent(),
    this.defaultCoolingSeconds = const Value.absent(),
    this.unloadMinSeconds = const Value.absent(),
    this.reloadMinSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idSensor = Value(idSensor),
       name = Value(name);
  static Insertable<Freezer> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<int>? idSensor,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? equipmentId,
    Expression<String>? equipmentName,
    Expression<double>? targetTemperature,
    Expression<int>? defaultCoolingSeconds,
    Expression<int>? unloadMinSeconds,
    Expression<int>? reloadMinSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idSensor != null) 'id_sensor': idSensor,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (equipmentName != null) 'equipment_name': equipmentName,
      if (targetTemperature != null) 'target_temperature': targetTemperature,
      if (defaultCoolingSeconds != null)
        'default_cooling_seconds': defaultCoolingSeconds,
      if (unloadMinSeconds != null) 'unload_min_seconds': unloadMinSeconds,
      if (reloadMinSeconds != null) 'reload_min_seconds': reloadMinSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreezersTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<int>? idSensor,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? equipmentId,
    Value<String?>? equipmentName,
    Value<double>? targetTemperature,
    Value<int>? defaultCoolingSeconds,
    Value<int>? unloadMinSeconds,
    Value<int>? reloadMinSeconds,
    Value<int>? rowid,
  }) {
    return FreezersTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      idSensor: idSensor ?? this.idSensor,
      name: name ?? this.name,
      description: description ?? this.description,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      defaultCoolingSeconds:
          defaultCoolingSeconds ?? this.defaultCoolingSeconds,
      unloadMinSeconds: unloadMinSeconds ?? this.unloadMinSeconds,
      reloadMinSeconds: reloadMinSeconds ?? this.reloadMinSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $FreezersTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (idSensor.present) {
      map['id_sensor'] = Variable<int>(idSensor.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (equipmentName.present) {
      map['equipment_name'] = Variable<String>(equipmentName.value);
    }
    if (targetTemperature.present) {
      map['target_temperature'] = Variable<double>(targetTemperature.value);
    }
    if (defaultCoolingSeconds.present) {
      map['default_cooling_seconds'] = Variable<int>(
        defaultCoolingSeconds.value,
      );
    }
    if (unloadMinSeconds.present) {
      map['unload_min_seconds'] = Variable<int>(unloadMinSeconds.value);
    }
    if (reloadMinSeconds.present) {
      map['reload_min_seconds'] = Variable<int>(reloadMinSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreezersTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idSensor: $idSensor, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('equipmentName: $equipmentName, ')
          ..write('targetTemperature: $targetTemperature, ')
          ..write('defaultCoolingSeconds: $defaultCoolingSeconds, ')
          ..write('unloadMinSeconds: $unloadMinSeconds, ')
          ..write('reloadMinSeconds: $reloadMinSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomEventsTableTable extends RoomEventsTable
    with TableInfo<$RoomEventsTableTable, RoomEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatusEnum, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatusEnum>(
        $RoomEventsTableTable.$convertersyncStatus,
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
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  static const VerificationMeta _humidityMeta = const VerificationMeta(
    'humidity',
  );
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
    'humidity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStatus,
    batchId,
    recordedAt,
    temperature,
    humidity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'room_events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoomEvent> instance, {
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
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
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
    if (data.containsKey('humidity')) {
      context.handle(
        _humidityMeta,
        humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta),
      );
    } else if (isInserting) {
      context.missing(_humidityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStatus: $RoomEventsTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      humidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity'],
      )!,
    );
  }

  @override
  $RoomEventsTableTable createAlias(String alias) {
    return $RoomEventsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatusEnum, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatusEnum>(SyncStatusEnum.values);
}

class RoomEvent extends DataClass implements Insertable<RoomEvent> {
  final String id;
  final SyncStatusEnum syncStatus;
  final String batchId;
  final DateTime recordedAt;
  final double temperature;
  final double humidity;
  const RoomEvent({
    required this.id,
    required this.syncStatus,
    required this.batchId,
    required this.recordedAt,
    required this.temperature,
    required this.humidity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['sync_status'] = Variable<int>(
        $RoomEventsTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['temperature'] = Variable<double>(temperature);
    map['humidity'] = Variable<double>(humidity);
    return map;
  }

  RoomEventsTableCompanion toCompanion(bool nullToAbsent) {
    return RoomEventsTableCompanion(
      id: Value(id),
      syncStatus: Value(syncStatus),
      batchId: Value(batchId),
      recordedAt: Value(recordedAt),
      temperature: Value(temperature),
      humidity: Value(humidity),
    );
  }

  factory RoomEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomEvent(
      id: serializer.fromJson<String>(json['id']),
      syncStatus: $RoomEventsTableTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      temperature: serializer.fromJson<double>(json['temperature']),
      humidity: serializer.fromJson<double>(json['humidity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStatus': serializer.toJson<int>(
        $RoomEventsTableTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'batchId': serializer.toJson<String>(batchId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'temperature': serializer.toJson<double>(temperature),
      'humidity': serializer.toJson<double>(humidity),
    };
  }

  RoomEvent copyWith({
    String? id,
    SyncStatusEnum? syncStatus,
    String? batchId,
    DateTime? recordedAt,
    double? temperature,
    double? humidity,
  }) => RoomEvent(
    id: id ?? this.id,
    syncStatus: syncStatus ?? this.syncStatus,
    batchId: batchId ?? this.batchId,
    recordedAt: recordedAt ?? this.recordedAt,
    temperature: temperature ?? this.temperature,
    humidity: humidity ?? this.humidity,
  );
  RoomEvent copyWithCompanion(RoomEventsTableCompanion data) {
    return RoomEvent(
      id: data.id.present ? data.id.value : this.id,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoomEvent(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, syncStatus, batchId, recordedAt, temperature, humidity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomEvent &&
          other.id == this.id &&
          other.syncStatus == this.syncStatus &&
          other.batchId == this.batchId &&
          other.recordedAt == this.recordedAt &&
          other.temperature == this.temperature &&
          other.humidity == this.humidity);
}

class RoomEventsTableCompanion extends UpdateCompanion<RoomEvent> {
  final Value<String> id;
  final Value<SyncStatusEnum> syncStatus;
  final Value<String> batchId;
  final Value<DateTime> recordedAt;
  final Value<double> temperature;
  final Value<double> humidity;
  final Value<int> rowid;
  const RoomEventsTableCompanion({
    this.id = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.temperature = const Value.absent(),
    this.humidity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomEventsTableCompanion.insert({
    required String id,
    this.syncStatus = const Value.absent(),
    required String batchId,
    this.recordedAt = const Value.absent(),
    required double temperature,
    required double humidity,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       temperature = Value(temperature),
       humidity = Value(humidity);
  static Insertable<RoomEvent> custom({
    Expression<String>? id,
    Expression<int>? syncStatus,
    Expression<String>? batchId,
    Expression<DateTime>? recordedAt,
    Expression<double>? temperature,
    Expression<double>? humidity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (batchId != null) 'batch_id': batchId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomEventsTableCompanion copyWith({
    Value<String>? id,
    Value<SyncStatusEnum>? syncStatus,
    Value<String>? batchId,
    Value<DateTime>? recordedAt,
    Value<double>? temperature,
    Value<double>? humidity,
    Value<int>? rowid,
  }) {
    return RoomEventsTableCompanion(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      batchId: batchId ?? this.batchId,
      recordedAt: recordedAt ?? this.recordedAt,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $RoomEventsTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('batchId: $batchId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BatchAdjustmentsTableTable batchAdjustmentsTable =
      $BatchAdjustmentsTableTable(this);
  late final $FreezerEventsTableTable freezerEventsTable =
      $FreezerEventsTableTable(this);
  late final $ProductionBatchesTableTable productionBatchesTable =
      $ProductionBatchesTableTable(this);
  late final $ProductionTimeLinesTableTable productionTimeLinesTable =
      $ProductionTimeLinesTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $CoolingCyclesTableTable coolingCyclesTable =
      $CoolingCyclesTableTable(this);
  late final $FreezerCalibrationsTableTable freezerCalibrationsTable =
      $FreezerCalibrationsTableTable(this);
  late final $FreezersTableTable freezersTable = $FreezersTableTable(this);
  late final $RoomEventsTableTable roomEventsTable = $RoomEventsTableTable(
    this,
  );
  late final ProductionDao productionDao = ProductionDao(this as AppDatabase);
  late final FreezerDao freezerDao = FreezerDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    batchAdjustmentsTable,
    freezerEventsTable,
    productionBatchesTable,
    productionTimeLinesTable,
    productsTable,
    coolingCyclesTable,
    freezerCalibrationsTable,
    freezersTable,
    roomEventsTable,
  ];
}

typedef $$BatchAdjustmentsTableTableCreateCompanionBuilder =
    BatchAdjustmentsTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String batchId,
      required int deltaQty,
      required AdjustmentReasonEnum reason,
      Value<String?> observation,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$BatchAdjustmentsTableTableUpdateCompanionBuilder =
    BatchAdjustmentsTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> batchId,
      Value<int> deltaQty,
      Value<AdjustmentReasonEnum> reason,
      Value<String?> observation,
      Value<DateTime> createdAt,
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deltaQty => $composableBuilder(
    column: $table.deltaQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AdjustmentReasonEnum,
    AdjustmentReasonEnum,
    int
  >
  get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deltaQty => $composableBuilder(
    column: $table.deltaQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<int> get deltaQty =>
      $composableBuilder(column: $table.deltaQty, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdjustmentReasonEnum, int> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get observation => $composableBuilder(
    column: $table.observation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BatchAdjustmentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchAdjustmentsTableTable,
          BatchAdjustment,
          $$BatchAdjustmentsTableTableFilterComposer,
          $$BatchAdjustmentsTableTableOrderingComposer,
          $$BatchAdjustmentsTableTableAnnotationComposer,
          $$BatchAdjustmentsTableTableCreateCompanionBuilder,
          $$BatchAdjustmentsTableTableUpdateCompanionBuilder,
          (
            BatchAdjustment,
            BaseReferences<
              _$AppDatabase,
              $BatchAdjustmentsTableTable,
              BatchAdjustment
            >,
          ),
          BatchAdjustment,
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
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<int> deltaQty = const Value.absent(),
                Value<AdjustmentReasonEnum> reason = const Value.absent(),
                Value<String?> observation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchAdjustmentsTableCompanion(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                deltaQty: deltaQty,
                reason: reason,
                observation: observation,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String batchId,
                required int deltaQty,
                required AdjustmentReasonEnum reason,
                Value<String?> observation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchAdjustmentsTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                deltaQty: deltaQty,
                reason: reason,
                observation: observation,
                createdAt: createdAt,
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
      BatchAdjustment,
      $$BatchAdjustmentsTableTableFilterComposer,
      $$BatchAdjustmentsTableTableOrderingComposer,
      $$BatchAdjustmentsTableTableAnnotationComposer,
      $$BatchAdjustmentsTableTableCreateCompanionBuilder,
      $$BatchAdjustmentsTableTableUpdateCompanionBuilder,
      (
        BatchAdjustment,
        BaseReferences<
          _$AppDatabase,
          $BatchAdjustmentsTableTable,
          BatchAdjustment
        >,
      ),
      BatchAdjustment,
      PrefetchHooks Function()
    >;
typedef $$FreezerEventsTableTableCreateCompanionBuilder =
    FreezerEventsTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String freezerId,
      required String batchId,
      Value<DateTime> recordedAt,
      required double temperature,
      required bool isDoorOpen,
      required TriggerFreezerEnum triggerReason,
      Value<int> rowid,
    });
typedef $$FreezerEventsTableTableUpdateCompanionBuilder =
    FreezerEventsTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> freezerId,
      Value<String> batchId,
      Value<DateTime> recordedAt,
      Value<double> temperature,
      Value<bool> isDoorOpen,
      Value<TriggerFreezerEnum> triggerReason,
      Value<int> rowid,
    });

class $$FreezerEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FreezerEventsTableTable> {
  $$FreezerEventsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

  ColumnWithTypeConverterFilters<TriggerFreezerEnum, TriggerFreezerEnum, int>
  get triggerReason => $composableBuilder(
    column: $table.triggerReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$FreezerEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FreezerEventsTableTable> {
  $$FreezerEventsTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

  ColumnOrderings<int> get triggerReason => $composableBuilder(
    column: $table.triggerReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FreezerEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreezerEventsTableTable> {
  $$FreezerEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get freezerId =>
      $composableBuilder(column: $table.freezerId, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDoorOpen => $composableBuilder(
    column: $table.isDoorOpen,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TriggerFreezerEnum, int> get triggerReason =>
      $composableBuilder(
        column: $table.triggerReason,
        builder: (column) => column,
      );
}

class $$FreezerEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FreezerEventsTableTable,
          FreezerEvent,
          $$FreezerEventsTableTableFilterComposer,
          $$FreezerEventsTableTableOrderingComposer,
          $$FreezerEventsTableTableAnnotationComposer,
          $$FreezerEventsTableTableCreateCompanionBuilder,
          $$FreezerEventsTableTableUpdateCompanionBuilder,
          (
            FreezerEvent,
            BaseReferences<
              _$AppDatabase,
              $FreezerEventsTableTable,
              FreezerEvent
            >,
          ),
          FreezerEvent,
          PrefetchHooks Function()
        > {
  $$FreezerEventsTableTableTableManager(
    _$AppDatabase db,
    $FreezerEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreezerEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreezerEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreezerEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> freezerId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<bool> isDoorOpen = const Value.absent(),
                Value<TriggerFreezerEnum> triggerReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezerEventsTableCompanion(
                id: id,
                syncStatus: syncStatus,
                freezerId: freezerId,
                batchId: batchId,
                recordedAt: recordedAt,
                temperature: temperature,
                isDoorOpen: isDoorOpen,
                triggerReason: triggerReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String freezerId,
                required String batchId,
                Value<DateTime> recordedAt = const Value.absent(),
                required double temperature,
                required bool isDoorOpen,
                required TriggerFreezerEnum triggerReason,
                Value<int> rowid = const Value.absent(),
              }) => FreezerEventsTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                freezerId: freezerId,
                batchId: batchId,
                recordedAt: recordedAt,
                temperature: temperature,
                isDoorOpen: isDoorOpen,
                triggerReason: triggerReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FreezerEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FreezerEventsTableTable,
      FreezerEvent,
      $$FreezerEventsTableTableFilterComposer,
      $$FreezerEventsTableTableOrderingComposer,
      $$FreezerEventsTableTableAnnotationComposer,
      $$FreezerEventsTableTableCreateCompanionBuilder,
      $$FreezerEventsTableTableUpdateCompanionBuilder,
      (
        FreezerEvent,
        BaseReferences<_$AppDatabase, $FreezerEventsTableTable, FreezerEvent>,
      ),
      FreezerEvent,
      PrefetchHooks Function()
    >;
typedef $$ProductionBatchesTableTableCreateCompanionBuilder =
    ProductionBatchesTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String productId,
      required int initialHardwareCount,
      Value<int?> finalHardwareCount,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$ProductionBatchesTableTableUpdateCompanionBuilder =
    ProductionBatchesTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> productId,
      Value<int> initialHardwareCount,
      Value<int?> finalHardwareCount,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalHardwareCount => $composableBuilder(
    column: $table.finalHardwareCount,
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalHardwareCount => $composableBuilder(
    column: $table.finalHardwareCount,
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

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get initialHardwareCount => $composableBuilder(
    column: $table.initialHardwareCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalHardwareCount => $composableBuilder(
    column: $table.finalHardwareCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$ProductionBatchesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionBatchesTableTable,
          ProductionBatch,
          $$ProductionBatchesTableTableFilterComposer,
          $$ProductionBatchesTableTableOrderingComposer,
          $$ProductionBatchesTableTableAnnotationComposer,
          $$ProductionBatchesTableTableCreateCompanionBuilder,
          $$ProductionBatchesTableTableUpdateCompanionBuilder,
          (
            ProductionBatch,
            BaseReferences<
              _$AppDatabase,
              $ProductionBatchesTableTable,
              ProductionBatch
            >,
          ),
          ProductionBatch,
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
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> initialHardwareCount = const Value.absent(),
                Value<int?> finalHardwareCount = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductionBatchesTableCompanion(
                id: id,
                syncStatus: syncStatus,
                productId: productId,
                initialHardwareCount: initialHardwareCount,
                finalHardwareCount: finalHardwareCount,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String productId,
                required int initialHardwareCount,
                Value<int?> finalHardwareCount = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductionBatchesTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                productId: productId,
                initialHardwareCount: initialHardwareCount,
                finalHardwareCount: finalHardwareCount,
                startedAt: startedAt,
                finishedAt: finishedAt,
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
      ProductionBatch,
      $$ProductionBatchesTableTableFilterComposer,
      $$ProductionBatchesTableTableOrderingComposer,
      $$ProductionBatchesTableTableAnnotationComposer,
      $$ProductionBatchesTableTableCreateCompanionBuilder,
      $$ProductionBatchesTableTableUpdateCompanionBuilder,
      (
        ProductionBatch,
        BaseReferences<
          _$AppDatabase,
          $ProductionBatchesTableTable,
          ProductionBatch
        >,
      ),
      ProductionBatch,
      PrefetchHooks Function()
    >;
typedef $$ProductionTimeLinesTableTableCreateCompanionBuilder =
    ProductionTimeLinesTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String batchId,
      Value<DateTime> recordedAt,
      required int currentHardwareCount,
      Value<int> rowid,
    });
typedef $$ProductionTimeLinesTableTableUpdateCompanionBuilder =
    ProductionTimeLinesTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> batchId,
      Value<DateTime> recordedAt,
      Value<int> currentHardwareCount,
      Value<int> rowid,
    });

class $$ProductionTimeLinesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionTimeLinesTableTable> {
  $$ProductionTimeLinesTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentHardwareCount => $composableBuilder(
    column: $table.currentHardwareCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductionTimeLinesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionTimeLinesTableTable> {
  $$ProductionTimeLinesTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentHardwareCount => $composableBuilder(
    column: $table.currentHardwareCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductionTimeLinesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionTimeLinesTableTable> {
  $$ProductionTimeLinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentHardwareCount => $composableBuilder(
    column: $table.currentHardwareCount,
    builder: (column) => column,
  );
}

class $$ProductionTimeLinesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionTimeLinesTableTable,
          ProductionTimeline,
          $$ProductionTimeLinesTableTableFilterComposer,
          $$ProductionTimeLinesTableTableOrderingComposer,
          $$ProductionTimeLinesTableTableAnnotationComposer,
          $$ProductionTimeLinesTableTableCreateCompanionBuilder,
          $$ProductionTimeLinesTableTableUpdateCompanionBuilder,
          (
            ProductionTimeline,
            BaseReferences<
              _$AppDatabase,
              $ProductionTimeLinesTableTable,
              ProductionTimeline
            >,
          ),
          ProductionTimeline,
          PrefetchHooks Function()
        > {
  $$ProductionTimeLinesTableTableTableManager(
    _$AppDatabase db,
    $ProductionTimeLinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionTimeLinesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductionTimeLinesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductionTimeLinesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> currentHardwareCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductionTimeLinesTableCompanion(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                recordedAt: recordedAt,
                currentHardwareCount: currentHardwareCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String batchId,
                Value<DateTime> recordedAt = const Value.absent(),
                required int currentHardwareCount,
                Value<int> rowid = const Value.absent(),
              }) => ProductionTimeLinesTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                recordedAt: recordedAt,
                currentHardwareCount: currentHardwareCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductionTimeLinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductionTimeLinesTableTable,
      ProductionTimeline,
      $$ProductionTimeLinesTableTableFilterComposer,
      $$ProductionTimeLinesTableTableOrderingComposer,
      $$ProductionTimeLinesTableTableAnnotationComposer,
      $$ProductionTimeLinesTableTableCreateCompanionBuilder,
      $$ProductionTimeLinesTableTableUpdateCompanionBuilder,
      (
        ProductionTimeline,
        BaseReferences<
          _$AppDatabase,
          $ProductionTimeLinesTableTable,
          ProductionTimeline
        >,
      ),
      ProductionTimeline,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String name,
      required double unitWeightGrams,
      Value<String> category,
      Value<String?> eanCode,
      Value<int> defaultBoxCapacity,
      Value<int> defaultCoolingSeconds,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> name,
      Value<double> unitWeightGrams,
      Value<String> category,
      Value<String?> eanCode,
      Value<int> defaultBoxCapacity,
      Value<int> defaultCoolingSeconds,
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitWeightGrams => $composableBuilder(
    column: $table.unitWeightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eanCode => $composableBuilder(
    column: $table.eanCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eanCode => $composableBuilder(
    column: $table.eanCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
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

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get unitWeightGrams => $composableBuilder(
    column: $table.unitWeightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get eanCode =>
      $composableBuilder(column: $table.eanCode, builder: (column) => column);

  GeneratedColumn<int> get defaultBoxCapacity => $composableBuilder(
    column: $table.defaultBoxCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
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
          Product,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            Product,
            BaseReferences<_$AppDatabase, $ProductsTableTable, Product>,
          ),
          Product,
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
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> unitWeightGrams = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> eanCode = const Value.absent(),
                Value<int> defaultBoxCapacity = const Value.absent(),
                Value<int> defaultCoolingSeconds = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                syncStatus: syncStatus,
                name: name,
                unitWeightGrams: unitWeightGrams,
                category: category,
                eanCode: eanCode,
                defaultBoxCapacity: defaultBoxCapacity,
                defaultCoolingSeconds: defaultCoolingSeconds,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String name,
                required double unitWeightGrams,
                Value<String> category = const Value.absent(),
                Value<String?> eanCode = const Value.absent(),
                Value<int> defaultBoxCapacity = const Value.absent(),
                Value<int> defaultCoolingSeconds = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                name: name,
                unitWeightGrams: unitWeightGrams,
                category: category,
                eanCode: eanCode,
                defaultBoxCapacity: defaultBoxCapacity,
                defaultCoolingSeconds: defaultCoolingSeconds,
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
      Product,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTableTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$CoolingCyclesTableTableCreateCompanionBuilder =
    CoolingCyclesTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      Value<String?> batchId,
      required String freezerId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<double?> baselineTemp,
      Value<double?> initialPeakTemp,
      required int expectedDurationSeconds,
      Value<int?> actualDurationSeconds,
      Value<int> accumulatedDoorOpenSeconds,
      Value<int> accumulatedPenaltySeconds,
      Value<int> doorOpenCount,
      Value<String?> feedback,
      Value<int> rowid,
    });
typedef $$CoolingCyclesTableTableUpdateCompanionBuilder =
    CoolingCyclesTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String?> batchId,
      Value<String> freezerId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<double?> baselineTemp,
      Value<double?> initialPeakTemp,
      Value<int> expectedDurationSeconds,
      Value<int?> actualDurationSeconds,
      Value<int> accumulatedDoorOpenSeconds,
      Value<int> accumulatedPenaltySeconds,
      Value<int> doorOpenCount,
      Value<String?> feedback,
      Value<int> rowid,
    });

class $$CoolingCyclesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CoolingCyclesTableTable> {
  $$CoolingCyclesTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
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

  ColumnFilters<double> get baselineTemp => $composableBuilder(
    column: $table.baselineTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialPeakTemp => $composableBuilder(
    column: $table.initialPeakTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedDurationSeconds => $composableBuilder(
    column: $table.expectedDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accumulatedDoorOpenSeconds => $composableBuilder(
    column: $table.accumulatedDoorOpenSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accumulatedPenaltySeconds => $composableBuilder(
    column: $table.accumulatedPenaltySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doorOpenCount => $composableBuilder(
    column: $table.doorOpenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoolingCyclesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CoolingCyclesTableTable> {
  $$CoolingCyclesTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
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

  ColumnOrderings<double> get baselineTemp => $composableBuilder(
    column: $table.baselineTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialPeakTemp => $composableBuilder(
    column: $table.initialPeakTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedDurationSeconds => $composableBuilder(
    column: $table.expectedDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accumulatedDoorOpenSeconds => $composableBuilder(
    column: $table.accumulatedDoorOpenSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accumulatedPenaltySeconds => $composableBuilder(
    column: $table.accumulatedPenaltySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doorOpenCount => $composableBuilder(
    column: $table.doorOpenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoolingCyclesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoolingCyclesTableTable> {
  $$CoolingCyclesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get freezerId =>
      $composableBuilder(column: $table.freezerId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baselineTemp => $composableBuilder(
    column: $table.baselineTemp,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialPeakTemp => $composableBuilder(
    column: $table.initialPeakTemp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedDurationSeconds => $composableBuilder(
    column: $table.expectedDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accumulatedDoorOpenSeconds => $composableBuilder(
    column: $table.accumulatedDoorOpenSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accumulatedPenaltySeconds => $composableBuilder(
    column: $table.accumulatedPenaltySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get doorOpenCount => $composableBuilder(
    column: $table.doorOpenCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);
}

class $$CoolingCyclesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoolingCyclesTableTable,
          CoolingCycle,
          $$CoolingCyclesTableTableFilterComposer,
          $$CoolingCyclesTableTableOrderingComposer,
          $$CoolingCyclesTableTableAnnotationComposer,
          $$CoolingCyclesTableTableCreateCompanionBuilder,
          $$CoolingCyclesTableTableUpdateCompanionBuilder,
          (
            CoolingCycle,
            BaseReferences<
              _$AppDatabase,
              $CoolingCyclesTableTable,
              CoolingCycle
            >,
          ),
          CoolingCycle,
          PrefetchHooks Function()
        > {
  $$CoolingCyclesTableTableTableManager(
    _$AppDatabase db,
    $CoolingCyclesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoolingCyclesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoolingCyclesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoolingCyclesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String> freezerId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<double?> baselineTemp = const Value.absent(),
                Value<double?> initialPeakTemp = const Value.absent(),
                Value<int> expectedDurationSeconds = const Value.absent(),
                Value<int?> actualDurationSeconds = const Value.absent(),
                Value<int> accumulatedDoorOpenSeconds = const Value.absent(),
                Value<int> accumulatedPenaltySeconds = const Value.absent(),
                Value<int> doorOpenCount = const Value.absent(),
                Value<String?> feedback = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoolingCyclesTableCompanion(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                freezerId: freezerId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                baselineTemp: baselineTemp,
                initialPeakTemp: initialPeakTemp,
                expectedDurationSeconds: expectedDurationSeconds,
                actualDurationSeconds: actualDurationSeconds,
                accumulatedDoorOpenSeconds: accumulatedDoorOpenSeconds,
                accumulatedPenaltySeconds: accumulatedPenaltySeconds,
                doorOpenCount: doorOpenCount,
                feedback: feedback,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                required String freezerId,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<double?> baselineTemp = const Value.absent(),
                Value<double?> initialPeakTemp = const Value.absent(),
                required int expectedDurationSeconds,
                Value<int?> actualDurationSeconds = const Value.absent(),
                Value<int> accumulatedDoorOpenSeconds = const Value.absent(),
                Value<int> accumulatedPenaltySeconds = const Value.absent(),
                Value<int> doorOpenCount = const Value.absent(),
                Value<String?> feedback = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoolingCyclesTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                freezerId: freezerId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                baselineTemp: baselineTemp,
                initialPeakTemp: initialPeakTemp,
                expectedDurationSeconds: expectedDurationSeconds,
                actualDurationSeconds: actualDurationSeconds,
                accumulatedDoorOpenSeconds: accumulatedDoorOpenSeconds,
                accumulatedPenaltySeconds: accumulatedPenaltySeconds,
                doorOpenCount: doorOpenCount,
                feedback: feedback,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoolingCyclesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoolingCyclesTableTable,
      CoolingCycle,
      $$CoolingCyclesTableTableFilterComposer,
      $$CoolingCyclesTableTableOrderingComposer,
      $$CoolingCyclesTableTableAnnotationComposer,
      $$CoolingCyclesTableTableCreateCompanionBuilder,
      $$CoolingCyclesTableTableUpdateCompanionBuilder,
      (
        CoolingCycle,
        BaseReferences<_$AppDatabase, $CoolingCyclesTableTable, CoolingCycle>,
      ),
      CoolingCycle,
      PrefetchHooks Function()
    >;
typedef $$FreezerCalibrationsTableTableCreateCompanionBuilder =
    FreezerCalibrationsTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String freezerId,
      Value<String?> productId,
      required int calibratedDurationSeconds,
      Value<int> sampleCount,
      Value<String?> lastFeedback,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FreezerCalibrationsTableTableUpdateCompanionBuilder =
    FreezerCalibrationsTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> freezerId,
      Value<String?> productId,
      Value<int> calibratedDurationSeconds,
      Value<int> sampleCount,
      Value<String?> lastFeedback,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FreezerCalibrationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FreezerCalibrationsTableTable> {
  $$FreezerCalibrationsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calibratedDurationSeconds => $composableBuilder(
    column: $table.calibratedDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFeedback => $composableBuilder(
    column: $table.lastFeedback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FreezerCalibrationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FreezerCalibrationsTableTable> {
  $$FreezerCalibrationsTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezerId => $composableBuilder(
    column: $table.freezerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calibratedDurationSeconds => $composableBuilder(
    column: $table.calibratedDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFeedback => $composableBuilder(
    column: $table.lastFeedback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FreezerCalibrationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreezerCalibrationsTableTable> {
  $$FreezerCalibrationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get freezerId =>
      $composableBuilder(column: $table.freezerId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get calibratedDurationSeconds => $composableBuilder(
    column: $table.calibratedDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFeedback => $composableBuilder(
    column: $table.lastFeedback,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FreezerCalibrationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FreezerCalibrationsTableTable,
          FreezerCalibration,
          $$FreezerCalibrationsTableTableFilterComposer,
          $$FreezerCalibrationsTableTableOrderingComposer,
          $$FreezerCalibrationsTableTableAnnotationComposer,
          $$FreezerCalibrationsTableTableCreateCompanionBuilder,
          $$FreezerCalibrationsTableTableUpdateCompanionBuilder,
          (
            FreezerCalibration,
            BaseReferences<
              _$AppDatabase,
              $FreezerCalibrationsTableTable,
              FreezerCalibration
            >,
          ),
          FreezerCalibration,
          PrefetchHooks Function()
        > {
  $$FreezerCalibrationsTableTableTableManager(
    _$AppDatabase db,
    $FreezerCalibrationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreezerCalibrationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FreezerCalibrationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FreezerCalibrationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> freezerId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<int> calibratedDurationSeconds = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<String?> lastFeedback = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezerCalibrationsTableCompanion(
                id: id,
                syncStatus: syncStatus,
                freezerId: freezerId,
                productId: productId,
                calibratedDurationSeconds: calibratedDurationSeconds,
                sampleCount: sampleCount,
                lastFeedback: lastFeedback,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String freezerId,
                Value<String?> productId = const Value.absent(),
                required int calibratedDurationSeconds,
                Value<int> sampleCount = const Value.absent(),
                Value<String?> lastFeedback = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezerCalibrationsTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                freezerId: freezerId,
                productId: productId,
                calibratedDurationSeconds: calibratedDurationSeconds,
                sampleCount: sampleCount,
                lastFeedback: lastFeedback,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FreezerCalibrationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FreezerCalibrationsTableTable,
      FreezerCalibration,
      $$FreezerCalibrationsTableTableFilterComposer,
      $$FreezerCalibrationsTableTableOrderingComposer,
      $$FreezerCalibrationsTableTableAnnotationComposer,
      $$FreezerCalibrationsTableTableCreateCompanionBuilder,
      $$FreezerCalibrationsTableTableUpdateCompanionBuilder,
      (
        FreezerCalibration,
        BaseReferences<
          _$AppDatabase,
          $FreezerCalibrationsTableTable,
          FreezerCalibration
        >,
      ),
      FreezerCalibration,
      PrefetchHooks Function()
    >;
typedef $$FreezersTableTableCreateCompanionBuilder =
    FreezersTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required int idSensor,
      required String name,
      Value<String?> description,
      Value<String?> equipmentId,
      Value<String?> equipmentName,
      Value<double> targetTemperature,
      Value<int> defaultCoolingSeconds,
      Value<int> unloadMinSeconds,
      Value<int> reloadMinSeconds,
      Value<int> rowid,
    });
typedef $$FreezersTableTableUpdateCompanionBuilder =
    FreezersTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<int> idSensor,
      Value<String> name,
      Value<String?> description,
      Value<String?> equipmentId,
      Value<String?> equipmentName,
      Value<double> targetTemperature,
      Value<int> defaultCoolingSeconds,
      Value<int> unloadMinSeconds,
      Value<int> reloadMinSeconds,
      Value<int> rowid,
    });

class $$FreezersTableTableFilterComposer
    extends Composer<_$AppDatabase, $FreezersTableTable> {
  $$FreezersTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get idSensor => $composableBuilder(
    column: $table.idSensor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentName => $composableBuilder(
    column: $table.equipmentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetTemperature => $composableBuilder(
    column: $table.targetTemperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unloadMinSeconds => $composableBuilder(
    column: $table.unloadMinSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reloadMinSeconds => $composableBuilder(
    column: $table.reloadMinSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FreezersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FreezersTableTable> {
  $$FreezersTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idSensor => $composableBuilder(
    column: $table.idSensor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentName => $composableBuilder(
    column: $table.equipmentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetTemperature => $composableBuilder(
    column: $table.targetTemperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unloadMinSeconds => $composableBuilder(
    column: $table.unloadMinSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reloadMinSeconds => $composableBuilder(
    column: $table.reloadMinSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FreezersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreezersTableTable> {
  $$FreezersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get idSensor =>
      $composableBuilder(column: $table.idSensor, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentName => $composableBuilder(
    column: $table.equipmentName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetTemperature => $composableBuilder(
    column: $table.targetTemperature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultCoolingSeconds => $composableBuilder(
    column: $table.defaultCoolingSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unloadMinSeconds => $composableBuilder(
    column: $table.unloadMinSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reloadMinSeconds => $composableBuilder(
    column: $table.reloadMinSeconds,
    builder: (column) => column,
  );
}

class $$FreezersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FreezersTableTable,
          Freezer,
          $$FreezersTableTableFilterComposer,
          $$FreezersTableTableOrderingComposer,
          $$FreezersTableTableAnnotationComposer,
          $$FreezersTableTableCreateCompanionBuilder,
          $$FreezersTableTableUpdateCompanionBuilder,
          (
            Freezer,
            BaseReferences<_$AppDatabase, $FreezersTableTable, Freezer>,
          ),
          Freezer,
          PrefetchHooks Function()
        > {
  $$FreezersTableTableTableManager(_$AppDatabase db, $FreezersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreezersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreezersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreezersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<int> idSensor = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> equipmentName = const Value.absent(),
                Value<double> targetTemperature = const Value.absent(),
                Value<int> defaultCoolingSeconds = const Value.absent(),
                Value<int> unloadMinSeconds = const Value.absent(),
                Value<int> reloadMinSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezersTableCompanion(
                id: id,
                syncStatus: syncStatus,
                idSensor: idSensor,
                name: name,
                description: description,
                equipmentId: equipmentId,
                equipmentName: equipmentName,
                targetTemperature: targetTemperature,
                defaultCoolingSeconds: defaultCoolingSeconds,
                unloadMinSeconds: unloadMinSeconds,
                reloadMinSeconds: reloadMinSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required int idSensor,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> equipmentName = const Value.absent(),
                Value<double> targetTemperature = const Value.absent(),
                Value<int> defaultCoolingSeconds = const Value.absent(),
                Value<int> unloadMinSeconds = const Value.absent(),
                Value<int> reloadMinSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FreezersTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                idSensor: idSensor,
                name: name,
                description: description,
                equipmentId: equipmentId,
                equipmentName: equipmentName,
                targetTemperature: targetTemperature,
                defaultCoolingSeconds: defaultCoolingSeconds,
                unloadMinSeconds: unloadMinSeconds,
                reloadMinSeconds: reloadMinSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FreezersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FreezersTableTable,
      Freezer,
      $$FreezersTableTableFilterComposer,
      $$FreezersTableTableOrderingComposer,
      $$FreezersTableTableAnnotationComposer,
      $$FreezersTableTableCreateCompanionBuilder,
      $$FreezersTableTableUpdateCompanionBuilder,
      (Freezer, BaseReferences<_$AppDatabase, $FreezersTableTable, Freezer>),
      Freezer,
      PrefetchHooks Function()
    >;
typedef $$RoomEventsTableTableCreateCompanionBuilder =
    RoomEventsTableCompanion Function({
      required String id,
      Value<SyncStatusEnum> syncStatus,
      required String batchId,
      Value<DateTime> recordedAt,
      required double temperature,
      required double humidity,
      Value<int> rowid,
    });
typedef $$RoomEventsTableTableUpdateCompanionBuilder =
    RoomEventsTableCompanion Function({
      Value<String> id,
      Value<SyncStatusEnum> syncStatus,
      Value<String> batchId,
      Value<DateTime> recordedAt,
      Value<double> temperature,
      Value<double> humidity,
      Value<int> rowid,
    });

class $$RoomEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoomEventsTableTable> {
  $$RoomEventsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncStatusEnum, SyncStatusEnum, int>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoomEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomEventsTableTable> {
  $$RoomEventsTableTableOrderingComposer({
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

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoomEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomEventsTableTable> {
  $$RoomEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatusEnum, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get humidity =>
      $composableBuilder(column: $table.humidity, builder: (column) => column);
}

class $$RoomEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomEventsTableTable,
          RoomEvent,
          $$RoomEventsTableTableFilterComposer,
          $$RoomEventsTableTableOrderingComposer,
          $$RoomEventsTableTableAnnotationComposer,
          $$RoomEventsTableTableCreateCompanionBuilder,
          $$RoomEventsTableTableUpdateCompanionBuilder,
          (
            RoomEvent,
            BaseReferences<_$AppDatabase, $RoomEventsTableTable, RoomEvent>,
          ),
          RoomEvent,
          PrefetchHooks Function()
        > {
  $$RoomEventsTableTableTableManager(
    _$AppDatabase db,
    $RoomEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomEventsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> humidity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomEventsTableCompanion(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                recordedAt: recordedAt,
                temperature: temperature,
                humidity: humidity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<SyncStatusEnum> syncStatus = const Value.absent(),
                required String batchId,
                Value<DateTime> recordedAt = const Value.absent(),
                required double temperature,
                required double humidity,
                Value<int> rowid = const Value.absent(),
              }) => RoomEventsTableCompanion.insert(
                id: id,
                syncStatus: syncStatus,
                batchId: batchId,
                recordedAt: recordedAt,
                temperature: temperature,
                humidity: humidity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoomEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomEventsTableTable,
      RoomEvent,
      $$RoomEventsTableTableFilterComposer,
      $$RoomEventsTableTableOrderingComposer,
      $$RoomEventsTableTableAnnotationComposer,
      $$RoomEventsTableTableCreateCompanionBuilder,
      $$RoomEventsTableTableUpdateCompanionBuilder,
      (
        RoomEvent,
        BaseReferences<_$AppDatabase, $RoomEventsTableTable, RoomEvent>,
      ),
      RoomEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BatchAdjustmentsTableTableTableManager get batchAdjustmentsTable =>
      $$BatchAdjustmentsTableTableTableManager(_db, _db.batchAdjustmentsTable);
  $$FreezerEventsTableTableTableManager get freezerEventsTable =>
      $$FreezerEventsTableTableTableManager(_db, _db.freezerEventsTable);
  $$ProductionBatchesTableTableTableManager get productionBatchesTable =>
      $$ProductionBatchesTableTableTableManager(
        _db,
        _db.productionBatchesTable,
      );
  $$ProductionTimeLinesTableTableTableManager get productionTimeLinesTable =>
      $$ProductionTimeLinesTableTableTableManager(
        _db,
        _db.productionTimeLinesTable,
      );
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$CoolingCyclesTableTableTableManager get coolingCyclesTable =>
      $$CoolingCyclesTableTableTableManager(_db, _db.coolingCyclesTable);
  $$FreezerCalibrationsTableTableTableManager get freezerCalibrationsTable =>
      $$FreezerCalibrationsTableTableTableManager(
        _db,
        _db.freezerCalibrationsTable,
      );
  $$FreezersTableTableTableManager get freezersTable =>
      $$FreezersTableTableTableManager(_db, _db.freezersTable);
  $$RoomEventsTableTableTableManager get roomEventsTable =>
      $$RoomEventsTableTableTableManager(_db, _db.roomEventsTable);
}
