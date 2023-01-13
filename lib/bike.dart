import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/names.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/styles.dart';
import 'package:superduper/widgets.dart';
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
    required int mode,
    required bool light,
    required int assist,
    required String name,
    @Default(false) bool modeLock,
    @Default(false) bool selected,
  }) = _BikeState;

  factory BikeState.fromJson(Map<String, Object?> json) =>
      _$BikeStateFromJson(json);

  factory BikeState.defaultState(String id) {
    return BikeState(
        id: id, mode: 0, light: false, assist: 0, name: getName(seed: id));
  }

  BikeState updateFromData(List<int> data) {
    const lightIdx = 4;
    const modeIdx = 5;
    const assistIdx = 2;
    return copyWith(
        light: data[lightIdx] == 1,
        mode: data[modeIdx],
        assist: data[assistIdx]);
  }

  List<int> toWriteData() {
    return [0, 209, light ? 1 : 0, assist, mode, 0, 0, 0, 0, 0];
  }
}

@riverpod
class Bike extends _$Bike {
  Timer? _updateDebounce;
  Timer? _updateTimer;

  @override
  BikeState build(String id) {
    ref.onDispose(() {
      _updateTimer?.cancel();
      _updateDebounce?.cancel();
    });
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      updateStateData();
    });
    return BikeState.defaultState(id);
  }

  Future<void> updateStateData() async {
    var status = ref.read(connectionStatusProvider);
    if (status != DeviceConnectionState.connected) {
      return;
    }
    if (_updateDebounce?.isActive ?? false) _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(seconds: 2), () async {
      var data = await ref
          .read(bluetoothRepositoryProvider)
          .readCurrentState(state.id);
      debugPrint('state update $data');
      if (data == null || data.isEmpty) {
        return;
      }
      var newState = state.updateFromData(data);
      if (state.modeLock && state.mode != newState.mode) {
        writeStateData(newState.copyWith(mode: state.mode));
      } else {
        state = newState;
      }
    });
  }

  void writeStateData(BikeState newState, {saveToBike = true}) {
    var status = ref.read(connectionStatusProvider);
    if (saveToBike) {
      if (status != DeviceConnectionState.connected) {
        return;
      }
      ref
          .read(bluetoothRepositoryProvider)
          .write(newState.id, data: newState.toWriteData());
    }
    updateStateData();
    state = newState;
  }

  void toggleLight() async {
    // await updateStateData();
    writeStateData(state.copyWith(light: !state.light));
  }

  void toggleMode() async {
    // await updateStateData();
    writeStateData(state.copyWith(mode: (state.mode + 1) % 4));
  }

  void toggleAssist() async {
    // await updateStateData();
    writeStateData(state.copyWith(assist: (state.assist + 1) % 5));
  }

  void toggleModeLock() async {
    // await updateStateData();
    writeStateData(state.copyWith(modeLock: !state.modeLock),
        saveToBike: false);
  }
}

class BikePage extends ConsumerStatefulWidget {
  const BikePage({super.key, required this.bike});
  final BikeState bike;

  @override
  BikePageState createState() => BikePageState();
}

class BikePageState extends ConsumerState<BikePage> {
  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bike.id));
    var bikeControl = ref.watch(bikeProvider(widget.bike.id).notifier);
    var connectionHandler = ref.watch(connectionHandlerProvider);
    var connectionStatus = ref.watch(connectionStatusProvider);
    ref.listen(connectionStatusProvider, (previous, next) {
      if (next == DeviceConnectionState.connected) {
        bikeControl.updateStateData();
      }
    });
    return WillStartForegroundTask(
      onWillStart: () async {
        return bike.modeLock;
      },
      androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: 'ModeLock Notification',
          priority: NotificationPriority.LOW,
          channelImportance: NotificationChannelImportance.LOW,
          iconData: null),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(),
      notificationTitle: 'SuperDuper ModeLock On',
      notificationText: 'Tap to return to the app',
      child: Scaffold(
          backgroundColor: const Color(0xff121421),
          body: SafeArea(
              child: Column(
            children: [
              ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
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
                          Text(widget.bike.name, style: Styles.header),
                          const SizedBox(
                            width: 10,
                          ),
                          const Icon(
                            Icons.unfold_more,
                            color: Colors.white,
                            size: 30,
                          )
                        ],
                      ),
                    ),
                    Text(
                      connectionStatus.name,
                      style: Styles.body,
                    ),
                    LightControlWidget(
                      bike: bike,
                    ),
                    ModeControlWidget(bike: bike),
                    ModeLockControlWidget(bike: bike),
                    AssistControlWidget(bike: bike),
                  ]),
              Expanded(
                child: Container(),
              ),
              Builder(builder: (c) {
                var text = 'Connecting...';
                var disabled = true;
                if (connectionStatus == DeviceConnectionState.connected) {
                  text = 'Connected';
                  disabled = true;
                } else if (connectionStatus ==
                    DeviceConnectionState.disconnected) {
                  text = 'Connect';
                  disabled = false;
                } else if (connectionStatus ==
                    DeviceConnectionState.disconnecting) {
                  text = 'Disconnecting...';
                }
                var style = Styles.body;
                if (disabled) {
                  style = style.copyWith(color: Colors.grey);
                }
                return InkWell(
                    onTap: disabled
                        ? null
                        : () {
                            connectionHandler.connect(bike.id);
                          },
                    child: Text(text, style: style));
              }),
              const SizedBox(
                height: 20,
              )
            ],
          ))),
    );
  }
}

class LightControlWidget extends ConsumerWidget {
  const LightControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: DiscoverCard(
        title: "Light",
        metric: bike.light ? "On" : "Off",
        selected: bike.light,
        onTap: () {
          bikeControl.toggleLight();
        },
      ),
    );
  }
}

class ModeControlWidget extends ConsumerWidget {
  const ModeControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: DiscoverCard(
        title: "Mode",
        metric: bike.mode.toString(),
        selected: bike.mode == 0 ? false : true,
        onTap: () {
          bikeControl.toggleMode();
        },
      ),
    );
  }
}

class ModeLockControlWidget extends ConsumerWidget {
  const ModeLockControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: DiscoverCard(
        title: "Mode Lock™",
        metric: bike.modeLock ? "On" : "Off",
        selected: bike.modeLock,
        onTap: () {
          bikeControl.toggleModeLock();
        },
      ),
    );
  }
}

class AssistControlWidget extends ConsumerWidget {
  const AssistControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: DiscoverCard(
        title: "Assist",
        metric: bike.assist.toString(),
        selected: bike.assist == 0 ? false : true,
        onTap: () {
          bikeControl.toggleAssist();
        },
      ),
    );
  }
}
