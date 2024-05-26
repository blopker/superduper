import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models.dart';

part 'db.freezed.dart';
part 'db.g.dart';

@freezed
class SettingsModel with _$SettingsModel {
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

Future<File> _writeSettings(SettingsModel setting) async {
  debugPrint('Writing settings to file');
  final file = await _settingsFile;
  return file.writeAsString(jsonEncode(setting));
}

Future<File> _writeBikes(List<BikeState> bikes) async {
  debugPrint('Writing bikes to file');
  debugPrint(jsonEncode(bikes));
  final file = await _bikesFile;
  return file.writeAsString(jsonEncode(bikes));
}

Future<SettingsModel> _readSettings() async {
  try {
    final file = await _settingsFile;
    final contents = await file.readAsString();
    return SettingsModel.fromJson(jsonDecode(contents));
  } catch (e) {
    return const SettingsModel();
  }
}

Future<List<BikeState>> _readBikes() async {
  debugPrint('Reading bikes from file');
  try {
    final file = await _bikesFile;
    final contents = await file.readAsString();
    debugPrint('Read contents: $contents');
    final bikes = (jsonDecode(contents) as List)
        .map((e) => BikeState.fromJson(e as Map<String, Object?>))
        .toList();
    debugPrint('Read bikes: $bikes');
    return bikes;
  } catch (e) {
    debugPrint('Error reading bikes: $e');
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
    } else {
      bikes[index] = bike;
    }
    state = bikes;
    _writeBikes(state);
  }

  void deleteBike(BikeState bike) {
    ref.read(settingsDBProvider.notifier).currentBike = null;
    state.removeWhere((element) => element.id == bike.id);
    _writeBikes(state);
  }

  void selectBike(BikeState? bike) {
    if (bike != null) {
      saveBike(bike);
    }
    ref.read(settingsDBProvider.notifier).currentBike = bike;
  }

  BikeState? getBike(String id) {
    try {
      return state.firstWhere((element) => element.id == id);
    } catch (e) {
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

  set currentBike(BikeState? bike) {
    state = state.copyWith(currentBike: bike?.id);
    _writeSettings(state);
  }
}

@Riverpod(keepAlive: true)
BikeState? currentBike(CurrentBikeRef ref) {
  final settings = ref.watch(settingsDBProvider);
  final bikes = ref.watch(bikesDBProvider);
  BikeState? currentBike;
  try {
    currentBike =
        bikes.firstWhere((element) => element.id == settings.currentBike);
  } catch (e) {
    // No current bike
  }
  debugPrint('Current bike: $currentBike');
  return currentBike;
}

Future init() async {}
