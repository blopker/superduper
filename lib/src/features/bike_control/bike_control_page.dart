import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/features/bike_settings/bike_settings_page.dart';
import 'package:superduper/src/features/help/help_page.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';

final class BikeControlPage extends SignalStatefulWidget {
  const BikeControlPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<BikeControlPage> createState() => _BikeControlPageState();
}

final class _BikeControlPageState extends State<BikeControlPage> {
  late AppServices _services;
  var _initialized = false;
  var _selectionStarted = false;
  var _temporarySelection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _services = AppServicesScope.of(context);
  }

  @override
  void dispose() {
    if (_temporarySelection) {
      unawaited(_services.activeBikeCoordinator.returnToActiveBike());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = _services.activeBikeCoordinator;
    final saved = coordinator.bikes.value.where(
      (bike) => bike.bike.deviceId == widget.deviceId,
    );
    if (saved.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('RIDE CONTROLS')),
        body: const AppPageBody(child: Center(child: Text('Bike not found'))),
      );
    }
    if (!_selectionStarted) {
      _selectionStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _selectBike());
    }
    final bike = saved.single;
    final activeState = coordinator.state.value;
    final session = coordinator.session.value;
    final isCurrentSession = session?.deviceId == widget.deviceId;
    final matchingSessionState =
        activeState is ActiveBikeSessionStatus &&
            activeState.bike.bike.deviceId == widget.deviceId
        ? activeState.sessionState
        : null;
    final sessionState =
        matchingSessionState ??
        switch (activeState) {
          ActiveBikePermissionRequired() => const SessionFailed(
            failure: BikeBluetoothUnavailable(
              'Bluetooth permission is required before this bike can connect.',
              canRetry: true,
            ),
            canRetry: true,
          ),
          ActiveBikeCoordinatorFailure(:final message) => SessionFailed(
            failure: BikeSessionTransportFailure(message),
            canRetry: true,
          ),
          _ => const SessionConnecting(),
        };
    final configuration = isCurrentSession
        ? session?.pending.value ?? session?.observed.value
        : null;
    final canControl =
        isCurrentSession &&
        session!.canChangeConfiguration &&
        configuration != null;
    final canChangeLocks = configuration != null;
    final canConnect =
        matchingSessionState is SessionDisconnected ||
        matchingSessionState is SessionFailed ||
        matchingSessionState == null &&
            (activeState is ActiveBikePermissionRequired ||
                activeState is ActiveBikeCoordinatorFailure);
    final isActive = coordinator.activeBikeId.value == widget.deviceId;
    final region = bike.bike.region;
    final palette = BikeColorPalette.from(bike.bike.color);

    return BikeColorTheme(
      color: bike.bike.color,
      child: Scaffold(
        backgroundColor: bike.bike.color.pageBaseColor,
        appBar: AppBar(
          title: const Text('RIDE CONTROLS'),
          actions: [
            IconButton(
              tooltip: 'Help & tips',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const HelpPage()),
              ),
              icon: const Icon(Icons.help_outline_rounded),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: canConnect ? 'Connect' : 'Disconnect',
              onPressed: isCurrentSession || canConnect
                  ? () => unawaited(
                      _runConnectionAction(
                        canConnect
                            ? coordinator.retry
                            : coordinator.disconnectManually,
                      ),
                    )
                  : null,
              icon: Icon(
                canConnect
                    ? Icons.bluetooth_rounded
                    : Icons.bluetooth_disabled_rounded,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: AppPageBody(
          maxWidth: 860,
          bikeColor: bike.bike.color,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Row(
                children: [
                  BikeAvatar(color: bike.bike.color, size: 70),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: StatusPill(
                              label: 'Active bike',
                              color: palette.accent,
                            ),
                          ),
                        Text(
                          bike.bike.displayName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (region != null) ...[
                          const SizedBox(height: 3),
                          Text('${region.label} region'),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bike settings',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ConnectionSummary(state: sessionState),
              const SizedBox(height: 14),
              _SettingSection(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Light',
                value: configuration == null
                    ? 'Waiting for bike'
                    : configuration.light
                    ? 'On'
                    : 'Off',
                toggleValue: configuration?.light ?? false,
                onToggleChanged: canControl
                    ? (value) => _runCommand(() => session.setLight(value))
                    : null,
                keep: bike.preferences.keepLight,
                onKeepChanged: canChangeLocks
                    ? (enabled) => _services.bikeRepository.setLightLock(
                        widget.deviceId,
                        enabled: enabled,
                        confirmedValue: configuration.light,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              _SettingSection(
                icon: Icons.speed_rounded,
                title: 'Mode',
                value: configuration == null
                    ? 'Waiting for bike'
                    : 'Mode ${configuration.mode + 1}',
                control: _ValueSelector(
                  values: const [0, 1, 2, 3],
                  selected: configuration?.mode,
                  enabled: canControl,
                  semanticLabel: 'Mode',
                  label: (mode) => '${mode + 1}',
                  onChanged: (mode) =>
                      _runCommand(() => session!.setMode(mode)),
                ),
                keep: bike.preferences.keepMode,
                onKeepChanged: canChangeLocks
                    ? (enabled) => _services.bikeRepository.setModeLock(
                        widget.deviceId,
                        enabled: enabled,
                        confirmedValue: configuration.mode,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              _SettingSection(
                icon: Icons.bolt_rounded,
                title: 'Assist',
                value: configuration == null
                    ? 'Waiting for bike'
                    : 'Level ${configuration.assist}',
                control: _ValueSelector(
                  values: const [0, 1, 2, 3, 4],
                  selected: configuration?.assist,
                  enabled: canControl,
                  semanticLabel: 'Assist level',
                  label: (assist) => '$assist',
                  onChanged: (assist) =>
                      _runCommand(() => session!.setAssist(assist)),
                ),
                keep: bike.preferences.keepAssist,
                onKeepChanged: canChangeLocks
                    ? (enabled) => _services.bikeRepository.setAssistLock(
                        widget.deviceId,
                        enabled: enabled,
                        confirmedValue: configuration.assist,
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              SurfacePanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded, color: palette.accent),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                        'Set on connect saves the confirmed value and reapplies it whenever this bike connects while Superduper is open.',
                      ),
                    ),
                  ],
                ),
              ),
              if (sessionState is SessionFailed ||
                  sessionState is SessionDisconnected) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: coordinator.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reconnect'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runCommand(Future<BikeConfiguration> Function() command) async {
    try {
      await command();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(error, context: UserErrorContext.bikeControl),
            ),
          ),
        );
      }
    }
  }

  Future<void> _runConnectionAction(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                context: UserErrorContext.bikeConnection,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectBike() async {
    if (!mounted ||
        _services.activeBikeCoordinator.activeBikeId.peek() ==
            widget.deviceId) {
      return;
    }
    _temporarySelection = true;
    try {
      await _services.activeBikeCoordinator.selectTemporarily(widget.deviceId);
    } on Object catch (error) {
      _temporarySelection = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                context: UserErrorContext.bikeConnection,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<BikeSettingsOutcome>(
      MaterialPageRoute<BikeSettingsOutcome>(
        builder: (_) => BikeSettingsPage(deviceId: widget.deviceId),
      ),
    );
    if (result == BikeSettingsOutcome.forgotten && mounted) {
      Navigator.pop(context);
    }
  }
}

typedef _ConnectionPresentation = ({
  IconData icon,
  String label,
  Color color,
  String title,
  String detail,
});

final class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.state});

  final BikeSessionState state;

  @override
  Widget build(BuildContext context) {
    if (state is SessionReady || state is SessionSynchronizing) {
      final synchronizing = state is SessionSynchronizing;
      return SizedBox(
        height: 32,
        child: Row(
          children: [
            Icon(
              synchronizing ? Icons.sync_rounded : Icons.check_circle_rounded,
              color: synchronizing ? AppColors.yellow : AppColors.mint,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              synchronizing ? 'Syncing…' : 'Connected',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      );
    }
    final presentation = _presentation(state);
    return SurfacePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(presentation.icon, color: presentation.color, size: 32),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: presentation.label,
                  color: presentation.color,
                ),
                const SizedBox(height: 11),
                Text(
                  presentation.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(presentation.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _ConnectionPresentation _presentation(BikeSessionState state) {
    return switch (state) {
      SessionReady() => (
        icon: Icons.check_circle_rounded,
        label: 'Connected',
        color: AppColors.mint,
        title: 'Ready to ride',
        detail: 'The bike is connected and kept settings are confirmed.',
      ),
      SessionSynchronizing() => (
        icon: Icons.sync_rounded,
        label: 'Synchronizing',
        color: AppColors.yellow,
        title: 'Applying settings…',
        detail: 'You can keep making changes while the bike catches up.',
      ),
      SessionDegraded(:final failure) => (
        icon: Icons.warning_amber_rounded,
        label: 'Connected with warning',
        color: AppColors.orange,
        title: 'A saved setting was not applied',
        detail: userFacingError(
          failure,
          context: UserErrorContext.bikeControl,
        ),
      ),
      SessionConnecting() => (
        icon: Icons.bluetooth_searching_rounded,
        label: 'Connecting',
        color: AppColors.yellow,
        title: 'Finding your bike…',
        detail: 'Keep the bike powered on and nearby.',
      ),
      SessionDiscovering() || SessionAuthenticating() || SessionConnected() => (
        icon: Icons.bluetooth_connected_rounded,
        label: 'Checking',
        color: AppColors.yellow,
        title: 'Checking bike…',
        detail: 'Validating services and reading current settings.',
      ),
      SessionReconnecting(:final failure) => (
        icon: Icons.refresh_rounded,
        label: 'Reconnecting',
        color: AppColors.orange,
        title: failure is BikeBluetoothUnavailable
            ? 'Bluetooth is unavailable'
            : 'Trying to reconnect…',
        detail: userFacingError(
          failure,
          context: UserErrorContext.reconnect,
        ),
      ),
      SessionDisconnected(:final manuallyPaused) => (
        icon: Icons.bluetooth_disabled_rounded,
        label: 'Disconnected',
        color: AppColors.orange,
        title: manuallyPaused ? 'Connection paused' : 'Bike disconnected',
        detail: manuallyPaused
            ? 'Reconnect when you are ready to use this bike.'
            : 'Check Bluetooth and make sure the bike is powered on.',
      ),
      SessionFailed(:final failure) => (
        icon: Icons.error_outline_rounded,
        label: 'Needs attention',
        color: AppColors.error,
        title: 'Bike needs attention',
        detail: userFacingError(
          failure,
          context: UserErrorContext.bikeConnection,
        ),
      ),
      SessionIdle() => (
        icon: Icons.bluetooth_searching_rounded,
        label: 'Preparing',
        color: AppColors.yellow,
        title: 'Starting bike session…',
        detail: 'This should only take a moment.',
      ),
      SessionDisposed() => (
        icon: Icons.bluetooth_disabled_rounded,
        label: 'Closed',
        color: AppColors.orange,
        title: 'Connection closed',
        detail: 'Return home and select the bike to try again.',
      ),
    };
  }
}

final class _SettingSection extends StatelessWidget {
  const _SettingSection({
    required this.icon,
    required this.title,
    required this.value,
    required this.keep,
    required this.onKeepChanged,
    this.control,
    this.toggleValue,
    this.onToggleChanged,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? control;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final bool keep;
  final Future<void> Function(bool enabled)? onKeepChanged;

  @override
  Widget build(BuildContext context) {
    final palette = BikeColorTheme.maybeOf(context);
    final accent = palette?.accent ?? AppColors.magentaSoft;
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (toggleValue case final toggled?)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              secondary: Icon(icon, color: accent, size: 30),
              title: Text(title),
              subtitle: Text(value),
              value: toggled,
              onChanged: onToggleChanged,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, color: accent, size: 30),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(value),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (control case final body?) ...[
                    const SizedBox(height: 18),
                    body,
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 3,
            ),
            secondary: Icon(
              keep ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: keep
                  ? accent
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Set on connect'),
            value: keep,
            onChanged: onKeepChanged == null
                ? null
                : (value) => unawaited(onKeepChanged!(value)),
          ),
        ],
      ),
    );
  }
}

final class _ValueSelector extends StatelessWidget {
  const _ValueSelector({
    required this.values,
    required this.selected,
    required this.enabled,
    required this.semanticLabel,
    required this.label,
    required this.onChanged,
  });

  final List<int> values;
  final int? selected;
  final bool enabled;
  final String semanticLabel;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: [
          for (final value in values)
            ButtonSegment<int>(
              value: value,
              label: Semantics(
                label: '$semanticLabel ${label(value)}',
                excludeSemantics: true,
                child: Text(label(value)),
              ),
            ),
        ],
        selected: selected == null ? const {} : {selected!},
        emptySelectionAllowed: true,
        onSelectionChanged: enabled
            ? (selection) {
                if (selection.isNotEmpty) {
                  onChanged(selection.single);
                }
              }
            : null,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(42, 50)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return states.contains(WidgetState.disabled)
                ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                : scheme.onSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
