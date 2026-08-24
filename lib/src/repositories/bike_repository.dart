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
    final query =
        database.select(database.bikes).join([
          innerJoin(
            database.bikePreferences,
            database.bikePreferences.deviceId.equalsExp(
              database.bikes.deviceId,
            ),
          ),
        ])..orderBy([
          OrderingTerm.asc(database.bikes.sortOrder),
          OrderingTerm.asc(database.bikes.createdAtMs),
          OrderingTerm.asc(database.bikes.deviceId),
        ]);

    return query.watch().map(
      (rows) => List.unmodifiable(
        rows.map(
          (row) => _mapBike(
            row.readTable(database.bikes),
            row.readTable(database.bikePreferences),
          ),
        ),
      ),
    );
  }

  Stream<SavedBike?> watchActiveBike() {
    final query = database.select(database.bikes).join([
      innerJoin(
        database.bikePreferences,
        database.bikePreferences.deviceId.equalsExp(database.bikes.deviceId),
      ),
      innerJoin(
        database.appSettings,
        database.appSettings.activeBikeId.equalsExp(database.bikes.deviceId),
      ),
    ]);

    return query.watch().map((rows) {
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.single;
      return _mapBike(
        row.readTable(database.bikes),
        row.readTable(database.bikePreferences),
      );
    });
  }

  Future<List<SavedBike>> getBikes() async {
    final query =
        database.select(database.bikes).join([
          innerJoin(
            database.bikePreferences,
            database.bikePreferences.deviceId.equalsExp(
              database.bikes.deviceId,
            ),
          ),
        ])..orderBy([
          OrderingTerm.asc(database.bikes.sortOrder),
          OrderingTerm.asc(database.bikes.createdAtMs),
          OrderingTerm.asc(database.bikes.deviceId),
        ]);
    final rows = await query.get();
    return List.unmodifiable(
      rows.map(
        (row) => _mapBike(
          row.readTable(database.bikes),
          row.readTable(database.bikePreferences),
        ),
      ),
    );
  }

  Future<SavedBike?> getActiveBike() async {
    final settings = await _getSettings();
    final deviceId = settings.activeBikeId;
    if (deviceId == null) {
      return null;
    }
    return _getBikeOrNull(deviceId);
  }

  Future<SavedBike> addBike({
    required String deviceId,
    String? displayName,
    BikeRegion? region,
    BikeColor color = BikeColor.royalHorizon,
    RidePreferences preferences = const RidePreferences.defaults(),
  }) {
    final normalizedId = deviceId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty.');
    }
    _validatePreferences(preferences);
    final normalizedName = _normalizeName(displayName, normalizedId);

    return database.transaction(() async {
      await _ensureSettings();
      final nextSortOrder = (await _highestSortOrder()) + 1;
      final now = _clock().millisecondsSinceEpoch;

      await database
          .into(database.bikes)
          .insert(
            BikesCompanion.insert(
              deviceId: normalizedId,
              displayName: normalizedName,
              region: Value(region?.name),
              colorKey: color.key,
              sortOrder: nextSortOrder,
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
      await database
          .into(database.bikePreferences)
          .insert(_preferencesInsert(normalizedId, preferences));

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

  Future<void> renameBike(String deviceId, String displayName) {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty.',
      );
    }
    return _updateBike(
      deviceId,
      BikesCompanion(displayName: Value(normalizedName)),
    );
  }

  Future<void> setRegion(String deviceId, BikeRegion? region) {
    return _updateBike(deviceId, BikesCompanion(region: Value(region?.name)));
  }

  Future<void> setColor(String deviceId, BikeColor color) {
    return _updateBike(deviceId, BikesCompanion(colorKey: Value(color.key)));
  }

  Future<void> updateBikeDetails(
    String deviceId, {
    required String displayName,
    required BikeRegion region,
    required BikeColor color,
  }) {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty.',
      );
    }
    return _updateBike(
      deviceId,
      BikesCompanion(
        displayName: Value(normalizedName),
        region: Value(region.name),
        colorKey: Value(color.key),
      ),
    );
  }

  Future<void> saveDesiredSettings(
    String deviceId, {
    bool? light,
    int? mode,
    int? assist,
  }) {
    if (mode != null) {
      _validateMode(mode);
    }
    if (assist != null) {
      _validateAssist(assist);
    }
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        desiredLight: light == null ? const Value.absent() : Value(light),
        desiredMode: mode == null ? const Value.absent() : Value(mode),
        desiredAssist: assist == null ? const Value.absent() : Value(assist),
      ),
    );
  }

  Future<void> setLightLock(
    String deviceId, {
    required bool enabled,
    required bool confirmedValue,
  }) {
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        keepLight: Value(enabled),
        desiredLight: enabled ? Value(confirmedValue) : const Value.absent(),
      ),
    );
  }

  Future<void> setModeLock(
    String deviceId, {
    required bool enabled,
    required int confirmedValue,
  }) {
    _validateMode(confirmedValue);
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        keepMode: Value(enabled),
        desiredMode: enabled ? Value(confirmedValue) : const Value.absent(),
      ),
    );
  }

  Future<void> setAssistLock(
    String deviceId, {
    required bool enabled,
    required int confirmedValue,
  }) {
    _validateAssist(confirmedValue);
    return _updatePreferences(
      deviceId,
      BikePreferencesCompanion(
        keepAssist: Value(enabled),
        desiredAssist: enabled ? Value(confirmedValue) : const Value.absent(),
      ),
    );
  }

  Future<void> setBackgroundRequest(
    String deviceId, {
    required bool requested,
    required int consentVersion,
  }) {
    if (consentVersion < 0) {
      throw ArgumentError.value(
        consentVersion,
        'consentVersion',
        'Must not be negative.',
      );
    }
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
    final query = database.select(database.bikes).join([
      innerJoin(
        database.bikePreferences,
        database.bikePreferences.deviceId.equalsExp(database.bikes.deviceId),
      ),
    ])..where(database.bikes.deviceId.equals(deviceId));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapBike(
      row.readTable(database.bikes),
      row.readTable(database.bikePreferences),
    );
  }

  Future<void> _requireBike(String deviceId) async {
    if (!await _bikeExists(deviceId)) {
      throw BikeNotFoundException(deviceId);
    }
  }

  Future<bool> _bikeExists(String deviceId) async {
    final row =
        await (database.selectOnly(database.bikes)
              ..addColumns([database.bikes.deviceId])
              ..where(database.bikes.deviceId.equals(deviceId)))
            .getSingleOrNull();
    return row != null;
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

  SavedBike _mapBike(BikeRow bike, BikePreferenceRow preferences) {
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
        region: region,
        color: color,
        sortOrder: bike.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(bike.createdAtMs),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(bike.updatedAtMs),
        lastConnectedAt: bike.lastConnectedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(bike.lastConnectedAtMs!),
      ),
      preferences: RidePreferences(
        desiredLight: preferences.desiredLight,
        desiredMode: preferences.desiredMode,
        desiredAssist: preferences.desiredAssist,
        keepLight: preferences.keepLight,
        keepMode: preferences.keepMode,
        keepAssist: preferences.keepAssist,
        backgroundRequested: preferences.backgroundRequested,
        backgroundConsentVersion: preferences.backgroundConsentVersion,
      ),
    );
  }

  BikePreferencesCompanion _preferencesInsert(
    String deviceId,
    RidePreferences preferences,
  ) {
    return BikePreferencesCompanion.insert(
      deviceId: deviceId,
      desiredLight: preferences.desiredLight,
      desiredMode: preferences.desiredMode,
      desiredAssist: preferences.desiredAssist,
      keepLight: preferences.keepLight,
      keepMode: preferences.keepMode,
      keepAssist: preferences.keepAssist,
      backgroundRequested: preferences.backgroundRequested,
      backgroundConsentVersion: preferences.backgroundConsentVersion,
    );
  }

  String _normalizeName(String? displayName, String deviceId) {
    final normalized = displayName?.trim() ?? '';
    return normalized.isEmpty ? defaultBikeName(deviceId) : normalized;
  }

  void _validatePreferences(RidePreferences preferences) {
    _validateMode(preferences.desiredMode);
    _validateAssist(preferences.desiredAssist);
    if (preferences.backgroundConsentVersion < 0) {
      throw ArgumentError.value(
        preferences.backgroundConsentVersion,
        'backgroundConsentVersion',
        'Must not be negative.',
      );
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
