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
  static const VerificationMeta _advertisedNameMeta = const VerificationMeta(
    'advertisedName',
  );
  @override
  late final GeneratedColumn<String> advertisedName = GeneratedColumn<String>(
    'advertised_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BikeProtocolVersion, String>
  protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<BikeProtocolVersion>($BikesTable.$converterprotocol);
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
  static const VerificationMeta _moduleSerialMeta = const VerificationMeta(
    'moduleSerial',
  );
  @override
  late final GeneratedColumn<String> moduleSerial = GeneratedColumn<String>(
    'module_serial',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _odometerMetersMeta = const VerificationMeta(
    'odometerMeters',
  );
  @override
  late final GeneratedColumn<int> odometerMeters = GeneratedColumn<int>(
    'odometer_meters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _odometerReadAtMsMeta = const VerificationMeta(
    'odometerReadAtMs',
  );
  @override
  late final GeneratedColumn<int> odometerReadAtMs = GeneratedColumn<int>(
    'odometer_read_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    displayName,
    advertisedName,
    protocol,
    region,
    colorKey,
    sortOrder,
    createdAtMs,
    updatedAtMs,
    lastConnectedAtMs,
    moduleSerial,
    odometerMeters,
    odometerReadAtMs,
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
    if (data.containsKey('advertised_name')) {
      context.handle(
        _advertisedNameMeta,
        advertisedName.isAcceptableOrUnknown(
          data['advertised_name']!,
          _advertisedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_advertisedNameMeta);
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
    if (data.containsKey('module_serial')) {
      context.handle(
        _moduleSerialMeta,
        moduleSerial.isAcceptableOrUnknown(
          data['module_serial']!,
          _moduleSerialMeta,
        ),
      );
    }
    if (data.containsKey('odometer_meters')) {
      context.handle(
        _odometerMetersMeta,
        odometerMeters.isAcceptableOrUnknown(
          data['odometer_meters']!,
          _odometerMetersMeta,
        ),
      );
    }
    if (data.containsKey('odometer_read_at_ms')) {
      context.handle(
        _odometerReadAtMsMeta,
        odometerReadAtMs.isAcceptableOrUnknown(
          data['odometer_read_at_ms']!,
          _odometerReadAtMsMeta,
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
      advertisedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advertised_name'],
      )!,
      protocol: $BikesTable.$converterprotocol.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}protocol'],
        )!,
      ),
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
      moduleSerial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_serial'],
      ),
      odometerMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer_meters'],
      ),
      odometerReadAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer_read_at_ms'],
      ),
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BikeProtocolVersion, String, String>
  $converterprotocol = const EnumNameConverter<BikeProtocolVersion>(
    BikeProtocolVersion.values,
  );
}

