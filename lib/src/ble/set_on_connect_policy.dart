import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';

abstract final class SetOnConnectPolicy {
  static BikeConfiguration effective({
    required BikeConfiguration observed,
    required SetOnConnectSettings settings,
    required BikeRegion? preferredRegion,
  }) {
    return BikeConfiguration(
      // The controller remembers its previous light bit even though the
      // physical light starts off. A complete startup write must not replay
      // that stale bit when Set on connect is disabled for Light.
      light: settings.lightEnabled,
      mode: settings.modeEnabled ? settings.mode : observed.mode,
      assist: settings.assistEnabled ? settings.assist : observed.assist,
      region: preferredRegion ?? observed.region,
    );
  }

  static bool enabledValuesMatch({
    required BikeConfiguration observed,
    required BikeConfiguration target,
    required SetOnConnectSettings settings,
  }) {
    // That retained light bit also survives the write, so it cannot confirm
    // an option the user left disabled.
    return (!settings.lightEnabled || observed.light == target.light) &&
        (!settings.modeEnabled || observed.mode == target.mode) &&
        (!settings.assistEnabled || observed.assist == target.assist);
  }

  static bool hasSettings(SetOnConnectSettings settings) {
    return settings.lightEnabled ||
        settings.modeEnabled ||
        settings.assistEnabled;
  }
}
