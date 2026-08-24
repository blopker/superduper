import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/add_bike/add_bike_controller.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

final class AddBikePage extends SignalStatefulWidget {
  const AddBikePage({required this.controller, super.key});

  final AddBikeController controller;

  @override
  State<AddBikePage> createState() => _AddBikePageState();
}

final class _AddBikePageState extends State<AddBikePage> {
  final TextEditingController _name = TextEditingController();
  String? _confirmationId;
  BikeRegion _region = BikeRegion.us;
  BikeColor _color = BikeColor.royalHorizon;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.start());
  }

  @override
  void dispose() {
    _name.dispose();
    unawaited(widget.controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state.value;
    if (state case AddBikeConfirming(
      :final candidate,
      :final configuration,
      :final suggestedName,
    )) {
      if (_confirmationId != candidate.deviceId) {
        _confirmationId = candidate.deviceId;
        _name.text = suggestedName;
        _region = configuration.region;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add bike')),
      body: SafeArea(
        child: switch (state) {
          AddBikeIdle() || AddBikeCheckingAccess() => const Center(
            child: CircularProgressIndicator(),
          ),
          AddBikePermissionRequired(:final permission) => _AccessMessage(
            icon: Icons.bluetooth_disabled,
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
            icon: Icons.bluetooth_disabled,
            title: switch (adapterState) {
              BikeAdapterState.unauthorized => 'Bluetooth access unavailable',
              BikeAdapterState.unavailable => 'Bluetooth unavailable',
              _ => 'Turn on Bluetooth',
            },
            detail: switch (adapterState) {
              BikeAdapterState.unauthorized =>
                'Review Bluetooth permission in system settings.',
              BikeAdapterState.unavailable =>
                'This device is not currently providing Bluetooth access.',
              _ => 'Bluetooth must be on before Superduper can find a bike.',
            },
            primaryLabel: 'Try again',
            onPrimary: widget.controller.retry,
          ),
          AddBikeScanning(:final results, :final isScanning) => _ScanResults(
            results: results,
            isScanning: isScanning,
            onSelect: widget.controller.selectCandidate,
            onScanAgain: widget.controller.retry,
          ),
          AddBikeConnecting(:final candidate) => _AccessMessage(
            icon: Icons.bluetooth_connected,
            title:
                'Checking ${candidate.name.isEmpty ? 'bike' : candidate.name}',
            detail: 'Connecting, discovering services, and reading settings…',
          ),
          AddBikeConfirming() => _confirmationForm(),
          AddBikeSaving() => const Center(child: CircularProgressIndicator()),
          AddBikeCompleted() => const Center(child: Text('Bike saved')),
          AddBikeFailure(:final message) => _AccessMessage(
            icon: Icons.error_outline,
            title: 'Could not add this bike',
            detail: message,
            primaryLabel: 'Scan again',
            onPrimary: widget.controller.retry,
          ),
        },
      ),
    );
  }

  Widget _confirmationForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Confirm bike', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('The connection and required bike services were verified.'),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Bike name',
            errorText: _validationMessage,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<BikeRegion>(
          initialValue: _region,
          decoration: const InputDecoration(labelText: 'Region'),
          items: [
            for (final region in BikeRegion.values)
              DropdownMenuItem(value: region, child: Text(region.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _region = value);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<BikeColor>(
          initialValue: _color,
          decoration: const InputDecoration(labelText: 'Color'),
          items: [
            for (final color in BikeColor.values)
              DropdownMenuItem(
                value: color,
                child: Text(color.key.replaceAll('_', ' ')),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _color = value);
            }
          },
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Save bike')),
      ],
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _validationMessage = 'Enter a bike name.');
      return;
    }
    setState(() => _validationMessage = null);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

final class _ScanResults extends StatelessWidget {
  const _ScanResults({
    required this.results,
    required this.isScanning,
    required this.onSelect,
    required this.onScanAgain,
  });

  final List<DiscoveredBike> results;
  final bool isScanning;
  final Future<void> Function(DiscoveredBike candidate) onSelect;
  final Future<void> Function() onScanAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isScanning ? 'Looking for bikes…' : 'Scan complete',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Keep the bike powered on and nearby.'),
        const SizedBox(height: 16),
        if (isScanning) const LinearProgressIndicator(),
        if (results.isEmpty && !isScanning) ...[
          const SizedBox(height: 32),
          const Text('No compatible bikes were found.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onScanAgain, child: const Text('Scan again')),
        ],
        for (final candidate in results)
          Card(
            child: ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(
                candidate.name.isEmpty ? 'SUPER73 bike' : candidate.name,
              ),
              subtitle: Text('Signal ${candidate.rssi} dBm'),
              onTap: () => unawaited(onSelect(candidate)),
            ),
          ),
      ],
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
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? primaryLabel;
  final Future<void> Function()? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 20),
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
