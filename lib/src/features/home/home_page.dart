import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/add_bike/add_bike_controller.dart';
import 'package:superduper/src/features/add_bike/add_bike_page.dart';
import 'package:superduper/src/features/bike_control/bike_control_page.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

final class HomePage extends SignalWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final coordinator = services.activeBikeCoordinator;
    final bikes = coordinator.bikes.value;
    final activeId = coordinator.activeBikeId.value;
    final activeState = coordinator.state.value;
    final migrationNoticePending = coordinator.migrationNoticePending.value;
    final startupState = services.startup.state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Superduper')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (migrationNoticePending) ...[
              _MigrationNotice(
                startupState: startupState,
                onDismiss: coordinator.dismissMigrationNotice,
              ),
              const SizedBox(height: 12),
            ],
            _ActiveStatus(
              state: activeState,
              onRetry: coordinator.retry,
              onOpenSettings: coordinator.openPermissionSettings,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    bikes.isEmpty ? 'No saved bikes' : 'Your bikes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddBike(context, services),
                  icon: const Icon(Icons.add),
                  label: const Text('Add bike'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bikes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Add a powered-on bike to read its current settings and save it.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final saved in bikes)
                _BikeTile(
                  saved: saved,
                  isActive: saved.bike.deviceId == activeId,
                  onOpen: () => _openBike(context, saved.bike.deviceId),
                  onMakeActive: () =>
                      coordinator.makeBikeActive(saved.bike.deviceId),
                  onForget: () => _forget(context, coordinator, saved),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddBike(BuildContext context, AppServices services) async {
    final controller = AddBikeController(
      transport: services.transport,
      permissions: services.permissions,
      bikeRepository: services.bikeRepository,
      activeBikeCoordinator: services.activeBikeCoordinator,
    );
    final deviceId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AddBikePage(controller: controller),
      ),
    );
    if (deviceId != null && context.mounted) {
      await _openBike(context, deviceId);
    }
  }

  Future<void> _openBike(BuildContext context, String deviceId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BikeControlPage(deviceId: deviceId),
      ),
    );
  }

  Future<void> _forget(
    BuildContext context,
    ActiveBikeCoordinator coordinator,
    SavedBike saved,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forget ${saved.bike.displayName}?'),
        content: const Text(
          'This removes the bike and its saved settings from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forget bike'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await coordinator.forgetBike(saved.bike.deviceId);
    }
  }
}

final class _MigrationNotice extends StatelessWidget {
  const _MigrationNotice({required this.startupState, required this.onDismiss});

  final StartupState startupState;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final detail = switch (startupState) {
      StartupReady(:final importResult) when importResult.warnings.isNotEmpty =>
        '${importResult.bikesImported} saved bike(s) imported with ${importResult.warnings.length} adjustment(s). The original files were left unchanged.',
      _ => 'Superduper repaired the saved active-bike selection. Review your bikes before riding.',
    };
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Saved bike data needs review'),
        subtitle: Text(detail),
        trailing: TextButton(
          onPressed: () => unawaited(onDismiss()),
          child: const Text('Dismiss'),
        ),
      ),
    );
  }
}

