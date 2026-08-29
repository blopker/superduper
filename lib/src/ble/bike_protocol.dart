import 'package:crypto/crypto.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';

export 'package:superduper/src/domain/bike.dart'
    show BikeConfiguration, BikeControlPatch, BikeProtocolVersion;

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
  static const v1OdometerSelector = <int>[0x02, 0x02];
  static const v2ControlSelector = <int>[0x00, 0xd0];
  static const v2ModeSelector = <int>[0x00, 0xd9];
  static const displayVersionSelector = <int>[0xfc, 0xfc];
  static const componentVersionsSelector = <int>[0xfa, 0xfa];
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

typedef BikeProtocolTimeout = Future<T> Function<T>(
  Future<T> operation,
  String name,
);

abstract class BikeProtocolDefinition {
  BikeProtocolDefinition() : _connection = null, _timed = null;

  BikeProtocolDefinition.connected({
    required this._connection,
    required this._timed,
  });

  final BikeConnection? _connection;
  final BikeProtocolTimeout? _timed;
  BikeRegion? _lastWireRegion;
  List<int>? _lastLatchedHistorySelector;

  Future<BikeConfiguration> readConfiguration({
    required BikeRegion? preferredRegion,
    required BikeRegion? fallbackRegion,
    void Function(int meters)? onOdometer,
  });

  Future<int> readOdometer({required int? cachedMeters});

  BikeControlPatch? decodeTelemetry(List<int> packet);

  BikeConfiguration? applyTelemetry(
    List<int> packet,
    BikeConfiguration current, {
    required BikeRegion? preferredRegion,
  }) {
    final patch = decodeTelemetry(packet);
    if (patch == null) {
      return null;
    }
    return patch
        .applyTo(current)
        .copyWith(region: preferredRegion ?? current.region);
  }

  List<int> encodeConfiguration(BikeConfiguration configuration);

  bool wireRegionMatches(BikeConfiguration target);

  Future<void> writeConfiguration(BikeConfiguration configuration) {
    return _run(
      _bike.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.stateRegister,
        value: encodeConfiguration(configuration),
      ),
      'Writing bike settings',
    );
  }

  Future<List<int>> readHistoryRecord(List<int> selector) async {
    final frame = await _tryReadHistoryRecord(selector);
    if (frame != null) {
      return frame;
    }
    throw UnexpectedBikePacket(
      expected: BikeProtocol._hexId(selector),
      actual: 'a different or malformed record',
    );
  }

  void reset() {
    _lastWireRegion = null;
    _lastLatchedHistorySelector = null;
  }

  Future<List<int>> readProtocolRecord(
    List<int> selector, {
    bool invalidateRetained = false,
  }) async {
    if (invalidateRetained) {
      final previous = _lastLatchedHistorySelector;
      if (previous == null || _sameSelector(previous, selector)) {
        await _tryReadHistoryRecord(BikeGatt.displayVersionSelector);
      }
    }
    return readHistoryRecord(selector);
  }

  Future<List<int>?> _tryReadHistoryRecord(List<int> selector) async {
    await _run(
      _bike.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.registerSelector,
        value: selector,
      ),
      'Selecting state register',
    );
    for (final delay in _historyResultRetryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      final frame = await _run(
        _bike.readCharacteristic(
          serviceUuid: BikeGatt.metricsService,
          characteristicUuid: BikeGatt.stateRegister,
        ),
        'Reading bike state',
      );
      if (BikeProtocol.hasPacketId(frame, selector)) {
        _lastLatchedHistorySelector = List<int>.unmodifiable(selector);
        return frame;
      }
    }
    return null;
  }

  Future<T> _run<T>(Future<T> operation, String name) {
    final timed = _timed;
    if (timed == null) {
      throw StateError('This protocol object is not connected.');
    }
    return timed(operation, name);
  }

  BikeConnection get _bike =>
      _connection ??
      (throw StateError('This protocol object is not connected.'));

  static bool _sameSelector(List<int> left, List<int> right) {
    return left.length == 2 &&
        right.length == 2 &&
        left[0] == right[0] &&
        left[1] == right[1];
  }

  static const List<Duration> _historyResultRetryDelays = [
    Duration.zero,
    Duration(milliseconds: 10),
    Duration(milliseconds: 25),
    Duration(milliseconds: 75),
  ];
}

final class V1BikeProtocol extends BikeProtocolDefinition {
  V1BikeProtocol();

