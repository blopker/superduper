import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/add_bike/add_bike_controller.dart';
import 'package:superduper/src/features/add_bike/add_bike_page.dart';
import 'package:superduper/src/features/bike_control/bike_control_page.dart';
import 'package:superduper/src/features/help/help_page.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';
import 'package:superduper/src/widgets/bike_session_presentation.dart';

final class HomePage extends SignalStatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final class _HomePageState extends State<HomePage> {
  var _openingAddBike = false;
  var _openingBike = false;
  var _autoOpenHandled = false;
  var _autoOpenScheduled = false;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final coordinator = services.activeBikeCoordinator;
    final bikes = coordinator.bikes.value;
    final activeId = coordinator.activeBikeId.value;
    final activeState = coordinator.state.value;
    final migrationNoticePending = coordinator.migrationNoticePending.value;
    final startupState = services.startup.state.value;
    _scheduleAutoOpen(activeState);
    final page = Scaffold(
      body: AppPageBody(
        maxWidth: double.infinity,
        safeTop: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            SizedBox(
              height: 116,
              child: Stack(
                children: [
                  const Positioned.fill(child: BrandMasthead()),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 4,
                    right: 16,
                    child: IconButton(
                      tooltip: 'Help & tips',
                      color: AppColors.magenta,
                      onPressed: () => _openHelp(context),
                      icon: const Icon(Icons.help_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      if (migrationNoticePending) ...[
                        _MigrationNotice(
                          startupState: startupState,
                          onDismiss: coordinator.dismissMigrationNotice,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _ActiveStatus(
                          key: ValueKey(activeState.runtimeType),
                          state: activeState,
                          onRetry: coordinator.retry,
                          onOpenSettings: coordinator.openPermissionSettings,
                          onOpenBike: (deviceId) =>
                              _openBike(context, deviceId),
                          onAddBike: () => _openAddBike(context, services),
                        ),
                      ),
                      const SizedBox(height: 34),
                      SectionHeader(
                        eyebrow: 'Garage',
                        title: bikes.isEmpty ? 'No saved bikes' : 'Your bikes',
                        action: bikes.isEmpty
                            ? null
                            : TextButton.icon(
                                onPressed: () =>
                                    _openAddBike(context, services),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add bike'),
                              ),
                      ),
                      const SizedBox(height: 16),
                      if (bikes.isEmpty)
                        const SurfacePanel(
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.yellow,
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Power on your bike and keep it nearby. Superduper will verify it and read its current settings.',
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final saved in bikes) ...[
                          _BikeTile(
                            saved: saved,
                            isActive: saved.bike.deviceId == activeId,
                            onOpen: () =>
                                _openBike(context, saved.bike.deviceId),
                            onMakeActive: () => _runAction(
                              context,
                              () => coordinator.makeBikeActive(
                                saved.bike.deviceId,
                              ),
                            ),
                            onForget: () =>
                                _forget(context, coordinator, saved),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: page,
    );
  }

  Future<void> _openAddBike(BuildContext context, AppServices services) async {
    if (_openingAddBike) {
      return;
    }
    _autoOpenHandled = true;
    _openingAddBike = true;
    final controller = AddBikeController(
      transport: services.transport,
      permissions: services.permissions,
      bikeRepository: services.bikeRepository,
      activeBikeCoordinator: services.activeBikeCoordinator,
    );
    try {
      final deviceId = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => AddBikePage(controller: controller),
        ),
      );
      if (deviceId != null && context.mounted) {
        await _openBike(context, deviceId);
      }
    } finally {
      _openingAddBike = false;
    }
  }

  Future<void> _openBike(BuildContext context, String deviceId) async {
    if (_openingBike || !context.mounted) {
      return;
    }
    _autoOpenHandled = true;
    _openingBike = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BikeControlPage(deviceId: deviceId),
        ),
      );
    } finally {
      _openingBike = false;
    }
  }

  Future<void> _openHelp(BuildContext context) async {
    _autoOpenHandled = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const HelpPage()),
    );
  }

  void _scheduleAutoOpen(ActiveBikeState activeState) {
    if (_autoOpenHandled || _autoOpenScheduled) {
      return;
    }
    final deviceId = switch (activeState) {
      ActiveBikeSessionStatus(
        :final bike,
        sessionState: SessionReady() || SessionDegraded(),
        isTemporary: false,
      ) =>
        bike.bike.deviceId,
      _ => null,
    };
    if (deviceId == null) {
      return;
    }
    _autoOpenScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoOpenScheduled = false;
      if (!mounted || _autoOpenHandled) {
        return;
      }
      final coordinator = AppServicesScope.of(context).activeBikeCoordinator;
      final current = coordinator.state.peek();
      final stillReady =
          current is ActiveBikeSessionStatus &&
          current.bike.bike.deviceId == deviceId &&
          !current.isTemporary &&
          (current.sessionState is SessionReady ||
              current.sessionState is SessionDegraded);
      if (!stillReady) {
        return;
      }
      if (ModalRoute.isCurrentOf(context) != true) {
        return;
      }
      _autoOpenHandled = true;
      unawaited(_openBike(context, deviceId));
    });
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
    if (!context.mounted) {
      return;
    }
    if (confirmed ?? false) {
      await _runAction(
        context,
        () => coordinator.forgetBike(saved.bike.deviceId),
      );
    }
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(error, context: UserErrorContext.bikeAction),
            ),
          ),
        );
      }
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
    return SurfacePanel(
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.violet),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved bike data needs review',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 5),
                Text(detail),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () => unawaited(onDismiss()),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