final class _ActiveStatus extends StatelessWidget {
  const _ActiveStatus({
    required this.state,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final ActiveBikeState state;
  final Future<void> Function() onRetry;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail, canRetry, needsSettings) = switch (state) {
      ActiveBikeLoading() => (
        Icons.bluetooth_searching,
        'Preparing active bike',
        'Loading saved bike settings…',
        false,
        false,
      ),
      NoActiveBike() => (
        Icons.electric_bike_outlined,
        'Add your first bike',
        'It will become active and connect automatically when the app opens.',
        false,
        false,
      ),
      ActiveBikePermissionRequired(:final permission) => (
        Icons.bluetooth_disabled,
        permission == BluetoothPermissionState.restricted
            ? 'Bluetooth access restricted'
            : 'Bluetooth permission needed',
        switch (permission) {
          BluetoothPermissionState.permanentlyDenied =>
            'Allow Bluetooth access in system settings.',
          BluetoothPermissionState.restricted =>
            'A device or account restriction is preventing Bluetooth access.',
          _ => 'Allow Bluetooth access to prepare the active bike.',
        },
        permission == BluetoothPermissionState.denied,
        permission == BluetoothPermissionState.permanentlyDenied,
      ),
      ActiveBikeCoordinatorFailure(:final message) => (
        Icons.error_outline,
        'Saved bikes unavailable',
        message,
        true,
        false,
      ),
      ActiveBikeSessionStatus(
        :final bike,
        :final sessionState,
        :final isTemporary,
      ) =>
        _sessionPresentation(bike, sessionState, isTemporary),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(detail),
                  if (canRetry || needsSettings) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: needsSettings
                          ? () => unawaited(onOpenSettings())
                          : onRetry,
                      child: Text(
                        needsSettings ? 'Open settings' : 'Try again',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, String, String, bool, bool) _sessionPresentation(
    SavedBike bike,
    BikeSessionState state,
    bool isTemporary,
  ) {
    final prefix = isTemporary ? 'Temporary bike' : bike.bike.displayName;
    return switch (state) {
      SessionIdle() || SessionConnecting() => (
        Icons.bluetooth_searching,
        'Connecting to $prefix',
        'Keep the bike powered on and nearby.',
        false,
        false,
      ),
      SessionDiscovering() || SessionConnected() => (
        Icons.bluetooth_connected,
        'Connected to $prefix',
        'Checking bike compatibility…',
        false,
        false,
      ),
      SessionSynchronizing() => (
        Icons.sync,
        'Applying saved settings',
        'Preparing $prefix for your ride.',
        false,
        false,
      ),
      SessionReady() => (
        Icons.check_circle_outline,
        'Ready to ride',
        '$prefix is connected and its kept settings are confirmed.',
        false,
        false,
      ),
      SessionReconnecting(:final retryAfter) => (
        Icons.refresh,
        'Bike unavailable',
        'Retrying in ${retryAfter.inSeconds} seconds.',
        false,
        false,
      ),
      SessionDisconnected(:final manuallyPaused) => (
        Icons.bluetooth_disabled,
        manuallyPaused ? 'Disconnected' : 'Connection paused',
        manuallyPaused
            ? 'Automatic reconnect is paused until you reconnect or reopen the app.'
            : 'Reconnect to prepare the bike.',
        true,
        false,
      ),
      SessionFailed(:final failure, :final canRetry) => (
        Icons.error_outline,
        'Bike setup failed',
        '${failure.message} Check that Bluetooth is on, the bike is powered nearby, and no other app is connected.',
        canRetry,
        false,
      ),
      SessionDisposed() => (
        Icons.bluetooth_disabled,
        'Connection closed',
        'Select the bike to connect again.',
        true,
        false,
      ),
    };
  }
}

final class _BikeTile extends StatelessWidget {
  const _BikeTile({
    required this.saved,
    required this.isActive,
    required this.onOpen,
    required this.onMakeActive,
    required this.onForget,
  });

  final SavedBike saved;
  final bool isActive;
  final VoidCallback onOpen;
  final Future<void> Function() onMakeActive;
  final Future<void> Function() onForget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(Icons.electric_bike),
        title: Text(saved.bike.displayName),
        subtitle: Text(
          isActive
              ? '${saved.bike.color.displayName} • Active • Auto-connects on launch'
              : saved.bike.color.displayName,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'active':
                unawaited(onMakeActive());
                return;
              case 'forget':
                unawaited(onForget());
                return;
            }
          },
          itemBuilder: (_) => [
            if (!isActive)
              const PopupMenuItem(value: 'active', child: Text('Make active')),
            const PopupMenuItem(value: 'forget', child: Text('Forget bike')),
          ],
        ),
      ),
    );
  }
}
