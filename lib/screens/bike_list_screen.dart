import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/router.dart';
import 'package:superduper/screens/bike_edit_sheet.dart';
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
                  color: Colors.amber.withAlpha(51),
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
                    ? const Color(0xff441DFC).withAlpha(51)
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
                  StatusChip(
                    icon: Icons.bluetooth_disabled,
                    label: 'Disconnect All',
                    color: Colors.red,
                    onTap: () {
                      ref.read(bikeRepositoryProvider).disconnectAllBikes();
                    },
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

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added bike: ${addedBike.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppRouter.navigateToBikeDetail(context, addedBike.id);
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error adding bike', e);

      if (!context.mounted) return;
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
                StatusChip(
                  icon: Icons.bluetooth_connected,
                  label: 'Connected',
                  color: Colors.green,
                )
              else
                StatusChip(
                  icon: Icons.bluetooth_disabled,
                  label: 'Disconnected',
                  color: Colors.grey,
                ),
              if (bike.isActive)
                StatusChip(
                  icon: Icons.autorenew,
                  label: 'Auto-connect',
                  color: const Color(0xff441DFC),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBikeOptionsDialog(
      BuildContext context, WidgetRef ref, BikeModel bike) {
    BikeEditBottomSheet.show(context, bike).then((updatedBike) {
      if (updatedBike != null) {
        ref.read(bikeRepositoryProvider).updateBike(updatedBike);
      }
    });
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
