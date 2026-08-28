import 'package:drift/drift.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/bike_names.dart';
import 'package:superduper/src/persistence/app_database.dart';

final class BikeRepository {
  BikeRepository({required this.database, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final DateTime Function() _clock;

  Stream<List<SavedBike>> watchBikes() {
    return _savedBikesQuery().watch().map(
      (rows) => List.unmodifiable(
        rows.map(
          (row) => _mapBike(
            row.readTable(database.bikes),
            row.readTable(database.bikePreferences),
            row.readTableOrNull(database.bikeVersions),
          ),
        ),
      ),
    );
  }

  Future<List<SavedBike>> getBikes() async {
    final rows = await _savedBikesQuery().get();
    return List.unmodifiable(
      rows.map(
        (row) => _mapBike(
          row.readTable(database.bikes),
          row.readTable(database.bikePreferences),
          row.readTableOrNull(database.bikeVersions),
        ),
      ),
    );
  }

  Future<SavedBike> addBike({
    required String deviceId,
    String advertisedName = 'SUPER73',
    String? displayName,
    BikeRegion? region = BikeRegion.us,
    BikeColor color = BikeColor.royalHorizon,
    SetOnConnectSettings setOnConnect = const SetOnConnectSettings.defaults(),
    BackgroundPreference backgroundPreference =
        const BackgroundPreference.defaults(),
    BikeVersionInfo? versions,
    String? moduleSerial,
    int? odometerMeters,
  }) {
    final normalizedId = deviceId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty.');
    }
    _validateSetOnConnect(setOnConnect);
    _validateBackgroundPreference(backgroundPreference);
    final normalizedVersions = versions == null
        ? null
        : _normalizeVersionInfo(versions);
    if (odometerMeters != null) {
      _validateUnsigned(odometerMeters, 0xffffffff, 'odometerMeters');
    }
    final normalizedAdvertisedName = advertisedName.trim();
    final protocol = BikeProtocolVersion.fromAdvertisedName(
      normalizedAdvertisedName,
    );
    if (protocol == null) {
      throw ArgumentError.value(
        advertisedName,
        'advertisedName',
        'Must be a supported bike advertised name.',
      );
    }
    if (protocol == BikeProtocolVersion.v1 && region == null) {
      throw ArgumentError.value(
        region,
        'region',
        'A region is required for the V1 protocol.',
      );
    }
    final persistedRegion = protocol == BikeProtocolVersion.v1 ? region : null;
    final normalizedName = _normalizeName(displayName, normalizedId);
    final normalizedSerial = moduleSerial == null
        ? null
        : _normalizeModuleSerial(moduleSerial);

    return database.transaction(() async {
      await _ensureSettings();
      final existing =
          await (database.select(
                database.bikes,
              )..where((table) => table.deviceId.equals(normalizedId)))
              .getSingleOrNull();
      if (existing != null) {
        throw BikeAlreadyExistsException(normalizedId);
      }
      final nextSortOrder = (await _highestSortOrder()) + 1;
      final now = _clock().millisecondsSinceEpoch;

      await database
          .into(database.bikes)
          .insert(
            BikesCompanion.insert(
              deviceId: normalizedId,
              displayName: normalizedName,
              advertisedName: normalizedAdvertisedName,
              protocol: protocol,
              region: Value(persistedRegion?.name),
              colorKey: color.key,
              sortOrder: nextSortOrder,
              createdAtMs: now,
              updatedAtMs: now,
              moduleSerial: Value(normalizedSerial),
              odometerMeters: Value(odometerMeters),
              odometerReadAtMs: Value(
                odometerMeters == null ? null : now,
              ),
            ),
          );
      await database
          .into(database.bikePreferences)
          .insert(
            _setOnConnectInsert(
              normalizedId,
              setOnConnect,
              backgroundPreference,
            ),
          );
      if (normalizedVersions != null) {
        await database
            .into(database.bikeVersions)
            .insert(_versionsInsert(normalizedId, normalizedVersions, now));
      }

      final settings = await _getSettings();
      if (settings.activeBikeId == null) {
        await _updateSettings(
          AppSettingsCompanion(activeBikeId: Value(normalizedId)),
        );
      }

      return (await _getBikeOrNull(normalizedId))!;
    });
  }

  Future<void> forgetBike(String deviceId) {
    return database.transaction(() async {
      await _requireBike(deviceId);
      await _ensureSettings();
      final settings = await _getSettings();
      await (database.delete(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).go();

      if (settings.activeBikeId == deviceId) {
        await _updateSettings(
          AppSettingsCompanion(
            activeBikeId: Value(await _lowestSortedBikeId()),
          ),
        );
      }
    });
  }

  Future<void> updateBikeDetails(
    String deviceId, {
    required String displayName,
    required BikeRegion? region,
    required BikeColor color,
    required BikeProtocolVersion protocol,
  }) {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty.',
      );
    }
    if (protocol == BikeProtocolVersion.v1 && region == null) {
      throw ArgumentError.value(
        region,
        'region',
        'A region is required for the V1 protocol.',
      );
    }
    return _updateBike(
      deviceId,
      BikesCompanion(
        displayName: Value(normalizedName),
        protocol: Value(protocol),
        region: Value(
          protocol == BikeProtocolVersion.v1 ? region?.name : null,
        ),
        colorKey: Value(color.key),
      ),
    );
  }

