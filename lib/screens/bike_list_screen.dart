import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/router.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';

/// Screen that displays a list of all saved bikes and allows scanning for new ones.
class BikeListScreen extends ConsumerWidget {
  const BikeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Bikes'),
      ),
      body: bikesAsync.when(
        data: (bikes) => _buildBikesList(context, ref, bikes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading bikes: ${err.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScanDialog(context, ref),
        icon: const Icon(Icons.bluetooth_searching),
        label: const Text('SCAN'),
      ),
    );
  }

  Widget _buildBikesList(
      BuildContext context, WidgetRef ref, List<BikeModel> bikes) {
    if (bikes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bikes added yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the SCAN button to find bikes',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bikes.length,
      itemBuilder: (context, index) {
        final bike = bikes[index];
        return _BikeListTile(bike: bike);
      },
    );
  }

  void _showScanDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => const _ScanDialog(),
    );
    ref.read(bluetoothServiceProvider).stopScan();
  }
}

class _BikeListTile extends ConsumerWidget {
  final BikeModel bike;

  const _BikeListTile({required this.bike});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeService = ref.watch(bikeServiceProvider(bike.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder<BikeConnectionState>(
        stream: bikeService?.connectionStateStream,
        initialData:
            bikeService?.connectionState ?? BikeConnectionState.disconnected,
        builder: (context, snapshot) {
          final connectionState =
              snapshot.data ?? BikeConnectionState.disconnected;
          final isConnected = connectionState == BikeConnectionState.connected;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.electric_bike),
            ),
            title: Text(
              bike.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 14,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                if (bike.isActive) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.autorenew, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text(
                    'Auto-connect',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ],
            ),
            trailing: Switch(
              value: bike.isActive,
              onChanged: (value) {
                ref.read(bikeRepositoryProvider).setBikeActive(bike.id, value);
              },
            ),
            onTap: () {
              AppRouter.navigateToBikeDetail(context, bike.id);
            },
          );
        },
      ),
    );
  }
}

class _ScanDialog extends ConsumerStatefulWidget {
  const _ScanDialog();

  @override
  ConsumerState<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends ConsumerState<_ScanDialog> {
  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    try {
      await ref.read(bluetoothServiceProvider).startScan(
            timeout: const Duration(seconds: 15),
          );
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error scanning for bikes', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResultsAsync = ref.watch(scanResultsProvider);
    final isScanning = ref.watch(isScanningStatusProvider).valueOrNull ?? false;

    return AlertDialog(
      title: const Text('Scan for Bikes'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (isScanning)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                isScanning
                    ? 'Scanning for bikes nearby...'
                    : 'Select a bike to add:',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: scanResultsAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'No bikes found. Make sure your bike is turned on.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final device = result.device;
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : device.remoteId.str;

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(device.remoteId.str),
                        leading: const Icon(Icons.bluetooth),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _addBike(device, name),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error: ${err.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        if (!isScanning)
          TextButton(
            onPressed: _startScan,
            child: const Text('SCAN AGAIN'),
          ),
      ],
    );
  }

  void _addBike(BluetoothDevice device, String name) async {
    try {
      final bike = await ref.read(bikeRepositoryProvider).addBike(
            device.remoteId.str,
            device.remoteId.str,
          );

      log.i(SDLogger.BIKE, 'Added new bike: ${bike.name} (${bike.id})');

      if (mounted) {
        Navigator.of(context).pop();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added bike: ${bike.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error adding bike', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding bike: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
