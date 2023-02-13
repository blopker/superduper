import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/styles.dart';
import 'package:superduper/widgets.dart';
import 'package:superduper/models.dart';
import 'package:superduper/db.dart';
import 'package:url_launcher/url_launcher.dart';
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
    var bike = ref.watch(dbProvider).getBike(id);
    if (bike != null) {
      return bike;
    }
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
    ref.read(dbProvider).setBike(newState);
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

  void toggleModeLock() async {
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
                          Text(bike.name, style: Styles.header),
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
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            edit.show(context, bike);
                          },
                          child: const Text(
                            'Edit',
                            style: Styles.body,
                          ),
                        ),
                        Expanded(child: Container()),
                        GestureDetector(
                          child: const Icon(
                            Icons.help,
                            color: Colors.white,
                            size: 30,
                          ),
                          onTap: () {
                            showModalBottomSheet<void>(
                                isScrollControlled: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return const HelpWidget();
                                });
                          },
                        )
                      ],
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
        metric: bike.viewMode,
        selected: bike.viewMode == '1' ? false : true,
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
        onTap: () async {
          await Permission.notification.request();
          if (Platform.isAndroid) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
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

const helpText = """
# Useful Links
### [Source Code/FAQ](https://github.com/blopker/superduper/)
### [Bug Reports](https://github.com/blopker/superduper/issues)

# Bike Functions
## Light
Toggles your bike's lights on and off, if your bike has them.

## Mode
Changes the legal category your bike will operate at.

US:
- 1: Class 1 - PAS Only, 20 mph
- 2: Class 2 - PAS & Throttle, 20 mph
- 3: Class 3 - PAS Only, 28 mph
- 4: OFF-ROAD - PAS & Throttle, no limit

EU:
- 1: EPAC - PAS, 25 km/h
- 2: 250W - PAS, 35 km/h
- 3: 850W - PAS, 45 km/h
- 4: OFF-ROAD - PAS/Throttle, no limit
""";

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white60,
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 35,
                    )),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Text(
                      'Help',
                      style: Styles.header.copyWith(color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: MarkdownBody(
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    data: helpText,
                  ),
                )
              ],
            ),
          ],
        ));
  }
}
