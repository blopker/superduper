import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/widgets.dart';
import 'package:superduper/bike.dart';

class BikeSelectWidget extends ConsumerStatefulWidget {
  const BikeSelectWidget({super.key});

  @override
  BikeSelectWidgetState createState() => BikeSelectWidgetState();
}

class BikeSelectWidgetState extends ConsumerState<BikeSelectWidget> {
  late StreamSubscription<DiscoveredDevice>? scanStream;
  final List<BikeState> foundBikes = [];
  BleStatus? bleStatus;
  @override
  void initState() {
    ref.listenManual(bluetoothStatusStreamProvider, (_, event) {
      setState(() {
        bleStatus = event.value;
      });
    });
    var ble = ref.read(bluetoothRepositoryProvider);
    var bikeList = ref.read(savedBikeListProvider.notifier);
    scanStream = ble.scan()?.listen((device) async {
      if (device.name != 'SUPER${70 + 3}') {
        return;
      }
      if (bikeList.hasBike(device.id)) {
        return;
      }
      if (foundBikes.any((element) => element.id == device.id)) {
        return;
      }
      setState(() {
        foundBikes.add(BikeState.defaultState(device.id));
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    scanStream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var bikeList = ref.watch(savedBikeListProvider);
    var currentBike = ref.watch(currentBikeProvider);
    var bikeNotifier = ref.watch(savedBikeListProvider.notifier);
    var scanText = bleStatus == BleStatus.ready
        ? 'Searching...'
        : 'Enable Bluetooth to scan.';
    return Container(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Text(
              'Select Bike',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                      selected: currentBike?.id == bikeList[i].id,
                      onTap: () {
                        bikeNotifier.selectBike(bikeList[i].id);
                        Navigator.pop(context);
                      },
                      title: bikeList[i].name,
                      subtitle: bikeList[i].id,
                    ),
                  );
                }),
            const SizedBox(
              height: 40,
            ),
            Row(children: [
              Text(
                'Found Bikes',
                style: Theme.of(context).textTheme.labelMedium,
              )
            ]),
            if (foundBikes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  scanText,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: foundBikes.length,
              itemBuilder: (ctx, i) {
                var b = foundBikes[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: DiscoverCard(
                    selected: currentBike?.id == b.id,
                    onTap: () {
                      bikeNotifier.addBike(b);
                      bikeNotifier.selectBike(b.id);
                      Navigator.pop(context);
                    },
                    title: b.name,
                    subtitle: b.id,
                  ),
                );
              },
            ),
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      ref.read(savedBikeListProvider.notifier).unselect();
                    },
                  ),
                ),
                InkWell(
                  child: Text(
                    'Close',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
