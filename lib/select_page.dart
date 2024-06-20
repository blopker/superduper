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
  @override
  void initState() {
    ref.read(bluetoothRepositoryProvider).scan();
    super.initState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void selectBike(BikeState bike) {
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
    List<BikeState> foundBikes = [];
    for (var result in scanResults) {
      if (bikeNotifier.getBike(result.device.remoteId.str) != null) {
        continue;
      }
      foundBikes.add(BikeState.defaultState(result.device.remoteId.str));
    }
    return Container(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Text(
              'SUPERDUPER',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (bikeList.isNotEmpty)
              Column(
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  Row(children: [
                    Text(
                      'My Bikes',
                      style: Theme.of(context).textTheme.labelMedium,
                    )
                  ]),
                  if (bikeList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        'No saved bikes.',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: bikeList.length,
                      itemBuilder: (ctx, i) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: DiscoverCard(
                            selected:
                                isConnected(connectedDevices, bikeList[i].id),
                            onTap: () {
                              selectBike(bikeList[i]);
                            },
                            title: bikeList[i].name,
                            subtitle: bikeList[i].id,
                          ),
                        );
                      }),
                ],
              ),
            const SizedBox(
              height: 40,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                'Found Bikes',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const NotConnectingButton(),
            ]),
            const SizedBox(
              height: 20,
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: foundBikes.length,
              itemBuilder: (ctx, i) {
                var b = foundBikes[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: DiscoverCard(
                    selected: isConnected(connectedDevices, b.id),
                    onTap: () {
                      selectBike(b);
                    },
                    title: b.name,
                    subtitle: b.id,
                  ),
                );
              },
            ),
            const SizedBox(
              height: 20,
            ),
            const ScannerButton(),
            const SizedBox(
              height: 40,
            ),
            if (connectedDevices.value?.isNotEmpty ?? false)
              Expanded(
                child: InkWell(
                  child: Text(
                    'Disconnect',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    ref.read(bluetoothRepositoryProvider).disconnect();
                  },
                ),
              ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const DebugPage(),
                        ),
                      );
                    },
                    child: const Text('DEBUG')),
              )
          ],
        ),
      ),
    );
  }
}

class ScannerButton extends ConsumerWidget {
  const ScannerButton({super.key});

  Widget _statusText(BuildContext context, String status) {
    return Text(
      status,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _startScanButton(BuildContext context, WidgetRef ref) {
    var isScanning = ref.watch(isScanningStatusProvider);
    var startScanButton = InkWell(
      child: Text(
        'Start Scan',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: () {
        ref.read(bluetoothRepositoryProvider).scan();
      },
    );
    return isScanning.map(
      data: (state) {
        return switch (state.value) {
          true => InkWell(
              child: Text(
                'Scanning...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                ref.read(bluetoothRepositoryProvider).stopScan();
              },
            ),
          false => startScanButton
        };
      },
      loading: (_) => startScanButton,
      error: (error) => _statusText(context, 'Error: ${error.error}'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bleStatus = ref.watch(adapterStateProvider);
    var scanWidget = bleStatus.map(
      data: (state) {
        return switch (state.value) {
          BluetoothAdapterState.on => _startScanButton(context, ref),
          BluetoothAdapterState.off =>
            _statusText(context, 'Enable Bluetooth to scan.'),
          BluetoothAdapterState.unauthorized =>
            _statusText(context, 'Enable Bluetooth Permissions to scan.'),
          _ => _statusText(context, 'Enable Bluetooth to scan.')
        };
      },
      loading: (_) => _statusText(context, 'Loading..?'),
      error: (error) => _statusText(context, 'Error: ${error.error}'),
    );
    return scanWidget;
  }
}

class NotConnectingButton extends StatelessWidget {
  const NotConnectingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        'Not connecting?',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.grey,
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
