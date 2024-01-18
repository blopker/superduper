import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superduper/names.dart';
import 'package:superduper/repository.dart';

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
      @Default(false) bool selected,
      required double speed,
      required double battery,
      @Default(0) int color}) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(
        id: id, mode: 0, light: false, assist: 0, name: getName(seed: id), speed: 0.0 , battery: 0.0);
  }

  BikeState updateFromData(List<int> SETTINGS, List<int> RIDE, List<int> MOTION) {
    //SETTINGS	0x03	0x00
    //RIDE	    0x02	0x03
    //MOTION	  0x02  0x01
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    final region = _guessRegion(SETTINGS[modeIdx]);
    final newmode = _modeFromRead(SETTINGS[modeIdx]);
    final newBattery = calculateBattery(RIDE);
    final newSpeed = calculateSpeed(MOTION);
    return copyWith(
        light: SETTINGS[lightIdx] == 1,
        mode: newmode,
        assist: SETTINGS[assistIdx],
        region: region,
        battery: newBattery,
        speed: newSpeed);
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

  List<int> toWriteData() {
    return [0, 209, light ? 1 : 0, assist, _modeToWrite(), 0, 0, 0, 0, 0];
  }

  calculateBattery(List<int> data2) {
    int range = data2[8];

    // Convert the range to %
    double batteryPercentage = range / 60.0 * 100;
    batteryPercentage = double.parse(batteryPercentage.toStringAsFixed(1));

    //print('$batteryPercentage %');
    return batteryPercentage;
    }

  calculateSpeed(List<int> data3) {
    int speed = data3[2] + (data3[3] * 256);

    // Convert the speed to km/h
    double speedKmH = speed / 100.0;

    //print('$speedKmH km/h');
    return speedKmH;
    }
}
