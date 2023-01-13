import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/preferences.dart';
import 'package:superduper/bike.dart';
part 'saved_bike.g.dart';

@riverpod
BikeState? currentBike(CurrentBikeRef ref) {
  try {
    return ref
        .watch(savedBikeListProvider)
        .firstWhere((element) => element.selected);
  } catch (e) {
    return null;
  }
}

@riverpod
class SavedBikeList extends _$SavedBikeList {
  final prefKey = 'SavedBikeList';
  ProviderSubscription? psub;
  @override
  List<BikeState> build() {
    load();
    return [];
  }

  Future<void> load() async {
    var json = await ref.read(prefProvider).getJson(prefKey) ?? {'list': []};
    var bikes =
        (json['list'] as List).map((e) => BikeState.fromJson(e)).toList();
    state = bikes;
    var bike = getCurrentBike();
    if (bike != null) {
      selectBike(bike.id);
    }
  }

  Future<void> save() async {
    var map = {'list': (state.map((e) => e.toJson())).toList()};
    // debugPrint('save $map');
    await ref.read(prefProvider).setJson(prefKey, map);
  }

  void addBike(BikeState bike) {
    if (state.any((element) => element.id == bike.id)) {
      return;
    }
    state = [...state, bike];
    save();
  }

  bool hasBike(String id) {
    return state.any((element) => element.id == id);
  }

  BikeState selectBike(String id) {
    state = state.map((e) {
      return e.copyWith(selected: e.id == id ? true : false);
    }).toList();
    save();
    psub?.close();
    psub = ref.listen<BikeState>(bikeProvider(id), (previous, next) {
      state = state.map<BikeState>((e) {
        if (e.id == next.id) {
          return next.copyWith(selected: true);
        }
        return e;
      }).toList();
      save();
    });
    return state.firstWhere((element) => element.selected);
  }

  BikeState? getCurrentBike() {
    try {
      return state.firstWhere((element) => element.selected);
    } catch (e) {
      return null;
    }
  }

  void unselect() {
    psub?.close();
    state = state.map((e) {
      return e.copyWith(selected: false);
    }).toList();
    save();
  }
}
