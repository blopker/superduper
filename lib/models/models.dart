import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superduper/models/names.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum BikeRegion {
  @JsonValue(200)
  us('US'),
  @JsonValue(201)
  eu('EU');

  const BikeRegion(this.value);
  final String value;
}

enum SDBluetoothConnectionState {
  disconnected,
  connected,
  connecting,
  disconnecting
}

@freezed
abstract class BikeState with _$BikeState {
  const BikeState._();
  @Assert('mode <= 7')
  @Assert('mode >= 0')
  @Assert('assist >= 0')
  @Assert('assist <= 4')
  const factory BikeState(
      {required String id,
      required int mode,
      required bool light,
      required int assist}) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(mode: 0, light: false, assist: 0, id: id);
  }

  BikeState updateFromRawData(List<int> data) {
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    return copyWith(
        light: data[lightIdx] == 1,
        mode: data[modeIdx],
        assist: data[assistIdx]);
  }

  BikeRegion get currentRegion {
    if (mode > 3) {
      return BikeRegion.eu;
    }
    return BikeRegion.us;
  }

  String get viewMode {
    return "${(mode % 4) + 1}";
  }

  int get nextMode {
    var next = (mode + 1) % 4;
    if (currentRegion == BikeRegion.eu) {
      next += 4;
    }
    return next;
  }

  BikeState withRegion(BikeRegion region) {
    var next = mode % 4;
    if (region == BikeRegion.eu) {
      next += 4;
    }
    return copyWith(mode: next);
  }

  List<int> toWriteRawData() {
    return [0, 209, light ? 1 : 0, assist, mode, 0, 0, 0, 0, 0];
  }
}

@freezed
abstract class BikeSettings with _$BikeSettings {
  const BikeSettings._();
  @Assert('color >= 0')
  const factory BikeSettings({
    required String id,
    required int? lockedMode,
    required bool? lockedLight,
    required int? lockedAssist,
    required bool? active,
    required bool modeLock,
    required String name,
    required BikeRegion? region,
    @Default(0) int color,
  }) = _BikeSettings;

  factory BikeSettings.fromJson(Map<String, Object?> json) =>
      _$BikeSettingsFromJson(json);

  factory BikeSettings.defaultSettings(String id) {
    return BikeSettings(
      lockedMode: null,
      lockedLight: null,
      lockedAssist: null,
      id: id,
      active: null,
      modeLock: false,
      name: getName(seed: id),
      region: null,
      color: 0,
    );
  }

  bool needsBikeSync(BikeState state) {
    if (lockedMode != null && lockedMode != state.mode) {
      return true;
    }
    if (lockedLight != null && lockedLight != state.light) {
      return true;
    }
    if (lockedAssist != null && lockedAssist != state.assist) {
      return true;
    }
    if (region != null && region != state.currentRegion) {
      return true;
    }
    return false;
  }
}
