import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';

void main() {
  group('decodeState', () {
    test('decodes US boundaries', () {
      expect(
        BikeProtocol.decodeState([0, 0, 0, 0, 0, 0]),
        const BikeConfiguration(
          light: false,
          mode: 0,
          assist: 0,
          region: BikeRegion.us,
        ),
      );
      expect(
        BikeProtocol.decodeState([0, 0, 4, 0, 1, 3, 99]),
        const BikeConfiguration(
          light: true,
          mode: 3,
          assist: 4,
          region: BikeRegion.us,
        ),
      );
    });

    test('decodes EU wire modes four through seven', () {
      for (var wireMode = 4; wireMode <= 7; wireMode++) {
        expect(
          BikeProtocol.decodeState([0, 0, 2, 0, 1, wireMode]),
          BikeConfiguration(
            light: true,
            mode: wireMode - 4,
            assist: 2,
            region: BikeRegion.eu,
          ),
        );
      }
    });

    test('rejects short and malformed frames', () {
      expect(
        () => BikeProtocol.decodeState([0, 1]),
        throwsA(isA<ShortBikeFrame>()),
      );
      expect(
        () => BikeProtocol.decodeState([0, 0, 0, 0, -1, 0]),
        throwsA(isA<MalformedBikeFrame>()),
      );
    });

    test('rejects unsupported field values instead of clamping', () {
      expect(
        () => BikeProtocol.decodeState([0, 0, 5, 0, 0, 0]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
      expect(
        () => BikeProtocol.decodeState([0, 0, 0, 0, 2, 0]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
      expect(
        () => BikeProtocol.decodeState([0, 0, 0, 0, 0, 8]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
    });
  });

  group('encodeConfiguration', () {
    test('encodes complete US and EU payloads', () {
      expect(
        BikeProtocol.encodeConfiguration(
          const BikeConfiguration(
            light: true,
            mode: 3,
            assist: 4,
            region: BikeRegion.us,
          ),
        ),
        [0, 0xd1, 1, 4, 3, 0, 0, 0, 0, 0],
      );
      expect(
        BikeProtocol.encodeConfiguration(
          const BikeConfiguration(
            light: false,
            mode: 0,
            assist: 0,
            region: BikeRegion.eu,
          ),
        ),
        [0, 0xd1, 0, 0, 4, 0, 0, 0, 0, 0],
      );
    });

    test('rejects invalid configuration ranges', () {
      expect(
        () => BikeProtocol.encodeConfiguration(
          const BikeConfiguration(
            light: false,
            mode: 4,
            assist: 0,
            region: BikeRegion.us,
          ),
        ),
        throwsRangeError,
      );
      expect(
        () => BikeProtocol.encodeConfiguration(
          const BikeConfiguration(
            light: false,
            mode: 0,
            assist: -1,
            region: BikeRegion.us,
          ),
        ),
        throwsRangeError,
      );
    });
  });
}
