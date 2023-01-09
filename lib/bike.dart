import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/bluetooth.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/styles.dart';
part 'bike.freezed.dart';
part 'bike.g.dart';

@freezed
class BikeState with _$BikeState {
  const BikeState._();
  @Assert('mode <= 3')
  @Assert('mode >= 0')
  @Assert('assist >= 0')
  @Assert('assist <= 4')
  const factory BikeState({
    required String id,
    required double rssi,
    required int mode,
    required bool light,
    required int assist,
    required DeviceConnectionState conectionStatus,
    @Default(0.0) double voltage,
  }) = _BikeState;
}

@riverpod
class Bike extends _$Bike {
  StreamSubscription<ConnectionStateUpdate>? connectionSub;
  Timer? connectTimer;

  @override
  BikeState build(String id) {
    ref.onDispose(
      dispose,
    );
    Future.delayed(Duration(seconds: 1), connect);
    return BikeState(
        id: id,
        rssi: 0,
        mode: 0,
        light: false,
        assist: 0,
        conectionStatus: DeviceConnectionState.connecting);
  }

  void connect() {
    if (state.conectionStatus == DeviceConnectionState.connected) {
      return;
    }
    connectionSub?.cancel();
    connectionSub =
        ref.read(bluetoothRepositoryProvider).connect(state.id).listen((event) {
      state = state.copyWith(conectionStatus: event.connectionState);
    });
    connectTimer = Timer.periodic(Duration(seconds: 10), ((timer) {
      connect();
    }));
  }

  void dispose() {
    connectionSub?.cancel();
    connectTimer?.cancel();
  }
}

class BikePage extends ConsumerStatefulWidget {
  const BikePage({super.key, required this.bike});
  final SavedBike bike;

  @override
  BikePageState createState() => BikePageState();
}

class BikePageState extends ConsumerState<BikePage> {
  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bike.id));
    return Scaffold(
        backgroundColor: const Color(0xff121421),
        body: SafeArea(
            child: ListView(physics: const BouncingScrollPhysics(), children: [
          InkWell(
            onTap: () {
              showModalBottomSheet<void>(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return const BikeSelectWidget();
                  });
            },
            child: Row(
              children: [
                Text(widget.bike.name!, style: Styles.header),
                SizedBox(
                  width: 10,
                ),
                Icon(
                  Icons.unfold_more,
                  color: Colors.white,
                  size: 30,
                )
              ],
            ),
          ),
          Text(
            bike.conectionStatus.name,
            style: Styles.body,
          ),
          ElevatedButton(
              onPressed: () {
                flashLight(widget.bike.id);
              },
              child: Text('Light is ${bike.light}'))
        ])));
  }
}
