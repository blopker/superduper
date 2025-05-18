import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/bike_region.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/utils/logger.dart';

part 'migration.g.dart';

/// Utility for migrating data from the old database format to the new one.
class MigrationUtil {
  final Ref _ref;

  /// Creates a new migration utility.
  MigrationUtil(this._ref);

  /// Migrates data from the old format to the new format if needed.
  Future<void> migrateIfNeeded() async {
    final directory = await getApplicationDocumentsDirectory();
    final oldBikesPath = '${directory.path}/bikes.json';
    final migrationFlagPath = '${directory.path}/migration_completed';

    // Check if migration has already been completed
    final migrationFlagFile = File(migrationFlagPath);
    if (await migrationFlagFile.exists()) {
      log.i(SDLogger.DB, 'Migration already completed');
      return;
    }

    // Check if there's old data to migrate
    final oldBikesFile = File(oldBikesPath);
    if (!await oldBikesFile.exists()) {
      log.i(SDLogger.DB, 'No old data to migrate');
      // Mark migration as completed
      await migrationFlagFile.writeAsString(DateTime.now().toIso8601String());
      return;
    }

    try {
      // Read old data
      final oldBikesJson = await oldBikesFile.readAsString();
      if (oldBikesJson.isEmpty) {
        log.i(SDLogger.DB, 'Old data file exists but is empty');
        await migrationFlagFile.writeAsString(DateTime.now().toIso8601String());
        return;
      }

      // Parse old data
      final oldBikes = (jsonDecode(oldBikesJson) as List)
          .map((e) => _convertOldBikeToNew(e as Map<String, dynamic>))
          .where((bike) => bike != null)
          .cast<BikeModel>()
          .toList();

      if (oldBikes.isEmpty) {
        log.i(SDLogger.DB, 'No valid bikes to migrate');
        await migrationFlagFile.writeAsString(DateTime.now().toIso8601String());
        return;
      }

      log.i(SDLogger.DB, 'Migrating ${oldBikes.length} bikes to new format');

      // Save using the new repository
      final bikeRepository = _ref.read(bikeRepositoryProvider);
      for (final bike in oldBikes) {
        await bikeRepository.updateBike(bike);
        log.d(SDLogger.DB, 'Migrated bike: ${bike.name} (${bike.id})');
      }

      // Mark migration as completed
      await migrationFlagFile.writeAsString(DateTime.now().toIso8601String());
      log.i(SDLogger.DB, 'Migration completed successfully');
    } catch (e) {
      log.e(SDLogger.DB, 'Error during migration', e);
    }
  }

  /// Converts an old bike format to the new BikeModel format.
  BikeModel? _convertOldBikeToNew(Map<String, dynamic> oldBike) {
    try {
      // Handle the case where the old format used different field names
      final String? id = oldBike['id'] as String?;
      if (id == null) {
        return null;
      }

      return BikeModel(
        id: id,
        name: oldBike['name'] as String? ?? 'Bike',
        bluetoothAddress: id, // In the old format, id was the bluetooth address
        isActive: true, // Assume all migrated bikes are active
        mode: oldBike['mode'] as int? ?? 0,
        modeLocked: oldBike['modeLocked'] as bool? ?? false,
        light: oldBike['light'] as bool? ?? false,
        lightLocked: oldBike['lightLocked'] as bool? ?? false,
        assist: oldBike['assist'] as int? ?? 0,
        assistLocked: oldBike['assistLocked'] as bool? ?? false,
        backgroundLock: oldBike['modeLock'] as bool? ?? false,
        region: _convertRegion(oldBike['region']),
        color: oldBike['color'] as int? ?? 0,
        isConnected: false,
      );
    } catch (e) {
      log.e(SDLogger.DB, 'Error converting bike data', e);
      return null;
    }
  }

  /// Converts the old region format to the new BikeRegion enum.
  BikeRegion? _convertRegion(dynamic oldRegion) {
    if (oldRegion == null) {
      return null;
    }

    // If it's a numeric value (old format used indices)
    if (oldRegion is int) {
      return oldRegion == 201 ? BikeRegion.eu : BikeRegion.us;
    }

    // If it's a string representation
    if (oldRegion is String) {
      return oldRegion.toLowerCase() == 'eu' ? BikeRegion.eu : BikeRegion.us;
    }

    // If it's already an object with a value property
    if (oldRegion is Map && oldRegion.containsKey('value')) {
      final value = oldRegion['value'];
      return value.toString().toLowerCase() == 'eu'
          ? BikeRegion.eu
          : BikeRegion.us;
    }

    return null;
  }
}

/// Provider for the migration utility.
@riverpod
MigrationUtil migrationUtil(Ref ref) {
  return MigrationUtil(ref);
}

/// Provider that runs the migration if needed.
@Riverpod(keepAlive: true)
Future<void> runMigration(Ref ref) async {
  final migrationUtil = ref.watch(migrationUtilProvider);
  await migrationUtil.migrateIfNeeded();
}
