// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BikesTable extends Bikes with TableInfo<$BikesTable, BikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastConnectedAtMsMeta = const VerificationMeta(
    'lastConnectedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastConnectedAtMs = GeneratedColumn<int>(
    'last_connected_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    displayName,
    region,
    colorKey,
    sortOrder,
    createdAtMs,
    updatedAtMs,
    lastConnectedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bikes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_colorKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('last_connected_at_ms')) {
      context.handle(
        _lastConnectedAtMsMeta,
        lastConnectedAtMs.isAcceptableOrUnknown(
          data['last_connected_at_ms']!,
          _lastConnectedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  BikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      lastConnectedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_connected_at_ms'],
      ),
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }
}

class BikeRow extends DataClass implements Insertable<BikeRow> {
  final String deviceId;
  final String displayName;
  final String? region;
  final String colorKey;
  final int sortOrder;
  final int createdAtMs;
  final int updatedAtMs;
  final int? lastConnectedAtMs;
  const BikeRow({
    required this.deviceId,
    required this.displayName,
    this.region,
    required this.colorKey,
    required this.sortOrder,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.lastConnectedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    map['color_key'] = Variable<String>(colorKey);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || lastConnectedAtMs != null) {
      map['last_connected_at_ms'] = Variable<int>(lastConnectedAtMs);
    }
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      colorKey: Value(colorKey),
      sortOrder: Value(sortOrder),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      lastConnectedAtMs: lastConnectedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnectedAtMs),
    );
  }

  factory BikeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      region: serializer.fromJson<String?>(json['region']),
      colorKey: serializer.fromJson<String>(json['colorKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      lastConnectedAtMs: serializer.fromJson<int?>(json['lastConnectedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'region': serializer.toJson<String?>(region),
      'colorKey': serializer.toJson<String>(colorKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'lastConnectedAtMs': serializer.toJson<int?>(lastConnectedAtMs),
    };
  }

  BikeRow copyWith({
    String? deviceId,
    String? displayName,
    Value<String?> region = const Value.absent(),
    String? colorKey,
    int? sortOrder,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> lastConnectedAtMs = const Value.absent(),
  }) => BikeRow(
    deviceId: deviceId ?? this.deviceId,
    displayName: displayName ?? this.displayName,
    region: region.present ? region.value : this.region,
    colorKey: colorKey ?? this.colorKey,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    lastConnectedAtMs: lastConnectedAtMs.present
        ? lastConnectedAtMs.value
        : this.lastConnectedAtMs,
  );
  BikeRow copyWithCompanion(BikesCompanion data) {
    return BikeRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      region: data.region.present ? data.region.value : this.region,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      lastConnectedAtMs: data.lastConnectedAtMs.present
          ? data.lastConnectedAtMs.value
          : this.lastConnectedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeRow(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('region: $region, ')
          ..write('colorKey: $colorKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastConnectedAtMs: $lastConnectedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    displayName,
    region,
    colorKey,
    sortOrder,
    createdAtMs,
    updatedAtMs,
    lastConnectedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeRow &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.region == this.region &&
          other.colorKey == this.colorKey &&
          other.sortOrder == this.sortOrder &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.lastConnectedAtMs == this.lastConnectedAtMs);
}

class BikesCompanion extends UpdateCompanion<BikeRow> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String?> region;
  final Value<String> colorKey;
  final Value<int> sortOrder;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> lastConnectedAtMs;
  final Value<int> rowid;
  const BikesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.region = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.lastConnectedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikesCompanion.insert({
    required String deviceId,
    required String displayName,
    this.region = const Value.absent(),
    required String colorKey,
    required int sortOrder,
    required int createdAtMs,
    required int updatedAtMs,
    this.lastConnectedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       displayName = Value(displayName),
       colorKey = Value(colorKey),
       sortOrder = Value(sortOrder),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<BikeRow> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? region,
    Expression<String>? colorKey,
    Expression<int>? sortOrder,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? lastConnectedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (region != null) 'region': region,
      if (colorKey != null) 'color_key': colorKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (lastConnectedAtMs != null) 'last_connected_at_ms': lastConnectedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? displayName,
    Value<String?>? region,
    Value<String>? colorKey,
    Value<int>? sortOrder,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? lastConnectedAtMs,
    Value<int>? rowid,
  }) {
    return BikesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      region: region ?? this.region,
      colorKey: colorKey ?? this.colorKey,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (lastConnectedAtMs.present) {
      map['last_connected_at_ms'] = Variable<int>(lastConnectedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('region: $region, ')
          ..write('colorKey: $colorKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastConnectedAtMs: $lastConnectedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BikePreferencesTable extends BikePreferences
    with TableInfo<$BikePreferencesTable, BikePreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (device_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _desiredLightMeta = const VerificationMeta(
    'desiredLight',
  );
  @override
  late final GeneratedColumn<bool> desiredLight = GeneratedColumn<bool>(
    'desired_light',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("desired_light" IN (0, 1))',
    ),
  );
  static const VerificationMeta _desiredModeMeta = const VerificationMeta(
    'desiredMode',
  );
  @override
  late final GeneratedColumn<int> desiredMode = GeneratedColumn<int>(
    'desired_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _desiredAssistMeta = const VerificationMeta(
    'desiredAssist',
  );
  @override
  late final GeneratedColumn<int> desiredAssist = GeneratedColumn<int>(
    'desired_assist',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keepLightMeta = const VerificationMeta(
    'keepLight',
  );
  @override
  late final GeneratedColumn<bool> keepLight = GeneratedColumn<bool>(
    'keep_light',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_light" IN (0, 1))',
    ),
  );
  static const VerificationMeta _keepModeMeta = const VerificationMeta(
    'keepMode',
  );
  @override
  late final GeneratedColumn<bool> keepMode = GeneratedColumn<bool>(
    'keep_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_mode" IN (0, 1))',
    ),
  );
  static const VerificationMeta _keepAssistMeta = const VerificationMeta(
    'keepAssist',
  );
  @override
  late final GeneratedColumn<bool> keepAssist = GeneratedColumn<bool>(
    'keep_assist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_assist" IN (0, 1))',
    ),
  );
  static const VerificationMeta _backgroundRequestedMeta =
      const VerificationMeta('backgroundRequested');
  @override
  late final GeneratedColumn<bool> backgroundRequested = GeneratedColumn<bool>(
    'background_requested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("background_requested" IN (0, 1))',
    ),
  );
  static const VerificationMeta _backgroundConsentVersionMeta =
      const VerificationMeta('backgroundConsentVersion');
  @override
  late final GeneratedColumn<int> backgroundConsentVersion =
      GeneratedColumn<int>(
        'background_consent_version',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    desiredLight,
    desiredMode,
    desiredAssist,
    keepLight,
    keepMode,
    keepAssist,
    backgroundRequested,
    backgroundConsentVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bike_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikePreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('desired_light')) {
      context.handle(
        _desiredLightMeta,
        desiredLight.isAcceptableOrUnknown(
          data['desired_light']!,
          _desiredLightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_desiredLightMeta);
    }
    if (data.containsKey('desired_mode')) {
      context.handle(
        _desiredModeMeta,
        desiredMode.isAcceptableOrUnknown(
          data['desired_mode']!,
          _desiredModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_desiredModeMeta);
    }
    if (data.containsKey('desired_assist')) {
      context.handle(
        _desiredAssistMeta,
        desiredAssist.isAcceptableOrUnknown(
          data['desired_assist']!,
          _desiredAssistMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_desiredAssistMeta);
    }
    if (data.containsKey('keep_light')) {
      context.handle(
        _keepLightMeta,
        keepLight.isAcceptableOrUnknown(data['keep_light']!, _keepLightMeta),
      );
    } else if (isInserting) {
      context.missing(_keepLightMeta);
    }
    if (data.containsKey('keep_mode')) {
      context.handle(
        _keepModeMeta,
        keepMode.isAcceptableOrUnknown(data['keep_mode']!, _keepModeMeta),
      );
    } else if (isInserting) {
      context.missing(_keepModeMeta);
    }
    if (data.containsKey('keep_assist')) {
      context.handle(
        _keepAssistMeta,
        keepAssist.isAcceptableOrUnknown(data['keep_assist']!, _keepAssistMeta),
      );
    } else if (isInserting) {
      context.missing(_keepAssistMeta);
    }
    if (data.containsKey('background_requested')) {
      context.handle(
        _backgroundRequestedMeta,
        backgroundRequested.isAcceptableOrUnknown(
          data['background_requested']!,
          _backgroundRequestedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backgroundRequestedMeta);
    }
    if (data.containsKey('background_consent_version')) {
      context.handle(
        _backgroundConsentVersionMeta,
        backgroundConsentVersion.isAcceptableOrUnknown(
          data['background_consent_version']!,
          _backgroundConsentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backgroundConsentVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  BikePreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikePreferenceRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      desiredLight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}desired_light'],
      )!,
      desiredMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}desired_mode'],
      )!,
      desiredAssist: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}desired_assist'],
      )!,
      keepLight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_light'],
      )!,
      keepMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_mode'],
      )!,
      keepAssist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_assist'],
      )!,
      backgroundRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_requested'],
      )!,
      backgroundConsentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}background_consent_version'],
      )!,
    );
  }

  @override
  $BikePreferencesTable createAlias(String alias) {
    return $BikePreferencesTable(attachedDatabase, alias);
  }
}

