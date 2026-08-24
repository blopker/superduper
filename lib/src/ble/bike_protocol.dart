import 'package:crypto/crypto.dart';
import 'package:superduper/src/domain/bike.dart';

enum BikeProtocolVersion {
  v1,
  v2;

  static BikeProtocolVersion? fromAdvertisedName(String name) {
    return switch (name.trim()) {
      'SUPER73' => BikeProtocolVersion.v1,
      'S73 FTEX' => BikeProtocolVersion.v2,
      _ => null,
    };
  }

  static BikeProtocolVersion? fromFirmwareRevision(String revision) {
    return switch (revision.trim()) {
      '221122' => BikeProtocolVersion.v1,
      '250426' => BikeProtocolVersion.v2,
      _ => null,
    };
  }
}

abstract final class BikeGatt {
  static const manufacturerId = 0x020f;

  static const metricsService = '00001554-1212-efde-1523-785feabcd123';
  static const telemetry = '0000155e-1212-efde-1523-785feabcd123';
  static const stateRegister = '0000155f-1212-efde-1523-785feabcd123';
  static const registerSelector = '00001564-1212-efde-1523-785feabcd123';

  static const authenticationService = '00002554-1212-efde-1523-785feabcd123';
  static const authenticationKeyUpdate = '00002555-1212-efde-1523-785feabcd123';
  static const authenticationChallenge = '00002556-1212-efde-1523-785feabcd123';
  static const authenticationResponse = '00002557-1212-efde-1523-785feabcd123';
  static const authenticationState = '00002558-1212-efde-1523-785feabcd123';

  static const deviceInformationService =
      '0000180a-0000-1000-8000-00805f9b34fb';
  static const firmwareRevision = '00002a26-0000-1000-8000-00805f9b34fb';
  static const hardwareRevision = '00002a27-0000-1000-8000-00805f9b34fb';
  static const softwareRevision = '00002a28-0000-1000-8000-00805f9b34fb';

  static const v1StateSelector = <int>[0x03, 0x00];
  static const v2ControlSelector = <int>[0x00, 0xd0];
  static const v2ModeSelector = <int>[0x00, 0xd9];
  static const displayVersionSelector = <int>[0xfc, 0xfc];
  static const componentVersionsSelector = <int>[0xfa, 0xfa];
}

final class BikeConfiguration {
  const BikeConfiguration({
    required this.light,
    required this.mode,
    required this.assist,
    required this.region,
  });

  final bool light;
  final int mode;
  final int assist;
  final BikeRegion region;

  BikeConfiguration copyWith({
    bool? light,
    int? mode,
    int? assist,
    BikeRegion? region,
  }) {
    return BikeConfiguration(
      light: light ?? this.light,
      mode: mode ?? this.mode,
      assist: assist ?? this.assist,
      region: region ?? this.region,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BikeConfiguration &&
        light == other.light &&
        mode == other.mode &&
        assist == other.assist &&
        region == other.region;
  }

  @override
  int get hashCode => Object.hash(light, mode, assist, region);
}

sealed class BikeProtocolFailure implements Exception {
  const BikeProtocolFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ShortBikeFrame extends BikeProtocolFailure {
  const ShortBikeFrame(int length)
    : super('Bike packet is too short: $length bytes.');
}

final class MalformedBikeFrame extends BikeProtocolFailure {
  const MalformedBikeFrame(String field)
    : super('Bike packet has a malformed $field value.');
}

final class UnsupportedBikeValue extends BikeProtocolFailure {
  const UnsupportedBikeValue(String field, int value)
    : super('Bike packet has unsupported $field value $value.');
}

final class UnexpectedBikePacket extends BikeProtocolFailure {
  const UnexpectedBikePacket({required String expected, required String actual})
    : super('Expected bike packet $expected, received $actual.');
}

final class InvalidAuthenticationValue extends BikeProtocolFailure {
  const InvalidAuthenticationValue(super.message);
}

abstract final class BikeProtocol {
  static const defaultAuthenticationKey = <int>[
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
  ];

  static List<int> authenticationResponse({
    required List<int> challenge,
    required List<int> key,
  }) {
    _validateAuthenticationBytes(challenge, 'challenge');
    _validateAuthenticationBytes(key, 'key');
    return List.unmodifiable(sha1.convert([...challenge, ...key]).bytes);
  }

  static String? decodeModuleSerial(List<int>? manufacturerData) {
    if (manufacturerData == null || manufacturerData.length != 8) {
      return null;
    }
    final serial = StringBuffer();
    for (final byte in manufacturerData) {
      if (byte < 0 || byte > 255) {
        return null;
      }
      serial.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return serial.toString();
  }

  static BikeConfiguration decodeV1State(List<int> packet) {
    _validatePacket(packet, BikeGatt.v1StateSelector);
    final assist = packet[2];
    final lightByte = packet[4];
    final wireMode = packet[5];
    _validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: wireMode,
      maximumMode: 7,
    );
    return BikeConfiguration(
      light: lightByte == 1,
      mode: wireMode % 4,
      assist: assist,
      region: wireMode >= 4 ? BikeRegion.eu : BikeRegion.us,
    );
  }

  static BikeConfiguration decodeV2State({
    required List<int> d0,
    required List<int> d9,
    required BikeRegion region,
  }) {
    _validatePacket(d0, BikeGatt.v2ControlSelector);
    _validatePacket(d9, BikeGatt.v2ModeSelector);
    final assist = d0[2];
    final lightByte = d0[4];
    final mode = d9[5];
    _validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: mode,
      maximumMode: 3,
    );
    return BikeConfiguration(
      light: lightByte == 1,
      mode: mode,
      assist: assist,
      region: region,
    );
  }

