import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';

abstract final class LockedConfigurationPolicy {
  static BikeConfiguration effective({
    required BikeConfiguration observed,
    required RidePreferences preferences,
    required BikeRegion? preferredRegion,
  }) {
    return BikeConfiguration(
      light: preferences.keepLight ? preferences.desiredLight : observed.light,
      mode: preferences.keepMode ? preferences.desiredMode : observed.mode,
      assist: preferences.keepAssist
          ? preferences.desiredAssist
          : observed.assist,
      region: preferredRegion ?? observed.region,
    );
  }

  static bool lockedValuesMatch({
    required BikeConfiguration observed,
    required BikeConfiguration target,
    required RidePreferences preferences,
  }) {
    return (!preferences.keepLight || observed.light == target.light) &&
        (!preferences.keepMode || observed.mode == target.mode) &&
        (!preferences.keepAssist || observed.assist == target.assist);
  }

  static bool sameEnforcement(
    RidePreferences previous,
    RidePreferences next,
  ) {
    return previous.keepLight == next.keepLight &&
        (!next.keepLight || previous.desiredLight == next.desiredLight) &&
        previous.keepMode == next.keepMode &&
        (!next.keepMode || previous.desiredMode == next.desiredMode) &&
        previous.keepAssist == next.keepAssist &&
        (!next.keepAssist || previous.desiredAssist == next.desiredAssist);
  }

  static bool hasLockedSettings(RidePreferences preferences) {
    return preferences.keepLight ||
        preferences.keepMode ||
        preferences.keepAssist;
  }
}