  Future<void> setOnConnect(
    String deviceId,
    SetOnConnectSettings settings,
  ) {
    _validateSetOnConnect(settings);
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        desiredLight: Value(settings.lightEnabled),
        desiredMode: Value(settings.mode),
        desiredAssist: Value(settings.assist),
        keepLight: Value(settings.lightEnabled),
        keepMode: Value(settings.modeEnabled),
        keepAssist: Value(settings.assistEnabled),
      ),
    );
  }

  Future<void> setBackgroundPreference(
    String deviceId, {
    required bool requested,
    required int consentVersion,
  }) {
    final preference = BackgroundPreference(
      requested: requested,
      consentVersion: consentVersion,
    );
    _validateBackgroundPreference(preference);
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        backgroundRequested: Value(requested),
        backgroundConsentVersion: Value(consentVersion),
      ),
    );
  }

  Future<void> markConnected(String deviceId) {
    return _updateBike(
      deviceId,
      BikesCompanion(lastConnectedAtMs: Value(_clock().millisecondsSinceEpoch)),
      touchUpdatedAt: false,
    );
  }

  Future<bool> saveVersions(String deviceId, BikeVersionInfo versions) {
    final normalized = _normalizeVersionInfo(versions);
    return database.transaction(() async {
      await _requireBike(deviceId);
      final current = await (database.select(
        database.bikeVersions,
      )..where((table) => table.deviceId.equals(deviceId))).getSingleOrNull();
      if (current != null && _mapVersionInfo(current) == normalized) {
        return false;
      }
      final now = _clock().millisecondsSinceEpoch;
      await database
          .into(database.bikeVersions)
          .insertOnConflictUpdate(
            _versionsInsert(
              deviceId,
              normalized,
              now,
            ),
          );
      await (database.update(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).write(
        BikesCompanion(
          updatedAtMs: Value(now),
        ),
      );
      return true;
    });
  }

  Future<bool> saveModuleSerial(String deviceId, String moduleSerial) {
    final normalized = _normalizeModuleSerial(moduleSerial);
    return database.transaction(() async {
      final bike = await _requireBike(deviceId);
      if (bike.moduleSerial == normalized) {
        return false;
      }
      await (database.update(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).write(
        BikesCompanion(
          moduleSerial: Value(normalized),
          updatedAtMs: Value(_clock().millisecondsSinceEpoch),
        ),
      );
      return true;
    });
  }

  Future<bool> saveOdometer(String deviceId, int meters) {
    _validateUnsigned(meters, 0xffffffff, 'meters');
    return database.transaction(() async {
      final bike = await _requireBike(deviceId);
      final changed = bike.odometerMeters != meters;
      await (database.update(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).write(
        BikesCompanion(
          odometerMeters: Value(meters),
          odometerReadAtMs: Value(_clock().millisecondsSinceEpoch),
        ),
      );
      return changed;
    });
  }

  Future<void> _updateBike(
    String deviceId,
    BikesCompanion changes, {
    bool touchUpdatedAt = true,
  }) {
    return database.transaction(() async {
      await _requireBike(deviceId);
      final update = touchUpdatedAt
          ? changes.copyWith(
              updatedAtMs: Value(_clock().millisecondsSinceEpoch),
            )
          : changes;
      await (database.update(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).write(update);
    });
  }

  Future<void> _updatePreferences(
    String deviceId,
    BikePreferencesCompanion changes,
  ) {
    return database.transaction(() async {
      await _requireBike(deviceId);
      await (database.update(
        database.bikePreferences,
      )..where((table) => table.deviceId.equals(deviceId))).write(changes);
      await (database.update(
        database.bikes,
      )..where((table) => table.deviceId.equals(deviceId))).write(
        BikesCompanion(updatedAtMs: Value(_clock().millisecondsSinceEpoch)),
      );
    });
  }

  Future<void> _ensureSettings() async {
    await database
        .into(database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            singletonId: const Value(1),
            migrationNoticePending: false,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<AppSettingRow> _getSettings() {
    return (database.select(
      database.appSettings,
    )..where((table) => table.singletonId.equals(1))).getSingle();
  }

  Future<void> _updateSettings(AppSettingsCompanion changes) async {
    await (database.update(
      database.appSettings,
    )..where((table) => table.singletonId.equals(1))).write(changes);
  }

  Future<SavedBike?> _getBikeOrNull(String deviceId) async {
    final query = _savedBikesQuery()
      ..where(database.bikes.deviceId.equals(deviceId));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapBike(
      row.readTable(database.bikes),
      row.readTable(database.bikePreferences),
      row.readTableOrNull(database.bikeVersions),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _savedBikesQuery() {
    final query = database.select(database.bikes).join([
      innerJoin(
        database.bikePreferences,
        database.bikePreferences.deviceId.equalsExp(database.bikes.deviceId),
      ),
      leftOuterJoin(
        database.bikeVersions,
        database.bikeVersions.deviceId.equalsExp(database.bikes.deviceId),
      ),
    ]);
    return query..orderBy([
      OrderingTerm.asc(database.bikes.sortOrder),
      OrderingTerm.asc(database.bikes.createdAtMs),
      OrderingTerm.asc(database.bikes.deviceId),
    ]);
  }

  Future<BikeRow> _requireBike(String deviceId) async {
    final bike = await (database.select(
      database.bikes,
    )..where((table) => table.deviceId.equals(deviceId))).getSingleOrNull();
    if (bike == null) {
      throw BikeNotFoundException(deviceId);
    }
    return bike;
  }

  Future<int> _highestSortOrder() async {
    final maxSortOrder = database.bikes.sortOrder.max();
    final row = await (database.selectOnly(
      database.bikes,
    )..addColumns([maxSortOrder])).getSingle();
    return row.read(maxSortOrder) ?? -1;
  }

  Future<String?> _lowestSortedBikeId() async {
    final row =
        await (database.select(database.bikes)
              ..orderBy([
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.createdAtMs),
                (table) => OrderingTerm.asc(table.deviceId),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.deviceId;
  }

  SavedBike _mapBike(
    BikeRow bike,
    BikePreferenceRow preferences,
    BikeVersionRow? versions,
  ) {
    final region = switch (bike.region) {
      'us' => BikeRegion.us,
      'eu' => BikeRegion.eu,
      null => null,
      final value => throw StateError('Unknown bike region "$value".'),
    };
    final color = BikeColor.fromKey(bike.colorKey);
    if (color == null) {
      throw StateError('Unknown bike color "${bike.colorKey}".');
    }
    return SavedBike(
      bike: Bike(
        deviceId: bike.deviceId,
        displayName: bike.displayName,
        advertisedName: bike.advertisedName,
        protocol: bike.protocol,
        region: region,
        color: color,
        sortOrder: bike.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(bike.createdAtMs),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(bike.updatedAtMs),
        lastConnectedAt: bike.lastConnectedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(bike.lastConnectedAtMs!),
        moduleSerial: bike.moduleSerial,
      ),
      setOnConnect: SetOnConnectSettings(
        lightEnabled: preferences.keepLight && preferences.desiredLight,
        mode: preferences.desiredMode,
        modeEnabled: preferences.keepMode,
        assist: preferences.desiredAssist,
        assistEnabled: preferences.keepAssist,
      ),
      backgroundPreference: BackgroundPreference(
        requested: preferences.backgroundRequested,
        consentVersion: preferences.backgroundConsentVersion,
      ),
      versions: versions == null
          ? null
          : CachedBikeVersions(
              info: _mapVersionInfo(versions),
              readAt: DateTime.fromMillisecondsSinceEpoch(versions.readAtMs),
            ),
      odometer: bike.odometerMeters == null || bike.odometerReadAtMs == null
          ? null
          : CachedBikeOdometer(
              meters: bike.odometerMeters!,
              readAt: DateTime.fromMillisecondsSinceEpoch(
                bike.odometerReadAtMs!,
              ),
            ),
    );
  }

  BikeVersionInfo _mapVersionInfo(BikeVersionRow row) {
    return BikeVersionInfo(
      hardwareRevision: row.hardwareRevision,
      firmwareRevision: row.firmwareRevision,
      softwareRevision: row.softwareRevision,
      stmFirmwareVersion: row.stmFirmwareVersion,
      controllerVariant: row.controllerVariant,
      bootloaderHandoff: row.bootloaderHandoff,
      motorControllerVersion: row.motorControllerVersion,
      bmsVersion: row.bmsVersion,
    );
  }

  BikePreferencesCompanion _setOnConnectInsert(
    String deviceId,
    SetOnConnectSettings setOnConnect,
    BackgroundPreference backgroundPreference,
  ) {
    return BikePreferencesCompanion.insert(
      deviceId: deviceId,
      desiredLight: setOnConnect.lightEnabled,
      desiredMode: setOnConnect.mode,
      desiredAssist: setOnConnect.assist,
      keepLight: setOnConnect.lightEnabled,
      keepMode: setOnConnect.modeEnabled,
      keepAssist: setOnConnect.assistEnabled,
      backgroundRequested: backgroundPreference.requested,
      backgroundConsentVersion: backgroundPreference.consentVersion,
    );
  }

  BikeVersionsCompanion _versionsInsert(
    String deviceId,
    BikeVersionInfo versions,
    int readAtMs,
  ) {
    return BikeVersionsCompanion.insert(
      deviceId: deviceId,
      hardwareRevision: versions.hardwareRevision,
      firmwareRevision: versions.firmwareRevision,
      softwareRevision: versions.softwareRevision,
      stmFirmwareVersion: versions.stmFirmwareVersion,
      controllerVariant: versions.controllerVariant,
      bootloaderHandoff: versions.bootloaderHandoff,
      motorControllerVersion: versions.motorControllerVersion,
      bmsVersion: versions.bmsVersion,
      readAtMs: readAtMs,
    );
  }

  String _normalizeName(String? displayName, String deviceId) {
    final normalized = displayName?.trim() ?? '';
    return normalized.isEmpty ? defaultBikeName(deviceId) : normalized;
  }

  String _normalizeModuleSerial(String moduleSerial) {
    final normalized = moduleSerial.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{16}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        moduleSerial,
        'moduleSerial',
        'Must be a 16-character hexadecimal chip ID.',
      );
    }
    return normalized;
  }

  void _validateSetOnConnect(SetOnConnectSettings settings) {
    _validateMode(settings.mode);
    _validateAssist(settings.assist);
  }

  void _validateBackgroundPreference(BackgroundPreference preference) {
    if (preference.consentVersion < 0) {
      throw ArgumentError.value(
        preference.consentVersion,
        'consentVersion',
        'Must not be negative.',
      );
    }
  }

  BikeVersionInfo _normalizeVersionInfo(BikeVersionInfo versions) {
    final hardware = versions.hardwareRevision.trim();
    final firmware = versions.firmwareRevision.trim();
    final software = versions.softwareRevision.trim();
    if (hardware.isEmpty || firmware.isEmpty || software.isEmpty) {
      throw ArgumentError.value(
        versions,
        'versions',
        'Revision strings must not be empty.',
      );
    }
    _validateUnsigned(
      versions.stmFirmwareVersion,
      0xffffff,
      'stmFirmwareVersion',
    );
    _validateUnsigned(versions.controllerVariant, 0xffff, 'controllerVariant');
    _validateUnsigned(versions.bootloaderHandoff, 0xff, 'bootloaderHandoff');
    _validateUnsigned(
      versions.motorControllerVersion,
      0xffffffff,
      'motorControllerVersion',
    );
    _validateUnsigned(versions.bmsVersion, 0xffffffff, 'bmsVersion');
    return BikeVersionInfo(
      hardwareRevision: hardware,
      firmwareRevision: firmware,
      softwareRevision: software,
      stmFirmwareVersion: versions.stmFirmwareVersion,
      controllerVariant: versions.controllerVariant,
      bootloaderHandoff: versions.bootloaderHandoff,
      motorControllerVersion: versions.motorControllerVersion,
      bmsVersion: versions.bmsVersion,
    );
  }

  void _validateUnsigned(int value, int maximum, String name) {
    if (value < 0 || value > maximum) {
      throw RangeError.range(value, 0, maximum, name);
    }
  }

  void _validateMode(int mode) {
    if (mode < 0 || mode > 3) {
      throw RangeError.range(mode, 0, 3, 'mode');
    }
  }

  void _validateAssist(int assist) {
    if (assist < 0 || assist > 4) {
      throw RangeError.range(assist, 0, 4, 'assist');
    }
  }
}