class BikePreferenceRow extends DataClass
    implements Insertable<BikePreferenceRow> {
  final String deviceId;
  final bool desiredLight;
  final int desiredMode;
  final int desiredAssist;
  final bool keepLight;
  final bool keepMode;
  final bool keepAssist;
  final bool backgroundRequested;
  final int backgroundConsentVersion;
  const BikePreferenceRow({
    required this.deviceId,
    required this.desiredLight,
    required this.desiredMode,
    required this.desiredAssist,
    required this.keepLight,
    required this.keepMode,
    required this.keepAssist,
    required this.backgroundRequested,
    required this.backgroundConsentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['desired_light'] = Variable<bool>(desiredLight);
    map['desired_mode'] = Variable<int>(desiredMode);
    map['desired_assist'] = Variable<int>(desiredAssist);
    map['keep_light'] = Variable<bool>(keepLight);
    map['keep_mode'] = Variable<bool>(keepMode);
    map['keep_assist'] = Variable<bool>(keepAssist);
    map['background_requested'] = Variable<bool>(backgroundRequested);
    map['background_consent_version'] = Variable<int>(backgroundConsentVersion);
    return map;
  }

  BikePreferencesCompanion toCompanion(bool nullToAbsent) {
    return BikePreferencesCompanion(
      deviceId: Value(deviceId),
      desiredLight: Value(desiredLight),
      desiredMode: Value(desiredMode),
      desiredAssist: Value(desiredAssist),
      keepLight: Value(keepLight),
      keepMode: Value(keepMode),
      keepAssist: Value(keepAssist),
      backgroundRequested: Value(backgroundRequested),
      backgroundConsentVersion: Value(backgroundConsentVersion),
    );
  }

  factory BikePreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikePreferenceRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      desiredLight: serializer.fromJson<bool>(json['desiredLight']),
      desiredMode: serializer.fromJson<int>(json['desiredMode']),
      desiredAssist: serializer.fromJson<int>(json['desiredAssist']),
      keepLight: serializer.fromJson<bool>(json['keepLight']),
      keepMode: serializer.fromJson<bool>(json['keepMode']),
      keepAssist: serializer.fromJson<bool>(json['keepAssist']),
      backgroundRequested: serializer.fromJson<bool>(
        json['backgroundRequested'],
      ),
      backgroundConsentVersion: serializer.fromJson<int>(
        json['backgroundConsentVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'desiredLight': serializer.toJson<bool>(desiredLight),
      'desiredMode': serializer.toJson<int>(desiredMode),
      'desiredAssist': serializer.toJson<int>(desiredAssist),
      'keepLight': serializer.toJson<bool>(keepLight),
      'keepMode': serializer.toJson<bool>(keepMode),
      'keepAssist': serializer.toJson<bool>(keepAssist),
      'backgroundRequested': serializer.toJson<bool>(backgroundRequested),
      'backgroundConsentVersion': serializer.toJson<int>(
        backgroundConsentVersion,
      ),
    };
  }

  BikePreferenceRow copyWith({
    String? deviceId,
    bool? desiredLight,
    int? desiredMode,
    int? desiredAssist,
    bool? keepLight,
    bool? keepMode,
    bool? keepAssist,
    bool? backgroundRequested,
    int? backgroundConsentVersion,
  }) => BikePreferenceRow(
    deviceId: deviceId ?? this.deviceId,
    desiredLight: desiredLight ?? this.desiredLight,
    desiredMode: desiredMode ?? this.desiredMode,
    desiredAssist: desiredAssist ?? this.desiredAssist,
    keepLight: keepLight ?? this.keepLight,
    keepMode: keepMode ?? this.keepMode,
    keepAssist: keepAssist ?? this.keepAssist,
    backgroundRequested: backgroundRequested ?? this.backgroundRequested,
    backgroundConsentVersion:
        backgroundConsentVersion ?? this.backgroundConsentVersion,
  );
  BikePreferenceRow copyWithCompanion(BikePreferencesCompanion data) {
    return BikePreferenceRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      desiredLight: data.desiredLight.present
          ? data.desiredLight.value
          : this.desiredLight,
      desiredMode: data.desiredMode.present
          ? data.desiredMode.value
          : this.desiredMode,
      desiredAssist: data.desiredAssist.present
          ? data.desiredAssist.value
          : this.desiredAssist,
      keepLight: data.keepLight.present ? data.keepLight.value : this.keepLight,
      keepMode: data.keepMode.present ? data.keepMode.value : this.keepMode,
      keepAssist: data.keepAssist.present
          ? data.keepAssist.value
          : this.keepAssist,
      backgroundRequested: data.backgroundRequested.present
          ? data.backgroundRequested.value
          : this.backgroundRequested,
      backgroundConsentVersion: data.backgroundConsentVersion.present
          ? data.backgroundConsentVersion.value
          : this.backgroundConsentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikePreferenceRow(')
          ..write('deviceId: $deviceId, ')
          ..write('desiredLight: $desiredLight, ')
          ..write('desiredMode: $desiredMode, ')
          ..write('desiredAssist: $desiredAssist, ')
          ..write('keepLight: $keepLight, ')
          ..write('keepMode: $keepMode, ')
          ..write('keepAssist: $keepAssist, ')
          ..write('backgroundRequested: $backgroundRequested, ')
          ..write('backgroundConsentVersion: $backgroundConsentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    desiredLight,
    desiredMode,
    desiredAssist,
    keepLight,
    keepMode,
    keepAssist,
    backgroundRequested,
    backgroundConsentVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikePreferenceRow &&
          other.deviceId == this.deviceId &&
          other.desiredLight == this.desiredLight &&
          other.desiredMode == this.desiredMode &&
          other.desiredAssist == this.desiredAssist &&
          other.keepLight == this.keepLight &&
          other.keepMode == this.keepMode &&
          other.keepAssist == this.keepAssist &&
          other.backgroundRequested == this.backgroundRequested &&
          other.backgroundConsentVersion == this.backgroundConsentVersion);
}

class BikePreferencesCompanion extends UpdateCompanion<BikePreferenceRow> {
  final Value<String> deviceId;
  final Value<bool> desiredLight;
  final Value<int> desiredMode;
  final Value<int> desiredAssist;
  final Value<bool> keepLight;
  final Value<bool> keepMode;
  final Value<bool> keepAssist;
  final Value<bool> backgroundRequested;
  final Value<int> backgroundConsentVersion;
  final Value<int> rowid;
  const BikePreferencesCompanion({
    this.deviceId = const Value.absent(),
    this.desiredLight = const Value.absent(),
    this.desiredMode = const Value.absent(),
    this.desiredAssist = const Value.absent(),
    this.keepLight = const Value.absent(),
    this.keepMode = const Value.absent(),
    this.keepAssist = const Value.absent(),
    this.backgroundRequested = const Value.absent(),
    this.backgroundConsentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikePreferencesCompanion.insert({
    required String deviceId,
    required bool desiredLight,
    required int desiredMode,
    required int desiredAssist,
    required bool keepLight,
    required bool keepMode,
    required bool keepAssist,
    required bool backgroundRequested,
    required int backgroundConsentVersion,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       desiredLight = Value(desiredLight),
       desiredMode = Value(desiredMode),
       desiredAssist = Value(desiredAssist),
       keepLight = Value(keepLight),
       keepMode = Value(keepMode),
       keepAssist = Value(keepAssist),
       backgroundRequested = Value(backgroundRequested),
       backgroundConsentVersion = Value(backgroundConsentVersion);
  static Insertable<BikePreferenceRow> custom({
    Expression<String>? deviceId,
    Expression<bool>? desiredLight,
    Expression<int>? desiredMode,
    Expression<int>? desiredAssist,
    Expression<bool>? keepLight,
    Expression<bool>? keepMode,
    Expression<bool>? keepAssist,
    Expression<bool>? backgroundRequested,
    Expression<int>? backgroundConsentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (desiredLight != null) 'desired_light': desiredLight,
      if (desiredMode != null) 'desired_mode': desiredMode,
      if (desiredAssist != null) 'desired_assist': desiredAssist,
      if (keepLight != null) 'keep_light': keepLight,
      if (keepMode != null) 'keep_mode': keepMode,
      if (keepAssist != null) 'keep_assist': keepAssist,
      if (backgroundRequested != null)
        'background_requested': backgroundRequested,
      if (backgroundConsentVersion != null)
        'background_consent_version': backgroundConsentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikePreferencesCompanion copyWith({
    Value<String>? deviceId,
    Value<bool>? desiredLight,
    Value<int>? desiredMode,
    Value<int>? desiredAssist,
    Value<bool>? keepLight,
    Value<bool>? keepMode,
    Value<bool>? keepAssist,
    Value<bool>? backgroundRequested,
    Value<int>? backgroundConsentVersion,
    Value<int>? rowid,
  }) {
    return BikePreferencesCompanion(
      deviceId: deviceId ?? this.deviceId,
      desiredLight: desiredLight ?? this.desiredLight,
      desiredMode: desiredMode ?? this.desiredMode,
      desiredAssist: desiredAssist ?? this.desiredAssist,
      keepLight: keepLight ?? this.keepLight,
      keepMode: keepMode ?? this.keepMode,
      keepAssist: keepAssist ?? this.keepAssist,
      backgroundRequested: backgroundRequested ?? this.backgroundRequested,
      backgroundConsentVersion:
          backgroundConsentVersion ?? this.backgroundConsentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (desiredLight.present) {
      map['desired_light'] = Variable<bool>(desiredLight.value);
    }
    if (desiredMode.present) {
      map['desired_mode'] = Variable<int>(desiredMode.value);
    }
    if (desiredAssist.present) {
      map['desired_assist'] = Variable<int>(desiredAssist.value);
    }
    if (keepLight.present) {
      map['keep_light'] = Variable<bool>(keepLight.value);
    }
    if (keepMode.present) {
      map['keep_mode'] = Variable<bool>(keepMode.value);
    }
    if (keepAssist.present) {
      map['keep_assist'] = Variable<bool>(keepAssist.value);
    }
    if (backgroundRequested.present) {
      map['background_requested'] = Variable<bool>(backgroundRequested.value);
    }
    if (backgroundConsentVersion.present) {
      map['background_consent_version'] = Variable<int>(
        backgroundConsentVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikePreferencesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('desiredLight: $desiredLight, ')
          ..write('desiredMode: $desiredMode, ')
          ..write('desiredAssist: $desiredAssist, ')
          ..write('keepLight: $keepLight, ')
          ..write('keepMode: $keepMode, ')
          ..write('keepAssist: $keepAssist, ')
          ..write('backgroundRequested: $backgroundRequested, ')
          ..write('backgroundConsentVersion: $backgroundConsentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeBikeIdMeta = const VerificationMeta(
    'activeBikeId',
  );
  @override
  late final GeneratedColumn<String> activeBikeId = GeneratedColumn<String>(
    'active_bike_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (device_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _lastViewedBikeIdMeta = const VerificationMeta(
    'lastViewedBikeId',
  );
  @override
  late final GeneratedColumn<String> lastViewedBikeId = GeneratedColumn<String>(
    'last_viewed_bike_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (device_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _migrationNoticePendingMeta =
      const VerificationMeta('migrationNoticePending');
  @override
  late final GeneratedColumn<bool> migrationNoticePending =
      GeneratedColumn<bool>(
        'migration_notice_pending',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("migration_notice_pending" IN (0, 1))',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    activeBikeId,
    lastViewedBikeId,
    migrationNoticePending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('active_bike_id')) {
      context.handle(
        _activeBikeIdMeta,
        activeBikeId.isAcceptableOrUnknown(
          data['active_bike_id']!,
          _activeBikeIdMeta,
        ),
      );
    }
    if (data.containsKey('last_viewed_bike_id')) {
      context.handle(
        _lastViewedBikeIdMeta,
        lastViewedBikeId.isAcceptableOrUnknown(
          data['last_viewed_bike_id']!,
          _lastViewedBikeIdMeta,
        ),
      );
    }
    if (data.containsKey('migration_notice_pending')) {
      context.handle(
        _migrationNoticePendingMeta,
        migrationNoticePending.isAcceptableOrUnknown(
          data['migration_notice_pending']!,
          _migrationNoticePendingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationNoticePendingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      activeBikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_bike_id'],
      ),
      lastViewedBikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_viewed_bike_id'],
      ),
      migrationNoticePending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}migration_notice_pending'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final int singletonId;
  final String? activeBikeId;
  final String? lastViewedBikeId;
  final bool migrationNoticePending;
  const AppSettingRow({
    required this.singletonId,
    this.activeBikeId,
    this.lastViewedBikeId,
    required this.migrationNoticePending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    if (!nullToAbsent || activeBikeId != null) {
      map['active_bike_id'] = Variable<String>(activeBikeId);
    }
    if (!nullToAbsent || lastViewedBikeId != null) {
      map['last_viewed_bike_id'] = Variable<String>(lastViewedBikeId);
    }
    map['migration_notice_pending'] = Variable<bool>(migrationNoticePending);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      singletonId: Value(singletonId),
      activeBikeId: activeBikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeBikeId),
      lastViewedBikeId: lastViewedBikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastViewedBikeId),
      migrationNoticePending: Value(migrationNoticePending),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      activeBikeId: serializer.fromJson<String?>(json['activeBikeId']),
      lastViewedBikeId: serializer.fromJson<String?>(json['lastViewedBikeId']),
      migrationNoticePending: serializer.fromJson<bool>(
        json['migrationNoticePending'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'activeBikeId': serializer.toJson<String?>(activeBikeId),
      'lastViewedBikeId': serializer.toJson<String?>(lastViewedBikeId),
      'migrationNoticePending': serializer.toJson<bool>(migrationNoticePending),
    };
  }

  AppSettingRow copyWith({
    int? singletonId,
    Value<String?> activeBikeId = const Value.absent(),
    Value<String?> lastViewedBikeId = const Value.absent(),
    bool? migrationNoticePending,
  }) => AppSettingRow(
    singletonId: singletonId ?? this.singletonId,
    activeBikeId: activeBikeId.present ? activeBikeId.value : this.activeBikeId,
    lastViewedBikeId: lastViewedBikeId.present
        ? lastViewedBikeId.value
        : this.lastViewedBikeId,
    migrationNoticePending:
        migrationNoticePending ?? this.migrationNoticePending,
  );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      activeBikeId: data.activeBikeId.present
          ? data.activeBikeId.value
          : this.activeBikeId,
      lastViewedBikeId: data.lastViewedBikeId.present
          ? data.lastViewedBikeId.value
          : this.lastViewedBikeId,
      migrationNoticePending: data.migrationNoticePending.present
          ? data.migrationNoticePending.value
          : this.migrationNoticePending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('singletonId: $singletonId, ')
          ..write('activeBikeId: $activeBikeId, ')
          ..write('lastViewedBikeId: $lastViewedBikeId, ')
          ..write('migrationNoticePending: $migrationNoticePending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    activeBikeId,
    lastViewedBikeId,
    migrationNoticePending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.singletonId == this.singletonId &&
          other.activeBikeId == this.activeBikeId &&
          other.lastViewedBikeId == this.lastViewedBikeId &&
          other.migrationNoticePending == this.migrationNoticePending);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<int> singletonId;
  final Value<String?> activeBikeId;
  final Value<String?> lastViewedBikeId;
  final Value<bool> migrationNoticePending;
  const AppSettingsCompanion({
    this.singletonId = const Value.absent(),
    this.activeBikeId = const Value.absent(),
    this.lastViewedBikeId = const Value.absent(),
    this.migrationNoticePending = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.singletonId = const Value.absent(),
    this.activeBikeId = const Value.absent(),
    this.lastViewedBikeId = const Value.absent(),
    required bool migrationNoticePending,
  }) : migrationNoticePending = Value(migrationNoticePending);
  static Insertable<AppSettingRow> custom({
    Expression<int>? singletonId,
    Expression<String>? activeBikeId,
    Expression<String>? lastViewedBikeId,
    Expression<bool>? migrationNoticePending,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (activeBikeId != null) 'active_bike_id': activeBikeId,
      if (lastViewedBikeId != null) 'last_viewed_bike_id': lastViewedBikeId,
      if (migrationNoticePending != null)
        'migration_notice_pending': migrationNoticePending,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? singletonId,
    Value<String?>? activeBikeId,
    Value<String?>? lastViewedBikeId,
    Value<bool>? migrationNoticePending,
  }) {
    return AppSettingsCompanion(
      singletonId: singletonId ?? this.singletonId,
      activeBikeId: activeBikeId ?? this.activeBikeId,
      lastViewedBikeId: lastViewedBikeId ?? this.lastViewedBikeId,
      migrationNoticePending:
          migrationNoticePending ?? this.migrationNoticePending,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (activeBikeId.present) {
      map['active_bike_id'] = Variable<String>(activeBikeId.value);
    }
    if (lastViewedBikeId.present) {
      map['last_viewed_bike_id'] = Variable<String>(lastViewedBikeId.value);
    }
    if (migrationNoticePending.present) {
      map['migration_notice_pending'] = Variable<bool>(
        migrationNoticePending.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('activeBikeId: $activeBikeId, ')
          ..write('lastViewedBikeId: $lastViewedBikeId, ')
          ..write('migrationNoticePending: $migrationNoticePending')
          ..write(')'))
        .toString();
  }
}

class $DataImportsTable extends DataImports
    with TableInfo<$DataImportsTable, DataImportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _importKeyMeta = const VerificationMeta(
    'importKey',
  );
  @override
  late final GeneratedColumn<String> importKey = GeneratedColumn<String>(
    'import_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMsMeta = const VerificationMeta(
    'completedAtMs',
  );
  @override
  late final GeneratedColumn<int> completedAtMs = GeneratedColumn<int>(
    'completed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bikesImportedMeta = const VerificationMeta(
    'bikesImported',
  );
  @override
  late final GeneratedColumn<int> bikesImported = GeneratedColumn<int>(
    'bikes_imported',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    importKey,
    outcome,
    completedAtMs,
    bikesImported,
    warningsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DataImportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('import_key')) {
      context.handle(
        _importKeyMeta,
        importKey.isAcceptableOrUnknown(data['import_key']!, _importKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_importKeyMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('completed_at_ms')) {
      context.handle(
        _completedAtMsMeta,
        completedAtMs.isAcceptableOrUnknown(
          data['completed_at_ms']!,
          _completedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMsMeta);
    }
    if (data.containsKey('bikes_imported')) {
      context.handle(
        _bikesImportedMeta,
        bikesImported.isAcceptableOrUnknown(
          data['bikes_imported']!,
          _bikesImportedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bikesImportedMeta);
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warningsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {importKey};
  @override
  DataImportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataImportRow(
      importKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_key'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      completedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_ms'],
      )!,
      bikesImported: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bikes_imported'],
      )!,
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      )!,
    );
  }

  @override
  $DataImportsTable createAlias(String alias) {
    return $DataImportsTable(attachedDatabase, alias);
  }
}

class DataImportRow extends DataClass implements Insertable<DataImportRow> {
  final String importKey;
  final String outcome;
  final int completedAtMs;
  final int bikesImported;
  final String warningsJson;
  const DataImportRow({
    required this.importKey,
    required this.outcome,
    required this.completedAtMs,
    required this.bikesImported,
    required this.warningsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['import_key'] = Variable<String>(importKey);
    map['outcome'] = Variable<String>(outcome);
    map['completed_at_ms'] = Variable<int>(completedAtMs);
    map['bikes_imported'] = Variable<int>(bikesImported);
    map['warnings_json'] = Variable<String>(warningsJson);
    return map;
  }

  DataImportsCompanion toCompanion(bool nullToAbsent) {
    return DataImportsCompanion(
      importKey: Value(importKey),
      outcome: Value(outcome),
      completedAtMs: Value(completedAtMs),
      bikesImported: Value(bikesImported),
      warningsJson: Value(warningsJson),
    );
  }

  factory DataImportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataImportRow(
      importKey: serializer.fromJson<String>(json['importKey']),
      outcome: serializer.fromJson<String>(json['outcome']),
      completedAtMs: serializer.fromJson<int>(json['completedAtMs']),
      bikesImported: serializer.fromJson<int>(json['bikesImported']),
      warningsJson: serializer.fromJson<String>(json['warningsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'importKey': serializer.toJson<String>(importKey),
      'outcome': serializer.toJson<String>(outcome),
      'completedAtMs': serializer.toJson<int>(completedAtMs),
      'bikesImported': serializer.toJson<int>(bikesImported),
      'warningsJson': serializer.toJson<String>(warningsJson),
    };
  }

  DataImportRow copyWith({
    String? importKey,
    String? outcome,
    int? completedAtMs,
    int? bikesImported,
    String? warningsJson,
  }) => DataImportRow(
    importKey: importKey ?? this.importKey,
    outcome: outcome ?? this.outcome,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    bikesImported: bikesImported ?? this.bikesImported,
    warningsJson: warningsJson ?? this.warningsJson,
  );
  DataImportRow copyWithCompanion(DataImportsCompanion data) {
    return DataImportRow(
      importKey: data.importKey.present ? data.importKey.value : this.importKey,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
      bikesImported: data.bikesImported.present
          ? data.bikesImported.value
          : this.bikesImported,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataImportRow(')
          ..write('importKey: $importKey, ')
          ..write('outcome: $outcome, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('bikesImported: $bikesImported, ')
          ..write('warningsJson: $warningsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    importKey,
    outcome,
    completedAtMs,
    bikesImported,
    warningsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataImportRow &&
          other.importKey == this.importKey &&
          other.outcome == this.outcome &&
          other.completedAtMs == this.completedAtMs &&
          other.bikesImported == this.bikesImported &&
          other.warningsJson == this.warningsJson);
}

class DataImportsCompanion extends UpdateCompanion<DataImportRow> {
  final Value<String> importKey;
  final Value<String> outcome;
  final Value<int> completedAtMs;
  final Value<int> bikesImported;
  final Value<String> warningsJson;
  final Value<int> rowid;
  const DataImportsCompanion({
    this.importKey = const Value.absent(),
    this.outcome = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.bikesImported = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataImportsCompanion.insert({
    required String importKey,
    required String outcome,
    required int completedAtMs,
    required int bikesImported,
    required String warningsJson,
    this.rowid = const Value.absent(),
  }) : importKey = Value(importKey),
       outcome = Value(outcome),
       completedAtMs = Value(completedAtMs),
       bikesImported = Value(bikesImported),
       warningsJson = Value(warningsJson);
  static Insertable<DataImportRow> custom({
    Expression<String>? importKey,
    Expression<String>? outcome,
    Expression<int>? completedAtMs,
    Expression<int>? bikesImported,
    Expression<String>? warningsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (importKey != null) 'import_key': importKey,
      if (outcome != null) 'outcome': outcome,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (bikesImported != null) 'bikes_imported': bikesImported,
      if (warningsJson != null) 'warnings_json': warningsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataImportsCompanion copyWith({
    Value<String>? importKey,
    Value<String>? outcome,
    Value<int>? completedAtMs,
    Value<int>? bikesImported,
    Value<String>? warningsJson,
    Value<int>? rowid,
  }) {
    return DataImportsCompanion(
      importKey: importKey ?? this.importKey,
      outcome: outcome ?? this.outcome,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      bikesImported: bikesImported ?? this.bikesImported,
      warningsJson: warningsJson ?? this.warningsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (importKey.present) {
      map['import_key'] = Variable<String>(importKey.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
    }
    if (bikesImported.present) {
      map['bikes_imported'] = Variable<int>(bikesImported.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataImportsCompanion(')
          ..write('importKey: $importKey, ')
          ..write('outcome: $outcome, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('bikesImported: $bikesImported, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $BikesTable bikes = $BikesTable(this);
  late final $BikePreferencesTable bikePreferences = $BikePreferencesTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DataImportsTable dataImports = $DataImportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bikes,
    bikePreferences,
    appSettings,
    dataImports,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bike_preferences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_settings', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_settings', kind: UpdateKind.update)],
    ),
  ]);
}
