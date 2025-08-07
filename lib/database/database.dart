import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models/models.dart';
import 'package:superduper/core/utils/logger.dart';

part 'database.freezed.dart';
part 'database.g.dart';

@freezed
abstract class SettingsModel with _$SettingsModel {
  const factory SettingsModel(
      {String? currentBike,
      required List<BikeSettings> bikeSettings}) = _SettingsModel;

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  factory SettingsModel.defaultSettings() => SettingsModel(
        currentBike: null,
        bikeSettings: [],
      );
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _settingsFile async {
  final path = await _localPath;
  return File('$path/settings.json');
}

Future<void> _writeSettings(SettingsModel settings) async {
  final file = await _settingsFile;
  await file.writeAsString(jsonEncode(settings.toJson()));
}

Future<SettingsModel> _readSettings() async {
  try {
    final file = await _settingsFile;
    final contents = await file.readAsString();
    log.d(SDLogger.DB, 'Read settings');
    return SettingsModel.fromJson(jsonDecode(contents));
  } catch (e) {
    log.w(SDLogger.DB, 'No settings found or corrupt, using defaults');
    final settings = SettingsModel.defaultSettings();
    return settings;
  }
}

@Riverpod(keepAlive: true)
class SettingsDB extends _$SettingsDB {
  @override
  Future<SettingsModel> build() async {
    return _readSettings();
  }

  Future<SettingsModel> save(SettingsModel settings) async {
    await _writeSettings(settings);
    state = AsyncValue.data(settings);
    return settings;
  }
}

@riverpod
class BikeDB extends _$BikeDB {
  @override
  BikeSettings? build(String id) {
    try {
      final settings = ref.watch(settingsDBProvider).requireValue;
      return _getBike(settings, id);
    } catch (e) {
      log.e(SDLogger.DB, 'Bike not found');
    }
    return null;
  }

  BikeSettings? _getBike(SettingsModel settings, String id) {
    try {
      final bikeSettings =
          settings.bikeSettings.firstWhere((element) => element.id == id);
      return bikeSettings;
    } catch (e) {
      log.e(SDLogger.DB, 'Bike not found');
    }
    return null;
  }

  void saveBike(BikeSettings bikeSettings) {
    var settings = ref.read(settingsDBProvider).requireValue;
    final bike = _getBike(settings, bikeSettings.id);
    if (bike == null) {
      log.i(SDLogger.DB, 'Added new bike: ${bikeSettings.name}');
      settings = settings
          .copyWith(bikeSettings: [...settings.bikeSettings, bikeSettings]);
    } else {
      log.d(SDLogger.DB, 'Updated bike: ${bikeSettings.name}');
      settings = settings.copyWith(
          bikeSettings: settings.bikeSettings
              .map((bike) => bike.id == bikeSettings.id ? bikeSettings : bike)
              .toList());
    }
    ref.read(settingsDBProvider.notifier).save(settings);
  }

  void deleteBike(String id) {
    var settings = ref.read(settingsDBProvider).requireValue;
    final bike = _getBike(settings, id);
    if (bike != null) {
      log.i(SDLogger.DB, 'Deleted bike: ${bike.name}');
      settings = settings.copyWith(
          bikeSettings:
              settings.bikeSettings.where((bike) => bike.id != id).toList());
      ref.read(settingsDBProvider.notifier).save(settings);
    } else {
      log.e(SDLogger.DB, 'Bike not found: $id');
    }
  }
}
//   void saveBike(BikeState bike) {
//     final bikes = state;
//     final index = bikes.indexWhere((element) => element.id == bike.id);
//     if (index == -1) {
//       bikes.add(bike);
//       log.i(SDLogger.DB, 'Added new bike: ${bike.name}');
//     } else {
//       bikes[index] = bike;
//       log.d(SDLogger.DB, 'Updated bike: ${bike.name}');
//     }
//     state = bikes;
//     _writeBikes(state);
//   }

//   void deleteBike(BikeState bike) {
//     state.removeWhere((element) => element.id == bike.id);
//     log.i(SDLogger.DB, 'Deleted bike: ${bike.name}');
//     _writeBikes(state);
//   }

//   BikeState? getBike(String id) {
//     try {
//       return state.firstWhere((element) => element.id == id);
//     } catch (e) {
//       log.d(SDLogger.DB, 'No bike found with ID: $id');
//       return null;
//     }
//   }
// }

// @Riverpod(keepAlive: true)
// class SettingsDB extends _$SettingsDB {
//   @override
//   SettingsModel build() {
//     _readSettings().then((settings) => state = settings);
//     return const SettingsModel();
//   }

//   void save(SettingsModel settings) {
//     _settingsFile.then((file) => file.writeAsString(jsonEncode(settings)));
//     log.d(SDLogger.DB, 'Saved settings: $settings');
//     state = settings;
//   }
// }
