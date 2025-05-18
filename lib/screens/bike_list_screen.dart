import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/router.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';
import 'package:superduper/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen that displays a list of all saved bikes and allows scanning for new ones.
class BikeListScreen extends ConsumerWidget {
  const BikeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikesProvider);
    final isScanning = ref.watch(isScanningStatusProvider);
    final bleStatus = ref.watch(adapterStateProvider);
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff441DFC),
        onPressed: () {
          if (isScanning.valueOrNull ?? false) {
            ref.read(bluetoothServiceProvider).stopScan();
          } else {
            ref.read(bluetoothServiceProvider).startScan();
          }
        },
        child: Icon(
          isScanning.valueOrNull ?? false
              ? Icons.stop
              : Icons.bluetooth_searching,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: bikesAsync.when(
            data: (bikes) => _buildBikesList(
                context, ref, bikes, scrollController, isScanning, bleStatus),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Error loading bikes: ${err.toString()}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBikesList(
      BuildContext context,
      WidgetRef ref,
      List<BikeModel> bikes,
      ScrollController scrollController,
      AsyncValue<bool> isScanning,
      AsyncValue<BluetoothAdapterState> bleStatus) {
    final scanResults = ref.watch(scanResultsProvider);

    List<BikeModel> foundBikes = [];
    for (var result in scanResults.valueOrNull ?? []) {
      if (bikes
          .any((bike) => bike.bluetoothAddress == result.device.remoteId.str)) {
        continue;
      }
      foundBikes.add(BikeModel.defaultBike(
          result.device.remoteId.str, result.device.remoteId.str));
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // App Bar with SUPERDUPER title
        SliverAppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.black,
          pinned: true,
          expandedHeight: 80,
          stretch: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: Colors.black),
            title: Text(
              'SUPERDUPER',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            collapseMode: CollapseMode.pin,
            stretchModes: const [],
          ),
        ),

        // Bluetooth Status Indicator
        SliverToBoxAdapter(
          child: bleStatus.when(
            data: (state) {
              if (state == BluetoothAdapterState.on) {
                return const SizedBox.shrink();
              }

              String message = switch (state) {
                BluetoothAdapterState.off => 'Bluetooth is turned off',
                BluetoothAdapterState.unauthorized =>
                  'Bluetooth permissions are needed',
                _ => 'Bluetooth unavailable'
              };

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.amber,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // Scanning Status Indicator
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 40,
              decoration: BoxDecoration(
                color: isScanning.valueOrNull ?? false
                    ? const Color(0xff441DFC).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: isScanning.valueOrNull ?? false
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Scanning for bikes...',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // My Bikes Section
        if (bikes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Bikes',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(bikeRepositoryProvider).disconnectAllBikes();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bluetooth_disabled,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Disconnect All',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _BikeCard(bike: bikes[index]),
                  );
                },
                childCount: bikes.length,
              ),
            ),
          ),
        ],

        // Found Bikes Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found Bikes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const _NotConnectingButton(),
              ],
            ),
          ),
        ),

        // Found Bikes List or Empty State
        foundBikes.isEmpty
            ? SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.only(top: 30),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        size: 50,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bikes found nearby',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(bluetoothServiceProvider).startScan();
                        },
                        child: Text(
                          'TAP TO SCAN',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xff441DFC),
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var bike = foundBikes[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: DiscoverCard(
                          selected: false,
                          onTap: () => _addBike(context, ref, bike),
                          title: bike.name,
                        ),
                      );
                    },
                    childCount: foundBikes.length,
                  ),
                ),
              ),

        // Debug Button in Debug Mode
        if (kDebugMode)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/debug');
                },
                child: const Text('DEBUG CONSOLE'),
              ),
            ),
          ),

        // Bottom Padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _addBike(BuildContext context, WidgetRef ref, BikeModel bike) async {
    try {
      final addedBike = await ref.read(bikeRepositoryProvider).addBike(
            bike.id,
            bike.bluetoothAddress,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added bike: ${addedBike.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppRouter.navigateToBikeDetail(context, addedBike.id);
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error adding bike', e);
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

class _BikeCard extends ConsumerWidget {
  final BikeModel bike;

  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeService = ref.watch(bikeServiceProvider(bike.id));

    return StreamBuilder<BikeConnectionState>(
      stream: bikeService?.connectionStateStream,
      initialData:
          bikeService?.connectionState ?? BikeConnectionState.disconnected,
      builder: (context, snapshot) {
        final connectionState =
            snapshot.data ?? BikeConnectionState.disconnected;
        final isConnected = connectionState == BikeConnectionState.connected;

        return DiscoverCard(
          selected: isConnected,
          onTap: () {
            AppRouter.navigateToBikeDetail(context, bike.id);
          },
          onLongPress: () {
            _showBikeOptionsDialog(context, ref, bike);
          },
          title: bike.name,
          colorIndex: bike.color,
          vectorBottom: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isConnected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bluetooth_connected,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bluetooth_disabled,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Disconnected',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              if (bike.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff441DFC).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xff441DFC).withOpacity(0.3),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.autorenew,
                          size: 14, color: Color(0xff441DFC)),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-connect',
                        style: const TextStyle(
                            color: Color(0xff441DFC),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBikeOptionsDialog(
      BuildContext context, WidgetRef ref, BikeModel bike) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(bike.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-connect',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Connect when app starts',
                  style: TextStyle(color: Colors.grey)),
              value: bike.isActive,
              onChanged: (value) {
                ref.read(bikeRepositoryProvider).setBikeActive(bike.id, value);
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title:
                  const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, bike);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, ref, bike);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: Color(0xff441DFC))),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, BikeModel bike) {
    final textController = TextEditingController(text: bike.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rename Bike', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Bike Name',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xff441DFC)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                final updatedBike =
                    bike.copyWith(name: textController.text.trim());
                ref.read(bikeRepositoryProvider).updateBike(updatedBike);
                Navigator.pop(context);
              }
            },
            child:
                const Text('SAVE', style: TextStyle(color: Color(0xff441DFC))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, BikeModel bike) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Bike', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${bike.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(bikeRepositoryProvider).deleteBike(bike.id);
              Navigator.pop(context);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _NotConnectingButton extends StatelessWidget {
  const _NotConnectingButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Not connecting?',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
      onTap: () async {
        final Uri url = Uri.parse('https://github.com/blopker/superduper#faq');
        launchUrl(url, mode: LaunchMode.externalApplication);
      },
    );
  }
}