  V1BikeProtocol.connected({
    required BikeConnection connection,
    required BikeProtocolTimeout timed,
  }) : super.connected(connection: connection, timed: timed);

  BikeConfiguration decodeState(List<int> packet) {
    BikeProtocol._validatePacket(packet, BikeGatt.v1StateSelector);
    final assist = packet[2];
    final lightByte = packet[4];
    final wireMode = packet[5];
    BikeProtocol._validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: wireMode,
      maximumMode: BikeControlValues.modeCount * BikeRegion.values.length - 1,
    );
    return BikeConfiguration(
      light: lightByte == 1,
      mode: wireMode % BikeControlValues.modeCount,
      assist: assist,
      region: wireMode >= BikeControlValues.modeCount
          ? BikeRegion.eu
          : BikeRegion.us,
    );
  }

  @override
  Future<BikeConfiguration> readConfiguration({
    required BikeRegion? preferredRegion,
    required BikeRegion? fallbackRegion,
    void Function(int meters)? onOdometer,
  }) async {
    final wire = decodeState(
      await readProtocolRecord(
        BikeGatt.v1StateSelector,
        invalidateRetained: true,
      ),
    );
    _lastWireRegion = wire.region;
    return wire.copyWith(region: preferredRegion);
  }

  @override
  BikeControlPatch? decodeTelemetry(List<int> packet) {
    if (!BikeProtocol._hasPacketIdValue(packet, 0x0300)) {
      return null;
    }
    final decoded = decodeState(packet);
    _lastWireRegion = decoded.region;
    return BikeControlPatch(
      light: decoded.light,
      mode: decoded.mode,
      assist: decoded.assist,
    );
  }

  @override
  BikeConfiguration? applyTelemetry(
    List<int> packet,
    BikeConfiguration current, {
    required BikeRegion? preferredRegion,
  }) {
    final patch = decodeTelemetry(packet);
    if (patch == null) {
      return null;
    }
    return patch
        .applyTo(current)
        .copyWith(region: preferredRegion ?? _lastWireRegion);
  }

  @override
  List<int> encodeConfiguration(BikeConfiguration configuration) {
    BikeProtocol._validateConfiguration(configuration);
    final mode = switch (configuration.region) {
      BikeRegion.us => configuration.mode,
      BikeRegion.eu => configuration.mode + BikeControlValues.modeCount,
    };
    return [
      0,
      0xd1,
      if (configuration.light) 1 else 0,
      configuration.assist,
      mode,
      0,
      0,
      0,
      0,
      0,
    ];
  }

  int decodeOdometer(List<int> packet) {
    BikeProtocol._validatePacket(packet, BikeGatt.v1OdometerSelector);
    return BikeProtocol._readLittleEndian(packet, 6, 4);
  }

  @override
  Future<int> readOdometer({required int? cachedMeters}) async {
    return decodeOdometer(
      await readProtocolRecord(BikeGatt.v1OdometerSelector),
    );
  }

  @override
  bool wireRegionMatches(BikeConfiguration target) {
    return _lastWireRegion == target.region;
  }
}

final class V2BikeProtocol extends BikeProtocolDefinition {
  V2BikeProtocol();

  V2BikeProtocol.connected({
    required BikeConnection connection,
    required BikeProtocolTimeout timed,
  }) : super.connected(connection: connection, timed: timed);

