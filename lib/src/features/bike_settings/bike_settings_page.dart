import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/help/help_page.dart';

enum BikeSettingsOutcome { forgotten }

final class BikeSettingsPage extends SignalStatefulWidget {
  const BikeSettingsPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<BikeSettingsPage> createState() => _BikeSettingsPageState();
}

final class _BikeSettingsPageState extends State<BikeSettingsPage> {
  final TextEditingController _name = TextEditingController();
  late AppServices _services;
  String? _loadedDeviceId;
  BikeRegion _region = BikeRegion.us;
  BikeColor _color = BikeColor.royalHorizon;
  String? _nameError;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = AppServicesScope.of(context);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _services.activeBikeCoordinator.bikes.value.where(
      (saved) => saved.bike.deviceId == widget.deviceId,
    );
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Bike not found')));
    }
    final saved = matches.single;
    if (_loadedDeviceId != saved.bike.deviceId) {
      _loadedDeviceId = saved.bike.deviceId;
      _name.text = saved.bike.displayName;
      _region = saved.bike.region ?? BikeRegion.us;
      _color = saved.bike.color;
    }
    final coordinator = _services.activeBikeCoordinator;
    final isActive = coordinator.activeBikeId.value == widget.deviceId;
    final hasSession = coordinator.session.value?.deviceId == widget.deviceId;

    return Scaffold(
      appBar: AppBar(title: const Text('Bike settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: 'Bike name',
              errorText: _nameError,
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
            onChanged: _saving
                ? null
                : (region) {
                    if (region != null) {
                      setState(() => _region = region);
                    }
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BikeColor>(
            initialValue: _color,
            decoration: const InputDecoration(labelText: 'Bike color'),
            items: [
              for (final color in BikeColor.values)
                DropdownMenuItem(value: color, child: Text(color.displayName)),
            ],
            onChanged: _saving
                ? null
                : (color) {
                    if (color != null) {
                      setState(() => _color = color);
                    }
                  },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : () => _save(saved),
            child: Text(_saving ? 'Saving…' : 'Save changes'),
          ),
          const SizedBox(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active bike'),
            subtitle: const Text(
              'Auto-connect and apply kept settings on launch.',
            ),
            value: isActive,
            onChanged: isActive || _saving
                ? null
                : (_) => unawaited(coordinator.makeBikeActive(widget.deviceId)),
          ),
          if (hasSession)
            OutlinedButton(
              onPressed: coordinator.disconnectManually,
              child: const Text('Disconnect'),
            ),
          const SizedBox(height: 28),
          Text('Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('BLE device identifier'),
          const SizedBox(height: 4),
          SelectionArea(child: Text(saved.bike.deviceId)),
          const SizedBox(height: 12),
          Text(
            saved.bike.lastConnectedAt == null
                ? 'No confirmed connection recorded yet.'
                : 'Last connected: ${saved.bike.lastConnectedAt!.toLocal()}',
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const HelpPage()),
            ),
            child: const Text('Connection help'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _saving ? null : () => _forget(saved),
            child: const Text('Forget bike'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(SavedBike saved) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a bike name.');
      return;
    }
    if (saved.bike.region != null && saved.bike.region != _region) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change bike region?'),
          content: const Text(
            'Region changes how future Mode commands are encoded. It does not change the bike until you explicitly choose a mode.',
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
      if (!(confirmed ?? false)) {
        return;
      }
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });
    try {
      await _services.bikeRepository.updateBikeDetails(
        widget.deviceId,
        displayName: name,
        region: _region,
        color: _color,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _forget(SavedBike saved) async {
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
    if (!(confirmed ?? false)) {
      return;
    }
    await _services.activeBikeCoordinator.forgetBike(widget.deviceId);
    if (mounted) {
      Navigator.pop(context, BikeSettingsOutcome.forgotten);
    }
  }
}
