import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/add_bike/add_bike_controller.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';

final class AddBikePage extends SignalStatefulWidget {
  const AddBikePage({required this.controller, super.key});

  final AddBikeController controller;

  @override
  State<AddBikePage> createState() => _AddBikePageState();
}

final class _AddBikePageState extends State<AddBikePage>
    with WidgetsBindingObserver {
  final TextEditingController _name = TextEditingController();
  String? _confirmationId;
  BikeRegion? _region;
  BikeColor _color = BikeColor.royalHorizon;
  String? _validationMessage;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.controller.state.peek() is AddBikePermissionRequired) {
      unawaited(widget.controller.retry(requestPermission: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    unawaited(widget.controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state.value;
    if (state case AddBikeConfirming(
      :final candidate,
      :final protocol,
      :final configuration,
      :final suggestedName,
    )) {
      if (_confirmationId != candidate.deviceId) {
        _confirmationId = candidate.deviceId;
        _name.text = suggestedName;
        _color = BikeColor.defaultForDeviceId(candidate.deviceId);
        _region = protocol.normalizeRegion(configuration.region);
      }
    } else {
      _confirmationId = null;
    }

    final previewColor = state is AddBikeConfirming ? _color : null;
    return Scaffold(
      backgroundColor: previewColor?.pageBaseColor,
      appBar: AppBar(title: const Text('ADD BIKE')),
      body: AppPageBody(
        bikeColor: previewColor,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (state) {
            AddBikeIdle() || AddBikeCheckingAccess() => const _ProgressMessage(
              key: ValueKey('checking'),
              title: 'Getting Bluetooth ready',
              detail: 'Superduper uses Bluetooth only to configure your bike.',
            ),
            AddBikePermissionRequired(:final permission) => _AccessMessage(
              key: const ValueKey('permission'),
              icon: Icons.bluetooth_disabled_rounded,
              title: permission == BluetoothPermissionState.restricted
                  ? 'Bluetooth access restricted'
                  : 'Bluetooth permission needed',
              detail: switch (permission) {
                BluetoothPermissionState.permanentlyDenied =>
                  'Allow Bluetooth access in system settings, then try again.',
                BluetoothPermissionState.restricted => 'A device or account restriction is preventing Bluetooth access.',
                _ => 'Bluetooth access is only used to find and configure your bike.',
              },
              primaryLabel: permission == BluetoothPermissionState.restricted
                  ? null
                  : permission == BluetoothPermissionState.permanentlyDenied
                  ? 'Open settings'
                  : 'Try again',
              onPrimary: permission == BluetoothPermissionState.restricted
                  ? null
                  : permission == BluetoothPermissionState.permanentlyDenied
                  ? () async {
                      await widget.controller.openPermissionSettings();
                    }
                  : widget.controller.retry,
            ),
            AddBikeAdapterUnavailable(:final adapterState) => _AccessMessage(
              key: const ValueKey('adapter'),
              icon: Icons.bluetooth_disabled_rounded,
              title: switch (adapterState) {
                BikeAdapterState.unauthorized => 'Bluetooth access unavailable',
                BikeAdapterState.unavailable => 'Bluetooth unavailable',
                BikeAdapterState.unknown => 'Bluetooth status unavailable',
                _ => 'Turn on Bluetooth',
              },
              detail: switch (adapterState) {
                BikeAdapterState.unauthorized =>
                  'Review Bluetooth permission in system settings.',
                BikeAdapterState.unavailable =>
                  'This device is not currently providing Bluetooth access.',
                BikeAdapterState.unknown =>
                  'Superduper could not determine whether Bluetooth is ready.',
                _ => 'Bluetooth must be on before Superduper can find a bike.',
              },
              primaryLabel: adapterState == BikeAdapterState.unauthorized
                  ? 'Open settings'
                  : 'Try again',
              onPrimary: adapterState == BikeAdapterState.unauthorized
                  ? () async {
                      await widget.controller.openPermissionSettings();
                    }
                  : widget.controller.retry,
            ),
            AddBikeLocationServicesDisabled() => _AccessMessage(
              key: const ValueKey('location-services'),
              icon: Icons.location_off_rounded,
              title: 'Turn on Location Services',
              detail: 'Android 10 and 11 require Location Services to be on while scanning for nearby Bluetooth bikes.',
              primaryLabel: 'Try again',
              onPrimary: widget.controller.retry,
            ),
            AddBikeScanning(
              :final results,
              :final savedDeviceIds,
              :final isScanning,
            ) =>
              _ScanResults(
                key: const ValueKey('scanning'),
                results: results,
                savedDeviceIds: savedDeviceIds,
                isScanning: isScanning,
                onSelect: widget.controller.selectCandidate,
                onScanAgain: widget.controller.retry,
              ),
            AddBikeConnecting(:final candidate) => _ProgressMessage(
              key: const ValueKey('connecting'),
              icon: Icons.bluetooth_connected_rounded,
              title:
                  'Checking ${candidate.name.isEmpty ? 'your bike' : candidate.name}',
              detail: 'Connecting, verifying compatibility, and reading its settings…',
            ),
            AddBikeConfirming(:final protocol) => KeyedSubtree(
              key: const ValueKey('confirming'),
              child: _confirmationForm(
                showRegion: protocol == BikeProtocolVersion.v1,
              ),
            ),
            AddBikeSaving() => const _ProgressMessage(
              key: ValueKey('saving'),
              icon: Icons.save_outlined,
              title: 'Saving your bike',
              detail: 'Finishing setup and making it ready to connect…',
            ),
            AddBikeCompleted() => const _AccessMessage(
              key: ValueKey('completed'),
              icon: Icons.check_circle_rounded,
              title: 'Bike saved',
              detail: 'Your bike is ready to use.',
              accent: AppColors.mint,
            ),
            AddBikeFailure(:final message) => _AccessMessage(
              key: const ValueKey('failure'),
              icon: Icons.error_outline_rounded,
              title: 'Could not add this bike',
              detail: userFacingError(
                message,
                context: UserErrorContext.addBike,
              ),
              primaryLabel: 'Scan again',
              onPrimary: widget.controller.retry,
              accent: AppColors.error,
            ),
          },
        ),
      ),
    );
  }

  Widget _confirmationForm({required bool showRegion}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        const StatusPill(
          label: 'Bike verified',
          color: AppColors.mint,
          icon: Icons.check_rounded,
        ),
        const SizedBox(height: 18),
        const SectionHeader(eyebrow: 'Step 2 of 2', title: 'Make it yours'),
        const SizedBox(height: 8),
        const Text(
          'Choose how this bike appears in your garage. You can change these details later.',
        ),
        const SizedBox(height: 24),
        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Bike name',
                  hintText: 'My bike',
                  errorText: _validationMessage,
                ),
              ),
              if (showRegion) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<BikeRegion>(
                  initialValue: _region,
                  decoration: const InputDecoration(labelText: 'Region'),
                  items: [
                    for (final region in BikeRegion.values)
                      DropdownMenuItem(
                        value: region,
                        child: Text(region.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _region = value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<BikeColor>(
                initialValue: _color,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Color'),
                items: [
                  for (final color in BikeColor.displayOrder)
                    DropdownMenuItem(
                      value: color,
                      child: BikeColorLabel(color: color),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _color = value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Save bike'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _validationMessage = 'Enter a bike name.');
      return;
    }
    setState(() {
      _validationMessage = null;
      _isSaving = true;
    });
    try {
      final saved = await widget.controller.confirm(
        displayName: _name.text,
        region: _region,
        color: _color,
      );
      if (mounted) {
        Navigator.pop(context, saved.bike.deviceId);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(error, context: UserErrorContext.saveBike),
            ),
          ),
        );
      }
    }
  }
}

final class _ScanResults extends StatelessWidget {
  const _ScanResults({
    required this.results,
    required this.savedDeviceIds,
    required this.isScanning,
    required this.onSelect,
    required this.onScanAgain,
    super.key,
  });

  final List<DiscoveredBike> results;
  final Set<String> savedDeviceIds;
  final bool isScanning;
  final Future<void> Function(DiscoveredBike candidate) onSelect;
  final Future<void> Function() onScanAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        StatusPill(
          label: isScanning ? 'Scanning' : 'Scan complete',
          color: isScanning ? AppColors.yellow : AppColors.textMuted,
          icon: Icons.bluetooth_searching_rounded,
        ),
        const SizedBox(height: 18),
        SectionHeader(
          eyebrow: 'Step 1 of 2',
          title: isScanning ? 'Looking for bikes…' : 'Choose your bike',
        ),
        const SizedBox(height: 8),
        const Text('Keep your bike powered on, unlocked, and nearby.'),
        if (isScanning) ...[
          const SizedBox(height: 24),
          const LinearProgressIndicator(borderRadius: BorderRadius.zero),
        ],
        const SizedBox(height: 24),
        if (results.isEmpty && !isScanning)
          SurfacePanel(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 14),
                Text(
                  'No compatible bikes found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Check bike power and make sure another app is not connected.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Scan again'),
                ),
              ],
            ),
          ),
        for (final candidate in results) ...[
          _CandidateTile(
            candidate: candidate,
            alreadySaved: savedDeviceIds.contains(candidate.deviceId),
            onTap: savedDeviceIds.contains(candidate.deviceId)
                ? null
                : () => unawaited(onSelect(candidate)),
          ),
          const SizedBox(height: 12),
        ],
        if (!isScanning && results.isNotEmpty)
          OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan again'),
          ),
      ],
    );
  }
}

