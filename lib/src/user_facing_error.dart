import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';

enum UserErrorContext {
  reconnect,
  bikeControl,
  bikeConnection,
  addBike,
  saveBike,
  bikeAction,
  savedBikes,
  startup,
  hardwareTest,
}

String userFacingError(
  Object error, {
  required UserErrorContext context,
}) {
  final known = switch (error) {
    BikeBluetoothUnavailable(:final message) => _bluetoothMessage(message),
    BikeCommandTimedOut() => 'The bike took too long to respond.',
    BikeSettingsNotApplied() => 'The bike didn’t apply the requested setting. Manual controls are still available.',
    BikeSessionNotReady() =>
      'Wait for the bike to finish connecting, then try again.',
    BikeSettingsPersistenceFailure() =>
      'The bike changed, but Superduper couldn’t save the change.',
    BikeAuthenticationFailed() =>
      'Couldn’t verify this bike. Close other bike apps and try again.',
    BikeProtocolNotSupported() => 'This bike’s Bluetooth protocol isn’t supported. Check the protocol under Advanced settings.',
    BikeSessionDisposedFailure() => 'The bike connection has closed.',
    BikeSessionTransportFailure(:final message) => _transportMessage(
      message,
      context,
    ),
    BikeAdapterUnavailable(:final message) => _bluetoothMessage(message),
    BikeGattNotSupported() =>
      'This bike doesn’t provide the Bluetooth features Superduper needs.',
    BikeConnectionFailure(:final operation, :final message) =>
      _connectionMessage(operation, message, context),
    BikeNotFoundException() => 'This bike is no longer saved.',
    _ => null,
  };
  if (known != null) {
    return known;
  }

  final hinted = _messageHint(error is String ? error : error.toString());
  if (hinted != null) {
    return hinted;
  }

  return switch (context) {
    UserErrorContext.reconnect =>
      'Couldn’t reach the bike. Make sure it’s powered on and nearby.',
    UserErrorContext.bikeControl => 'Couldn’t update the bike. Try again.',
    UserErrorContext.bikeConnection =>
      'Couldn’t update the connection. Try again.',
    UserErrorContext.addBike =>
      'Couldn’t add this bike. Check Bluetooth and try again.',
    UserErrorContext.saveBike => 'Couldn’t save the bike. Try again.',
    UserErrorContext.bikeAction => 'Couldn’t update the bike. Try again.',
    UserErrorContext.savedBikes =>
      'Your saved bikes aren’t available right now. Try again.',
    UserErrorContext.startup =>
      'Your saved bikes couldn’t be opened. Try again.',
    UserErrorContext.hardwareTest => 'The test couldn’t complete this step.',
  };
}

String _bluetoothMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('off')) {
    return 'Bluetooth is off. Turn it on to connect.';
  }
  if (lower.contains('permission') ||
      lower.contains('access') ||
      lower.contains('unauthorized')) {
    return 'Bluetooth permission is needed to connect to your bike.';
  }
  return 'Bluetooth isn’t available right now.';
}

String _transportMessage(String message, UserErrorContext context) {
  final hinted = _messageHint(message);
  if (hinted != null) {
    return hinted;
  }
  return context == UserErrorContext.reconnect
      ? 'Couldn’t reach the bike. Make sure it’s powered on and nearby.'
      : 'The bike stopped responding. Try again.';
}

String _connectionMessage(
  String operation,
  String message,
  UserErrorContext context,
) {
  final lowerOperation = operation.toLowerCase();
  if (lowerOperation.contains('scan')) {
    return 'Couldn’t start scanning. Check Bluetooth and try again.';
  }
  if (lowerOperation == 'connection') {
    return 'Couldn’t reach the bike. Make sure it’s powered on and nearby.';
  }
  final hinted = _messageHint(message);
  if (hinted != null) {
    return hinted;
  }
  if (context == UserErrorContext.addBike) {
    return 'Couldn’t verify this bike. Make sure it’s powered on and try again.';
  }
  return 'The bike stopped responding. Try again.';
}

String? _messageHint(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('permission channel')) {
    return 'Couldn’t check Bluetooth permission. Try again.';
  }
  if (lower.contains('could not be reached') ||
      lower.contains('couldn’t be reached') ||
      lower.contains('connection failed')) {
    return 'Couldn’t reach the bike. Make sure it’s powered on and nearby.';
  }
  if (lower.contains('bluetooth') && lower.contains('off')) {
    return 'Bluetooth is off. Turn it on to connect.';
  }
  if (lower.contains('permission') || lower.contains('unauthorized')) {
    return 'Bluetooth permission is needed to connect to your bike.';
  }
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'The bike took too long to respond.';
  }
  if (lower.contains('authentication') || lower.contains('challenge')) {
    return 'Couldn’t verify this bike. Close other bike apps and try again.';
  }
  if (lower.contains('protocol') || lower.contains('unsupported service')) {
    return 'This bike’s Bluetooth protocol isn’t supported.';
  }
  if (lower.contains('unique constraint') ||
      lower.contains('already saved') ||
      lower.contains('duplicate')) {
    return 'This bike is already saved.';
  }
  if (lower.contains('region') && lower.contains('required')) {
    return 'Choose a region to continue.';
  }
  return null;
}
