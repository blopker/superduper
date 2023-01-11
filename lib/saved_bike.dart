import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/preferences.dart';
part 'saved_bike.freezed.dart';
part 'saved_bike.g.dart';

@freezed
class SavedBike with _$SavedBike {
  const SavedBike._();
  const factory SavedBike({
    required String id,
    @Default(false) bool selected,
    String? name,
  }) = _SavedBike;

  factory SavedBike.fromJson(Map<String, Object?> json) =>
      _$SavedBikeFromJson(json);
}

final currentBikeProvider = StateProvider<SavedBike?>((ref) {
  return null;
});

@riverpod
class SavedBikeList extends _$SavedBikeList {
  final prefKey = 'SavedBikeList';
  @override
  List<SavedBike> build() {
    load();
    return [];
  }

  Future<void> load() async {
    var json = await ref.read(prefProvider).getJson(prefKey) ?? {'list': []};
    var bikes =
        (json['list'] as List).map((e) => SavedBike.fromJson(e)).toList();
    state = bikes;
  }

  Future<void> save() async {
    var map = {'list': (state.map((e) => e.toJson())).toList()};
    await ref.read(prefProvider).setJson(prefKey, map);
  }

  void addBike(SavedBike bike) {
    if (state.any((element) => element.id == bike.id)) {
      return;
    }
    state = [...state, bike];
    save();
  }

  bool hasBike(String id) {
    return state.any((element) => element.id == id);
  }

  SavedBike selectBike(String id) {
    state = state.map((e) {
      return e.copyWith(selected: e.id == id ? true : false);
    }).toList();
    save();
    var b = state.firstWhere((element) => element.id == id);
    ref.read(currentBikeProvider.notifier).state = b;
    return b;
  }

  SavedBike? getCurrentBike() {
    try {
      return state.firstWhere((element) => element.selected);
    } catch (e) {
      return null;
    }
  }

  void unselect() {
    state = state.map((e) {
      return e.copyWith(selected: false);
    }).toList();
    save();
  }
}
