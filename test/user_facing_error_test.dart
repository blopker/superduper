import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_session.dart';
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
}
