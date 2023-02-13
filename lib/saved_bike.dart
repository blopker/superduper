import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/db.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/repository.dart';
part 'saved_bike.g.dart';

@riverpod
BikeState? currentBike(CurrentBikeRef ref) {
  var db = ref.watch(dbProvider);
  var sub = db.watchCurrentBike().listen((event) {
    debugPrint('currentBike: $event');
    ref.state = db.currentBike;
  });
  ref.onDispose(() {
    sub.cancel();
  });
  return db.currentBike;
}

@riverpod
class SavedBikeList extends _$SavedBikeList {
  @override
  List<BikeState> build() {
    var db = ref.watch(dbProvider);
    var sub = db.bikesdb.watch().listen((event) {
      state = db.bikes;
    });
    ref.onDispose(() {
      sub.cancel();
    });
    return db.bikes;
  }

  void addBike(BikeState bike) {
    var db = ref.read(dbProvider);
    db.setBike(bike);
    state = db.bikes;
  }

  bool hasBike(String id) {
    var db = ref.watch(dbProvider);
    return db.getBike(id) != null;
  }

  BikeState selectBike(String id) {
    var db = ref.read(dbProvider);
    var bike = db.getBike(id);
    if (bike == null) {
      throw Exception('Bike not found');
    }
    db.currentBike = bike;
    var connectionHandler = ref.read(connectionHandlerProvider);
    connectionHandler.connect(id);
    return db.currentBike!;
  }

  BikeState? getCurrentBike() {
    return ref.read(dbProvider).currentBike;
  }

  void unselect() {
    var db = ref.read(dbProvider);
    db.currentBike = null;
    var connectionHandler = ref.read(connectionHandlerProvider);
    connectionHandler.disconect();
  }
}
