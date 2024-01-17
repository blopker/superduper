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

  BikeState updateFromData(List<int> data, List<int> data2, List<int> data3) {
    //data  SETTINGS	0x03	0x00
    //data2 RIDE	0x02	0x03
    //data3 MOTION	0x02
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    final region = _guessRegion(data[modeIdx]);
    final newmode = _modeFromRead(data[modeIdx]);
    final newBattery = calculateBattery(data2);
    final newSpeed = calculateSpeed(data3);
    return copyWith(
        light: data[lightIdx] == 1,
        mode: newmode,
        assist: data[assistIdx],
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
/*
  // get bikeBattery can return percentage.
  String get bikeBattery {

    BluetoothRepository().readCurrentState(id, [2,3]).then((List<int>? currentState) {
      if (currentState != null) {
        int range = currentState[8];

        // Convert the range to %
        double batteryPercentage = range / 60.0 * 100;
        batteryPercentage = double.parse(batteryPercentage.toStringAsFixed(1));

        print('$batteryPercentage %');
        return '$batteryPercentage %';
      }
    });
    // Default value if reading fails or if the data is not as expected
    return '0.0 %';
  }

  // get bikeBattery can return percentage.
  String get bikeSpeed {
    BluetoothRepository().readCurrentState(id, [2,1]).then((List<int>? currentState) {
      if (currentState != null) {
        int speed = currentState[2] + (currentState[3] * 256);

        // Convert the speed to km/h
        double speedKmH = speed / 100.0;

        print('$speedKmH km/h');
        return '$speedKmH km/h';
      }
    });
    // Default value if reading fails or if the data is not as expected
    return '0.0 km/h';
  }*/

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
