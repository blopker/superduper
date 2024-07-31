import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/db.dart';
import 'package:superduper/edit_bike.dart' as edit;
import 'package:superduper/help.dart';
import 'package:superduper/models.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/widgets.dart';

export 'package:superduper/models.dart';

part 'bike.g.dart';

@riverpod
class Bike extends _$Bike {
  Timer? _updateDebounce;
  Timer? _updateTimer;
  bool _writing = false;

  @override
  BikeState build(String id) {
    ref.onDispose(() {
      _updateTimer?.cancel();
      _updateDebounce?.cancel();
    });
    _resetReadTimer();
    var bike = ref.watch(bikesDBProvider.notifier).getBike(id);
    if (bike != null) {
      return bike;
    }
    return BikeState.defaultState(id);
  }

  _resetReadTimer() {
    if (_updateTimer?.isActive ?? false) {
      _updateTimer?.cancel();
    }
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_writing) {
        return;
      }
      updateStateData();
    });
  }

  _resetDebounce() {
    if (_updateDebounce?.isActive ?? false) _updateDebounce?.cancel();
    _resetReadTimer();
  }

  Future<void> updateStateData({force = false}) async {
    var status = ref.read(connectionStatusProvider);
    if (status != BluetoothConnectionState.connected) {
      return;
    }
    _resetDebounce();
    _writing = false;
    _updateDebounce = Timer(const Duration(seconds: 2), () async {
      _resetReadTimer();
      var data = await ref
          .read(bluetoothRepositoryProvider)
          .readCurrentState(state.id);
      if (data == null || data.isEmpty) {
        return;
      }
      var newState = state.updateFromData(data);
      if (newState == state && !force) {
        return;
      }
      debugPrint('state update $data');
      if (state.lightLocked && state.light != newState.light) {
        newState = newState.copyWith(light: state.light);
      }

      if (state.modeLocked && state.mode != newState.mode) {
        newState = newState.copyWith(mode: state.mode);
      }

      if (state.assistLocked && state.assist != newState.assist) {
        newState = newState.copyWith(assist: state.assist);
      }
      writeStateData(newState);
    });
  }

  void writeStateData(BikeState newState, {saveToBike = true}) async {
    _resetDebounce();
    if (state.id != newState.id) {
      throw Exception('Bike id mismatch');
    }
    var status = ref.read(connectionStatusProvider);
    if (saveToBike) {
      if (status != BluetoothConnectionState.connected) {
        return;
      }
      _writing = true;
      final repo = ref.read(bluetoothRepositoryProvider);
      await repo.write(newState.id, data: newState.toWriteData());
    }
    ref.read(bikesDBProvider.notifier).saveBike(newState);
    state = newState;
    updateStateData();
  }

  void toggleLight() async {
    writeStateData(state.copyWith(light: !state.light));
  }

  void toggleMode() async {
    writeStateData(state.copyWith(mode: state.nextMode));
  }

  void toggleAssist() async {
    writeStateData(state.copyWith(assist: (state.assist + 1) % 5));
  }

  void toggleLightLocked() async {
    writeStateData(state.copyWith(lightLocked: !state.lightLocked),
        saveToBike: false);
  }

  void toggleModeLocked() async {
    writeStateData(state.copyWith(modeLocked: !state.modeLocked),
        saveToBike: false);
  }

  void toggleAssistLocked() async {
    writeStateData(state.copyWith(assistLocked: !state.assistLocked),
        saveToBike: false);
  }

  void toggleBackgroundLock() async {
    writeStateData(state.copyWith(modeLock: !state.modeLock),
        saveToBike: false);
  }

  void deleteStateData(BikeState bike) {
    ref.read(bikesDBProvider.notifier).deleteBike(bike);
  }
}

class BikePage extends ConsumerStatefulWidget {
  const BikePage({super.key, required this.bikeID});
  final String bikeID;

  @override
  BikePageState createState() => BikePageState();
}

class ForegroundNotificationWrapper extends StatelessWidget {
  const ForegroundNotificationWrapper(
      {super.key, required this.child, required this.onWillStart});
  final Widget child;
  final Future<bool> Function() onWillStart;

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return child;
    }
    return WillStartForegroundTask(
      onWillStart: onWillStart,
      androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: 'Background Lock Notification',
          priority: NotificationPriority.LOW,
          channelImportance: NotificationChannelImportance.LOW,
          iconData: null),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(),
      notificationTitle: 'SuperDuper Background Lock On',
      notificationText: 'Tap to return to the app',
      child: child,
    );
  }
}

