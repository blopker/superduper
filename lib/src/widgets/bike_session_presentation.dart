import 'package:flutter/material.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';

final class BikeSessionPresentation {
  const BikeSessionPresentation({
    required this.icon,
    required this.label,
    required this.color,
    required this.title,
    required this.detail,
    required this.canRetry,
  });

  factory BikeSessionPresentation.from(
    BikeSessionState state, {
    String bikeName = 'your bike',
  }) {
    return switch (state) {
      SessionIdle() || SessionConnecting() => BikeSessionPresentation(
        icon: Icons.bluetooth_searching_rounded,
        label: 'Connecting',
        color: AppColors.yellow,
        title: 'Finding $bikeName…',
        detail: 'Keep the bike powered on and nearby.',
        canRetry: false,
      ),
      SessionDiscovering() ||
      SessionAuthenticating() ||
      SessionConnected() => BikeSessionPresentation(
        icon: Icons.bluetooth_connected_rounded,
        label: 'Checking',
        color: AppColors.yellow,
        title: 'Connected to $bikeName',
        detail: 'Checking compatibility and reading the current setup…',
        canRetry: false,
      ),
      SessionSynchronizing() => const BikeSessionPresentation(
        icon: Icons.sync_rounded,
        label: 'Synchronizing',
        color: AppColors.yellow,
        title: 'Applying saved settings…',
        detail: 'You can keep making changes while the bike catches up.',
        canRetry: false,
      ),
      SessionDegraded(:final failure) => BikeSessionPresentation(
        icon: Icons.warning_amber_rounded,
        label: 'Connected with warning',
        color: AppColors.orange,
        title: 'The bike did not accept a setting',
        detail: userFacingError(
          failure,
          context: UserErrorContext.bikeControl,
        ),
        canRetry: true,
      ),
      SessionReady() => BikeSessionPresentation(
        icon: Icons.check_circle_rounded,
        label: 'Connected',
        color: AppColors.mint,
        title: 'Ready to ride',
        detail:
            '$bikeName is connected and its Set on connect values are confirmed.',
        canRetry: false,
      ),
      SessionReconnecting(:final retryAfter, :final failure) =>
        BikeSessionPresentation(
          icon: Icons.refresh_rounded,
          label: 'Reconnecting',
          color: AppColors.orange,
          title: failure is BikeBluetoothUnavailable
              ? 'Bluetooth is unavailable'
              : 'Trying to reconnect…',
          detail:
              '${userFacingError(failure, context: UserErrorContext.reconnect)} Trying again in ${retryAfter.inSeconds} seconds.',
          canRetry: false,
        ),
      SessionDisconnected(:final manuallyPaused) => BikeSessionPresentation(
        icon: Icons.bluetooth_disabled_rounded,
        label: 'Disconnected',
        color: AppColors.orange,
        title: manuallyPaused ? 'Connection paused' : 'Bike disconnected',
        detail: manuallyPaused
            ? 'Reconnect when you are ready to use this bike.'
            : 'Check bike power and Bluetooth, then reconnect.',
        canRetry: true,
      ),
      SessionFailed(:final failure, :final canRetry) => BikeSessionPresentation(
        icon: Icons.error_outline_rounded,
        label: 'Needs attention',
        color: AppColors.error,
        title: 'Bike setup failed',
        detail: userFacingError(
          failure,
          context: UserErrorContext.bikeConnection,
        ),
        canRetry: canRetry,
      ),
      SessionDisposed() => const BikeSessionPresentation(
        icon: Icons.bluetooth_disabled_rounded,
        label: 'Closed',
        color: AppColors.orange,
        title: 'Connection closed',
        detail: 'Open the bike to connect again.',
        canRetry: true,
      ),
    };
  }

  factory BikeSessionPresentation.savedBikesFailure(Object error) {
    return BikeSessionPresentation(
      icon: Icons.error_outline_rounded,
      label: 'Needs attention',
      color: AppColors.error,
      title: 'Saved bikes unavailable',
      detail: userFacingError(error, context: UserErrorContext.savedBikes),
      canRetry: true,
    );
  }

  final IconData icon;
  final String label;
  final Color color;
  final String title;
  final String detail;
  final bool canRetry;
}
