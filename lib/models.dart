import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superduper/names.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum BikeRegion {
  // R,RX
  @JsonValue(200)
  us('us'),
  // S2
  @JsonValue(201)
  eu('eu');

  const BikeRegion(this.value);
  final String value;
}

@freezed
class BikeState with _$BikeState {
  const BikeState._();
  @Assert('mode <= 3')
  @Assert('mode >= 0')
  @Assert('assist >= 0')
  @Assert('assist <= 4')
  const factory BikeState({
    required String id,
    required int mode,
    required bool light,
    required int assist,
    required String name,
    BikeRegion? region,
    @Default(false) bool modeLock,
    @Default(false) bool selected,
  }) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(
        id: id, mode: 0, light: false, assist: 0, name: getName(seed: id));
  }

  BikeState updateFromData(List<int> data) {
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    return copyWith(
        light: data[lightIdx] == 1,
        mode: data[modeIdx],
        assist: data[assistIdx]);
  }

  get viewMode {
    return (mode + 1).toString();
  }

  List<int> toWriteData() {
    return [0, 209, light ? 1 : 0, assist, mode, 0, 0, 0, 0, 0];
  }
}
