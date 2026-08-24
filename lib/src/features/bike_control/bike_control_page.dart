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
      return const Scaffold(
        body: AppPageBody(child: Center(child: CircularProgressIndicator())),
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
    final sessionState =
        activeState is ActiveBikeSessionStatus &&
            activeState.bike.bike.deviceId == widget.deviceId
        ? activeState.sessionState
        : const SessionConnecting();
    final configuration = isCurrentSession ? session?.observed.value : null;
    final ready = sessionState is SessionReady && configuration != null;
    final isActive = coordinator.activeBikeId.value == widget.deviceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride controls'),
        actions: [
          IconButton(
            tooltip: 'Help & tips',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const HelpPage()),
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Bike actions',
            onSelected: (value) => unawaited(_handleMenu(value)),
            itemBuilder: (_) => [
              if (!isActive)
                const PopupMenuItem(
                  value: 'active',
                  child: Text('Make active'),
                ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Bike settings'),
              ),
              const PopupMenuItem(
                value: 'disconnect',
                child: Text('Disconnect'),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AppPageBody(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BikeAvatar(color: bike.bike.color, size: 70),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: StatusPill(
                            label: 'Active bike',
                            color: AppColors.magentaSoft,
                          ),
                        ),
                      Text(
                        bike.bike.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(bike.bike.color.displayName),
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
            const SizedBox(height: 24),
            _ConnectionSummary(state: sessionState),
            const SizedBox(height: 32),
            const SectionHeader(
              eyebrow: 'Live setup',
              title: 'Set up your ride',
            ),
            const SizedBox(height: 8),
            Text(
              ready
                  ? 'Changes are sent to the bike and confirmed immediately.'
                  : 'Controls unlock after the bike connects and confirms its settings.',
            ),
            const SizedBox(height: 18),
            _SettingSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Light',
              value: configuration == null
                  ? 'Waiting for bike'
                  : configuration.light
                  ? 'On'
                  : 'Off',
              control: _LightControl(
                value: configuration?.light ?? false,
                enabled: ready,
                onChanged: (value) =>
                    _runCommand(() => session!.setLight(value)),
              ),
              keep: bike.preferences.keepLight,
              onKeepChanged: ready
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
                enabled: ready,
                label: (mode) => '${mode + 1}',
                onChanged: (mode) => _runCommand(() => session!.setMode(mode)),
              ),
              keep: bike.preferences.keepMode,
              onKeepChanged: ready
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
                enabled: ready,
                label: (assist) => '$assist',
                onChanged: (assist) =>
                    _runCommand(() => session!.setAssist(assist)),
              ),
              keep: bike.preferences.keepAssist,
              onKeepChanged: ready
                  ? (enabled) => _services.bikeRepository.setAssistLock(
                      widget.deviceId,
                      enabled: enabled,
                      confirmedValue: configuration.assist,
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            const SurfacePanel(
              color: AppColors.inkLight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.yellow),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Keep on connect saves the confirmed value and reapplies it whenever this bike connects while Superduper is open.',
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
    );
  }

  Future<void> _runCommand(Future<BikeConfiguration> Function() command) async {
    try {
      await command();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update the bike. $error')),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _handleMenu(String value) async {
    switch (value) {
      case 'active':
        await _services.activeBikeCoordinator.makeBikeActive(widget.deviceId);
      case 'settings':
        await _openSettings();
      case 'disconnect':
        await _services.activeBikeCoordinator.disconnectManually();
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
    final presentation = _presentation(state);
    return SurfacePanel(
      borderColor: presentation.color.withValues(alpha: 0.48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: presentation.color.withValues(alpha: 0.13),
            ),
            child: Icon(presentation.icon, color: presentation.color),
          ),
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
        detail: 'Controls unlock after the bike confirms the change.',
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
      SessionReconnecting() => (
        icon: Icons.refresh_rounded,
        label: 'Reconnecting',
        color: AppColors.orange,
        title: 'Trying to reconnect…',
        detail: 'Check bike power and close any other connected app.',
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
        color: const Color(0xFFFF7982),
        title: failure.message,
        detail: 'Check Bluetooth, bike power, and other app connections.',
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
    required this.control,
    required this.keep,
    required this.onKeepChanged,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget control;
  final bool keep;
  final Future<void> Function(bool enabled)? onKeepChanged;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.magenta.withValues(alpha: 0.12),
                      ),
                      child: Icon(icon, color: AppColors.magentaSoft),
                    ),
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
                const SizedBox(height: 18),
                control,
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
              color: keep ? AppColors.yellow : AppColors.textMuted,
            ),
            title: const Text('Keep on connect'),
            subtitle: const Text('Reapply this value automatically'),
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

final class _LightControl extends StatelessWidget {
  const _LightControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value && enabled
          ? AppColors.yellow.withValues(alpha: 0.12)
          : AppColors.inkLight,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
                color: value && enabled
                    ? AppColors.yellow
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value ? 'Light on' : 'Light off',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ValueSelector extends StatelessWidget {
  const _ValueSelector({
    required this.values,
    required this.selected,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final List<int> values;
  final int? selected;
  final bool enabled;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: [
          for (final value in values)
            ButtonSegment<int>(value: value, label: Text(label(value))),
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
              return AppColors.magenta;
            }
            return AppColors.inkLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.ink;
            }
            return states.contains(WidgetState.disabled)
                ? AppColors.textMuted.withValues(alpha: 0.45)
                : AppColors.text;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
