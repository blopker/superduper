import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/styles.dart';
import 'package:superduper/widgets.dart';
import 'package:superduper/bike.dart';

import 'native.dart';

class BikeSelectWidget extends ConsumerStatefulWidget {
  const BikeSelectWidget({super.key});

  @override
  BikeSelectWidgetState createState() => BikeSelectWidgetState();
}

class BikeSelectWidgetState extends ConsumerState<BikeSelectWidget> {
  late StreamSubscription<DiscoveredDevice>? scanStream;
  late StreamSubscription<BleStatus> bleStatusStream;
  final List<BikeState> foundBikes = [];
  BleStatus? bleStatus;
  @override
  void initState() {
    getBatteryLevel().then((value) => print(value));
    bleStatusStream = ref.read(bluetoothStatusStreamProvider).listen((event) {
      setState(() {
        bleStatus = event;
      });
    });
    var ble = ref.read(bluetoothRepositoryProvider);
    var bikeList = ref.read(savedBikeListProvider.notifier);
    scanStream = ble.scan()?.listen((device) async {
      if (device.name != 'SUPER73') {
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
    bleStatusStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var bikeList = ref.watch(savedBikeListProvider);
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
            const Text(
              'Select Bike',
              style: Styles.header,
            ),
            Row(children: const [
              Text(
                'My Bikes',
                style: Styles.section,
              )
            ]),
            if (bikeList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  'No saved bikes.',
                  style: Styles.section,
                ),
              ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: bikeList.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: DiscoverCard(
                      selected: bikeList[i].selected,
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
              height: 20,
            ),
            Row(children: const [
              Text(
                'Found Bikes',
                style: Styles.section,
              )
            ]),
            if (foundBikes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  scanText,
                  style: Styles.section,
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
                    selected: b.selected,
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
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: const Text(
                      'Clear',
                      style: Styles.body,
                    ),
                    onTap: () {
                      ref.read(savedBikeListProvider.notifier).unselect();
                    },
                  ),
                ),
                InkWell(
                  child: const Text(
                    'Close',
                    style: Styles.body,
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
