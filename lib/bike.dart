import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/widgets.dart';
import 'package:superduper/models.dart';
import 'package:superduper/help.dart';
import 'package:superduper/db.dart';
import 'package:superduper/edit_bike.dart' as edit;

export 'package:superduper/models.dart';
part 'bike.g.dart';

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
    var bike = ref.watch(databaseProvider).getBike(id);
    if (bike != null) {
      return bike;
    }
    return BikeState.defaultState(id);
  }

  Future<void> updateStateData({force = false}) async {
    var status = ref.read(connectionStatusProvider);
    if (status != DeviceConnectionState.connected) {
      return;
    }
    if (_updateDebounce?.isActive ?? false) _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(seconds: 2), () async {
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

  void writeStateData(BikeState newState, {saveToBike = true}) {
    if (state.id != newState.id) {
      throw Exception('Bike id mismatch');
    }
    var status = ref.read(connectionStatusProvider);
    if (saveToBike) {
      if (status != DeviceConnectionState.connected) {
        return;
      }
      ref
          .read(bluetoothRepositoryProvider)
          .write(newState.id, data: newState.toWriteData());
    }
    ref.read(databaseProvider).addBike(newState);
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
}

class BikePage extends ConsumerStatefulWidget {
  const BikePage({super.key, required this.bikeID});
  final String bikeID;

  @override
  BikePageState createState() => BikePageState();
}

class BikePageState extends ConsumerState<BikePage> {
  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bikeID));
    var bikeControl = ref.watch(bikeProvider(widget.bikeID).notifier);
    ref.listen(connectionStatusProvider, (previous, next) {
      if (next == DeviceConnectionState.connected) {
        // First connect, force update
        bikeControl.updateStateData(force: true);
      }
    });
    return WillStartForegroundTask(
      onWillStart: () async {
        return bike.modeLock;
      },
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
      child: Scaffold(
          backgroundColor: const Color(0xff121421),
          body: SafeArea(
              child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                const SizedBox(
                  height: 20,
                ),
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
                      Text(bike.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(
                        width: 5,
                      ),
                      const Icon(
                        Icons.unfold_more,
                        color: Colors.white,
                        size: 20,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        edit.show(context, bike);
                      },
                      child: Text(
                        'Edit',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(child: Container()),
                    const ConnectionWidget()
                  ],
                ),
                LightControlWidget(
                  bike: bike,
                ),
                ModeControlWidget(bike: bike),
                AssistControlWidget(bike: bike),
                if (Platform.isAndroid) BackgroundLockControlWidget(bike: bike),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Long press control to lock",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet<void>(
                              isScrollControlled: true,
                              context: context,
                              builder: (BuildContext context) {
                                return const HelpWidget();
                              });
                        },
                        child: Text(
                          "Help",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: const Color(0xff4A80F0)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
              ]))),
    );
  }
}

class ConnectionWidget extends ConsumerWidget {
  const ConnectionWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var connectionStatus = ref.watch(connectionStatusProvider);
    var connectionHandler = ref.watch(connectionHandlerProvider);
    var text = 'Connecting...';
    var disabled = true;
    if (connectionStatus == DeviceConnectionState.connected) {
      text = 'Connected';
      disabled = true;
    } else if (connectionStatus == DeviceConnectionState.disconnected) {
      text = 'Connect';
      disabled = false;
    } else if (connectionStatus == DeviceConnectionState.disconnecting) {
      text = 'Disconnecting...';
    }
    var style = Theme.of(context).textTheme.bodyMedium;
    if (disabled) {
      style = style!.copyWith(color: Colors.grey);
    }
    return InkWell(
        onTap: disabled
            ? null
            : () {
                connectionHandler.connect();
              },
        child: Text(text, style: style));
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
          locked: bike.lightLocked,
          metric: bike.light ? "On" : "Off",
          selected: bike.light,
          onTap: () {
            bikeControl.toggleLight();
          },
          onLongPress: () {
            bikeControl.toggleLightLocked();
          }),
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
        locked: bike.modeLocked,
        metric: bike.viewMode,
        selected: bike.viewMode == '1' ? false : true,
        onTap: () {
          bikeControl.toggleMode();
        },
        onLongPress: () {
          bikeControl.toggleModeLocked();
        },
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
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: DiscoverCard(
        title: "Background Lock",
        metric: bike.modeLock ? "On" : "Off",
        selected: bike.modeLock,
        onTap: () async {
          await Permission.notification.request();
          if (Platform.isAndroid) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
          bikeControl.toggleBackgroundLock();
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
          locked: bike.assistLocked,
          metric: bike.assist.toString(),
          selected: bike.assist == 0 ? false : true,
          onTap: () {
            bikeControl.toggleAssist();
          },
          onLongPress: () {
            bikeControl.toggleAssistLocked();
          }),
    );
  }
}
