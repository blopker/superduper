import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';

void main() {
  group('module serial', () {
    test('decodes the eight-byte COMODULE manufacturer payload', () {
      expect(
        BikeProtocol.decodeModuleSerial(const [
          0x00,
          0x11,
          0x22,
          0x33,
          0xaa,
          0xbb,
          0xcc,
          0xdd,
        ]),
        '00112233aabbccdd',
      );
    });

    test('ignores missing or malformed manufacturer payloads', () {
      expect(BikeProtocol.decodeModuleSerial(null), isNull);
      expect(BikeProtocol.decodeModuleSerial(const [0, 1]), isNull);
      expect(
        BikeProtocol.decodeModuleSerial(const [0, 1, 2, 3, 4, 5, 6, 256]),
        isNull,
      );
    });
  });

  group('protocol identification', () {
    test('uses only complete documented advertised names', () {
      expect(
        BikeProtocolVersion.fromAdvertisedName('SUPER73'),
        BikeProtocolVersion.v1,
      );
      expect(
        BikeProtocolVersion.fromAdvertisedName('S73 FTEX'),
        BikeProtocolVersion.v2,
      );
      expect(BikeProtocolVersion.fromAdvertisedName('SUPER73-X'), isNull);
      expect(BikeProtocolVersion.fromAdvertisedName(' SUPER73 '), isNull);
    });
  });

  group('authentication', () {
    test('computes SHA1 of the exact challenge followed by the key', () {
      final challenge = List<int>.generate(20, (index) => index);

      expect(
        BikeProtocol.authenticationResponse(
          challenge: challenge,
          key: BikeProtocol.defaultAuthenticationKey,
        ),
        [
          0x13,
          0x44,
          0xd4,
          0x9a,
          0x08,
          0xc2,
          0x0a,
          0x39,
          0x2a,
          0x05,
          0xf6,
          0x0e,
          0x0c,
          0x26,
          0x9d,
          0x94,
          0xd3,
          0x86,
          0x48,
          0xec,
        ],
      );
    });

    test('rejects malformed challenge and key lengths', () {
      expect(
        () => BikeProtocol.authenticationResponse(
          challenge: const [1],
          key: BikeProtocol.defaultAuthenticationKey,
        ),
        throwsA(isA<InvalidAuthenticationValue>()),
      );
      expect(
        () => BikeProtocol.authenticationResponse(
          challenge: List<int>.filled(20, 1),
          key: const [1],
        ),
        throwsA(isA<InvalidAuthenticationValue>()),
      );
    });
  });

  group('decodeV1State', () {
    test('decodes US boundaries', () {
      expect(
        BikeProtocol.v1.decodeState([3, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        const BikeConfiguration(
          light: false,
          mode: 0,
          assist: 0,
          region: BikeRegion.us,
        ),
      );
      expect(
        BikeProtocol.v1.decodeState([3, 0, 4, 0, 1, 3, 0, 0, 0, 0]),
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
          BikeProtocol.v1.decodeState([3, 0, 2, 0, 1, wireMode, 0, 0, 0, 0]),
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
        () => BikeProtocol.v1.decodeState([0, 1]),
        throwsA(isA<ShortBikeFrame>()),
      );
      expect(
        () => BikeProtocol.v1.decodeState([3, 0, 0, 0, -1, 0, 0, 0, 0, 0]),
        throwsA(isA<MalformedBikeFrame>()),
      );
    });

    test('rejects unsupported field values instead of clamping', () {
      expect(
        () => BikeProtocol.v1.decodeState([3, 0, 5, 0, 0, 0, 0, 0, 0, 0]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
      expect(
        () => BikeProtocol.v1.decodeState([3, 0, 0, 0, 2, 0, 0, 0, 0, 0]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
      expect(
        () => BikeProtocol.v1.decodeState([3, 0, 0, 0, 0, 8, 0, 0, 0, 0]),
        throwsA(isA<UnsupportedBikeValue>()),
      );
      expect(
        () => BikeProtocol.v1.decodeState([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        throwsA(isA<UnexpectedBikePacket>()),
      );
    });
  });

  group('decodeV2State', () {
    test('combines validated D0 and D9 history records', () {
      expect(
        BikeProtocol.v2.decodeState(
          d0: const [0, 0xd0, 3, 0, 1, 88, 0, 0, 0, 0],
          d9: const [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
          region: BikeRegion.eu,
        ),
        const BikeConfiguration(
          light: true,
          mode: 2,
          assist: 3,
          region: BikeRegion.eu,
        ),
      );
    });

    test('rejects mismatched records and unsupported control values', () {
      expect(
        () => BikeProtocol.v2.decodeState(
          d0: const [0, 0xd1, 3, 0, 1, 88, 0, 0, 0, 0],
          d9: const [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
          region: BikeRegion.us,
        ),
        throwsA(isA<UnexpectedBikePacket>()),
      );
      expect(
        () => BikeProtocol.v2.decodeState(
          d0: const [0, 0xd0, 5, 0, 1, 88, 0, 0, 0, 0],
          d9: const [0, 0xd9, 0, 0, 0, 4, 0, 0, 0, 0],
          region: BikeRegion.us,
        ),
        throwsA(isA<UnsupportedBikeValue>()),
      );
    });
  });

  group('decodeTelemetry', () {
    test('V1 reports every field carried by the state frame', () {
      expect(
        BikeProtocol.v1.decodeTelemetry(
          const [3, 0, 4, 0, 1, 3, 0, 0, 0, 0],
        ),
        isA<BikeControlPatch>()
            .having((patch) => patch.light, 'light', isTrue)
            .having((patch) => patch.mode, 'mode', 3)
            .having((patch) => patch.assist, 'assist', 4)
            .having((patch) => patch.region, 'region', BikeRegion.us),
      );
    });

    test('V2 D0 reports only light and assist', () {
      expect(
        BikeProtocol.v2.decodeTelemetry(
          const [0, 0xd0, 4, 0, 1, 0, 0, 0, 0, 0],
        ),
        isA<BikeControlPatch>()
            .having((patch) => patch.light, 'light', isTrue)
            .having((patch) => patch.assist, 'assist', 4),
      );
    });

    test('V2 D9 reports only mode and cannot confirm light', () {
      expect(
        BikeProtocol.v2.decodeTelemetry(
          const [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
        ),
        isA<BikeControlPatch>().having((patch) => patch.mode, 'mode', 3),
      );
    });
  });

  group('decodeOdometerMeters', () {
    test('decodes the protocol-specific record as a little-endian u32', () {
      expect(
        BikeProtocol.v1.decodeOdometer(
          const [2, 2, 0, 0, 0, 0, 0x78, 0x56, 0x34, 0x12],
        ),
        0x12345678,
      );
      expect(
        BikeProtocol.v2.decodeOdometer(
          const [0, 0xd0, 0, 0, 0, 0, 0xef, 0xcd, 0xab, 0x90],
        ),
        0x90abcdef,
      );
    });

    test('rejects a record from the wrong protocol', () {
      expect(
        () => BikeProtocol.v1.decodeOdometer(
          const [0, 0xd0, 0, 0, 0, 0, 1, 0, 0, 0],
        ),
        throwsA(isA<UnexpectedBikePacket>()),
      );
    });
  });

  group('decodeVersionInfo', () {
    test('combines Device Information with full FCFC and FAFA records', () {
      expect(
        BikeProtocol.decodeVersionInfo(
          hardwareRevision: 'v3.3.0',
          firmwareRevision: '250426',
          softwareRevision: '250426',
          fcfc: const [0xfc, 0xfc, 0x01, 0x23, 0x45, 0x96, 0x01, 0x08, 0, 1],
          fafa: const [
            0xfa,
            0xfa,
            0x12,
            0x34,
            0x56,
            0x78,
            0x9a,
            0xbc,
            0xde,
            0xf0,
          ],
        ),
        const BikeVersionInfo(
          hardwareRevision: 'v3.3.0',
          firmwareRevision: '250426',
          softwareRevision: '250426',
          stmFirmwareVersion: 0x012345,
          controllerVariant: 0x0196,
          bootloaderHandoff: 8,
          motorControllerVersion: 0x12345678,
          bmsVersion: 0x9abcdef0,
        ),
      );
    });

    test('rejects incomplete strings and mismatched history records', () {
      const fcfc = [0xfc, 0xfc, 0, 0, 1, 0, 1, 8, 0, 1];
      const fafa = [0xfa, 0xfa, 0, 0, 0, 1, 0, 0, 0, 2];

      expect(
        () => BikeProtocol.decodeVersionInfo(
          hardwareRevision: '',
          firmwareRevision: '250426',
          softwareRevision: '250426',
          fcfc: fcfc,
          fafa: fafa,
        ),
        throwsA(isA<MalformedBikeFrame>()),
      );
      expect(
        () => BikeProtocol.decodeVersionInfo(
          hardwareRevision: 'v3.3.0',
          firmwareRevision: '250426',
          softwareRevision: '250426',
          fcfc: const [0xfa, 0xfa, 0, 0, 1, 0, 1, 8, 0, 1],
          fafa: fafa,
        ),
        throwsA(isA<UnexpectedBikePacket>()),
      );
    });
  });

  group('encodeConfiguration', () {
    test('encodes complete US and EU payloads', () {
      expect(
        BikeProtocol.v1.encodeConfiguration(
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
        BikeProtocol.v1.encodeConfiguration(
          const BikeConfiguration(
            light: false,
            mode: 0,
            assist: 0,
            region: BikeRegion.eu,
          ),
        ),
        [0, 0xd1, 0, 0, 4, 0, 0, 0, 0, 0],
      );
      expect(
        BikeProtocol.v2.encodeConfiguration(
          const BikeConfiguration(
            light: true,
            mode: 2,
            assist: 3,
            region: BikeRegion.eu,
          ),
        ),
        [0, 0xc1, 1, 3, 2, 0, 0, 0, 0, 0],
      );
    });

    test('rejects invalid configuration ranges', () {
      expect(
        () => BikeProtocol.v1.encodeConfiguration(
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
        () => BikeProtocol.v2.encodeConfiguration(
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