  BikeConfiguration decodeState({
    required List<int> d0,
    required List<int> d9,
    required BikeRegion region,
  }) {
    BikeProtocol._validatePacket(d0, BikeGatt.v2ControlSelector);
    BikeProtocol._validatePacket(d9, BikeGatt.v2ModeSelector);
    final assist = d0[2];
    final lightByte = d0[4];
    final mode = d9[5];
    BikeProtocol._validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: mode,
      maximumMode: BikeControlValues.maximumMode,
    );
    return BikeConfiguration(
      light: lightByte == 1,
      mode: mode,
      assist: assist,
      region: region,
    );
  }

  @override
  Future<BikeConfiguration> readConfiguration({
    required BikeRegion? preferredRegion,
    required BikeRegion? fallbackRegion,
    void Function(int meters)? onOdometer,
  }) async {
    final d0 = await readProtocolRecord(
      BikeGatt.v2ControlSelector,
      invalidateRetained: true,
    );
    onOdometer?.call(decodeOdometer(d0));
    return decodeState(
      d0: d0,
      d9: await readProtocolRecord(BikeGatt.v2ModeSelector),
      region: preferredRegion ?? fallbackRegion ?? BikeRegion.us,
    );
  }

  @override
  BikeControlPatch? decodeTelemetry(List<int> packet) {
    if (packet.length < 2) {
      throw ShortBikeFrame(packet.length);
    }
    final packetId = (packet[0] << 8) | packet[1];
    return switch (packetId) {
      0x00d0 => _decodeD0Telemetry(packet),
      0x00d9 => _decodeD9Telemetry(packet),
      _ => null,
    };
  }

  @override
  List<int> encodeConfiguration(BikeConfiguration configuration) {
    BikeProtocol._validateConfiguration(configuration);
    return [
      0,
      0xc1,
      if (configuration.light) 1 else 0,
      configuration.assist,
      configuration.mode,
      0,
      0,
      0,
      0,
      0,
    ];
  }

  int decodeOdometer(List<int> packet) {
    BikeProtocol._validatePacket(packet, BikeGatt.v2ControlSelector);
    return BikeProtocol._readLittleEndian(packet, 6, 4);
  }

  @override
  Future<int> readOdometer({required int? cachedMeters}) async {
    return cachedMeters ??
        decodeOdometer(
          await readProtocolRecord(BikeGatt.v2ControlSelector),
        );
  }

  @override
  bool wireRegionMatches(BikeConfiguration target) {
    return true;
  }

  BikeControlPatch _decodeD0Telemetry(List<int> packet) {
    BikeProtocol._validatePacket(packet, BikeGatt.v2ControlSelector);
    final assist = packet[2];
    final lightByte = packet[4];
    BikeProtocol._validateControlValues(
      assist: assist,
      lightByte: lightByte,
      mode: BikeControlValues.minimumMode,
      maximumMode: BikeControlValues.maximumMode,
    );
    return BikeControlPatch(light: lightByte == 1, assist: assist);
  }

  BikeControlPatch _decodeD9Telemetry(List<int> packet) {
    BikeProtocol._validatePacket(packet, BikeGatt.v2ModeSelector);
    final mode = packet[5];
    if (!BikeControlValues.isValidMode(mode)) {
      throw UnsupportedBikeValue('ride mode', mode);
    }
    return BikeControlPatch(mode: mode);
  }
}

abstract final class BikeProtocol {
  static final v1 = V1BikeProtocol();
  static final v2 = V2BikeProtocol();

  static BikeProtocolDefinition forVersion(BikeProtocolVersion version) {
    return switch (version) {
      BikeProtocolVersion.v1 => v1,
      BikeProtocolVersion.v2 => v2,
    };
  }

  static BikeProtocolDefinition connected({
    required BikeProtocolVersion version,
    required BikeConnection connection,
    required BikeProtocolTimeout timed,
  }) {
    return switch (version) {
      BikeProtocolVersion.v1 => V1BikeProtocol.connected(
        connection: connection,
        timed: timed,
      ),
      BikeProtocolVersion.v2 => V2BikeProtocol.connected(
        connection: connection,
        timed: timed,
      ),
    };
  }

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

  static bool hasPacketId(List<int> packet, List<int> packetId) {
    return packet.length == 10 &&
        packetId.length == 2 &&
        packet[0] == packetId[0] &&
        packet[1] == packetId[1];
  }

  static bool _hasPacketIdValue(List<int> packet, int packetId) {
    if (packet.length < 2) {
      throw ShortBikeFrame(packet.length);
    }
    return ((packet[0] << 8) | packet[1]) == packetId;
  }

  static void _validateConfiguration(BikeConfiguration configuration) {
    BikeControlValues.validateMode(configuration.mode);
    BikeControlValues.validateAssist(configuration.assist);
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
      throw const MalformedBikeFrame('length');
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
    if (!BikeControlValues.isValidAssist(assist)) {
      throw UnsupportedBikeValue('assist', assist);
    }
    if (lightByte != 0 && lightByte != 1) {
      throw UnsupportedBikeValue('light', lightByte);
    }
    if (mode < BikeControlValues.minimumMode || mode > maximumMode) {
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

  static int _readLittleEndian(List<int> bytes, int offset, int length) {
    var value = 0;
    for (var index = offset + length - 1; index >= offset; index--) {
      value = (value << 8) | bytes[index];
    }
    return value;
  }
}
