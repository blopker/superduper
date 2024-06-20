// ignore_for_file: non_constant_identifier_names

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:superduper/utils.dart';

final UUID_SECURITY_SERVICE =
    Guid.fromString("00002554-1212-efde-1523-785feabcd123");
final UUID_SECURITY_HASH =
    Guid.fromString("00002557-1212-efde-1523-785feabcd123");
final UUID_PRIVATE_KEY =
    Guid.fromString("00002555-1212-efde-1523-785feabcd123");
final UUID_PUBLIC_KEY = Guid.fromString("00002556-1212-efde-1523-785feabcd123");
final UUID_AUTH = Guid.fromString("00002558-1212-efde-1523-785feabcd123");
final UUID_DEVICE_INFORMATION_SERVICE =
    Guid.fromString("0000180a-0000-1000-8000-00805f9b34fb");
final UUID_NRF_VERSION_CHARACTERISTIC_UUID =
    Guid.fromString("00002a26-0000-1000-8000-00805f9b34fb");
final UUID_METRICS_SERVICE =
    Guid.fromString("00001554-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER_NOTIFIER =
    Guid.fromString("0000155e-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER_ID =
    Guid.fromString("00001564-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER =
    Guid.fromString("0000155f-1212-efde-1523-785feabcd123");
final UUID_INFO_SERVICE = Guid.fromString("180a");
// see https://nordicsemiconductor.github.io/Nordic-Thingy52-FW/documentation/firmware_architecture.html
final UUID_DEVICE_FIRMWARE_UPDATES = Guid.fromString('fe59');

class StateData {
  StateData(this.config);
  List<int> config;
  final _lightIdx = 4;
  final _modeIdx = 5;
  final _assistIdx = 2;

  factory StateData.defaultState() {
    return StateData(strToLis('03000000000000000000'));
  }

  static isValid(List<int> maybeConfig) {
    // Read configs start with 3.
    return maybeConfig[0] == 3;
  }

  bool get lightOn {
    return light == 1;
  }

  int get light {
    return config[_lightIdx];
  }

  set light(int on) {
    config[_lightIdx] = on;
  }

  int get mode {
    return config[_modeIdx];
  }

  set mode(int level) {
    config[_modeIdx] = level;
  }

  int get assist {
    return config[_assistIdx];
  }

  set assist(int level) {
    config[_assistIdx] = level;
  }

  List<int> write() {
    return [0, 209, light, assist, mode, 0, 0, 0, 0, 0];
  }
}
