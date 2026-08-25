import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/locked_configuration_policy.dart';
import 'package:superduper/src/domain/bike.dart';

void main() {
  const observed = BikeConfiguration(
    light: false,
    mode: 2,
    assist: 1,
    region: BikeRegion.us,
  );
  const preferences = RidePreferences(
    desiredLight: true,
    desiredMode: 0,
    desiredAssist: 4,
    keepLight: true,
    keepMode: false,
    keepAssist: true,
  );

  test('effective configuration changes only locked values', () {
    expect(
      LockedConfigurationPolicy.effective(
        observed: observed,
        preferences: preferences,
        preferredRegion: BikeRegion.eu,
      ),
      const BikeConfiguration(
        light: true,
        mode: 2,
        assist: 4,
        region: BikeRegion.eu,
      ),
    );
  });

  test('matching ignores values that are not locked', () {
    expect(
      LockedConfigurationPolicy.lockedValuesMatch(
        observed: const BikeConfiguration(
          light: true,
          mode: 3,
          assist: 4,
          region: BikeRegion.us,
        ),
        target: const BikeConfiguration(
          light: true,
          mode: 0,
          assist: 4,
          region: BikeRegion.eu,
        ),
        preferences: preferences,
      ),
      isTrue,
    );
  });

  test('enforcement equality ignores an unlocked desired value', () {
    expect(
      LockedConfigurationPolicy.sameEnforcement(
        preferences,
        preferences.copyWith(desiredMode: 3),
      ),
      isTrue,
    );
    expect(
      LockedConfigurationPolicy.sameEnforcement(
        preferences,
        preferences.copyWith(desiredAssist: 3),
      ),
      isFalse,
    );
  });
}
