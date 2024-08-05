import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superduper/names.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum BikeRegion {
  // R,RX
  @JsonValue(200)
  us('US'),
  // S2
  @JsonValue(201)
  eu('EU');

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
  @Assert('color >= 0')
  @Assert('battery >= 0')
  @Assert('battery <= 100')
  @Assert('range >= 0')
  @Assert('speedMetric == "metric" || speedMetric == "imperial"')
  const factory BikeState(
      {required String id,
      required int mode,
      @Default(false) bool modeLocked,
      required bool light,
      @Default(false) bool lightLocked,
      required int assist,
      @Default(false) bool assistLocked,
      required String name,
      BikeRegion? region,
      @Default(false) bool modeLock,
      @Default(0) int color,
      @Default(0.0) double battery,
      @Default(0) int range,
      @Default('metric') String speedMetric
      }) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(
        id: id, mode: 0, light: false, assist: 0, name: getName(seed: id), battery: 0.0, range: 0);
  }

  BikeState updateFromData(List<int> data) {
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    final region = _guessRegion(data[modeIdx]);
    final newmode = _modeFromRead(data[modeIdx]);
    return copyWith(
        light: data[lightIdx] == 1,
        mode: newmode,
        assist: data[assistIdx],
        region: region);
  }

  BikeState updateRideFromData(List<int> data) {
    const cadenceIdx = 3;
    const rangeIdx = 8;
    final batteryPercentage = _batteryPercentage(data[rangeIdx]);
    return copyWith(battery: batteryPercentage, range: data[rangeIdx]);
  }

  BikeRegion _guessRegion(int mode) {
    if (region != null) {
      return region!;
    }
    if (mode > 3) {
      return BikeRegion.eu;
    }
    return BikeRegion.us;
  }

  int _modeToWrite() {
    if (region == BikeRegion.eu) {
      return mode + 4;
    }
    return mode;
  }

  int _modeFromRead(int newmode) {
    if (newmode > 3) {
      return newmode - 4;
    }
    return newmode;
  }

  String get viewMode {
    return (mode + 1).toString();
  }

  int get nextMode {
    return (mode + 1) % 4;
  }

  double _batteryPercentage(int range) {
    // All current Super73 max range is 60km
    double batteryPercentage = range / 60.0 * 100;
    return double.parse(batteryPercentage.toStringAsFixed(1));
  }

  List<int> toWriteData() {
    return [0, 209, light ? 1 : 0, assist, _modeToWrite(), 0, 0, 0, 0, 0];
  }
}
