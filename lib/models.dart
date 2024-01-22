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
  @Assert('speedKM >= 0')
  @Assert('speedKM <= 100') //if you are going faster than 100km/h you are not on a bike
  @Assert('speedMI >= 0')
  @Assert('speedMI <= 100') //if you are going faster than 100mps you are not on a bike
  @Assert('range >= 0')
  @Assert('range <= 65')
  @Assert('battery >= 0')
  @Assert('battery <= 100')
  @Assert('voltage >= 0') //Your battery is dead
  @Assert('voltage <= 55') //Your battery is in danger of exploding
  @Assert('speedMetric == "metric" || speedMetric == "imperial"')
  @Assert('batteryMetric == "percent" || batteryMetric == "voltage"')
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
      required double speedKM,
      required double speedMI,
      required int range,
      required double battery,
      required double voltage,
      @Default(0) int color,
      @Default('metric') String speedMetric,
      @Default('percent') String batteryMetric}) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(
        id: id, mode: 0, light: false, assist: 0, name: getName(seed: id), speedKM: 0.0, speedMI: 0.0, range: 0, battery: 0.0, voltage: 0.0);
  }

  BikeState updateFromData(List<int> SETTINGS, List<int> RIDE, List<int> MOTION) {
    //SETTINGS	0x03	0x00
    //RIDE	    0x02	0x03
    //MOTION	  0x02  0x01
    return copyWith(
      light: SETTINGS[4] == 1,
      mode: _modeFromRead(SETTINGS[5]),
      assist: SETTINGS[2],
      region: _guessRegion(SETTINGS[5]),
      speedKM: _speedKM(MOTION),
      speedMI: _speedMI(MOTION),
      range: _currentRange(RIDE),
      battery: _batteryPercentage(RIDE),
      voltage: _batteryVoltage(RIDE),
    );
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
    //SETTINGS WRITE => 0x00,0xD1,LIGHT,ASSIST,MODE,ignored,ignored,ignored,ignored,ignored
    return [0, 209, light ? 1 : 0, assist, _modeToWrite(), 0, 0, 0, 0, 0];
  }

  double _speedKM(List<int> MOTION){
    int speed = MOTION[2] + (MOTION[3] * 256);
    // Convert the speed from metre/h to km/h
    double speedKmH = speed / 100.0;
    //print('$speedKmH km/h');
    return speedKmH;
  }

  double _speedMI(List<int> MOTION){
    int speed = MOTION[2] + (MOTION[3] * 256);
    // Convert the speed from metre/h to mph
    double speedMpH = speed / 100.0 * 0.621371;
    //print('$speedMpH mph');
    return double.parse(speedMpH.toStringAsFixed(1));
  }

  int _currentRange(List<int> RIDE){
    int range = RIDE[8];
    return range;
  }

  _batteryPercentage(List<int> RIDE){
    int range = _currentRange(RIDE);

    // All current Super73 max range is 60km
    double batteryPercentage = range / 60.0 * 100;
    batteryPercentage = double.parse(batteryPercentage.toStringAsFixed(1));
    //print('$batteryPercentage %');
    return batteryPercentage;
  }

  _batteryVoltage(List<int> RIDE){
    const double maxVoltage = 4.2;
    const double minVoltage = 3.0;
    //All current super73 are current 48V batteries with 13 cells
    const double cells = 13;
    // Calculate voltage using linear interpolation
    double voltage = (minVoltage + (maxVoltage - minVoltage) * (_batteryPercentage(RIDE) / 100.0)) * cells;
    // Round to two decimal places
    return double.parse(voltage.toStringAsFixed(2));
  }
}