class BikeRow extends DataClass implements Insertable<BikeRow> {
  final String deviceId;
  final String displayName;
  final String advertisedName;
  final BikeProtocolVersion protocol;
  final String? region;
  final String colorKey;
  final int sortOrder;
  final int createdAtMs;
  final int updatedAtMs;
  final int? lastConnectedAtMs;
  final String? moduleSerial;
  final int? odometerMeters;
  final int? odometerReadAtMs;
  const BikeRow({
    required this.deviceId,
    required this.displayName,
    required this.advertisedName,
    required this.protocol,
    this.region,
    required this.colorKey,
    required this.sortOrder,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.lastConnectedAtMs,
    this.moduleSerial,
    this.odometerMeters,
    this.odometerReadAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['advertised_name'] = Variable<String>(advertisedName);
    {
      map['protocol'] = Variable<String>(
        $BikesTable.$converterprotocol.toSql(protocol),
      );
    }
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
    if (!nullToAbsent || moduleSerial != null) {
      map['module_serial'] = Variable<String>(moduleSerial);
    }
    if (!nullToAbsent || odometerMeters != null) {
      map['odometer_meters'] = Variable<int>(odometerMeters);
    }
    if (!nullToAbsent || odometerReadAtMs != null) {
      map['odometer_read_at_ms'] = Variable<int>(odometerReadAtMs);
    }
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      advertisedName: Value(advertisedName),
      protocol: Value(protocol),
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
      moduleSerial: moduleSerial == null && nullToAbsent
          ? const Value.absent()
          : Value(moduleSerial),
      odometerMeters: odometerMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(odometerMeters),
      odometerReadAtMs: odometerReadAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(odometerReadAtMs),
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
      advertisedName: serializer.fromJson<String>(json['advertisedName']),
      protocol: $BikesTable.$converterprotocol.fromJson(
        serializer.fromJson<String>(json['protocol']),
      ),
      region: serializer.fromJson<String?>(json['region']),
      colorKey: serializer.fromJson<String>(json['colorKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      lastConnectedAtMs: serializer.fromJson<int?>(json['lastConnectedAtMs']),
      moduleSerial: serializer.fromJson<String?>(json['moduleSerial']),
      odometerMeters: serializer.fromJson<int?>(json['odometerMeters']),
      odometerReadAtMs: serializer.fromJson<int?>(json['odometerReadAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'advertisedName': serializer.toJson<String>(advertisedName),
      'protocol': serializer.toJson<String>(
        $BikesTable.$converterprotocol.toJson(protocol),
      ),
      'region': serializer.toJson<String?>(region),
      'colorKey': serializer.toJson<String>(colorKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'lastConnectedAtMs': serializer.toJson<int?>(lastConnectedAtMs),
      'moduleSerial': serializer.toJson<String?>(moduleSerial),
      'odometerMeters': serializer.toJson<int?>(odometerMeters),
      'odometerReadAtMs': serializer.toJson<int?>(odometerReadAtMs),
    };
  }

  BikeRow copyWith({
    String? deviceId,
    String? displayName,
    String? advertisedName,
    BikeProtocolVersion? protocol,
    Value<String?> region = const Value.absent(),
    String? colorKey,
    int? sortOrder,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> lastConnectedAtMs = const Value.absent(),
    Value<String?> moduleSerial = const Value.absent(),
    Value<int?> odometerMeters = const Value.absent(),
    Value<int?> odometerReadAtMs = const Value.absent(),
  }) => BikeRow(
    deviceId: deviceId ?? this.deviceId,
    displayName: displayName ?? this.displayName,
    advertisedName: advertisedName ?? this.advertisedName,
    protocol: protocol ?? this.protocol,
    region: region.present ? region.value : this.region,
    colorKey: colorKey ?? this.colorKey,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    lastConnectedAtMs: lastConnectedAtMs.present
        ? lastConnectedAtMs.value
        : this.lastConnectedAtMs,
    moduleSerial: moduleSerial.present ? moduleSerial.value : this.moduleSerial,
    odometerMeters: odometerMeters.present
        ? odometerMeters.value
        : this.odometerMeters,
    odometerReadAtMs: odometerReadAtMs.present
        ? odometerReadAtMs.value
        : this.odometerReadAtMs,
  );
  BikeRow copyWithCompanion(BikesCompanion data) {
    return BikeRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      advertisedName: data.advertisedName.present
          ? data.advertisedName.value
          : this.advertisedName,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
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
      moduleSerial: data.moduleSerial.present
          ? data.moduleSerial.value
          : this.moduleSerial,
      odometerMeters: data.odometerMeters.present
          ? data.odometerMeters.value
          : this.odometerMeters,
      odometerReadAtMs: data.odometerReadAtMs.present
          ? data.odometerReadAtMs.value
          : this.odometerReadAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeRow(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('advertisedName: $advertisedName, ')
          ..write('protocol: $protocol, ')
          ..write('region: $region, ')
          ..write('colorKey: $colorKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastConnectedAtMs: $lastConnectedAtMs, ')
          ..write('moduleSerial: $moduleSerial, ')
          ..write('odometerMeters: $odometerMeters, ')
          ..write('odometerReadAtMs: $odometerReadAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    displayName,
    advertisedName,
    protocol,
    region,
    colorKey,
    sortOrder,
    createdAtMs,
    updatedAtMs,
    lastConnectedAtMs,
    moduleSerial,
    odometerMeters,
    odometerReadAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeRow &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.advertisedName == this.advertisedName &&
          other.protocol == this.protocol &&
          other.region == this.region &&
          other.colorKey == this.colorKey &&
          other.sortOrder == this.sortOrder &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.lastConnectedAtMs == this.lastConnectedAtMs &&
          other.moduleSerial == this.moduleSerial &&
          other.odometerMeters == this.odometerMeters &&
          other.odometerReadAtMs == this.odometerReadAtMs);
}

class BikesCompanion extends UpdateCompanion<BikeRow> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String> advertisedName;
  final Value<BikeProtocolVersion> protocol;
  final Value<String?> region;
  final Value<String> colorKey;
  final Value<int> sortOrder;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> lastConnectedAtMs;
  final Value<String?> moduleSerial;
  final Value<int?> odometerMeters;
  final Value<int?> odometerReadAtMs;
  final Value<int> rowid;
  const BikesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.advertisedName = const Value.absent(),
    this.protocol = const Value.absent(),
    this.region = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.lastConnectedAtMs = const Value.absent(),
    this.moduleSerial = const Value.absent(),
    this.odometerMeters = const Value.absent(),
    this.odometerReadAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikesCompanion.insert({
    required String deviceId,
    required String displayName,
    required String advertisedName,
    required BikeProtocolVersion protocol,
    this.region = const Value.absent(),
    required String colorKey,
    required int sortOrder,
    required int createdAtMs,
    required int updatedAtMs,
    this.lastConnectedAtMs = const Value.absent(),
    this.moduleSerial = const Value.absent(),
    this.odometerMeters = const Value.absent(),
    this.odometerReadAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       displayName = Value(displayName),
       advertisedName = Value(advertisedName),
       protocol = Value(protocol),
       colorKey = Value(colorKey),
       sortOrder = Value(sortOrder),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<BikeRow> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? advertisedName,
    Expression<String>? protocol,
    Expression<String>? region,
    Expression<String>? colorKey,
    Expression<int>? sortOrder,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? lastConnectedAtMs,
    Expression<String>? moduleSerial,
    Expression<int>? odometerMeters,
    Expression<int>? odometerReadAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (advertisedName != null) 'advertised_name': advertisedName,
      if (protocol != null) 'protocol': protocol,
      if (region != null) 'region': region,
      if (colorKey != null) 'color_key': colorKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (lastConnectedAtMs != null) 'last_connected_at_ms': lastConnectedAtMs,
      if (moduleSerial != null) 'module_serial': moduleSerial,
      if (odometerMeters != null) 'odometer_meters': odometerMeters,
      if (odometerReadAtMs != null) 'odometer_read_at_ms': odometerReadAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? displayName,
    Value<String>? advertisedName,
    Value<BikeProtocolVersion>? protocol,
    Value<String?>? region,
    Value<String>? colorKey,
    Value<int>? sortOrder,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? lastConnectedAtMs,
    Value<String?>? moduleSerial,
    Value<int?>? odometerMeters,
    Value<int?>? odometerReadAtMs,
    Value<int>? rowid,
  }) {
    return BikesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      advertisedName: advertisedName ?? this.advertisedName,
      protocol: protocol ?? this.protocol,
      region: region ?? this.region,
      colorKey: colorKey ?? this.colorKey,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      moduleSerial: moduleSerial ?? this.moduleSerial,
      odometerMeters: odometerMeters ?? this.odometerMeters,
      odometerReadAtMs: odometerReadAtMs ?? this.odometerReadAtMs,
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
    if (advertisedName.present) {
      map['advertised_name'] = Variable<String>(advertisedName.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(
        $BikesTable.$converterprotocol.toSql(protocol.value),
      );
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
    if (moduleSerial.present) {
      map['module_serial'] = Variable<String>(moduleSerial.value);
    }
    if (odometerMeters.present) {
      map['odometer_meters'] = Variable<int>(odometerMeters.value);
    }
    if (odometerReadAtMs.present) {
      map['odometer_read_at_ms'] = Variable<int>(odometerReadAtMs.value);
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
          ..write('advertisedName: $advertisedName, ')
          ..write('protocol: $protocol, ')
          ..write('region: $region, ')
          ..write('colorKey: $colorKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastConnectedAtMs: $lastConnectedAtMs, ')
          ..write('moduleSerial: $moduleSerial, ')
          ..write('odometerMeters: $odometerMeters, ')
          ..write('odometerReadAtMs: $odometerReadAtMs, ')
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

class $BikeVersionsTable extends BikeVersions
    with TableInfo<$BikeVersionsTable, BikeVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikeVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _hardwareRevisionMeta = const VerificationMeta(
    'hardwareRevision',
  );
  @override
  late final GeneratedColumn<String> hardwareRevision = GeneratedColumn<String>(
    'hardware_revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firmwareRevisionMeta = const VerificationMeta(
    'firmwareRevision',
  );
  @override
  late final GeneratedColumn<String> firmwareRevision = GeneratedColumn<String>(
    'firmware_revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _softwareRevisionMeta = const VerificationMeta(
    'softwareRevision',
  );
  @override
  late final GeneratedColumn<String> softwareRevision = GeneratedColumn<String>(
    'software_revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stmFirmwareVersionMeta =
      const VerificationMeta('stmFirmwareVersion');
  @override
  late final GeneratedColumn<int> stmFirmwareVersion = GeneratedColumn<int>(
    'stm_firmware_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _controllerVariantMeta = const VerificationMeta(
    'controllerVariant',
  );
  @override
  late final GeneratedColumn<int> controllerVariant = GeneratedColumn<int>(
    'controller_variant',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bootloaderHandoffMeta = const VerificationMeta(
    'bootloaderHandoff',
  );
  @override
  late final GeneratedColumn<int> bootloaderHandoff = GeneratedColumn<int>(
    'bootloader_handoff',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motorControllerVersionMeta =
      const VerificationMeta('motorControllerVersion');
  @override
  late final GeneratedColumn<int> motorControllerVersion = GeneratedColumn<int>(
    'motor_controller_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bmsVersionMeta = const VerificationMeta(
    'bmsVersion',
  );
  @override
  late final GeneratedColumn<int> bmsVersion = GeneratedColumn<int>(
    'bms_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMsMeta = const VerificationMeta(
    'readAtMs',
  );
  @override
  late final GeneratedColumn<int> readAtMs = GeneratedColumn<int>(
    'read_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    hardwareRevision,
    firmwareRevision,
    softwareRevision,
    stmFirmwareVersion,
    controllerVariant,
    bootloaderHandoff,
    motorControllerVersion,
    bmsVersion,
    readAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bike_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikeVersionRow> instance, {
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
    if (data.containsKey('hardware_revision')) {
      context.handle(
        _hardwareRevisionMeta,
        hardwareRevision.isAcceptableOrUnknown(
          data['hardware_revision']!,
          _hardwareRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hardwareRevisionMeta);
    }
    if (data.containsKey('firmware_revision')) {
      context.handle(
        _firmwareRevisionMeta,
        firmwareRevision.isAcceptableOrUnknown(
          data['firmware_revision']!,
          _firmwareRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firmwareRevisionMeta);
    }
    if (data.containsKey('software_revision')) {
      context.handle(
        _softwareRevisionMeta,
        softwareRevision.isAcceptableOrUnknown(
          data['software_revision']!,
          _softwareRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_softwareRevisionMeta);
    }
    if (data.containsKey('stm_firmware_version')) {
      context.handle(
        _stmFirmwareVersionMeta,
        stmFirmwareVersion.isAcceptableOrUnknown(
          data['stm_firmware_version']!,
          _stmFirmwareVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stmFirmwareVersionMeta);
    }
    if (data.containsKey('controller_variant')) {
      context.handle(
        _controllerVariantMeta,
        controllerVariant.isAcceptableOrUnknown(
          data['controller_variant']!,
          _controllerVariantMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_controllerVariantMeta);
    }
    if (data.containsKey('bootloader_handoff')) {
      context.handle(
        _bootloaderHandoffMeta,
        bootloaderHandoff.isAcceptableOrUnknown(
          data['bootloader_handoff']!,
          _bootloaderHandoffMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bootloaderHandoffMeta);
    }
    if (data.containsKey('motor_controller_version')) {
      context.handle(
        _motorControllerVersionMeta,
        motorControllerVersion.isAcceptableOrUnknown(
          data['motor_controller_version']!,
          _motorControllerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_motorControllerVersionMeta);
    }
    if (data.containsKey('bms_version')) {
      context.handle(
        _bmsVersionMeta,
        bmsVersion.isAcceptableOrUnknown(data['bms_version']!, _bmsVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_bmsVersionMeta);
    }
    if (data.containsKey('read_at_ms')) {
      context.handle(
        _readAtMsMeta,
        readAtMs.isAcceptableOrUnknown(data['read_at_ms']!, _readAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  BikeVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeVersionRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      hardwareRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hardware_revision'],
      )!,
      firmwareRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_revision'],
      )!,
      softwareRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}software_revision'],
      )!,
      stmFirmwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stm_firmware_version'],
      )!,
      controllerVariant: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}controller_variant'],
      )!,
      bootloaderHandoff: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bootloader_handoff'],
      )!,
      motorControllerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}motor_controller_version'],
      )!,
      bmsVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bms_version'],
      )!,
      readAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at_ms'],
      )!,
    );
  }

  @override
  $BikeVersionsTable createAlias(String alias) {
    return $BikeVersionsTable(attachedDatabase, alias);
  }
}

class BikeVersionRow extends DataClass implements Insertable<BikeVersionRow> {
  final String deviceId;
  final String hardwareRevision;
  final String firmwareRevision;
  final String softwareRevision;
  final int stmFirmwareVersion;
  final int controllerVariant;
  final int bootloaderHandoff;
  final int motorControllerVersion;
  final int bmsVersion;
  final int readAtMs;
  const BikeVersionRow({
    required this.deviceId,
    required this.hardwareRevision,
    required this.firmwareRevision,
    required this.softwareRevision,
    required this.stmFirmwareVersion,
    required this.controllerVariant,
    required this.bootloaderHandoff,
    required this.motorControllerVersion,
    required this.bmsVersion,
    required this.readAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['hardware_revision'] = Variable<String>(hardwareRevision);
    map['firmware_revision'] = Variable<String>(firmwareRevision);
    map['software_revision'] = Variable<String>(softwareRevision);
    map['stm_firmware_version'] = Variable<int>(stmFirmwareVersion);
    map['controller_variant'] = Variable<int>(controllerVariant);
    map['bootloader_handoff'] = Variable<int>(bootloaderHandoff);
    map['motor_controller_version'] = Variable<int>(motorControllerVersion);
    map['bms_version'] = Variable<int>(bmsVersion);
    map['read_at_ms'] = Variable<int>(readAtMs);
    return map;
  }

  BikeVersionsCompanion toCompanion(bool nullToAbsent) {
    return BikeVersionsCompanion(
      deviceId: Value(deviceId),
      hardwareRevision: Value(hardwareRevision),
      firmwareRevision: Value(firmwareRevision),
      softwareRevision: Value(softwareRevision),
      stmFirmwareVersion: Value(stmFirmwareVersion),
      controllerVariant: Value(controllerVariant),
      bootloaderHandoff: Value(bootloaderHandoff),
      motorControllerVersion: Value(motorControllerVersion),
      bmsVersion: Value(bmsVersion),
      readAtMs: Value(readAtMs),
    );
  }

  factory BikeVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeVersionRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      hardwareRevision: serializer.fromJson<String>(json['hardwareRevision']),
      firmwareRevision: serializer.fromJson<String>(json['firmwareRevision']),
      softwareRevision: serializer.fromJson<String>(json['softwareRevision']),
      stmFirmwareVersion: serializer.fromJson<int>(json['stmFirmwareVersion']),
      controllerVariant: serializer.fromJson<int>(json['controllerVariant']),
      bootloaderHandoff: serializer.fromJson<int>(json['bootloaderHandoff']),
      motorControllerVersion: serializer.fromJson<int>(
        json['motorControllerVersion'],
      ),
      bmsVersion: serializer.fromJson<int>(json['bmsVersion']),
      readAtMs: serializer.fromJson<int>(json['readAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'hardwareRevision': serializer.toJson<String>(hardwareRevision),
      'firmwareRevision': serializer.toJson<String>(firmwareRevision),
      'softwareRevision': serializer.toJson<String>(softwareRevision),
      'stmFirmwareVersion': serializer.toJson<int>(stmFirmwareVersion),
      'controllerVariant': serializer.toJson<int>(controllerVariant),
      'bootloaderHandoff': serializer.toJson<int>(bootloaderHandoff),
      'motorControllerVersion': serializer.toJson<int>(motorControllerVersion),
      'bmsVersion': serializer.toJson<int>(bmsVersion),
      'readAtMs': serializer.toJson<int>(readAtMs),
    };
  }

  BikeVersionRow copyWith({
    String? deviceId,
    String? hardwareRevision,
    String? firmwareRevision,
    String? softwareRevision,
    int? stmFirmwareVersion,
    int? controllerVariant,
    int? bootloaderHandoff,
    int? motorControllerVersion,
    int? bmsVersion,
    int? readAtMs,
  }) => BikeVersionRow(
    deviceId: deviceId ?? this.deviceId,
    hardwareRevision: hardwareRevision ?? this.hardwareRevision,
    firmwareRevision: firmwareRevision ?? this.firmwareRevision,
    softwareRevision: softwareRevision ?? this.softwareRevision,
    stmFirmwareVersion: stmFirmwareVersion ?? this.stmFirmwareVersion,
    controllerVariant: controllerVariant ?? this.controllerVariant,
    bootloaderHandoff: bootloaderHandoff ?? this.bootloaderHandoff,
    motorControllerVersion:
        motorControllerVersion ?? this.motorControllerVersion,
    bmsVersion: bmsVersion ?? this.bmsVersion,
    readAtMs: readAtMs ?? this.readAtMs,
  );
  BikeVersionRow copyWithCompanion(BikeVersionsCompanion data) {
    return BikeVersionRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      hardwareRevision: data.hardwareRevision.present
          ? data.hardwareRevision.value
          : this.hardwareRevision,
      firmwareRevision: data.firmwareRevision.present
          ? data.firmwareRevision.value
          : this.firmwareRevision,
      softwareRevision: data.softwareRevision.present
          ? data.softwareRevision.value
          : this.softwareRevision,
      stmFirmwareVersion: data.stmFirmwareVersion.present
          ? data.stmFirmwareVersion.value
          : this.stmFirmwareVersion,
      controllerVariant: data.controllerVariant.present
          ? data.controllerVariant.value
          : this.controllerVariant,
      bootloaderHandoff: data.bootloaderHandoff.present
          ? data.bootloaderHandoff.value
          : this.bootloaderHandoff,
      motorControllerVersion: data.motorControllerVersion.present
          ? data.motorControllerVersion.value
          : this.motorControllerVersion,
      bmsVersion: data.bmsVersion.present
          ? data.bmsVersion.value
          : this.bmsVersion,
      readAtMs: data.readAtMs.present ? data.readAtMs.value : this.readAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeVersionRow(')
          ..write('deviceId: $deviceId, ')
          ..write('hardwareRevision: $hardwareRevision, ')
          ..write('firmwareRevision: $firmwareRevision, ')
          ..write('softwareRevision: $softwareRevision, ')
          ..write('stmFirmwareVersion: $stmFirmwareVersion, ')
          ..write('controllerVariant: $controllerVariant, ')
          ..write('bootloaderHandoff: $bootloaderHandoff, ')
          ..write('motorControllerVersion: $motorControllerVersion, ')
          ..write('bmsVersion: $bmsVersion, ')
          ..write('readAtMs: $readAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    hardwareRevision,
    firmwareRevision,
    softwareRevision,
    stmFirmwareVersion,
    controllerVariant,
    bootloaderHandoff,
    motorControllerVersion,
    bmsVersion,
    readAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeVersionRow &&
          other.deviceId == this.deviceId &&
          other.hardwareRevision == this.hardwareRevision &&
          other.firmwareRevision == this.firmwareRevision &&
          other.softwareRevision == this.softwareRevision &&
          other.stmFirmwareVersion == this.stmFirmwareVersion &&
          other.controllerVariant == this.controllerVariant &&
          other.bootloaderHandoff == this.bootloaderHandoff &&
          other.motorControllerVersion == this.motorControllerVersion &&
          other.bmsVersion == this.bmsVersion &&
          other.readAtMs == this.readAtMs);
}

class BikeVersionsCompanion extends UpdateCompanion<BikeVersionRow> {
  final Value<String> deviceId;
  final Value<String> hardwareRevision;
  final Value<String> firmwareRevision;
  final Value<String> softwareRevision;
  final Value<int> stmFirmwareVersion;
  final Value<int> controllerVariant;
  final Value<int> bootloaderHandoff;
  final Value<int> motorControllerVersion;
  final Value<int> bmsVersion;
  final Value<int> readAtMs;
  final Value<int> rowid;
  const BikeVersionsCompanion({
    this.deviceId = const Value.absent(),
    this.hardwareRevision = const Value.absent(),
    this.firmwareRevision = const Value.absent(),
    this.softwareRevision = const Value.absent(),
    this.stmFirmwareVersion = const Value.absent(),
    this.controllerVariant = const Value.absent(),
    this.bootloaderHandoff = const Value.absent(),
    this.motorControllerVersion = const Value.absent(),
    this.bmsVersion = const Value.absent(),
    this.readAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikeVersionsCompanion.insert({
    required String deviceId,
    required String hardwareRevision,
    required String firmwareRevision,
    required String softwareRevision,
    required int stmFirmwareVersion,
    required int controllerVariant,
    required int bootloaderHandoff,
    required int motorControllerVersion,
    required int bmsVersion,
    required int readAtMs,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       hardwareRevision = Value(hardwareRevision),
       firmwareRevision = Value(firmwareRevision),
       softwareRevision = Value(softwareRevision),
       stmFirmwareVersion = Value(stmFirmwareVersion),
       controllerVariant = Value(controllerVariant),
       bootloaderHandoff = Value(bootloaderHandoff),
       motorControllerVersion = Value(motorControllerVersion),
       bmsVersion = Value(bmsVersion),
       readAtMs = Value(readAtMs);
  static Insertable<BikeVersionRow> custom({
    Expression<String>? deviceId,
    Expression<String>? hardwareRevision,
    Expression<String>? firmwareRevision,
    Expression<String>? softwareRevision,
    Expression<int>? stmFirmwareVersion,
    Expression<int>? controllerVariant,
    Expression<int>? bootloaderHandoff,
    Expression<int>? motorControllerVersion,
    Expression<int>? bmsVersion,
    Expression<int>? readAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (hardwareRevision != null) 'hardware_revision': hardwareRevision,
      if (firmwareRevision != null) 'firmware_revision': firmwareRevision,
      if (softwareRevision != null) 'software_revision': softwareRevision,
      if (stmFirmwareVersion != null)
        'stm_firmware_version': stmFirmwareVersion,
      if (controllerVariant != null) 'controller_variant': controllerVariant,
      if (bootloaderHandoff != null) 'bootloader_handoff': bootloaderHandoff,
      if (motorControllerVersion != null)
        'motor_controller_version': motorControllerVersion,
      if (bmsVersion != null) 'bms_version': bmsVersion,
      if (readAtMs != null) 'read_at_ms': readAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikeVersionsCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? hardwareRevision,
    Value<String>? firmwareRevision,
    Value<String>? softwareRevision,
    Value<int>? stmFirmwareVersion,
    Value<int>? controllerVariant,
    Value<int>? bootloaderHandoff,
    Value<int>? motorControllerVersion,
    Value<int>? bmsVersion,
    Value<int>? readAtMs,
    Value<int>? rowid,
  }) {
    return BikeVersionsCompanion(
      deviceId: deviceId ?? this.deviceId,
      hardwareRevision: hardwareRevision ?? this.hardwareRevision,
      firmwareRevision: firmwareRevision ?? this.firmwareRevision,
      softwareRevision: softwareRevision ?? this.softwareRevision,
      stmFirmwareVersion: stmFirmwareVersion ?? this.stmFirmwareVersion,
      controllerVariant: controllerVariant ?? this.controllerVariant,
      bootloaderHandoff: bootloaderHandoff ?? this.bootloaderHandoff,
      motorControllerVersion:
          motorControllerVersion ?? this.motorControllerVersion,
      bmsVersion: bmsVersion ?? this.bmsVersion,
      readAtMs: readAtMs ?? this.readAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (hardwareRevision.present) {
      map['hardware_revision'] = Variable<String>(hardwareRevision.value);
    }
    if (firmwareRevision.present) {
      map['firmware_revision'] = Variable<String>(firmwareRevision.value);
    }
    if (softwareRevision.present) {
      map['software_revision'] = Variable<String>(softwareRevision.value);
    }
    if (stmFirmwareVersion.present) {
      map['stm_firmware_version'] = Variable<int>(stmFirmwareVersion.value);
    }
    if (controllerVariant.present) {
      map['controller_variant'] = Variable<int>(controllerVariant.value);
    }
    if (bootloaderHandoff.present) {
      map['bootloader_handoff'] = Variable<int>(bootloaderHandoff.value);
    }
    if (motorControllerVersion.present) {
      map['motor_controller_version'] = Variable<int>(
        motorControllerVersion.value,
      );
    }
    if (bmsVersion.present) {
      map['bms_version'] = Variable<int>(bmsVersion.value);
    }
    if (readAtMs.present) {
      map['read_at_ms'] = Variable<int>(readAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikeVersionsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('hardwareRevision: $hardwareRevision, ')
          ..write('firmwareRevision: $firmwareRevision, ')
          ..write('softwareRevision: $softwareRevision, ')
          ..write('stmFirmwareVersion: $stmFirmwareVersion, ')
          ..write('controllerVariant: $controllerVariant, ')
          ..write('bootloaderHandoff: $bootloaderHandoff, ')
          ..write('motorControllerVersion: $motorControllerVersion, ')
          ..write('bmsVersion: $bmsVersion, ')
          ..write('readAtMs: $readAtMs, ')
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
  late final $BikeVersionsTable bikeVersions = $BikeVersionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DataImportsTable dataImports = $DataImportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bikes,
    bikePreferences,
    bikeVersions,
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
      result: [TableUpdate('bike_versions', kind: UpdateKind.delete)],
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
