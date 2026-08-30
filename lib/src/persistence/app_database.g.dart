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
  @override
  late final GeneratedColumnWithTypeConverter<BikeControlPatch, String>
  setOnConnect =
      GeneratedColumn<String>(
        'set_on_connect',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BikeControlPatch>(
        $BikePreferencesTable.$convertersetOnConnect,
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
    setOnConnect,
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
      setOnConnect: $BikePreferencesTable.$convertersetOnConnect.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_on_connect'],
        )!,
      ),
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

  static TypeConverter<BikeControlPatch, String> $convertersetOnConnect =
      const BikeControlPatchConverter();
}

class BikePreferenceRow extends DataClass
    implements Insertable<BikePreferenceRow> {
  final String deviceId;
  final BikeControlPatch setOnConnect;
  final bool backgroundRequested;
  final int backgroundConsentVersion;
  const BikePreferenceRow({
    required this.deviceId,
    required this.setOnConnect,
    required this.backgroundRequested,
    required this.backgroundConsentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    {
      map['set_on_connect'] = Variable<String>(
        $BikePreferencesTable.$convertersetOnConnect.toSql(setOnConnect),
      );
    }
    map['background_requested'] = Variable<bool>(backgroundRequested);
    map['background_consent_version'] = Variable<int>(backgroundConsentVersion);
    return map;
  }

  BikePreferencesCompanion toCompanion(bool nullToAbsent) {
    return BikePreferencesCompanion(
      deviceId: Value(deviceId),
      setOnConnect: Value(setOnConnect),
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
      setOnConnect: serializer.fromJson<BikeControlPatch>(json['setOnConnect']),
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
      'setOnConnect': serializer.toJson<BikeControlPatch>(setOnConnect),
      'backgroundRequested': serializer.toJson<bool>(backgroundRequested),
      'backgroundConsentVersion': serializer.toJson<int>(
        backgroundConsentVersion,
      ),
    };
  }

  BikePreferenceRow copyWith({
    String? deviceId,
    BikeControlPatch? setOnConnect,
    bool? backgroundRequested,
    int? backgroundConsentVersion,
  }) => BikePreferenceRow(
    deviceId: deviceId ?? this.deviceId,
    setOnConnect: setOnConnect ?? this.setOnConnect,
    backgroundRequested: backgroundRequested ?? this.backgroundRequested,
    backgroundConsentVersion:
        backgroundConsentVersion ?? this.backgroundConsentVersion,
  );
  BikePreferenceRow copyWithCompanion(BikePreferencesCompanion data) {
    return BikePreferenceRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      setOnConnect: data.setOnConnect.present
          ? data.setOnConnect.value
          : this.setOnConnect,
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
          ..write('setOnConnect: $setOnConnect, ')
          ..write('backgroundRequested: $backgroundRequested, ')
          ..write('backgroundConsentVersion: $backgroundConsentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    setOnConnect,
    backgroundRequested,
    backgroundConsentVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikePreferenceRow &&
          other.deviceId == this.deviceId &&
          other.setOnConnect == this.setOnConnect &&
          other.backgroundRequested == this.backgroundRequested &&
          other.backgroundConsentVersion == this.backgroundConsentVersion);
}

class BikePreferencesCompanion extends UpdateCompanion<BikePreferenceRow> {
  final Value<String> deviceId;
  final Value<BikeControlPatch> setOnConnect;
  final Value<bool> backgroundRequested;
  final Value<int> backgroundConsentVersion;
  final Value<int> rowid;
  const BikePreferencesCompanion({
    this.deviceId = const Value.absent(),
    this.setOnConnect = const Value.absent(),
    this.backgroundRequested = const Value.absent(),
    this.backgroundConsentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikePreferencesCompanion.insert({
    required String deviceId,
    required BikeControlPatch setOnConnect,
    required bool backgroundRequested,
    required int backgroundConsentVersion,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       setOnConnect = Value(setOnConnect),
       backgroundRequested = Value(backgroundRequested),
       backgroundConsentVersion = Value(backgroundConsentVersion);
  static Insertable<BikePreferenceRow> custom({
    Expression<String>? deviceId,
    Expression<String>? setOnConnect,
    Expression<bool>? backgroundRequested,
    Expression<int>? backgroundConsentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (setOnConnect != null) 'set_on_connect': setOnConnect,
      if (backgroundRequested != null)
        'background_requested': backgroundRequested,
      if (backgroundConsentVersion != null)
        'background_consent_version': backgroundConsentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikePreferencesCompanion copyWith({
    Value<String>? deviceId,
    Value<BikeControlPatch>? setOnConnect,
    Value<bool>? backgroundRequested,
    Value<int>? backgroundConsentVersion,
    Value<int>? rowid,
  }) {
    return BikePreferencesCompanion(
      deviceId: deviceId ?? this.deviceId,
      setOnConnect: setOnConnect ?? this.setOnConnect,
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
    if (setOnConnect.present) {
      map['set_on_connect'] = Variable<String>(
        $BikePreferencesTable.$convertersetOnConnect.toSql(setOnConnect.value),
      );
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
          ..write('setOnConnect: $setOnConnect, ')
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

class $BackgroundSyncPlansTable extends BackgroundSyncPlans
    with TableInfo<$BackgroundSyncPlansTable, BackgroundSyncPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackgroundSyncPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planVersionMeta = const VerificationMeta(
    'planVersion',
  );
  @override
  late final GeneratedColumn<int> planVersion = GeneratedColumn<int>(
    'plan_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _scanManufacturerIdMeta =
      const VerificationMeta('scanManufacturerId');
  @override
  late final GeneratedColumn<int> scanManufacturerId = GeneratedColumn<int>(
    'scan_manufacturer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanManufacturerDataMeta =
      const VerificationMeta('scanManufacturerData');
  @override
  late final GeneratedColumn<Uint8List> scanManufacturerData =
      GeneratedColumn<Uint8List>(
        'scan_manufacturer_data',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _scanManufacturerMaskMeta =
      const VerificationMeta('scanManufacturerMask');
  @override
  late final GeneratedColumn<Uint8List> scanManufacturerMask =
      GeneratedColumn<Uint8List>(
        'scan_manufacturer_mask',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationServiceUuidMeta =
      const VerificationMeta('authenticationServiceUuid');
  @override
  late final GeneratedColumn<String> authenticationServiceUuid =
      GeneratedColumn<String>(
        'authentication_service_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationChallengeUuidMeta =
      const VerificationMeta('authenticationChallengeUuid');
  @override
  late final GeneratedColumn<String> authenticationChallengeUuid =
      GeneratedColumn<String>(
        'authentication_challenge_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationResponseUuidMeta =
      const VerificationMeta('authenticationResponseUuid');
  @override
  late final GeneratedColumn<String> authenticationResponseUuid =
      GeneratedColumn<String>(
        'authentication_response_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationStateUuidMeta =
      const VerificationMeta('authenticationStateUuid');
  @override
  late final GeneratedColumn<String> authenticationStateUuid =
      GeneratedColumn<String>(
        'authentication_state_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationChallengeLengthMeta =
      const VerificationMeta('authenticationChallengeLength');
  @override
  late final GeneratedColumn<int> authenticationChallengeLength =
      GeneratedColumn<int>(
        'authentication_challenge_length',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationDigestMeta =
      const VerificationMeta('authenticationDigest');
  @override
  late final GeneratedColumn<String> authenticationDigest =
      GeneratedColumn<String>(
        'authentication_digest',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticationKeyMeta = const VerificationMeta(
    'authenticationKey',
  );
  @override
  late final GeneratedColumn<Uint8List> authenticationKey =
      GeneratedColumn<Uint8List>(
        'authentication_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authenticatedStateMeta =
      const VerificationMeta('authenticatedState');
  @override
  late final GeneratedColumn<Uint8List> authenticatedState =
      GeneratedColumn<Uint8List>(
        'authenticated_state',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _commandServiceUuidMeta =
      const VerificationMeta('commandServiceUuid');
  @override
  late final GeneratedColumn<String> commandServiceUuid =
      GeneratedColumn<String>(
        'command_service_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _commandCharacteristicUuidMeta =
      const VerificationMeta('commandCharacteristicUuid');
  @override
  late final GeneratedColumn<String> commandCharacteristicUuid =
      GeneratedColumn<String>(
        'command_characteristic_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    planVersion,
    deviceId,
    scanManufacturerId,
    scanManufacturerData,
    scanManufacturerMask,
    authenticationServiceUuid,
    authenticationChallengeUuid,
    authenticationResponseUuid,
    authenticationStateUuid,
    authenticationChallengeLength,
    authenticationDigest,
    authenticationKey,
    authenticatedState,
    commandServiceUuid,
    commandCharacteristicUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'background_sync_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackgroundSyncPlanRow> instance, {
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
    if (data.containsKey('plan_version')) {
      context.handle(
        _planVersionMeta,
        planVersion.isAcceptableOrUnknown(
          data['plan_version']!,
          _planVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planVersionMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('scan_manufacturer_id')) {
      context.handle(
        _scanManufacturerIdMeta,
        scanManufacturerId.isAcceptableOrUnknown(
          data['scan_manufacturer_id']!,
          _scanManufacturerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanManufacturerIdMeta);
    }
    if (data.containsKey('scan_manufacturer_data')) {
      context.handle(
        _scanManufacturerDataMeta,
        scanManufacturerData.isAcceptableOrUnknown(
          data['scan_manufacturer_data']!,
          _scanManufacturerDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanManufacturerDataMeta);
    }
    if (data.containsKey('scan_manufacturer_mask')) {
      context.handle(
        _scanManufacturerMaskMeta,
        scanManufacturerMask.isAcceptableOrUnknown(
          data['scan_manufacturer_mask']!,
          _scanManufacturerMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanManufacturerMaskMeta);
    }
    if (data.containsKey('authentication_service_uuid')) {
      context.handle(
        _authenticationServiceUuidMeta,
        authenticationServiceUuid.isAcceptableOrUnknown(
          data['authentication_service_uuid']!,
          _authenticationServiceUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationServiceUuidMeta);
    }
    if (data.containsKey('authentication_challenge_uuid')) {
      context.handle(
        _authenticationChallengeUuidMeta,
        authenticationChallengeUuid.isAcceptableOrUnknown(
          data['authentication_challenge_uuid']!,
          _authenticationChallengeUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationChallengeUuidMeta);
    }
    if (data.containsKey('authentication_response_uuid')) {
      context.handle(
        _authenticationResponseUuidMeta,
        authenticationResponseUuid.isAcceptableOrUnknown(
          data['authentication_response_uuid']!,
          _authenticationResponseUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationResponseUuidMeta);
    }
    if (data.containsKey('authentication_state_uuid')) {
      context.handle(
        _authenticationStateUuidMeta,
        authenticationStateUuid.isAcceptableOrUnknown(
          data['authentication_state_uuid']!,
          _authenticationStateUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationStateUuidMeta);
    }
    if (data.containsKey('authentication_challenge_length')) {
      context.handle(
        _authenticationChallengeLengthMeta,
        authenticationChallengeLength.isAcceptableOrUnknown(
          data['authentication_challenge_length']!,
          _authenticationChallengeLengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationChallengeLengthMeta);
    }
    if (data.containsKey('authentication_digest')) {
      context.handle(
        _authenticationDigestMeta,
        authenticationDigest.isAcceptableOrUnknown(
          data['authentication_digest']!,
          _authenticationDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationDigestMeta);
    }
    if (data.containsKey('authentication_key')) {
      context.handle(
        _authenticationKeyMeta,
        authenticationKey.isAcceptableOrUnknown(
          data['authentication_key']!,
          _authenticationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticationKeyMeta);
    }
    if (data.containsKey('authenticated_state')) {
      context.handle(
        _authenticatedStateMeta,
        authenticatedState.isAcceptableOrUnknown(
          data['authenticated_state']!,
          _authenticatedStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authenticatedStateMeta);
    }
    if (data.containsKey('command_service_uuid')) {
      context.handle(
        _commandServiceUuidMeta,
        commandServiceUuid.isAcceptableOrUnknown(
          data['command_service_uuid']!,
          _commandServiceUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commandServiceUuidMeta);
    }
    if (data.containsKey('command_characteristic_uuid')) {
      context.handle(
        _commandCharacteristicUuidMeta,
        commandCharacteristicUuid.isAcceptableOrUnknown(
          data['command_characteristic_uuid']!,
          _commandCharacteristicUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commandCharacteristicUuidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  BackgroundSyncPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackgroundSyncPlanRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      planVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      scanManufacturerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_manufacturer_id'],
      )!,
      scanManufacturerData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}scan_manufacturer_data'],
      )!,
      scanManufacturerMask: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}scan_manufacturer_mask'],
      )!,
      authenticationServiceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_service_uuid'],
      )!,
      authenticationChallengeUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_challenge_uuid'],
      )!,
      authenticationResponseUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_response_uuid'],
      )!,
      authenticationStateUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_state_uuid'],
      )!,
      authenticationChallengeLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}authentication_challenge_length'],
      )!,
      authenticationDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_digest'],
      )!,
      authenticationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}authentication_key'],
      )!,
      authenticatedState: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}authenticated_state'],
      )!,
      commandServiceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_service_uuid'],
      )!,
      commandCharacteristicUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_characteristic_uuid'],
      )!,
    );
  }

  @override
  $BackgroundSyncPlansTable createAlias(String alias) {
    return $BackgroundSyncPlansTable(attachedDatabase, alias);
  }
}

class BackgroundSyncPlanRow extends DataClass
    implements Insertable<BackgroundSyncPlanRow> {
  final int singletonId;
  final int planVersion;
  final String deviceId;
  final int scanManufacturerId;
  final Uint8List scanManufacturerData;
  final Uint8List scanManufacturerMask;
  final String authenticationServiceUuid;
  final String authenticationChallengeUuid;
  final String authenticationResponseUuid;
  final String authenticationStateUuid;
  final int authenticationChallengeLength;
  final String authenticationDigest;
  final Uint8List authenticationKey;
  final Uint8List authenticatedState;
  final String commandServiceUuid;
  final String commandCharacteristicUuid;
  const BackgroundSyncPlanRow({
    required this.singletonId,
    required this.planVersion,
    required this.deviceId,
    required this.scanManufacturerId,
    required this.scanManufacturerData,
    required this.scanManufacturerMask,
    required this.authenticationServiceUuid,
    required this.authenticationChallengeUuid,
    required this.authenticationResponseUuid,
    required this.authenticationStateUuid,
    required this.authenticationChallengeLength,
    required this.authenticationDigest,
    required this.authenticationKey,
    required this.authenticatedState,
    required this.commandServiceUuid,
    required this.commandCharacteristicUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['plan_version'] = Variable<int>(planVersion);
    map['device_id'] = Variable<String>(deviceId);
    map['scan_manufacturer_id'] = Variable<int>(scanManufacturerId);
    map['scan_manufacturer_data'] = Variable<Uint8List>(scanManufacturerData);
    map['scan_manufacturer_mask'] = Variable<Uint8List>(scanManufacturerMask);
    map['authentication_service_uuid'] = Variable<String>(
      authenticationServiceUuid,
    );
    map['authentication_challenge_uuid'] = Variable<String>(
      authenticationChallengeUuid,
    );
    map['authentication_response_uuid'] = Variable<String>(
      authenticationResponseUuid,
    );
    map['authentication_state_uuid'] = Variable<String>(
      authenticationStateUuid,
    );
    map['authentication_challenge_length'] = Variable<int>(
      authenticationChallengeLength,
    );
    map['authentication_digest'] = Variable<String>(authenticationDigest);
    map['authentication_key'] = Variable<Uint8List>(authenticationKey);
    map['authenticated_state'] = Variable<Uint8List>(authenticatedState);
    map['command_service_uuid'] = Variable<String>(commandServiceUuid);
    map['command_characteristic_uuid'] = Variable<String>(
      commandCharacteristicUuid,
    );
    return map;
  }

  BackgroundSyncPlansCompanion toCompanion(bool nullToAbsent) {
    return BackgroundSyncPlansCompanion(
      singletonId: Value(singletonId),
      planVersion: Value(planVersion),
      deviceId: Value(deviceId),
      scanManufacturerId: Value(scanManufacturerId),
      scanManufacturerData: Value(scanManufacturerData),
      scanManufacturerMask: Value(scanManufacturerMask),
      authenticationServiceUuid: Value(authenticationServiceUuid),
      authenticationChallengeUuid: Value(authenticationChallengeUuid),
      authenticationResponseUuid: Value(authenticationResponseUuid),
      authenticationStateUuid: Value(authenticationStateUuid),
      authenticationChallengeLength: Value(authenticationChallengeLength),
      authenticationDigest: Value(authenticationDigest),
      authenticationKey: Value(authenticationKey),
      authenticatedState: Value(authenticatedState),
      commandServiceUuid: Value(commandServiceUuid),
      commandCharacteristicUuid: Value(commandCharacteristicUuid),
    );
  }

  factory BackgroundSyncPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackgroundSyncPlanRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      planVersion: serializer.fromJson<int>(json['planVersion']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      scanManufacturerId: serializer.fromJson<int>(json['scanManufacturerId']),
      scanManufacturerData: serializer.fromJson<Uint8List>(
        json['scanManufacturerData'],
      ),
      scanManufacturerMask: serializer.fromJson<Uint8List>(
        json['scanManufacturerMask'],
      ),
      authenticationServiceUuid: serializer.fromJson<String>(
        json['authenticationServiceUuid'],
      ),
      authenticationChallengeUuid: serializer.fromJson<String>(
        json['authenticationChallengeUuid'],
      ),
      authenticationResponseUuid: serializer.fromJson<String>(
        json['authenticationResponseUuid'],
      ),
      authenticationStateUuid: serializer.fromJson<String>(
        json['authenticationStateUuid'],
      ),
      authenticationChallengeLength: serializer.fromJson<int>(
        json['authenticationChallengeLength'],
      ),
      authenticationDigest: serializer.fromJson<String>(
        json['authenticationDigest'],
      ),
      authenticationKey: serializer.fromJson<Uint8List>(
        json['authenticationKey'],
      ),
      authenticatedState: serializer.fromJson<Uint8List>(
        json['authenticatedState'],
      ),
      commandServiceUuid: serializer.fromJson<String>(
        json['commandServiceUuid'],
      ),
      commandCharacteristicUuid: serializer.fromJson<String>(
        json['commandCharacteristicUuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'planVersion': serializer.toJson<int>(planVersion),
      'deviceId': serializer.toJson<String>(deviceId),
      'scanManufacturerId': serializer.toJson<int>(scanManufacturerId),
      'scanManufacturerData': serializer.toJson<Uint8List>(
        scanManufacturerData,
      ),
      'scanManufacturerMask': serializer.toJson<Uint8List>(
        scanManufacturerMask,
      ),
      'authenticationServiceUuid': serializer.toJson<String>(
        authenticationServiceUuid,
      ),
      'authenticationChallengeUuid': serializer.toJson<String>(
        authenticationChallengeUuid,
      ),
      'authenticationResponseUuid': serializer.toJson<String>(
        authenticationResponseUuid,
      ),
      'authenticationStateUuid': serializer.toJson<String>(
        authenticationStateUuid,
      ),
      'authenticationChallengeLength': serializer.toJson<int>(
        authenticationChallengeLength,
      ),
      'authenticationDigest': serializer.toJson<String>(authenticationDigest),
      'authenticationKey': serializer.toJson<Uint8List>(authenticationKey),
      'authenticatedState': serializer.toJson<Uint8List>(authenticatedState),
      'commandServiceUuid': serializer.toJson<String>(commandServiceUuid),
      'commandCharacteristicUuid': serializer.toJson<String>(
        commandCharacteristicUuid,
      ),
    };
  }

  BackgroundSyncPlanRow copyWith({
    int? singletonId,
    int? planVersion,
    String? deviceId,
    int? scanManufacturerId,
    Uint8List? scanManufacturerData,
    Uint8List? scanManufacturerMask,
    String? authenticationServiceUuid,
    String? authenticationChallengeUuid,
    String? authenticationResponseUuid,
    String? authenticationStateUuid,
    int? authenticationChallengeLength,
    String? authenticationDigest,
    Uint8List? authenticationKey,
    Uint8List? authenticatedState,
    String? commandServiceUuid,
    String? commandCharacteristicUuid,
  }) => BackgroundSyncPlanRow(
    singletonId: singletonId ?? this.singletonId,
    planVersion: planVersion ?? this.planVersion,
    deviceId: deviceId ?? this.deviceId,
    scanManufacturerId: scanManufacturerId ?? this.scanManufacturerId,
    scanManufacturerData: scanManufacturerData ?? this.scanManufacturerData,
    scanManufacturerMask: scanManufacturerMask ?? this.scanManufacturerMask,
    authenticationServiceUuid:
        authenticationServiceUuid ?? this.authenticationServiceUuid,
    authenticationChallengeUuid:
        authenticationChallengeUuid ?? this.authenticationChallengeUuid,
    authenticationResponseUuid:
        authenticationResponseUuid ?? this.authenticationResponseUuid,
    authenticationStateUuid:
        authenticationStateUuid ?? this.authenticationStateUuid,
    authenticationChallengeLength:
        authenticationChallengeLength ?? this.authenticationChallengeLength,
    authenticationDigest: authenticationDigest ?? this.authenticationDigest,
    authenticationKey: authenticationKey ?? this.authenticationKey,
    authenticatedState: authenticatedState ?? this.authenticatedState,
    commandServiceUuid: commandServiceUuid ?? this.commandServiceUuid,
    commandCharacteristicUuid:
        commandCharacteristicUuid ?? this.commandCharacteristicUuid,
  );
  BackgroundSyncPlanRow copyWithCompanion(BackgroundSyncPlansCompanion data) {
    return BackgroundSyncPlanRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      planVersion: data.planVersion.present
          ? data.planVersion.value
          : this.planVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      scanManufacturerId: data.scanManufacturerId.present
          ? data.scanManufacturerId.value
          : this.scanManufacturerId,
      scanManufacturerData: data.scanManufacturerData.present
          ? data.scanManufacturerData.value
          : this.scanManufacturerData,
      scanManufacturerMask: data.scanManufacturerMask.present
          ? data.scanManufacturerMask.value
          : this.scanManufacturerMask,
      authenticationServiceUuid: data.authenticationServiceUuid.present
          ? data.authenticationServiceUuid.value
          : this.authenticationServiceUuid,
      authenticationChallengeUuid: data.authenticationChallengeUuid.present
          ? data.authenticationChallengeUuid.value
          : this.authenticationChallengeUuid,
      authenticationResponseUuid: data.authenticationResponseUuid.present
          ? data.authenticationResponseUuid.value
          : this.authenticationResponseUuid,
      authenticationStateUuid: data.authenticationStateUuid.present
          ? data.authenticationStateUuid.value
          : this.authenticationStateUuid,
      authenticationChallengeLength: data.authenticationChallengeLength.present
          ? data.authenticationChallengeLength.value
          : this.authenticationChallengeLength,
      authenticationDigest: data.authenticationDigest.present
          ? data.authenticationDigest.value
          : this.authenticationDigest,
      authenticationKey: data.authenticationKey.present
          ? data.authenticationKey.value
          : this.authenticationKey,
      authenticatedState: data.authenticatedState.present
          ? data.authenticatedState.value
          : this.authenticatedState,
      commandServiceUuid: data.commandServiceUuid.present
          ? data.commandServiceUuid.value
          : this.commandServiceUuid,
      commandCharacteristicUuid: data.commandCharacteristicUuid.present
          ? data.commandCharacteristicUuid.value
          : this.commandCharacteristicUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackgroundSyncPlanRow(')
          ..write('singletonId: $singletonId, ')
          ..write('planVersion: $planVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('scanManufacturerId: $scanManufacturerId, ')
          ..write('scanManufacturerData: $scanManufacturerData, ')
          ..write('scanManufacturerMask: $scanManufacturerMask, ')
          ..write('authenticationServiceUuid: $authenticationServiceUuid, ')
          ..write('authenticationChallengeUuid: $authenticationChallengeUuid, ')
          ..write('authenticationResponseUuid: $authenticationResponseUuid, ')
          ..write('authenticationStateUuid: $authenticationStateUuid, ')
          ..write(
            'authenticationChallengeLength: $authenticationChallengeLength, ',
          )
          ..write('authenticationDigest: $authenticationDigest, ')
          ..write('authenticationKey: $authenticationKey, ')
          ..write('authenticatedState: $authenticatedState, ')
          ..write('commandServiceUuid: $commandServiceUuid, ')
          ..write('commandCharacteristicUuid: $commandCharacteristicUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    planVersion,
    deviceId,
    scanManufacturerId,
    $driftBlobEquality.hash(scanManufacturerData),
    $driftBlobEquality.hash(scanManufacturerMask),
    authenticationServiceUuid,
    authenticationChallengeUuid,
    authenticationResponseUuid,
    authenticationStateUuid,
    authenticationChallengeLength,
    authenticationDigest,
    $driftBlobEquality.hash(authenticationKey),
    $driftBlobEquality.hash(authenticatedState),
    commandServiceUuid,
    commandCharacteristicUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackgroundSyncPlanRow &&
          other.singletonId == this.singletonId &&
          other.planVersion == this.planVersion &&
          other.deviceId == this.deviceId &&
          other.scanManufacturerId == this.scanManufacturerId &&
          $driftBlobEquality.equals(
            other.scanManufacturerData,
            this.scanManufacturerData,
          ) &&
          $driftBlobEquality.equals(
            other.scanManufacturerMask,
            this.scanManufacturerMask,
          ) &&
          other.authenticationServiceUuid == this.authenticationServiceUuid &&
          other.authenticationChallengeUuid ==
              this.authenticationChallengeUuid &&
          other.authenticationResponseUuid == this.authenticationResponseUuid &&
          other.authenticationStateUuid == this.authenticationStateUuid &&
          other.authenticationChallengeLength ==
              this.authenticationChallengeLength &&
          other.authenticationDigest == this.authenticationDigest &&
          $driftBlobEquality.equals(
            other.authenticationKey,
            this.authenticationKey,
          ) &&
          $driftBlobEquality.equals(
            other.authenticatedState,
            this.authenticatedState,
          ) &&
          other.commandServiceUuid == this.commandServiceUuid &&
          other.commandCharacteristicUuid == this.commandCharacteristicUuid);
}

class BackgroundSyncPlansCompanion
    extends UpdateCompanion<BackgroundSyncPlanRow> {
  final Value<int> singletonId;
  final Value<int> planVersion;
  final Value<String> deviceId;
  final Value<int> scanManufacturerId;
  final Value<Uint8List> scanManufacturerData;
  final Value<Uint8List> scanManufacturerMask;
  final Value<String> authenticationServiceUuid;
  final Value<String> authenticationChallengeUuid;
  final Value<String> authenticationResponseUuid;
  final Value<String> authenticationStateUuid;
  final Value<int> authenticationChallengeLength;
  final Value<String> authenticationDigest;
  final Value<Uint8List> authenticationKey;
  final Value<Uint8List> authenticatedState;
  final Value<String> commandServiceUuid;
  final Value<String> commandCharacteristicUuid;
  const BackgroundSyncPlansCompanion({
    this.singletonId = const Value.absent(),
    this.planVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.scanManufacturerId = const Value.absent(),
    this.scanManufacturerData = const Value.absent(),
    this.scanManufacturerMask = const Value.absent(),
    this.authenticationServiceUuid = const Value.absent(),
    this.authenticationChallengeUuid = const Value.absent(),
    this.authenticationResponseUuid = const Value.absent(),
    this.authenticationStateUuid = const Value.absent(),
    this.authenticationChallengeLength = const Value.absent(),
    this.authenticationDigest = const Value.absent(),
    this.authenticationKey = const Value.absent(),
    this.authenticatedState = const Value.absent(),
    this.commandServiceUuid = const Value.absent(),
    this.commandCharacteristicUuid = const Value.absent(),
  });
  BackgroundSyncPlansCompanion.insert({
    this.singletonId = const Value.absent(),
    required int planVersion,
    required String deviceId,
    required int scanManufacturerId,
    required Uint8List scanManufacturerData,
    required Uint8List scanManufacturerMask,
    required String authenticationServiceUuid,
    required String authenticationChallengeUuid,
    required String authenticationResponseUuid,
    required String authenticationStateUuid,
    required int authenticationChallengeLength,
    required String authenticationDigest,
    required Uint8List authenticationKey,
    required Uint8List authenticatedState,
    required String commandServiceUuid,
    required String commandCharacteristicUuid,
  }) : planVersion = Value(planVersion),
       deviceId = Value(deviceId),
       scanManufacturerId = Value(scanManufacturerId),
       scanManufacturerData = Value(scanManufacturerData),
       scanManufacturerMask = Value(scanManufacturerMask),
       authenticationServiceUuid = Value(authenticationServiceUuid),
       authenticationChallengeUuid = Value(authenticationChallengeUuid),
       authenticationResponseUuid = Value(authenticationResponseUuid),
       authenticationStateUuid = Value(authenticationStateUuid),
       authenticationChallengeLength = Value(authenticationChallengeLength),
       authenticationDigest = Value(authenticationDigest),
       authenticationKey = Value(authenticationKey),
       authenticatedState = Value(authenticatedState),
       commandServiceUuid = Value(commandServiceUuid),
       commandCharacteristicUuid = Value(commandCharacteristicUuid);
  static Insertable<BackgroundSyncPlanRow> custom({
    Expression<int>? singletonId,
    Expression<int>? planVersion,
    Expression<String>? deviceId,
    Expression<int>? scanManufacturerId,
    Expression<Uint8List>? scanManufacturerData,
    Expression<Uint8List>? scanManufacturerMask,
    Expression<String>? authenticationServiceUuid,
    Expression<String>? authenticationChallengeUuid,
    Expression<String>? authenticationResponseUuid,
    Expression<String>? authenticationStateUuid,
    Expression<int>? authenticationChallengeLength,
    Expression<String>? authenticationDigest,
    Expression<Uint8List>? authenticationKey,
    Expression<Uint8List>? authenticatedState,
    Expression<String>? commandServiceUuid,
    Expression<String>? commandCharacteristicUuid,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (planVersion != null) 'plan_version': planVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (scanManufacturerId != null)
        'scan_manufacturer_id': scanManufacturerId,
      if (scanManufacturerData != null)
        'scan_manufacturer_data': scanManufacturerData,
      if (scanManufacturerMask != null)
        'scan_manufacturer_mask': scanManufacturerMask,
      if (authenticationServiceUuid != null)
        'authentication_service_uuid': authenticationServiceUuid,
      if (authenticationChallengeUuid != null)
        'authentication_challenge_uuid': authenticationChallengeUuid,
      if (authenticationResponseUuid != null)
        'authentication_response_uuid': authenticationResponseUuid,
      if (authenticationStateUuid != null)
        'authentication_state_uuid': authenticationStateUuid,
      if (authenticationChallengeLength != null)
        'authentication_challenge_length': authenticationChallengeLength,
      if (authenticationDigest != null)
        'authentication_digest': authenticationDigest,
      if (authenticationKey != null) 'authentication_key': authenticationKey,
      if (authenticatedState != null) 'authenticated_state': authenticatedState,
      if (commandServiceUuid != null)
        'command_service_uuid': commandServiceUuid,
      if (commandCharacteristicUuid != null)
        'command_characteristic_uuid': commandCharacteristicUuid,
    });
  }

  BackgroundSyncPlansCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? planVersion,
    Value<String>? deviceId,
    Value<int>? scanManufacturerId,
    Value<Uint8List>? scanManufacturerData,
    Value<Uint8List>? scanManufacturerMask,
    Value<String>? authenticationServiceUuid,
    Value<String>? authenticationChallengeUuid,
    Value<String>? authenticationResponseUuid,
    Value<String>? authenticationStateUuid,
    Value<int>? authenticationChallengeLength,
    Value<String>? authenticationDigest,
    Value<Uint8List>? authenticationKey,
    Value<Uint8List>? authenticatedState,
    Value<String>? commandServiceUuid,
    Value<String>? commandCharacteristicUuid,
  }) {
    return BackgroundSyncPlansCompanion(
      singletonId: singletonId ?? this.singletonId,
      planVersion: planVersion ?? this.planVersion,
      deviceId: deviceId ?? this.deviceId,
      scanManufacturerId: scanManufacturerId ?? this.scanManufacturerId,
      scanManufacturerData: scanManufacturerData ?? this.scanManufacturerData,
      scanManufacturerMask: scanManufacturerMask ?? this.scanManufacturerMask,
      authenticationServiceUuid:
          authenticationServiceUuid ?? this.authenticationServiceUuid,
      authenticationChallengeUuid:
          authenticationChallengeUuid ?? this.authenticationChallengeUuid,
      authenticationResponseUuid:
          authenticationResponseUuid ?? this.authenticationResponseUuid,
      authenticationStateUuid:
          authenticationStateUuid ?? this.authenticationStateUuid,
      authenticationChallengeLength:
          authenticationChallengeLength ?? this.authenticationChallengeLength,
      authenticationDigest: authenticationDigest ?? this.authenticationDigest,
      authenticationKey: authenticationKey ?? this.authenticationKey,
      authenticatedState: authenticatedState ?? this.authenticatedState,
      commandServiceUuid: commandServiceUuid ?? this.commandServiceUuid,
      commandCharacteristicUuid:
          commandCharacteristicUuid ?? this.commandCharacteristicUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (planVersion.present) {
      map['plan_version'] = Variable<int>(planVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (scanManufacturerId.present) {
      map['scan_manufacturer_id'] = Variable<int>(scanManufacturerId.value);
    }
    if (scanManufacturerData.present) {
      map['scan_manufacturer_data'] = Variable<Uint8List>(
        scanManufacturerData.value,
      );
    }
    if (scanManufacturerMask.present) {
      map['scan_manufacturer_mask'] = Variable<Uint8List>(
        scanManufacturerMask.value,
      );
    }
    if (authenticationServiceUuid.present) {
      map['authentication_service_uuid'] = Variable<String>(
        authenticationServiceUuid.value,
      );
    }
    if (authenticationChallengeUuid.present) {
      map['authentication_challenge_uuid'] = Variable<String>(
        authenticationChallengeUuid.value,
      );
    }
    if (authenticationResponseUuid.present) {
      map['authentication_response_uuid'] = Variable<String>(
        authenticationResponseUuid.value,
      );
    }
    if (authenticationStateUuid.present) {
      map['authentication_state_uuid'] = Variable<String>(
        authenticationStateUuid.value,
      );
    }
    if (authenticationChallengeLength.present) {
      map['authentication_challenge_length'] = Variable<int>(
        authenticationChallengeLength.value,
      );
    }
    if (authenticationDigest.present) {
      map['authentication_digest'] = Variable<String>(
        authenticationDigest.value,
      );
    }
    if (authenticationKey.present) {
      map['authentication_key'] = Variable<Uint8List>(authenticationKey.value);
    }
    if (authenticatedState.present) {
      map['authenticated_state'] = Variable<Uint8List>(
        authenticatedState.value,
      );
    }
    if (commandServiceUuid.present) {
      map['command_service_uuid'] = Variable<String>(commandServiceUuid.value);
    }
    if (commandCharacteristicUuid.present) {
      map['command_characteristic_uuid'] = Variable<String>(
        commandCharacteristicUuid.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackgroundSyncPlansCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('planVersion: $planVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('scanManufacturerId: $scanManufacturerId, ')
          ..write('scanManufacturerData: $scanManufacturerData, ')
          ..write('scanManufacturerMask: $scanManufacturerMask, ')
          ..write('authenticationServiceUuid: $authenticationServiceUuid, ')
          ..write('authenticationChallengeUuid: $authenticationChallengeUuid, ')
          ..write('authenticationResponseUuid: $authenticationResponseUuid, ')
          ..write('authenticationStateUuid: $authenticationStateUuid, ')
          ..write(
            'authenticationChallengeLength: $authenticationChallengeLength, ',
          )
          ..write('authenticationDigest: $authenticationDigest, ')
          ..write('authenticationKey: $authenticationKey, ')
          ..write('authenticatedState: $authenticatedState, ')
          ..write('commandServiceUuid: $commandServiceUuid, ')
          ..write('commandCharacteristicUuid: $commandCharacteristicUuid')
          ..write(')'))
        .toString();
  }
}

class $BackgroundSyncCommandsTable extends BackgroundSyncCommands
    with TableInfo<$BackgroundSyncCommandsTable, BackgroundSyncCommandRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackgroundSyncCommandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planSingletonIdMeta = const VerificationMeta(
    'planSingletonId',
  );
  @override
  late final GeneratedColumn<int> planSingletonId = GeneratedColumn<int>(
    'plan_singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES background_sync_plans (singleton_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [planSingletonId, sequence, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'background_sync_commands';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackgroundSyncCommandRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_singleton_id')) {
      context.handle(
        _planSingletonIdMeta,
        planSingletonId.isAcceptableOrUnknown(
          data['plan_singleton_id']!,
          _planSingletonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planSingletonIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planSingletonId, sequence};
  @override
  BackgroundSyncCommandRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackgroundSyncCommandRow(
      planSingletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_singleton_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $BackgroundSyncCommandsTable createAlias(String alias) {
    return $BackgroundSyncCommandsTable(attachedDatabase, alias);
  }
}

class BackgroundSyncCommandRow extends DataClass
    implements Insertable<BackgroundSyncCommandRow> {
  final int planSingletonId;
  final int sequence;
  final Uint8List payload;
  const BackgroundSyncCommandRow({
    required this.planSingletonId,
    required this.sequence,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_singleton_id'] = Variable<int>(planSingletonId);
    map['sequence'] = Variable<int>(sequence);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  BackgroundSyncCommandsCompanion toCompanion(bool nullToAbsent) {
    return BackgroundSyncCommandsCompanion(
      planSingletonId: Value(planSingletonId),
      sequence: Value(sequence),
      payload: Value(payload),
    );
  }

  factory BackgroundSyncCommandRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackgroundSyncCommandRow(
      planSingletonId: serializer.fromJson<int>(json['planSingletonId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planSingletonId': serializer.toJson<int>(planSingletonId),
      'sequence': serializer.toJson<int>(sequence),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  BackgroundSyncCommandRow copyWith({
    int? planSingletonId,
    int? sequence,
    Uint8List? payload,
  }) => BackgroundSyncCommandRow(
    planSingletonId: planSingletonId ?? this.planSingletonId,
    sequence: sequence ?? this.sequence,
    payload: payload ?? this.payload,
  );
  BackgroundSyncCommandRow copyWithCompanion(
    BackgroundSyncCommandsCompanion data,
  ) {
    return BackgroundSyncCommandRow(
      planSingletonId: data.planSingletonId.present
          ? data.planSingletonId.value
          : this.planSingletonId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackgroundSyncCommandRow(')
          ..write('planSingletonId: $planSingletonId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(planSingletonId, sequence, $driftBlobEquality.hash(payload));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackgroundSyncCommandRow &&
          other.planSingletonId == this.planSingletonId &&
          other.sequence == this.sequence &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class BackgroundSyncCommandsCompanion
    extends UpdateCompanion<BackgroundSyncCommandRow> {
  final Value<int> planSingletonId;
  final Value<int> sequence;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const BackgroundSyncCommandsCompanion({
    this.planSingletonId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackgroundSyncCommandsCompanion.insert({
    required int planSingletonId,
    required int sequence,
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : planSingletonId = Value(planSingletonId),
       sequence = Value(sequence),
       payload = Value(payload);
  static Insertable<BackgroundSyncCommandRow> custom({
    Expression<int>? planSingletonId,
    Expression<int>? sequence,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planSingletonId != null) 'plan_singleton_id': planSingletonId,
      if (sequence != null) 'sequence': sequence,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackgroundSyncCommandsCompanion copyWith({
    Value<int>? planSingletonId,
    Value<int>? sequence,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return BackgroundSyncCommandsCompanion(
      planSingletonId: planSingletonId ?? this.planSingletonId,
      sequence: sequence ?? this.sequence,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planSingletonId.present) {
      map['plan_singleton_id'] = Variable<int>(planSingletonId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackgroundSyncCommandsCompanion(')
          ..write('planSingletonId: $planSingletonId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
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
  late final $BackgroundSyncPlansTable backgroundSyncPlans =
      $BackgroundSyncPlansTable(this);
  late final $BackgroundSyncCommandsTable backgroundSyncCommands =
      $BackgroundSyncCommandsTable(this);
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
    backgroundSyncPlans,
    backgroundSyncCommands,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('background_sync_plans', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'background_sync_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('background_sync_commands', kind: UpdateKind.delete),
      ],
    ),
  ]);
}
