import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/db.dart';
import 'package:superduper/debug.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class BikeSelectWidget extends ConsumerStatefulWidget {
  const BikeSelectWidget({super.key});

  @override
  BikeSelectWidgetState createState() => BikeSelectWidgetState();
}

class BikeSelectWidgetState extends ConsumerState<BikeSelectWidget> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    ref.read(bluetoothRepositoryProvider).scan();
    super.initState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void selectBike(BikeState bike) {
    var settings = ref.read(settingsDBProvider);
    ref
        .read(settingsDBProvider.notifier)
        .save(settings.copyWith(currentBike: bike.id));
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return BikePage(bikeID: bike.id);
    }));
  }

  bool isConnected(
          AsyncValue<List<BluetoothDevice>> connected, String bikeID) =>
      connected.value?.any((element) => element.remoteId.str == bikeID) ??
      false;

  @override
  Widget build(BuildContext context) {
    var bikeList = ref.watch(bikesDBProvider);
    var connectedDevices = ref.watch(connectedDevicesProvider);
    var bikeNotifier = ref.watch(bikesDBProvider.notifier);
    var scanResults = ref.watch(scanResultsProvider);
    var isScanning = ref.watch(isScanningStatusProvider);

    List<BikeState> foundBikes = [];
    for (var result in scanResults.value ?? []) {
      if (bikeNotifier.getBike(result.device.remoteId.str) != null) {
        continue;
      }
      foundBikes.add(BikeState.defaultState(result.device.remoteId.str));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff441DFC),
        onPressed: () {
          if (isScanning.value ?? false) {
            ref.read(bluetoothRepositoryProvider).stopScan();
          } else {
            ref.read(bluetoothRepositoryProvider).scan();
          }
        },
        child: Icon(
          isScanning.value ?? false ? Icons.stop : Icons.bluetooth_searching,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar with SUPERDUPER title
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'SUPERDUPER',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                centerTitle: true,
              ),
            ),

            // Bluetooth Status Indicator
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  var bleStatus = ref.watch(adapterStateProvider);

                  return bleStatus.when(
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
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
                  );
                },
              ),
            ),

            // Scanning Status Indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 40,
                  decoration: BoxDecoration(
                    color: isScanning.value ?? false
                        ? const Color(0xff441DFC).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isScanning.value ?? false
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
            if (bikeList.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Bikes',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (connectedDevices.value?.isNotEmpty ?? false)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.bluetooth_disabled,
                              color: Colors.red, size: 16),
                          onPressed: () {
                            ref.read(bluetoothRepositoryProvider).disconnect();
                          },
                          label: Text(
                            'Disconnect',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.red),
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
                        child: DiscoverCard(
                          selected:
                              isConnected(connectedDevices, bikeList[index].id),
                          onTap: () => selectBike(bikeList[index]),
                          title: bikeList[index].name,
                          subtitle: bikeList[index].id,
                          titleIcon: Icons.directions_bike,
                          colorIndex: index % 10, // Vary colors based on index
                        ),
                      );
                    },
                    childCount: bikeList.length,
                  ),
                ),
              ),
            ],

            // Found Bikes Section
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
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
                    const NotConnectingButton(),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              ref.read(bluetoothRepositoryProvider).scan();
                            },
                            child: Text(
                              'TAP TO SCAN',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                              selected: isConnected(connectedDevices, bike.id),
                              onTap: () => selectBike(bike),
                              title: bike.name,
                              subtitle: bike.id,
                              titleIcon: Icons.bluetooth,
                              colorIndex: (index + 3) %
                                  10, // Different color range for found bikes
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 40.0, horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const DebugPage(),
                        ),
                      );
                    },
                    child: const Text('DEBUG CONSOLE'),
                  ),
                ),
              ),

            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class NotConnectingButton extends StatelessWidget {
  const NotConnectingButton({super.key});

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
        if (!await launchUrl(url)) {
          throw Exception('Could not launch $url');
        }
      },
    );
  }
}
