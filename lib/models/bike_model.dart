import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superduper/models/bike_region.dart';
import 'package:superduper/utils/names.dart';

part 'bike_model.freezed.dart';
part 'bike_model.g.dart';

// Must be an abstract class to work with new freezed version
@freezed
abstract class BikeModel with _$BikeModel {
  const BikeModel._();

  @Assert('mode <= 3')
  @Assert('mode >= 0')
  @Assert('assist >= 0')
  @Assert('assist <= 4')
  const factory BikeModel({
    required String id,
    required String name,
    required String bluetoothAddress,
    @Default(false) bool isActive,
    @Default(0) int mode,
    @Default(false) bool modeLocked,
    @Default(false) bool light,
    @Default(false) bool lightLocked,
    @Default(0) int assist,
    @Default(false) bool assistLocked,
    @Default(false) bool backgroundLock,
    BikeRegion? region,
    @Default(0) int color,
    @Default(false) bool isConnected,
  }) = _BikeModel;

  factory BikeModel.defaultBike(String id, String bluetoothAddress) {
    return BikeModel(
      id: id,
      name: getName(seed: id),
      bluetoothAddress: bluetoothAddress,
    );
  }

  factory BikeModel.fromJson(Map<String, Object?> json) =>
      _$BikeModelFromJson(json);

  /// Current mode displayed to the user (1-indexed)
  String get viewMode {
    return "${mode + 1}";
  }

  /// Next mode index when cycling through modes
  int get nextMode {
    return (mode + 1) % 4;
  }

  /// Convert model data to the format needed to write to the bike
  List<int> toWriteData() {
    final modeToWrite = region == BikeRegion.eu ? mode + 4 : mode;
    return [0, 209, light ? 1 : 0, assist, modeToWrite, 0, 0, 0, 0, 0];
  }

  /// Updates this model with data received from the bike
  BikeModel updateFromData(List<int> data) {
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;

    final newRegion = _guessRegion(data[modeIdx]);
    final newMode = _modeFromRead(data[modeIdx]);

    return copyWith(
      light: data[lightIdx] == 1,
      mode: newMode,
      assist: data[assistIdx],
      region: newRegion,
    );
  }

  /// Guess region based on mode value
  BikeRegion _guessRegion(int mode) {
    if (region != null) {
      return region!;
    }
    if (mode > 3) {
      return BikeRegion.eu;
    }
    return BikeRegion.us;
  }

  /// Convert received mode value to internal mode value
  int _modeFromRead(int newMode) {
    if (newMode > 3) {
      return newMode - 4;
    }
    return newMode;
  }
}
