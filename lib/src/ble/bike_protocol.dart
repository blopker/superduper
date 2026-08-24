import 'package:superduper/src/domain/bike.dart';

abstract final class BikeGatt {
  static const metricsService = '00001554-1212-efde-1523-785feabcd123';
  static const registerSelector = '00001564-1212-efde-1523-785feabcd123';
  static const stateRegister = '0000155f-1212-efde-1523-785feabcd123';
  static const selectCurrentState = <int>[3, 0];
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
    : super('Bike state frame is too short: $length bytes.');
}

final class MalformedBikeFrame extends BikeProtocolFailure {
  const MalformedBikeFrame(String field)
    : super('Bike state frame has a malformed $field value.');
}

final class UnsupportedBikeValue extends BikeProtocolFailure {
  const UnsupportedBikeValue(String field, int value)
    : super('Bike state frame has unsupported $field value $value.');
}

abstract final class BikeProtocol {
  static BikeConfiguration decodeState(List<int> frame) {
    if (frame.length < 6) {
      throw ShortBikeFrame(frame.length);
    }
    for (var index = 0; index < 6; index++) {
      final byte = frame[index];
      if (byte < 0 || byte > 255) {
        throw MalformedBikeFrame('byte $index');
      }
    }

    final assist = frame[2];
    if (assist < 0 || assist > 4) {
      throw UnsupportedBikeValue('assist', assist);
    }
    final lightByte = frame[4];
    if (lightByte != 0 && lightByte != 1) {
      throw UnsupportedBikeValue('light', lightByte);
    }
    final wireMode = frame[5];
    if (wireMode < 0 || wireMode > 7) {
      throw UnsupportedBikeValue('mode', wireMode);
    }

    return BikeConfiguration(
      light: lightByte == 1,
      mode: wireMode % 4,
      assist: assist,
      region: wireMode >= 4 ? BikeRegion.eu : BikeRegion.us,
    );
  }

  static List<int> encodeConfiguration(BikeConfiguration configuration) {
    if (configuration.mode < 0 || configuration.mode > 3) {
      throw RangeError.range(configuration.mode, 0, 3, 'mode');
    }
    if (configuration.assist < 0 || configuration.assist > 4) {
      throw RangeError.range(configuration.assist, 0, 4, 'assist');
    }
    final wireMode = switch (configuration.region) {
      BikeRegion.us => configuration.mode,
      BikeRegion.eu => configuration.mode + 4,
    };
    return [
      0,
      0xd1,
      configuration.light ? 1 : 0,
      configuration.assist,
      wireMode,
      0,
      0,
      0,
      0,
      0,
    ];
  }
}
