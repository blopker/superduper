import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/set_on_connect_policy.dart';
import 'package:superduper/src/domain/bike.dart';

void main() {
  const observed = BikeConfiguration(
    light: false,
    mode: 2,
    assist: 1,
    region: BikeRegion.us,
  );
  const settings = SetOnConnectSettings(
    lightEnabled: true,
    mode: 0,
    modeEnabled: false,
    assist: 4,
    assistEnabled: true,
  );

  test('effective configuration changes only enabled values', () {
    expect(
      SetOnConnectPolicy.effective(
        observed: observed,
        settings: settings,
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

  test('a disabled light is off in a complete Set on connect packet', () {
    const staleObserved = BikeConfiguration(
      light: true,
      mode: 2,
      assist: 1,
      region: BikeRegion.us,
    );
    const settings = SetOnConnectSettings(
      lightEnabled: false,
      mode: 3,
      modeEnabled: true,
      assist: 1,
      assistEnabled: false,
    );
    const target = BikeConfiguration(
      light: false,
      mode: 3,
      assist: 1,
      region: BikeRegion.us,
    );

    expect(
      SetOnConnectPolicy.effective(
        observed: staleObserved,
        settings: settings,
        preferredRegion: null,
      ),
      target,
    );
    expect(
      SetOnConnectPolicy.enabledValuesMatch(
        observed: staleObserved.copyWith(mode: 3),
        target: target,
        settings: settings,
      ),
      isTrue,
    );
  });

  test('matching ignores values that are not enabled', () {
    expect(
      SetOnConnectPolicy.enabledValuesMatch(
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
        settings: settings,
      ),
      isTrue,
    );
  });

  test('reports whether any Set on connect setting is enabled', () {
    expect(SetOnConnectPolicy.hasSettings(settings), isTrue);
    expect(
      SetOnConnectPolicy.hasSettings(const SetOnConnectSettings.defaults()),
      isFalse,
    );
  });
}