typedef _StatusPresentation = ({
  IconData icon,
  String label,
  Color color,
  String title,
  String detail,
  bool canRetry,
  bool needsSettings,
  SavedBike? bike,
});

final class _ActiveStatus extends StatelessWidget {
  const _ActiveStatus({
    required this.state,
    required this.onRetry,
    required this.onOpenSettings,
    required this.onOpenBike,
    required this.onAddBike,
    super.key,
  });

  final ActiveBikeState state;
  final Future<void> Function() onRetry;
  final Future<bool> Function() onOpenSettings;
  final Future<void> Function(String deviceId) onOpenBike;
  final Future<void> Function() onAddBike;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(state);
    final bike = presentation.bike;

    return SurfacePanel(
      padding: const EdgeInsets.all(24),
      color: bike?.bike.color.panelTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: presentation.label,
            color: presentation.color,
            icon: presentation.icon,
          ),
          const SizedBox(height: 28),
          Semantics(
            label: presentation.title,
            excludeSemantics: true,
            child: Text(
              presentation.title.toUpperCase(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            presentation.detail,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (bike != null ||
              presentation.canRetry ||
              presentation.needsSettings ||
              state is NoActiveBike) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (bike != null)
                  FilledButton.icon(
                    onPressed: () => onOpenBike(bike.bike.deviceId),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Open controls'),
                  )
                else if (state is NoActiveBike)
                  FilledButton.icon(
                    onPressed: onAddBike,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add bike'),
                  ),
                if (presentation.canRetry || presentation.needsSettings)
                  OutlinedButton.icon(
                    onPressed: presentation.needsSettings
                        ? () => unawaited(onOpenSettings())
                        : onRetry,
                    icon: Icon(
                      presentation.needsSettings
                          ? Icons.settings_outlined
                          : Icons.refresh_rounded,
                    ),
                    label: Text(
                      presentation.needsSettings
                          ? 'Open settings'
                          : 'Try again',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static _StatusPresentation _presentation(ActiveBikeState state) {
    return switch (state) {
      ActiveBikeLoading() => (
        icon: Icons.bluetooth_searching_rounded,
        label: 'Preparing',
        color: AppColors.yellow,
        title: 'Preparing active bike',
        detail: 'Loading your saved bike and ride settings…',
        canRetry: false,
        needsSettings: false,
        bike: null,
      ),
      NoActiveBike() => (
        icon: Icons.electric_bike_outlined,
        label: 'Start here',
        color: AppColors.yellow,
        title: 'Add your first bike',
        detail: 'Once it is saved, Superduper will connect and prepare it whenever the app opens.',
        canRetry: false,
        needsSettings: false,
        bike: null,
      ),
      ActiveBikePermissionRequired(:final permission) => (
        icon: Icons.bluetooth_disabled_rounded,
        label: 'Action needed',
        color: AppColors.orange,
        title: permission == BluetoothPermissionState.restricted
            ? 'Bluetooth access restricted'
            : 'Bluetooth permission needed',
        detail: switch (permission) {
          BluetoothPermissionState.permanentlyDenied =>
            'Allow Bluetooth access in system settings to prepare your bike.',
          BluetoothPermissionState.restricted =>
            'A device or account restriction is preventing Bluetooth access.',
          _ =>
            'Allow Bluetooth access to connect and apply your ride settings.',
        },
        canRetry: permission == BluetoothPermissionState.denied,
        needsSettings: permission == BluetoothPermissionState.permanentlyDenied,
        bike: null,
      ),
      ActiveBikeCoordinatorFailure(:final error) => (
        icon: Icons.error_outline_rounded,
        label: 'Needs attention',
        color: AppColors.error,
        title: 'Saved bikes unavailable',
        detail: userFacingError(
          error,
          context: UserErrorContext.savedBikes,
        ),
        canRetry: true,
        needsSettings: false,
        bike: null,
      ),
      ActiveBikeSessionStatus(
        :final bike,
        :final sessionState,
        :final isTemporary,
      ) =>
        _sessionPresentation(bike, sessionState, isTemporary),
    };
  }

  static _StatusPresentation _sessionPresentation(
    SavedBike bike,
    BikeSessionState state,
    bool isTemporary,
  ) {
    final name = isTemporary ? 'Temporary bike' : bike.bike.displayName;
    final presentation = BikeSessionPresentation.from(state, bikeName: name);
    return (
      icon: presentation.icon,
      label: presentation.label,
      color: presentation.color,
      title: presentation.title,
      detail: presentation.detail,
      canRetry: presentation.canRetry,
      needsSettings: false,
      bike: bike,
    );
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
    final region = saved.bike.region;
    final detail = [
      if (region != null) '${region.label} region',
      if (isActive) 'Auto-connects on launch',
    ].join(' · ');
    return Material(
      color: isActive ? saved.bike.color.panelTint : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              BikeAvatar(color: saved.bike.color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            saved.bike.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 9),
                          const StatusPill(
                            label: 'Active',
                            color: AppColors.magentaSoft,
                          ),
                        ],
                      ],
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(detail),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Bike actions',
                onSelected: (value) {
                  switch (value) {
                    case 'active':
                      unawaited(onMakeActive());
                    case 'forget':
                      unawaited(onForget());
                  }
                },
                itemBuilder: (_) => [
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'active',
                      child: Text('Make active'),
                    ),
                  const PopupMenuItem(
                    value: 'forget',
                    child: Text('Forget bike'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
