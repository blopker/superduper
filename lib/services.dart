import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:superduper/utils.dart';

final UUID_SECURITY_SERVICE =
    Uuid.parse("00002554-1212-efde-1523-785feabcd123");
final UUID_SECURITY_HASH = Uuid.parse("00002557-1212-efde-1523-785feabcd123");
final UUID_PRIVATE_KEY = Uuid.parse("00002555-1212-efde-1523-785feabcd123");
final UUID_PUBLIC_KEY = Uuid.parse("00002556-1212-efde-1523-785feabcd123");
final UUID_AUTH = Uuid.parse("00002558-1212-efde-1523-785feabcd123");
final UUID_DEVICE_INFORMATION_SERVICE =
    Uuid.parse("0000180a-0000-1000-8000-00805f9b34fb");
final UUID_NRF_VERSION_CHARACTERISTIC_UUID =
    Uuid.parse("00002a26-0000-1000-8000-00805f9b34fb");
final UUID_METRICS_SERVICE = Uuid.parse("00001554-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER_NOTIFIER =
    Uuid.parse("0000155e-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER_ID =
    Uuid.parse("00001564-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER =
    Uuid.parse("0000155f-1212-efde-1523-785feabcd123");
final UUID_INFO_SERVICE = Uuid.parse("180a");
// see https://nordicsemiconductor.github.io/Nordic-Thingy52-FW/documentation/firmware_architecture.html
final UUID_DEVICE_FIRMWARE_UPDATES = Uuid.parse('fe59');

class Service {
  final Uuid serviceId;
  static final InfoService = Service(UUID_INFO_SERVICE);
  static final MetricService = Service(UUID_METRICS_SERVICE);
  const Service(this.serviceId);
}

class BikeState {
  BikeState(this.config);
  List<int> config;
  final _lightIdx = 4;
  final _modeIdx = 5;
  final _assistIdx = 2;

  factory BikeState.defaultState() {
    return BikeState(strToLis('03000000000000000000'));
  }

  static isConfig(List<int> maybeConfig) {
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
