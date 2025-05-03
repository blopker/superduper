import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models.dart';
import 'package:superduper/utils/logger.dart';

part 'db.freezed.dart';
part 'db.g.dart';

@freezed
abstract class SettingsModel with _$SettingsModel {
  const factory SettingsModel({String? currentBike}) = _SettingsModel;

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _settingsFile async {
  final path = await _localPath;
  return File('$path/settings.json');
}

Future<File> get _bikesFile async {
  final path = await _localPath;
  return File('$path/bikes.json');
}

Future<File> _writeBikes(List<BikeState> bikes) async {
  log.d(SDLogger.DB, 'Writing bikes to file');
  if (kDebugMode) {
    log.v(SDLogger.DB, 'Bike data: ${jsonEncode(bikes)}');
  }
  final file = await _bikesFile;
  return file.writeAsString(jsonEncode(bikes));
}

Future<SettingsModel> _readSettings() async {
  try {
    final file = await _settingsFile;
    final contents = await file.readAsString();
    log.d(SDLogger.DB, 'Read settings');
    return SettingsModel.fromJson(jsonDecode(contents));
  } catch (e) {
    log.w(SDLogger.DB, 'No settings found, using defaults');
    return const SettingsModel();
  }
}

Future<List<BikeState>> _readBikes() async {
  log.d(SDLogger.DB, 'Reading bikes from file');
  try {
    final file = await _bikesFile;
    final contents = await file.readAsString();
    if (kDebugMode) {
      log.v(SDLogger.DB, 'Read contents: $contents');
    }
    final bikes = (jsonDecode(contents) as List)
        .map((e) => BikeState.fromJson(e as Map<String, Object?>))
        .toList();
    log.d(SDLogger.DB, 'Read ${bikes.length} bikes');
    return bikes;
  } catch (e) {
    log.e(SDLogger.DB, 'Error reading bikes', e);
    return [];
  }
}

@Riverpod(keepAlive: true)
class BikesDB extends _$BikesDB {
  @override
  List<BikeState> build() {
    _readBikes().then((bikes) => state = bikes);
    return [];
  }

  void saveBike(BikeState bike) {
    final bikes = state;
    final index = bikes.indexWhere((element) => element.id == bike.id);
    if (index == -1) {
      bikes.add(bike);
      log.i(SDLogger.DB, 'Added new bike: ${bike.name}');
    } else {
      bikes[index] = bike;
      log.d(SDLogger.DB, 'Updated bike: ${bike.name}');
    }
    state = bikes;
    _writeBikes(state);
  }

  void deleteBike(BikeState bike) {
    state.removeWhere((element) => element.id == bike.id);
    log.i(SDLogger.DB, 'Deleted bike: ${bike.name}');
    _writeBikes(state);
  }

  BikeState? getBike(String id) {
    try {
      return state.firstWhere((element) => element.id == id);
    } catch (e) {
      log.d(SDLogger.DB, 'No bike found with ID: $id');
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
class SettingsDB extends _$SettingsDB {
  @override
  SettingsModel build() {
    _readSettings().then((settings) => state = settings);
    return const SettingsModel();
  }

  void save(SettingsModel settings) {
    _settingsFile.then((file) => file.writeAsString(jsonEncode(settings)));
    log.d(SDLogger.DB, 'Saved settings: $settings');
    state = settings;
  }
}