class BikePageState extends ConsumerState<BikePage> {
  @override
  void initState() {
    super.initState();
    ref.read(connectionHandlerProvider).connect(widget.bikeID);
  }

  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bikeID));
    var bikeControl = ref.watch(bikeProvider(widget.bikeID).notifier);
    ref.listen(connectionStatusProvider, (previous, next) {
      if (next == BluetoothConnectionState.connected) {
        // First connect, force update
        bikeControl.updateStateData(force: true);
      }
    });
    return ForegroundNotificationWrapper(
      onWillStart: () async {
        return bike.modeLock;
      },
      child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title:
                Text(bike.name, style: Theme.of(context).textTheme.titleMedium),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  edit.show(context, bike);
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
                child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [ConnectionWidget(bike: bike)],
                  ),
                  LightControlWidget(
                    bike: bike,
                  ),
                  ModeControlWidget(bike: bike),
                  AssistControlWidget(bike: bike),
                  if (Platform.isAndroid)
                    BackgroundLockControlWidget(bike: bike),
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            showModalBottomSheet<void>(
                                isScrollControlled: true,
                                backgroundColor: Colors.black,
                                useSafeArea: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return const HelpWidget();
                                });
                          },
                          child: Text(
                            "Help",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: const Color(0xff4A80F0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                ])),
          )),
    );
  }
}

class ConnectionWidget extends ConsumerWidget {
  const ConnectionWidget({super.key, required this.bike});
  final BikeState bike;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var connectionStatus = ref.watch(connectionStatusProvider);
    var connectionHandler = ref.watch(connectionHandlerProvider);
    var isScanning = ref.watch(isScanningStatusProvider).value == true;
    var text = 'Connecting...';
    var disabled = true;
    if (connectionStatus == BluetoothConnectionState.connected) {
      text = 'Connected';
      disabled = true;
    } else if (connectionStatus == BluetoothConnectionState.disconnected &&
        !isScanning) {
      text = 'Connect';
      disabled = false;
    }
    var style = Theme.of(context).textTheme.bodyMedium;
    if (disabled) {
      style = style!.copyWith(color: Colors.grey);
    }
    return InkWell(
        onTap: disabled
            ? null
            : () {
                connectionHandler.connect(bike.id);
              },
        child: Text(text, style: style));
  }
}

class LockWidget extends StatelessWidget {
  const LockWidget({super.key, required this.locked, required this.onTap});
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: IconButton(
          iconSize: 30,
          onPressed: onTap,
          icon: Icon(locked ? Icons.lock : Icons.lock_open)),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: DiscoverCard(
              colorIndex: bike.color,
              title: "Light",
              metric: bike.light ? "On" : "Off",
              titleIcon: bike.light ? Icons.lightbulb : Icons.lightbulb_outline,
              selected: bike.light,
              onTap: () {
                bikeControl.toggleLight();
              },
            ),
          ),
          LockWidget(
            locked: bike.lightLocked,
            onTap: bikeControl.toggleLightLocked,
          )
        ],
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
      child: Row(
        children: [
          Expanded(
            child: DiscoverCard(
              colorIndex: bike.color,
              title: "Mode",
              metric: bike.viewMode,
              titleIcon: Icons.electric_bike,
              selected: bike.viewMode == '1' ? false : true,
              onTap: () {
                bikeControl.toggleMode();
              },
            ),
          ),
          LockWidget(
              locked: bike.modeLocked, onTap: bikeControl.toggleModeLocked)
        ],
      ),
    );
  }
}

class BackgroundLockControlWidget extends ConsumerWidget {
  const BackgroundLockControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: DiscoverCard(
            title: "Background Lock",
            metric: bike.modeLock ? "On" : "Off",
            titleIcon: Icons.phonelink_lock,
            selected: bike.modeLock,
            colorIndex: bike.color,
            onTap: () async {
              await Permission.notification.request();
              if (Platform.isAndroid) {
                await FlutterForegroundTask.requestIgnoreBatteryOptimization();
              }
              bikeControl.toggleBackgroundLock();
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "Background Lock may cause phone battery drain. See Help for more info.",
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
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
      child: Row(
        children: [
          Expanded(
            child: DiscoverCard(
              colorIndex: bike.color,
              title: "Assist",
              metric: bike.assist.toString(),
              titleIcon: Icons.autorenew,
              selected: bike.assist == 0 ? false : true,
              onTap: () {
                bikeControl.toggleAssist();
              },
            ),
          ),
          LockWidget(
              locked: bike.assistLocked, onTap: bikeControl.toggleAssistLocked)
        ],
      ),
    );
  }
}
