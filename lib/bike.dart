import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/db.dart';
import 'package:superduper/edit_bike.dart' as edit;
import 'package:superduper/help.dart';
import 'package:superduper/models.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/widgets.dart';

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

  void deleteStateData(BikeState bike) {
    ref.read(databaseProvider).deleteBike(bike);
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
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: 8.0, top: 20.0),
                            child: DiscoverCard(
                              colorIndex: bike.color,
                              title: "",
                              metric: "${bike.bikeBattery} %",
                              titleIcon: getBatteryIcon(bike.bikeBattery),
                              selected: false,
                              onTap: () {

                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0, top: 20.0),
                            child: DiscoverCard(
                              colorIndex: bike.color,
                              title: "",
                              metric: bike.bikeSpeed,
                              titleIcon: Icons.speed,
                              selected: false,
                              onTap: () {

                              },
                            ),
                          ),
                        ),
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

  IconData getBatteryIcon(int batteryPercentage) {
    if (batteryPercentage >= 95) {
      return Icons.battery_full;
    } else if (batteryPercentage >= 85) {
      return Icons.battery_6_bar;
    } else if (batteryPercentage >= 75) {
      return Icons.battery_5_bar;
    } else if (batteryPercentage >= 65) {
      return Icons.battery_4_bar;
    } else if (batteryPercentage >= 45) {
      return Icons.battery_3_bar;
    } else if (batteryPercentage >= 30) {
      return Icons.battery_2_bar;
    } else if (batteryPercentage >= 10) {
      return Icons.battery_1_bar;
    } else if (batteryPercentage >= 0) {
      return Icons.battery_0_bar;
    } else {
      return Icons.battery_alert;
    }
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
          "Background Lock tries to keep your settings locked even when the app is closed. It may cause battery drain.",
          style: Theme.of(context).textTheme.bodySmall,
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
              titleIcon: Icons.admin_panel_settings_outlined,
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
