import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/distance.dart';
import 'package:superduper/src/features/bike_settings/bike_version_report.dart';
import 'package:superduper/src/features/help/help_page.dart';
import 'package:superduper/src/platform/report_exporter.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';
import 'package:superduper/src/widgets/report_actions.dart';

enum BikeSettingsOutcome { forgotten }

final class BikeSettingsPage extends SignalStatefulWidget {
  const BikeSettingsPage({required this.initialBike, super.key});

  final SavedBike initialBike;

  @override
  State<BikeSettingsPage> createState() => _BikeSettingsPageState();
}

final class _BikeSettingsPageState extends State<BikeSettingsPage> {
  static const _nameSaveDelay = Duration(milliseconds: 600);

  final TextEditingController _name = TextEditingController();
  late AppServices _services;
  late BikeRegion? _region;
  late BikeColor _color;
  late BikeProtocolVersion _protocol;
  Timer? _nameSaveTimer;
  Future<void>? _saveFuture;
  String? _nameError;
  String? _regionError;
  var _saveRequested = false;
  var _saving = false;
  var _forgetting = false;
  var _closing = false;
  var _allowPop = false;
  var _regionFieldRevision = 0;
  var _protocolFieldRevision = 0;

  @override
  void initState() {
    super.initState();
    final bike = widget.initialBike.bike;
    _name.text = bike.displayName;
    _protocol = bike.protocol;
    _region = bike.region;
    _color = bike.color;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = AppServicesScope.of(context);
  }

