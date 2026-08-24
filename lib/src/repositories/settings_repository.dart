import 'package:drift/drift.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';

final class SettingsInitialization {
  const SettingsInitialization({required this.activeBikeRepaired});

  final bool activeBikeRepaired;
}

final class AppPreferences {
  const AppPreferences({
    required this.activeBikeId,
    required this.lastViewedBikeId,
    required this.migrationNoticePending,
  });

  final String? activeBikeId;
  final String? lastViewedBikeId;
  final bool migrationNoticePending;
}

final class SettingsRepository {
  const SettingsRepository({required this.database});

  final AppDatabase database;

  Stream<AppPreferences> watch() {
    return (database.select(
      database.appSettings,
    )..where((table) => table.singletonId.equals(1))).watchSingleOrNull().map(
      (row) => row == null
          ? const AppPreferences(
              activeBikeId: null,
              lastViewedBikeId: null,
              migrationNoticePending: false,
            )
          : _map(row),
    );
  }

  Future<AppPreferences> get() async {
    await _ensureSettings();
    return _map(await _getSettings());
  }

  Future<SettingsInitialization> initialize() {
    return database.transaction(() async {
      await _ensureSettings();
      final settings = await _getSettings();
      final activeBikeId = settings.activeBikeId;
      final activeExists =
          activeBikeId != null && await _bikeExists(activeBikeId);
      final needsRepair = settings.activeBikeId == null
          ? await _hasBikes()
          : !activeExists;

      if (!needsRepair) {
        return const SettingsInitialization(activeBikeRepaired: false);
      }

      await _update(
        AppSettingsCompanion(
          activeBikeId: Value(await _lowestSortedBikeId()),
          migrationNoticePending: const Value(true),
        ),
      );
      return const SettingsInitialization(activeBikeRepaired: true);
    });
  }

  Future<void> makeBikeActive(String deviceId) {
    return database.transaction(() async {
      await _requireBike(deviceId);
      await _ensureSettings();
      await _update(AppSettingsCompanion(activeBikeId: Value(deviceId)));
    });
  }

  Future<void> setLastViewedBike(String? deviceId) {
    return database.transaction(() async {
      if (deviceId != null) {
        await _requireBike(deviceId);
      }
      await _ensureSettings();
      await _update(AppSettingsCompanion(lastViewedBikeId: Value(deviceId)));
    });
  }

  Future<void> dismissMigrationNotice() async {
    await _ensureSettings();
    await _update(
      const AppSettingsCompanion(migrationNoticePending: Value(false)),
    );
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

  Future<void> _update(AppSettingsCompanion changes) async {
    await (database.update(
      database.appSettings,
    )..where((table) => table.singletonId.equals(1))).write(changes);
  }

  Future<void> _requireBike(String deviceId) async {
    if (!await _bikeExists(deviceId)) {
      throw BikeNotFoundException(deviceId);
    }
  }

  Future<bool> _bikeExists(String deviceId) async {
    return await (database.selectOnly(database.bikes)
              ..addColumns([database.bikes.deviceId])
              ..where(database.bikes.deviceId.equals(deviceId)))
            .getSingleOrNull() !=
        null;
  }

  Future<bool> _hasBikes() async {
    return await (database.selectOnly(database.bikes)
              ..addColumns([database.bikes.deviceId])
              ..limit(1))
            .getSingleOrNull() !=
        null;
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

  AppPreferences _map(AppSettingRow settings) {
    return AppPreferences(
      activeBikeId: settings.activeBikeId,
      lastViewedBikeId: settings.lastViewedBikeId,
      migrationNoticePending: settings.migrationNoticePending,
    );
  }
}