final class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.alreadySaved,
    required this.onTap,
  });

  final DiscoveredBike candidate;
  final bool alreadySaved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (quality, icon, color) = switch (candidate.rssi) {
      >= -60 => (
        'Strong signal',
        Icons.signal_cellular_alt_rounded,
        AppColors.mint,
      ),
      >= -75 => (
        'Good signal',
        Icons.signal_cellular_alt_2_bar_rounded,
        AppColors.yellow,
      ),
      _ => (
        'Weak signal',
        Icons.signal_cellular_alt_1_bar_rounded,
        AppColors.orange,
      ),
    };
    return Opacity(
      opacity: alreadySaved ? 0.55 : 1,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  Icons.electric_bike_rounded,
                  color: AppColors.magentaSoft,
                  size: 32,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name.isEmpty
                            ? 'Compatible bike'
                            : candidate.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      if (alreadySaved)
                        const Text('Already saved')
                      else
                        Row(
                          children: [
                            Icon(icon, size: 17, color: color),
                            const SizedBox(width: 6),
                            Text('$quality · ${candidate.rssi} dBm'),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!alreadySaved)
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ProgressMessage extends StatelessWidget {
  const _ProgressMessage({
    required this.title,
    required this.detail,
    this.icon = Icons.bluetooth_searching_rounded,
    super.key,
  });

  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      child: SurfacePanel(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox.square(
                  dimension: 76,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                Icon(icon, color: AppColors.magentaSoft, size: 30),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _AccessMessage extends StatelessWidget {
  const _AccessMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.primaryLabel,
    this.onPrimary,
    this.accent = AppColors.orange,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? primaryLabel;
  final Future<void> Function()? onPrimary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      child: SurfacePanel(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: accent),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => unawaited(onPrimary!()),
                child: Text(primaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
