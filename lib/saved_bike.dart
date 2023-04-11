import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/db.dart';
import 'package:superduper/bike.dart';
part 'saved_bike.g.dart';

@riverpod
BikeState? currentBike(CurrentBikeRef ref) {
  var db = ref.watch(databaseProvider);
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
    var db = ref.watch(databaseProvider);
    var sub = db.bikesdb.watch().listen((event) {
      state = db.bikes;
    });
    ref.onDispose(() {
      sub.cancel();
    });
    return db.bikes;
  }

  bool hasBike(String id) {
    return state.any((element) => element.id == id);
  }

  BikeState selectBike(BikeState bike) {
    var db = ref.read(databaseProvider);
    db.currentBike = bike;
    return db.currentBike!;
  }

  void unselect() {
    var db = ref.read(databaseProvider);
    db.currentBike = null;
  }
}
