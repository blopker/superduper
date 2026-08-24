import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/features/bike_settings/bike_settings_page.dart';
import 'package:superduper/src/features/help/help_page.dart';

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
      return const Scaffold(body: Center(child: Text('Loading bike…')));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(bike.bike.displayName),
        actions: [
          IconButton(
            tooltip: 'Help & tips',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const HelpPage()),
            ),
            icon: const Icon(Icons.help_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => unawaited(_handleMenu(value)),
            itemBuilder: (_) => [
              if (coordinator.activeBikeId.peek() != widget.deviceId)
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ConnectionSummary(state: sessionState),
            const SizedBox(height: 20),
            _SettingSection(
              title: 'Light',
              value: configuration == null
                  ? 'Unavailable'
                  : configuration.light
                  ? 'On'
                  : 'Off',
              control: Switch(
                value: configuration?.light ?? false,
                onChanged: ready
                    ? (value) => _runCommand(() => session!.setLight(value))
                    : null,
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
            _SettingSection(
              title: 'Mode',
              value: configuration == null
                  ? 'Unavailable'
                  : '${configuration.mode + 1}',
              control: DropdownButton<int>(
                value: configuration?.mode,
                hint: const Text('—'),
                items: [
                  for (var mode = 0; mode < 4; mode++)
                    DropdownMenuItem(value: mode, child: Text('${mode + 1}')),
                ],
                onChanged: ready
                    ? (value) {
                        if (value != null) {
                          _runCommand(() => session!.setMode(value));
                        }
                      }
                    : null,
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
            _SettingSection(
              title: 'Assist',
              value: configuration == null
                  ? 'Unavailable'
                  : '${configuration.assist}',
              control: DropdownButton<int>(
                value: configuration?.assist,
                hint: const Text('—'),
                items: [
                  for (var assist = 0; assist < 5; assist++)
                    DropdownMenuItem(value: assist, child: Text('$assist')),
                ],
                onChanged: ready
                    ? (value) {
                        if (value != null) {
                          _runCommand(() => session!.setAssist(value));
                        }
                      }
                    : null,
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
            const SizedBox(height: 12),
            const Text(
              '“Keep this setting” applies the confirmed value whenever this bike connects while Superduper is open.',
            ),
            if (sessionState is SessionFailed ||
                sessionState is SessionDisconnected) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: coordinator.retry,
                child: const Text('Reconnect'),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
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
        return;
      case 'settings':
        await _openSettings();
        return;
      case 'disconnect':
        await _services.activeBikeCoordinator.disconnectManually();
        return;
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

final class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.state});

  final BikeSessionState state;

  @override
  Widget build(BuildContext context) {
    final (icon, text, detail) = switch (state) {
      SessionReady() => (
        Icons.check_circle_outline,
        'Ready to ride',
        'The bike is connected and kept settings are confirmed.',
      ),
      SessionSynchronizing() => (
        Icons.sync,
        'Applying settings…',
        'Controls will be available after the bike confirms the change.',
      ),
      SessionConnecting() => (
        Icons.bluetooth_searching,
        'Connecting…',
        'Keep the bike powered on and nearby.',
      ),
      SessionDiscovering() || SessionConnected() => (
        Icons.bluetooth_connected,
        'Checking bike…',
        'Validating services and reading current settings.',
      ),
      SessionReconnecting() => (
        Icons.refresh,
        'Reconnecting…',
        'Check that the bike is on and no other app is connected.',
      ),
      SessionDisconnected(:final manuallyPaused) => (
        Icons.bluetooth_disabled,
        manuallyPaused ? 'Disconnected by you' : 'Disconnected',
        manuallyPaused
            ? 'Automatic reconnect is paused until you reconnect or reopen the app.'
            : 'Check Bluetooth and make sure the bike is powered on.',
      ),
      SessionFailed(:final failure) => (
        Icons.error_outline,
        failure.message,
        'Check Bluetooth, bike power, and whether another app is connected.',
      ),
      SessionIdle() => (
        Icons.bluetooth_searching,
        'Preparing…',
        'Starting the bike session.',
      ),
      SessionDisposed() => (
        Icons.bluetooth_disabled,
        'Connection closed',
        'Return Home and select the bike to try again.',
      ),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      subtitle: Text(detail),
    );
  }
}

final class _SettingSection extends StatelessWidget {
  const _SettingSection({
    required this.title,
    required this.value,
    required this.control,
    required this.keep,
    required this.onKeepChanged,
  });

  final String title;
  final String value;
  final Widget control;
  final bool keep;
  final Future<void> Function(bool enabled)? onKeepChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            subtitle: Text(value),
            trailing: control,
          ),
          SwitchListTile(
            title: const Text('Keep this setting'),
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
