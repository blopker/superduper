import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/exclusive_bluetooth_operation.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/user_facing_error.dart';

void main() {
  test('removes nested transport prefixes from reconnect errors', () {
    expect(
      userFacingError(
        const BikeSessionTransportFailure(
          'Connection: The bike could not be reached.',
        ),
        context: UserErrorContext.reconnect,
      ),
      'Couldn’t reach the bike. Make sure it’s powered on and nearby.',
    );
  });

  test('turns internal control state into an actionable instruction', () {
    expect(
      userFacingError(
        const BikeSessionNotReady(),
        context: UserErrorContext.bikeControl,
      ),
      'Wait for the bike to finish connecting, then try again.',
    );
  });

  test('does not expose unknown exception text', () {
    expect(
      userFacingError(
        StateError('private database implementation detail'),
        context: UserErrorContext.startup,
      ),
      'Your saved bikes couldn’t be opened. Try again.',
    );
  });

  test('preserves an intentional hardware-test diagnostic', () {
    expect(
      userFacingError(
        const BikeHardwareTestFailure('Light did not toggle.'),
        context: UserErrorContext.hardwareTest,
      ),
      'Light did not toggle.',
    );
  });

  test('explains when another Bluetooth operation owns the radio', () {
    expect(
      userFacingError(
        const ExclusiveBluetoothOperationBusy(),
        context: UserErrorContext.hardwareTest,
      ),
      ExclusiveBluetoothOperationBusy.message,
    );
  });

  test('classifies duplicate bikes by type', () {
    expect(
      userFacingError(
        const BikeAlreadyExistsException('bike'),
        context: UserErrorContext.saveBike,
      ),
      'This bike is already saved.',
    );
  });

  test('does not apply bike heuristics to startup errors', () {
    expect(
      userFacingError(
        StateError('no such column: protocol after timeout'),
        context: UserErrorContext.startup,
      ),
      'Your saved bikes couldn’t be opened. Try again.',
    );
  });
}
