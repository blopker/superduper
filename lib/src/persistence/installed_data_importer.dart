import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/bike_names.dart';
import 'package:superduper/src/persistence/app_database.dart';

const installedJsonImportKey = 'v1_json';

enum DataImportOutcome {
  completed('completed'),
  noSource('no_source'),
  skippedByUser('skipped_by_user');

  const DataImportOutcome(this.databaseValue);

  final String databaseValue;

  static DataImportOutcome fromDatabase(String value) {
    return values.firstWhere(
      (outcome) => outcome.databaseValue == value,
      orElse: () => throw StateError('Unknown data import outcome "$value".'),
    );
  }
}

final class ImportWarning {
  const ImportWarning({required this.code, this.record, this.field});

  factory ImportWarning.fromJson(Object? value) {
    if (value is! Map<String, Object?> || value['code'] is! String) {
      throw const FormatException('Invalid stored import warning.');
    }
    return ImportWarning(
      code: value['code']! as String,
      record: value['record'] as int?,
      field: value['field'] as String?,
    );
  }

  final String code;
  final int? record;
  final String? field;

  Map<String, Object> toJson() => {
    'code': code,
    'record': ?record,
    'field': ?field,
  };
}

sealed class InstalledDataImportResult {
  const InstalledDataImportResult();
}

final class InstalledDataImportSuccess extends InstalledDataImportResult {
  const InstalledDataImportSuccess({
    required this.outcome,
    required this.bikesImported,
    required this.warnings,
    required this.previouslyHandled,
  });

  final DataImportOutcome outcome;
  final int bikesImported;
  final List<ImportWarning> warnings;
  final bool previouslyHandled;
}

enum ImportRecoveryReason { unreadableBikes, malformedBikes, noValidBikes }

final class InstalledDataImportRecovery extends InstalledDataImportResult {
  const InstalledDataImportRecovery({
    required this.reason,
    required this.warnings,
  });

  final ImportRecoveryReason reason;
  final List<ImportWarning> warnings;
}

typedef DocumentsDirectoryProvider = Future<Directory> Function();