  static BikeConfiguration? applyTelemetry({
    required BikeProtocolVersion version,
    required List<int> packet,
    required BikeConfiguration? current,
  }) {
    if (packet.length < 2) {
      throw ShortBikeFrame(packet.length);
    }
    final packetId = (packet[0] << 8) | packet[1];
    return switch ((version, packetId)) {
      (BikeProtocolVersion.v1, 0x0300) => decodeV1State(packet),
      (BikeProtocolVersion.v2, 0x00d0) when current != null => _applyV2D0(
        packet,
        current,
      ),
      (BikeProtocolVersion.v2, 0x00d9) when current != null => _applyV2D9(
        packet,
        current,
      ),
      _ => null,
    };
  }

  static BikeVersionInfo decodeVersionInfo({
    required String hardwareRevision,
    required String firmwareRevision,
    required String softwareRevision,
    required List<int> fcfc,
    required List<int> fafa,
  }) {
    final hardware = hardwareRevision.trim();
    final firmware = firmwareRevision.trim();
    final software = softwareRevision.trim();
    if (hardware.isEmpty || firmware.isEmpty || software.isEmpty) {
      throw const MalformedBikeFrame('version string');
    }
    _validatePacket(fcfc, BikeGatt.displayVersionSelector);
    _validatePacket(fafa, BikeGatt.componentVersionsSelector);
    return BikeVersionInfo(
      hardwareRevision: hardware,
      firmwareRevision: firmware,
      softwareRevision: software,
      stmFirmwareVersion: _readBigEndian(fcfc, 2, 3),
      controllerVariant: fcfc[5] | (fcfc[6] << 8),
      bootloaderHandoff: fcfc[7],
      motorControllerVersion: _readBigEndian(fafa, 2, 4),
      bmsVersion: _readBigEndian(fafa, 6, 4),
    );
  }

  static List<int> encodeConfiguration(
    BikeConfiguration configuration, {
    required BikeProtocolVersion version,
  }) {
    if (configuration.mode < 0 || configuration.mode > 3) {
      throw RangeError.range(configuration.mode, 0, 3, 'mode');
    }
    if (configuration.assist < 0 || configuration.assist > 4) {
      throw RangeError.range(configuration.assist, 0, 4, 'assist');
    }
    final mode = switch (version) {
      BikeProtocolVersion.v1 => switch (configuration.region) {
        BikeRegion.us => configuration.mode,
        BikeRegion.eu => configuration.mode + 4,
      },
      BikeProtocolVersion.v2 => configuration.mode,
    };
    return [
      0,
      version == BikeProtocolVersion.v1 ? 0xd1 : 0xc1,
      configuration.light ? 1 : 0,
      configuration.assist,
      mode,
      0,
      0,
      0,
      0,
      0,
    ];
  }

  static bool hasPacketId(List<int> packet, List<int> packetId) {
    return packet.length == 10 &&
        packetId.length == 2 &&
        packet[0] == packetId[0] &&
        packet[1] == packetId[1];
  }

  static BikeConfiguration _applyV2D0(
    List<int> packet,
    BikeConfiguration current,
  ) {
    _validatePacket(packet, BikeGatt.v2ControlSelector);
    final assist = packet[2];
    final lightByte = packet[4];
    _validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: current.mode,
      maximumMode: 3,
    );
    return current.copyWith(light: lightByte == 1, assist: assist);
  }

  static BikeConfiguration _applyV2D9(
    List<int> packet,
    BikeConfiguration current,
  ) {
    _validatePacket(packet, BikeGatt.v2ModeSelector);
    final mode = packet[5];
    if (mode < 0 || mode > 3) {
      throw UnsupportedBikeValue('ride mode', mode);
    }
    return current.copyWith(mode: mode);
  }

  static void _validateAuthenticationBytes(List<int> value, String name) {
    if (value.length != 20) {
      throw InvalidAuthenticationValue(
        'The authentication $name must contain exactly 20 bytes.',
      );
    }
    for (final byte in value) {
      if (byte < 0 || byte > 255) {
        throw InvalidAuthenticationValue(
          'The authentication $name contains an invalid byte.',
        );
      }
    }
  }

  static void _validatePacket(List<int> packet, List<int> expectedId) {
    if (packet.length < 10) {
      throw ShortBikeFrame(packet.length);
    }
    if (packet.length != 10) {
      throw MalformedBikeFrame('length');
    }
    for (var index = 0; index < packet.length; index++) {
      final byte = packet[index];
      if (byte < 0 || byte > 255) {
        throw MalformedBikeFrame('byte $index');
      }
    }
    if (!hasPacketId(packet, expectedId)) {
      throw UnexpectedBikePacket(
        expected: _hexId(expectedId),
        actual: _hexId(packet),
      );
    }
  }

  static void _validateControlValues({
    required int assist,
    required int lightByte,
    required int mode,
    required int maximumMode,
  }) {
    if (assist < 0 || assist > 4) {
      throw UnsupportedBikeValue('assist', assist);
    }
    if (lightByte != 0 && lightByte != 1) {
      throw UnsupportedBikeValue('light', lightByte);
    }
    if (mode < 0 || mode > maximumMode) {
      throw UnsupportedBikeValue('mode', mode);
    }
  }

  static String _hexId(List<int> bytes) {
    if (bytes.length < 2) {
      return 'short';
    }
    return bytes
        .take(2)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static int _readBigEndian(List<int> bytes, int offset, int length) {
    var value = 0;
    for (var index = offset; index < offset + length; index++) {
      value = (value << 8) | bytes[index];
    }
    return value;
  }
}
