import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/help/help_page.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

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
      backgroundColor: _color.pageBaseColor,
      appBar: AppBar(title: const Text('Bike settings')),
      body: AppPageBody(
        bikeColor: _color,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                BikeAvatar(color: _color, size: 68),
                const SizedBox(width: 16),
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
                        saved.bike.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
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
                        DropdownMenuItem(
                          value: region,
                          child: Text(region.label),
                        ),
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
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Bike color'),
                    items: [
                      for (final color in BikeColor.values)
                        DropdownMenuItem(
                          value: color,
                          child: BikeColorLabel(color: color),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (color) {
                            if (color != null) {
                              setState(() => _color = color);
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(saved),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving…' : 'Save changes'),
            ),
            const SizedBox(height: 34),
            const SectionHeader(
              eyebrow: 'On app launch',
              title: 'Automatic connection',
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
                      isActive
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isActive ? AppColors.yellow : AppColors.textMuted,
                    ),
                    title: const Text('Active bike'),
                    subtitle: Text(
                      isActive
                          ? 'Connects and applies kept settings when Superduper opens.'
                          : 'Make this the bike Superduper prepares first.',
                    ),
                    value: isActive,
                    onChanged: isActive || _saving
                        ? null
                        : (_) => unawaited(
                            coordinator.makeBikeActive(widget.deviceId),
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
                      title: const Text('Disconnect now'),
                      subtitle: const Text(
                        'Pause this connection until you reconnect or reopen the app.',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: coordinator.disconnectManually,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 34),
            const SectionHeader(eyebrow: 'Technical', title: 'Bike versions'),
            const SizedBox(height: 16),
            _BikeVersionsPanel(
              moduleSerial: saved.bike.moduleSerial,
              versions: saved.versions,
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
                        : 'Last connected ${saved.bike.lastConnectedAt!.toLocal()}',
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const HelpPage()),
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
              'This removes the bike and every kept setting from this device.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: _saving ? null : () => _forget(saved),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Forget bike'),
            ),
          ],
        ),
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

final class _BikeVersionsPanel extends StatelessWidget {
  const _BikeVersionsPanel({
    required this.moduleSerial,
    required this.versions,
  });

  final String? moduleSerial;
  final CachedBikeVersions? versions;

  @override
  Widget build(BuildContext context) {
    final cached = versions;
    if (cached == null && moduleSerial == null) {
      return const SurfacePanel(
        child: Text(
          'Connect to read version numbers. The module serial is captured when the bike is seen during discovery.',
        ),
      );
    }
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (moduleSerial case final serial?)
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
              value: _hex(info.stmFirmwareVersion, 6),
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
              value: _hex(info.motorControllerVersion, 8),
            ),
            _VersionRow(label: 'BMS', value: _hex(info.bmsVersion, 8)),
            const SizedBox(height: 12),
            Text(
              'Cache updated ${_formatTimestamp(readAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
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

  static String _hex(int value, int width) {
    return '0x${value.toRadixString(16).padLeft(width, '0').toUpperCase()}';
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 20),
          SelectionArea(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