  @override
  void dispose() {
    _nameSaveTimer?.cancel();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _services.activeBikeCoordinator.bikes.value.where(
      (saved) => saved.bike.deviceId == widget.initialBike.bike.deviceId,
    );
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('BIKE SETTINGS')),
        body: const AppPageBody(child: Center(child: Text('Bike not found'))),
      );
    }
    final saved = matches.single;
    final coordinator = _services.activeBikeCoordinator;
    final deviceId = widget.initialBike.bike.deviceId;
    final isActive = coordinator.activeBikeId.value == deviceId;
    final activeState = coordinator.state.value;
    final matchingStatus =
        activeState is ActiveBikeSessionStatus &&
            activeState.bike.bike.deviceId == deviceId
        ? activeState
        : null;
    final hasSession = matchingStatus != null;
    final sessionState = matchingStatus?.sessionState;
    final canReconnect =
        sessionState is SessionDisconnected || sessionState is SessionFailed;
    final page = BikePageScaffold(
      title: 'Bike settings',
      color: _color,
      children: [
        BikeHeader(
          color: _color,
          name: saved.bike.displayName,
          isActive: isActive,
        ),
        const SizedBox(height: 30),
        const SectionHeader(eyebrow: 'Identity', title: 'Bike details'),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Bike name',
                  errorText: _nameError,
                ),
                onChanged: _scheduleNameSave,
                onSubmitted: (_) => _saveNameNow(),
              ),
              if (_protocol == BikeProtocolVersion.v1) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<BikeRegion>(
                  key: ValueKey((_region, _regionFieldRevision)),
                  initialValue: _region,
                  decoration: InputDecoration(
                    labelText: 'Region',
                    errorText: _regionError,
                  ),
                  items: [
                    for (final region in BikeRegion.values)
                      DropdownMenuItem(
                        value: region,
                        child: Text(region.label),
                      ),
                  ],
                  onChanged: (region) {
                    if (region != null) {
                      unawaited(_changeRegion(region));
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<BikeColor>(
                initialValue: _color,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bike color',
                ),
                items: [
                  for (final color in BikeColor.displayOrder)
                    DropdownMenuItem(
                      value: color,
                      child: BikeColorLabel(color: color),
                    ),
                ],
                onChanged: (color) {
                  if (color != null && color != _color) {
                    setState(() => _color = color);
                    unawaited(_queueSaveNow());
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const SectionHeader(
          eyebrow: 'Advanced',
          title: 'BLE protocol',
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<BikeProtocolVersion>(
                key: ValueKey((_protocol, _protocolFieldRevision)),
                initialValue: _protocol,
                decoration: const InputDecoration(labelText: 'Protocol'),
                items: [
                  for (final protocol in BikeProtocolVersion.values)
                    DropdownMenuItem(
                      value: protocol,
                      child: Text(_protocolLabel(protocol)),
                    ),
                ],
                onChanged: (protocol) {
                  if (protocol != null) {
                    unawaited(_changeProtocol(protocol));
                  }
                },
              ),
              const SizedBox(height: 14),
              Text(
                'The advertised name “${saved.bike.advertisedName}” selects ${_protocolLabel(BikeProtocolVersion.fromAdvertisedName(saved.bike.advertisedName) ?? BikeProtocolVersion.v1)} by default. Only change this if that choice is wrong; the wrong protocol can prevent controls and Set on connect values from working.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const SectionHeader(
          eyebrow: 'On app launch',
          title: 'Connection preference',
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                secondary: Icon(
                  isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isActive ? AppColors.yellow : AppColors.textMuted,
                ),
                title: const Text('Auto connect'),
                subtitle: Text(
                  isActive
                      ? 'Connects and applies Set on connect values when Superduper opens.'
                      : 'Use this bike when Superduper opens.',
                ),
                value: isActive,
                onChanged: isActive
                    ? null
                    : (_) => unawaited(
                        _runCoordinatorAction(
                          () => coordinator.makeBikeActive(
                            deviceId,
                          ),
                        ),
                      ),
              ),
              if (hasSession) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  leading: const Icon(Icons.bluetooth_disabled_rounded),
                  title: Text(
                    canReconnect ? 'Reconnect now' : 'Disconnect now',
                  ),
                  subtitle: Text(
                    canReconnect
                        ? 'Connect again and apply this bike’s Set on connect values.'
                        : 'Pause this connection until you reconnect or reopen the app.',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => unawaited(
                    _runCoordinatorAction(
                      canReconnect
                          ? coordinator.retry
                          : coordinator.disconnectManually,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 34),
        const SectionHeader(eyebrow: 'Technical', title: 'Bike information'),
        const SizedBox(height: 16),
        _BikeVersionsPanel(
          bike: saved.bike,
          versions: saved.versions,
          odometer: saved.odometer,
        ),
        const SizedBox(height: 34),
        const SectionHeader(
          eyebrow: 'Technical',
          title: 'Connection details',
        ),
        const SizedBox(height: 16),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BLE device identifier',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 7),
              SelectionArea(
                child: Text(
                  saved.bike.deviceId,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                saved.bike.lastConnectedAt == null
                    ? 'No confirmed connection recorded yet.'
                    : 'Last connected ${_BikeVersionsPanel._formatTimestamp(saved.bike.lastConnectedAt!)}',
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpPage(),
                  ),
                ),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Connection help'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const SectionHeader(
          eyebrow: 'Danger zone',
          title: 'Forget this bike',
        ),
        const SizedBox(height: 10),
        const Text(
          'This removes the bike and every Set on connect value from this device.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _saving || _forgetting ? null : () => _forget(saved),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(_forgetting ? 'Forgetting…' : 'Forget bike'),
        ),
      ],
    );
    return PopScope(
      canPop: _allowPop || (!_saving && _nameSaveTimer == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_saveBeforeExit());
        }
      },
      child: page,
    );
  }

  void _scheduleNameSave(String value) {
    _nameSaveTimer?.cancel();
    _nameSaveTimer = null;
    final nameIsEmpty = value.trim().isEmpty;
    setState(() {
      _nameError = nameIsEmpty ? 'Enter a bike name.' : null;
      if (!nameIsEmpty) {
        _nameSaveTimer = Timer(_nameSaveDelay, () {
          _nameSaveTimer = null;
          if (!mounted) {
            return;
          }
          setState(() {});
          unawaited(_queueSave());
        });
      }
    });
  }

  void _saveNameNow() {
    _nameSaveTimer?.cancel();
    _nameSaveTimer = null;
    final nameIsEmpty = _name.text.trim().isEmpty;
    setState(() {
      _nameError = nameIsEmpty ? 'Enter a bike name.' : null;
    });
    if (!nameIsEmpty) {
      unawaited(_queueSave());
    }
  }

  Future<void> _changeRegion(BikeRegion region) async {
    if (region == _region) {
      return;
    }
    if (_region != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change bike region?'),
          content: const Text(
            'The selected region is included the next time Superduper sends settings to the bike. Changing it here does not immediately write to the bike.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Change region'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      if (!(confirmed ?? false)) {
        setState(() => _regionFieldRevision += 1);
        return;
      }
    }
    setState(() {
      _region = region;
      _regionError = null;
      _regionFieldRevision += 1;
    });
    await _queueSaveNow();
  }

  Future<void> _changeProtocol(BikeProtocolVersion protocol) async {
    if (protocol == _protocol) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CHANGE BIKE PROTOCOL?'),
        content: Text(
          'Superduper will reconnect using ${_protocolLabel(protocol)}. If this does not match the bike, controls and Set on connect values may stop working.${protocol == BikeProtocolVersion.v1 && _region == null ? ' V1 will initially use the US region.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change protocol'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (!(confirmed ?? false)) {
      setState(() => _protocolFieldRevision += 1);
      return;
    }
    setState(() {
      _protocol = protocol;
      _region = protocol == BikeProtocolVersion.v1
          ? (_region ?? BikeRegion.us)
          : null;
      _regionError = null;
      _protocolFieldRevision += 1;
      _regionFieldRevision += 1;
    });
    await _queueSaveNow();
  }

  Future<void> _queueSaveNow() {
    _nameSaveTimer?.cancel();
    _nameSaveTimer = null;
    return _queueSave();
  }

  Future<void> _queueSave() {
    _saveRequested = true;
    if (_saveFuture case final pending?) {
      return pending;
    }
    final future = _drainSaves();
    _saveFuture = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_saveFuture, future)) {
          _saveFuture = null;
        }
      }),
    );
    return future;
  }

  Future<void> _drainSaves() async {
    if (mounted) {
      setState(() => _saving = true);
    }
    var savedAnyChanges = false;
    var failed = false;
    while (_saveRequested) {
      _saveRequested = false;
      final name = _name.text.trim();
      if (name.isEmpty ||
          (_protocol == BikeProtocolVersion.v1 && _region == null)) {
        if (mounted) {
          setState(() {
            _nameError = name.isEmpty ? 'Enter a bike name.' : null;
            _regionError =
                _protocol == BikeProtocolVersion.v1 && _region == null
                ? 'Choose the bike region.'
                : null;
          });
        }
        break;
      }
      try {
        await _services.bikeRepository.updateBikeDetails(
          widget.initialBike.bike.deviceId,
          displayName: name,
          region: _region,
          color: _color,
          protocol: _protocol,
        );
        savedAnyChanges = true;
      } on Object catch (error) {
        failed = true;
        _saveRequested = false;
        if (mounted) {
          _showMessage(
            userFacingError(error, context: UserErrorContext.saveBike),
          );
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (savedAnyChanges && !failed) {
      _showMessage('Saved', isToast: true);
    }
  }

  Future<void> _saveBeforeExit() async {
    if (_closing) {
      return;
    }
    _closing = true;
    final hasPendingNameSave = _nameSaveTimer != null;
    _nameSaveTimer?.cancel();
    _nameSaveTimer = null;
    if (hasPendingNameSave && _name.text.trim().isNotEmpty) {
      await _queueSave();
    } else if (_saveFuture case final pending?) {
      await pending;
    }
    if (!mounted) {
      return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showMessage(String message, {bool isToast = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: isToast ? SnackBarBehavior.floating : null,
          duration: isToast
              ? const Duration(milliseconds: 1200)
              : const Duration(seconds: 4),
          content: Text(message),
        ),
      );
  }

  static String _protocolLabel(BikeProtocolVersion protocol) {
    return '${protocol.name.toUpperCase()} — ${protocol.advertisedName}';
  }

  Future<void> _runCoordinatorAction(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
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

  Future<void> _forget(SavedBike saved) async {
    if (_forgetting) {
      return;
    }
    setState(() => _forgetting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Forget ${saved.bike.displayName}?'),
          content: const Text(
            'This removes the bike and all its saved settings.',
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
      if (!mounted || !(confirmed ?? false)) {
        return;
      }
      try {
        await _services.activeBikeCoordinator.forgetBike(
          widget.initialBike.bike.deviceId,
        );
        if (mounted) {
          Navigator.pop(context, BikeSettingsOutcome.forgotten);
        }
      } on Object catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userFacingError(error, context: UserErrorContext.bikeAction),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _forgetting = false);
      }
    }
  }
}

final class _BikeVersionsPanel extends StatelessWidget {
  const _BikeVersionsPanel({
    required this.bike,
    required this.versions,
    required this.odometer,
  });

  final Bike bike;
  final CachedBikeVersions? versions;
  final CachedBikeOdometer? odometer;

  @override
  Widget build(BuildContext context) {
    final cached = versions;
    if (cached == null && bike.moduleSerial == null && odometer == null) {
      return const SurfacePanel(
        child: Text(
          'Connect to read the odometer and version numbers. The module serial is captured when the bike is seen during discovery.',
        ),
      );
    }
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (odometer case CachedBikeOdometer(
            :final meters,
            :final readAt,
          )) ...[
            _VersionRow(
              label: 'Odometer',
              value: formatOdometerDistance(meters),
            ),
            Text(
              'Read ${_formatTimestamp(readAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (bike.moduleSerial case final serial?)
            _VersionRow(label: 'Module serial', value: serial),
          if (cached case CachedBikeVersions(:final info, :final readAt)) ...[
            _VersionRow(
              label: 'Hardware revision',
              value: info.hardwareRevision,
            ),
            _VersionRow(
              label: 'Display firmware',
              value: info.firmwareRevision,
            ),
            _VersionRow(
              label: 'Software revision',
              value: info.softwareRevision,
            ),
            _VersionRow(
              label: 'STM firmware',
              value: info.stmFirmwareVersion.toString(),
            ),
            _VersionRow(
              label: 'Controller variant',
              value: info.controllerVariant.toString(),
            ),
            _VersionRow(
              label: 'Bootloader handoff',
              value: info.bootloaderHandoff.toString(),
            ),
            _VersionRow(
              label: 'Motor controller',
              value: info.motorControllerVersion.toString(),
            ),
            _VersionRow(label: 'BMS', value: info.bmsVersion.toString()),
            const SizedBox(height: 12),
            Text(
              'Cache updated ${_formatTimestamp(readAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            ReportActions(
              createReport: () => _createReport(cached),
              shareLabel: 'Save or send bike info',
              copyLabel: 'Copy bike info',
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Version numbers will appear after a successful connection.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Future<ShareableReport> _createReport(CachedBikeVersions versions) async {
    final metadata = await ReportMetadata.fromPlatform();
    return ShareableReport(
      content: createBikeVersionReport(
        bike: bike,
        versions: versions,
        odometer: odometer,
        metadata: metadata,
      ),
      filenamePrefix: 'superduper-bike-info',
      subject: 'Superduper bike information',
      message: 'Bike information exported from Superduper. The attached text file contains the bike BLE identifier and may contain its module serial.',
    );
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

final class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          SelectionArea(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
