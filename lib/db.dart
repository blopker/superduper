import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'db.g.dart';

enum DBKey {
  bikes('bikes'),
  settings('settings');

  const DBKey(this.value);
  final String value;
}

enum Settings {
  currentBike('currentBike');

  const Settings(this.value);
  final String value;
}

@Riverpod(keepAlive: true)
Database database(DatabaseRef ref) {
  return Database(ref);
}

class Database {
  Database(this.ref);
  final Ref ref;

  Box<String?> db(DBKey key) {
    return Hive.box<String?>(key.value);
  }

  Box<String?> get bikesdb {
    return db(DBKey.bikes);
  }

  Box<String?> get settingsdb {
    return db(DBKey.settings);
  }

  BikeState? getBike(String id) {
    var data = getJson(bikesdb.get(id));
    if (data == null) {
      return null;
    }
    return BikeState.fromJson(data);
  }

  List<BikeState> get bikes {
    return bikesdb.keys.map((e) => getBike(e)).whereType<BikeState>().toList();
  }

  addBike(BikeState bike) {
    bikesdb.put(bike.id, jsonEncode(bike.toJson()));
  }

  Map<String, dynamic>? getJson(String? data) {
    if (data == null) {
      return null;
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  BikeState? get currentBike {
    var id = settingsdb.get(Settings.currentBike.value);
    if (id == null) {
      return null;
    }
    return getBike(id);
  }

  set currentBike(BikeState? bike) {
    if (bike == null) {
      settingsdb.put(Settings.currentBike.value, null);
      return;
    }
    if (!bikesdb.containsKey(bike.id)) {
      addBike(bike);
    }
    settingsdb.put(Settings.currentBike.value, bike.id);
  }

  Stream<BikeState?> watchCurrentBike() {
    return settingsdb.watch(key: Settings.currentBike.value).map((event) {
      return currentBike;
    });
  }
}

Future init() async {
  await Hive.initFlutter();
  for (var k in DBKey.values) {
    await Hive.openBox<String?>(k.value);
  }
}