final class InstalledDataImporter {
  InstalledDataImporter({
    required this.database,
    DocumentsDirectoryProvider? documentsDirectory,
    DateTime Function()? clock,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final DocumentsDirectoryProvider _documentsDirectory;
  final DateTime Function() _clock;

  Future<InstalledDataImportResult> run() async {
    final marker = await _getMarker();
    if (marker != null) {
      return _resultFromMarker(marker);
    }

    final documents = await _documentsDirectory();
    final bikesFile = File(path.join(documents.path, installedBikesFilename));
    final settingsFile = File(
      path.join(documents.path, installedSettingsFilename),
    );
    final bikesExist = bikesFile.existsSync();
    final settingsExist = settingsFile.existsSync();

    if (!bikesExist && !settingsExist) {
      return _recordNoSource();
    }

    final warnings = <ImportWarning>[];
    List<Object?>? sourceBikes;
    if (bikesExist) {
      Object? decoded;
      try {
        decoded = jsonDecode(await bikesFile.readAsString());
      } on FileSystemException {
        return const InstalledDataImportRecovery(
          reason: ImportRecoveryReason.unreadableBikes,
          warnings: [],
        );
      } on FormatException {
        return const InstalledDataImportRecovery(
          reason: ImportRecoveryReason.malformedBikes,
          warnings: [],
        );
      }
      if (decoded is! List<Object?>) {
        return const InstalledDataImportRecovery(
          reason: ImportRecoveryReason.malformedBikes,
          warnings: [],
        );
      }
      sourceBikes = decoded;
    }

    String? currentBikeId;
    if (settingsExist) {
      try {
        final decoded = jsonDecode(await settingsFile.readAsString());
        if (decoded case {'currentBike': final String value}
            when value.trim().isNotEmpty) {
          currentBikeId = value.trim();
        } else if (decoded is! Map<String, Object?>) {
          warnings.add(const ImportWarning(code: 'malformed_settings'));
        } else if (decoded.containsKey('currentBike') &&
            decoded['currentBike'] != null) {
          warnings.add(
            const ImportWarning(
              code: 'invalid_settings_field',
              field: 'currentBike',
            ),
          );
        }
      } on FileSystemException {
        warnings.add(const ImportWarning(code: 'unreadable_settings'));
      } on FormatException {
        warnings.add(const ImportWarning(code: 'malformed_settings'));
      }
    }

    final importedById = <String, _ImportedBike>{};
    final records = sourceBikes ?? const <Object?>[];
    for (var index = 0; index < records.length; index++) {
      final imported = _parseBike(records[index], index, warnings);
      if (imported == null) {
        continue;
      }
      final previous = importedById[imported.deviceId];
      if (previous != null) {
        warnings.add(ImportWarning(code: 'duplicate_bike', record: index));
        importedById[imported.deviceId] = imported.withSortOrder(
          previous.sortOrder,
        );
      } else {
        importedById[imported.deviceId] = imported;
      }
    }

    if (records.isNotEmpty && importedById.isEmpty) {
      return InstalledDataImportRecovery(
        reason: ImportRecoveryReason.noValidBikes,
        warnings: List.unmodifiable(warnings),
      );
    }

    return database.transaction(() async {
      await _ensureSettings();
      final now = _clock().millisecondsSinceEpoch;
      var inserted = 0;

      for (final imported in importedById.values) {
        if (await _bikeExists(imported.deviceId)) {
          warnings.add(
            ImportWarning(
              code: 'existing_bike_preserved',
              record: imported.sortOrder,
            ),
          );
          continue;
        }
        await database
            .into(database.bikes)
            .insert(
              BikesCompanion.insert(
                deviceId: imported.deviceId,
                displayName: imported.displayName,
                advertisedName: 'SUPER73',
                protocol: BikeProtocolVersion.v1,
                region: Value(imported.region.name),
                colorKey: imported.color.key,
                sortOrder: imported.sortOrder,
                createdAtMs: now,
                updatedAtMs: now,
              ),
            );
        await database
            .into(database.bikePreferences)
            .insert(
              BikePreferencesCompanion.insert(
                deviceId: imported.deviceId,
                setOnConnect: BikeControlPatch(
                  light: imported.lightLocked && imported.light ? true : null,
                  mode: imported.modeLocked ? imported.mode : null,
                  assist: imported.assistLocked ? imported.assist : null,
                ),
                backgroundRequested: imported.backgroundRequested,
                backgroundConsentVersion: 0,
              ),
            );
        inserted++;
      }

      final settings = await _getSettings();
      final validActive =
          settings.activeBikeId != null &&
          await _bikeExists(settings.activeBikeId!);
      final fallbackId = validActive
          ? settings.activeBikeId
          : await _lowestId();

      var lastViewedId = settings.lastViewedBikeId;
      if (currentBikeId != null) {
        if (await _bikeExists(currentBikeId)) {
          lastViewedId = currentBikeId;
        } else {
          warnings.add(
            const ImportWarning(
              code: 'unknown_current_bike',
              field: 'currentBike',
            ),
          );
        }
      }

      await (database.update(
        database.appSettings,
      )..where((table) => table.singletonId.equals(1))).write(
        AppSettingsCompanion(
          activeBikeId: Value(fallbackId),
          lastViewedBikeId: Value(lastViewedId),
          migrationNoticePending: Value(warnings.isNotEmpty),
        ),
      );

      await database
          .into(database.dataImports)
          .insertOnConflictUpdate(
            DataImportsCompanion.insert(
              importKey: installedJsonImportKey,
              outcome: DataImportOutcome.completed.databaseValue,
              completedAtMs: now,
              bikesImported: inserted,
              warningsJson: _encodeWarnings(warnings),
            ),
          );

      return InstalledDataImportSuccess(
        outcome: DataImportOutcome.completed,
        bikesImported: inserted,
        warnings: List.unmodifiable(warnings),
        previouslyHandled: false,
      );
    });
  }

  Future<InstalledDataImportSuccess> continueWithoutImport() async {
    final now = _clock().millisecondsSinceEpoch;
    await database
        .into(database.dataImports)
        .insertOnConflictUpdate(
          DataImportsCompanion.insert(
            importKey: installedJsonImportKey,
            outcome: DataImportOutcome.skippedByUser.databaseValue,
            completedAtMs: now,
            bikesImported: 0,
            warningsJson: '[]',
          ),
        );
    return const InstalledDataImportSuccess(
      outcome: DataImportOutcome.skippedByUser,
      bikesImported: 0,
      warnings: [],
      previouslyHandled: false,
    );
  }

  Future<InstalledDataImportResult> retry() async {
    await (database.delete(database.dataImports)..where(
          (table) =>
              table.importKey.equals(installedJsonImportKey) &
              table.outcome.equals(
                DataImportOutcome.skippedByUser.databaseValue,
              ),
        ))
        .go();
    return run();
  }

  Future<InstalledDataImportSuccess> _recordNoSource() async {
    final now = _clock().millisecondsSinceEpoch;
    await database
        .into(database.dataImports)
        .insertOnConflictUpdate(
          DataImportsCompanion.insert(
            importKey: installedJsonImportKey,
            outcome: DataImportOutcome.noSource.databaseValue,
            completedAtMs: now,
            bikesImported: 0,
            warningsJson: '[]',
          ),
        );
    return const InstalledDataImportSuccess(
      outcome: DataImportOutcome.noSource,
      bikesImported: 0,
      warnings: [],
      previouslyHandled: false,
    );
  }

  Future<DataImportRow?> _getMarker() {
    return (database.select(database.dataImports)
          ..where((table) => table.importKey.equals(installedJsonImportKey)))
        .getSingleOrNull();
  }

  InstalledDataImportSuccess _resultFromMarker(DataImportRow marker) {
    var warnings = const <ImportWarning>[];
    try {
      final decoded = jsonDecode(marker.warningsJson);
      if (decoded is List<Object?>) {
        warnings = List.unmodifiable(decoded.map(ImportWarning.fromJson));
      }
    } on FormatException {
      warnings = const [ImportWarning(code: 'invalid_stored_warnings')];
    }
    return InstalledDataImportSuccess(
      outcome: DataImportOutcome.fromDatabase(marker.outcome),
      bikesImported: marker.bikesImported,
      warnings: warnings,
      previouslyHandled: true,
    );
  }

  _ImportedBike? _parseBike(
    Object? source,
    int index,
    List<ImportWarning> warnings,
  ) {
    if (source is! Map<String, Object?>) {
      warnings.add(ImportWarning(code: 'invalid_bike', record: index));
      return null;
    }

    final id = source['id'];
    if (id is! String || id.trim().isEmpty) {
      warnings.add(
        ImportWarning(code: 'invalid_bike', record: index, field: 'id'),
      );
      return null;
    }
    final deviceId = id.trim();
    final light = source['light'];
    if (light is! bool) {
      warnings.add(
        ImportWarning(code: 'invalid_bike', record: index, field: 'light'),
      );
      return null;
    }
    final mode = source['mode'];
    if (mode is! int || !BikeControlValues.isValidMode(mode)) {
      warnings.add(
        ImportWarning(code: 'invalid_bike', record: index, field: 'mode'),
      );
      return null;
    }
    final assist = source['assist'];
    if (assist is! int || !BikeControlValues.isValidAssist(assist)) {
      warnings.add(
        ImportWarning(code: 'invalid_bike', record: index, field: 'assist'),
      );
      return null;
    }

    final name = source['name'];
    final normalizedName = name is String ? name.trim() : '';
    if (normalizedName.isEmpty) {
      warnings.add(
        ImportWarning(
          code: 'defaulted_bike_field',
          record: index,
          field: 'name',
        ),
      );
    }

    final region = _parseRegion(source['region'], index, warnings);
    final color = _parseColor(source['color'], index, warnings);

    return _ImportedBike(
      deviceId: deviceId,
      displayName: normalizedName.isEmpty
          ? defaultBikeName(deviceId)
          : normalizedName,
      region: region,
      color: color,
      sortOrder: index,
      light: light,
      mode: mode,
      assist: assist,
      lightLocked: _optionalBool(source, 'lightLocked', index, warnings),
      modeLocked: _optionalBool(source, 'modeLocked', index, warnings),
      assistLocked: _optionalBool(source, 'assistLocked', index, warnings),
      backgroundRequested: _optionalBool(source, 'modeLock', index, warnings),
    );
  }

  BikeRegion _parseRegion(
    Object? value,
    int index,
    List<ImportWarning> warnings,
  ) {
    if (value == null) {
      warnings.add(
        ImportWarning(
          code: 'defaulted_bike_field',
          record: index,
          field: 'region',
        ),
      );
      return BikeRegion.us;
    }
    if (value == 200 || (value is String && value.toLowerCase() == 'us')) {
      return BikeRegion.us;
    }
    if (value == 201 || (value is String && value.toLowerCase() == 'eu')) {
      return BikeRegion.eu;
    }
    warnings.add(
      ImportWarning(code: 'unknown_region', record: index, field: 'region'),
    );
    return BikeRegion.us;
  }

  BikeColor _parseColor(
    Object? value,
    int index,
    List<ImportWarning> warnings,
  ) {
    final color = value is int ? BikeColor.fromLegacyIndex(value) : null;
    if (color != null) {
      return color;
    }
    warnings.add(
      ImportWarning(
        code: 'defaulted_bike_field',
        record: index,
        field: 'color',
      ),
    );
    return BikeColor.royalHorizon;
  }

  bool _optionalBool(
    Map<String, Object?> source,
    String field,
    int index,
    List<ImportWarning> warnings,
  ) {
    final value = source[field];
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    warnings.add(
      ImportWarning(code: 'defaulted_bike_field', record: index, field: field),
    );
    return false;
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

  Future<bool> _bikeExists(String deviceId) async {
    return await (database.selectOnly(database.bikes)
              ..addColumns([database.bikes.deviceId])
              ..where(database.bikes.deviceId.equals(deviceId)))
            .getSingleOrNull() !=
        null;
  }

  Future<String?> _lowestId() async {
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

  String _encodeWarnings(List<ImportWarning> warnings) {
    return jsonEncode(warnings.map((warning) => warning.toJson()).toList());
  }
}

final class _ImportedBike {
  const _ImportedBike({
    required this.deviceId,
    required this.displayName,
    required this.region,
    required this.color,
    required this.sortOrder,
    required this.light,
    required this.mode,
    required this.assist,
    required this.lightLocked,
    required this.modeLocked,
    required this.assistLocked,
    required this.backgroundRequested,
  });

  final String deviceId;
  final String displayName;
  final BikeRegion region;
  final BikeColor color;
  final int sortOrder;
  final bool light;
  final int mode;
  final int assist;
  final bool lightLocked;
  final bool modeLocked;
  final bool assistLocked;
  final bool backgroundRequested;

  _ImportedBike withSortOrder(int newSortOrder) {
    return _ImportedBike(
      deviceId: deviceId,
      displayName: displayName,
      region: region,
      color: color,
      sortOrder: newSortOrder,
      light: light,
      mode: mode,
      assist: assist,
      lightLocked: lightLocked,
      modeLocked: modeLocked,
      assistLocked: assistLocked,
      backgroundRequested: backgroundRequested,
    );
  }
}
