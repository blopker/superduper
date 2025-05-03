import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/db.dart';
import 'package:superduper/edit_bike.dart' as edit;
import 'package:superduper/help.dart';
import 'package:superduper/models.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/utils/logger.dart';
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
    ref.watch(connectionHandlerProvider(id));
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
    var status = ref.read(connectionHandlerProvider(state.id));
    if (status != SDBluetoothConnectionState.connected) {
      return;
    }
    _resetDebounce();
    _writing = false;
    _updateDebounce = Timer(const Duration(seconds: 2), () async {
      _resetReadTimer();
      await updateStateDataNow();
    });
  }

  Future<void> updateStateDataNow({force = false}) async {
    var data =
        await ref.read(connectionHandlerProvider(state.id).notifier).read();
    if (data == null || data.isEmpty) {
      return;
    }
    var newState = state.updateFromData(data);
    if (newState == state && !force) {
      return;
    }
    log.d(SDLogger.BIKE, 'State update from data: $data');
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
  }

  void writeStateData(BikeState newState, {saveToBike = true}) async {
    _resetDebounce();
    if (state.id != newState.id) {
      throw Exception('Bike id mismatch');
    }
    var status = ref.read(connectionHandlerProvider(state.id));
    if (saveToBike) {
      if (status != SDBluetoothConnectionState.connected) {
        return;
      }
      _writing = true;
      final repo = ref.read(connectionHandlerProvider(state.id).notifier);
      await repo.write(newState.toWriteData());
      log.d(SDLogger.BIKE, 'Wrote data to bike: ${newState.toWriteData()}');
    }
    ref.read(bikesDBProvider.notifier).saveBike(newState);
    state = newState;
    updateStateData();
  }

  void toggleLight() async {
    log.d(SDLogger.BIKE, 'Toggling light: ${!state.light}');
    writeStateData(state.copyWith(light: !state.light));
  }

  void toggleMode() async {
    log.d(SDLogger.BIKE, 'Toggling mode to: ${state.nextMode}');
    writeStateData(state.copyWith(mode: state.nextMode));
  }

  void toggleAssist() async {
    final newAssist = (state.assist + 1) % 5;
    log.d(SDLogger.BIKE, 'Toggling assist to: $newAssist');
    writeStateData(state.copyWith(assist: newAssist));
  }

  void toggleLightLocked() async {
    log.d(SDLogger.BIKE, 'Toggling light lock: ${!state.lightLocked}');
    writeStateData(state.copyWith(lightLocked: !state.lightLocked),
        saveToBike: false);
  }

  void toggleModeLocked() async {
    log.d(SDLogger.BIKE, 'Toggling mode lock: ${!state.modeLocked}');
    writeStateData(state.copyWith(modeLocked: !state.modeLocked),
        saveToBike: false);
  }

  void toggleAssistLocked() async {
    log.d(SDLogger.BIKE, 'Toggling assist lock: ${!state.assistLocked}');
    writeStateData(state.copyWith(assistLocked: !state.assistLocked),
        saveToBike: false);
  }

  void toggleBackgroundLock() async {
    log.d(SDLogger.BIKE, 'Toggling background lock: ${!state.modeLock}');
    writeStateData(state.copyWith(modeLock: !state.modeLock),
        saveToBike: false);
  }

  void deleteStateData(BikeState bike) {
    log.i(SDLogger.BIKE, 'Deleting bike: ${bike.name}');
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
      ),
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
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bikeID));
    var bikeControl = ref.watch(bikeProvider(widget.bikeID).notifier);
    ref.listen(connectionHandlerProvider(bike.id), (previous, next) {
      if (previous != SDBluetoothConnectionState.connected &&
          next == SDBluetoothConnectionState.connected) {
        // add a delay
        Future.delayed(const Duration(milliseconds: 200), () {
          bikeControl.updateStateDataNow(force: true);
        });
      }
    });
    return ForegroundNotificationWrapper(
      onWillStart: () async {
        return bike.modeLock;
      },
      child: Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar without bike name
              SliverAppBar(
                backgroundColor: Colors.black,
                pinned: true,
                expandedHeight: 60, // Reduced height without the title
                stretch: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51), // 0.2 opacity
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () {
                    var settings = ref.read(settingsDBProvider);
                    ref
                        .read(settingsDBProvider.notifier)
                        .save(settings.copyWith(currentBike: null));
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51), // 0.2 opacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                    onPressed: () {
                      edit.show(context, bike);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(color: Colors.black),
                  collapseMode: CollapseMode.pin,
                  stretchModes: const [],
                ),
              ),

              // Bike name as a header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                EnhancedConnectionWidget(bike: bike),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Controls Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Light Control
                    EnhancedLightControlWidget(bike: bike),
                    const SizedBox(height: 16),

                    // Mode Control
                    EnhancedModeControlWidget(bike: bike),
                    const SizedBox(height: 16),

                    // Assist Control
                    EnhancedAssistControlWidget(bike: bike),

                    // Background Lock (Android only)
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      EnhancedBackgroundLockWidget(bike: bike),
                    ],

                    // Help Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet<void>(
                                isScrollControlled: true,
                                backgroundColor: Colors.black,
                                useSafeArea: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return const HelpWidget();
                                });
                          },
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: Text(
                            "HELP & TIPS",
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4A80F0)
                                .withAlpha(51), // 0.2 opacity
                            foregroundColor: const Color(0xff4A80F0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          )),
    );
  }
}

class EnhancedConnectionWidget extends ConsumerWidget {
  const EnhancedConnectionWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var connectionProvider = connectionHandlerProvider(bike.id);
    var connectionStatus = ref.watch(connectionProvider);
    var connectionHandler = ref.watch(connectionProvider.notifier);
    var isScanning = ref.watch(isScanningStatusProvider).value == true;

    String text = 'Connecting...';
    IconData icon = Icons.sync;
    Color textColor = Colors.grey;
    bool disabled = true;
    Color bgColor =
        Colors.grey.withAlpha(51); // 0.2 opacity equals alpha 51 (0.2 * 255)

    if (connectionStatus == SDBluetoothConnectionState.connected) {
      text = 'Connected';
      icon = Icons.bluetooth_connected;
      textColor = Colors.green;
      bgColor = Colors.green
          .withAlpha(38); // 0.15 opacity equals alpha 38 (0.15 * 255)
      disabled = true;
    } else if (connectionStatus == SDBluetoothConnectionState.disconnected &&
        !isScanning) {
      text = 'Connect';
      icon = Icons.bluetooth;
      textColor = const Color(0xff4A80F0);
      bgColor = const Color(0xff4A80F0).withAlpha(38); // 0.15 opacity
      disabled = false;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: disabled
          ? null
          : () {
              connectionHandler.connect();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedLockWidget extends StatelessWidget {
  const EnhancedLockWidget(
      {super.key,
      required this.locked,
      required this.onTap,
      this.activeColor = Colors.white});

  final bool locked;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: locked
            ? Colors.grey.withAlpha(38)
            : Colors.transparent, // 0.15 opacity
        borderRadius: BorderRadius.circular(50),
      ),
      child: IconButton(
        iconSize: 24,
        padding: const EdgeInsets.all(12),
        onPressed: onTap,
        icon: Icon(
          locked ? Icons.lock : Icons.lock_open,
          color: locked ? activeColor : Colors.grey[600],
        ),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}

class EnhancedLightControlWidget extends ConsumerWidget {
  const EnhancedLightControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Row(
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
        EnhancedLockWidget(
          locked: bike.lightLocked,
          onTap: bikeControl.toggleLightLocked,
          activeColor: Colors.white,
        )
      ],
    );
  }
}

class EnhancedModeControlWidget extends ConsumerWidget {
  const EnhancedModeControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    final bool isActiveMode = bike.viewMode != '1';

    return Row(
      children: [
        Expanded(
          child: DiscoverCard(
            colorIndex: bike.color,
            title: "Mode",
            metric: "${bike.viewMode}/4",
            titleIcon: Icons.electric_bike,
            selected: isActiveMode,
            onTap: () {
              bikeControl.toggleMode();
            },
          ),
        ),
        EnhancedLockWidget(
          locked: bike.modeLocked,
          onTap: bikeControl.toggleModeLocked,
          activeColor: Colors.white,
        )
      ],
    );
  }
}

class EnhancedBackgroundLockWidget extends ConsumerWidget {
  const EnhancedBackgroundLockWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    return Column(
      children: [
        DiscoverCard(
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
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "Background Lock may cause phone battery drain. See Help for more info.",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EnhancedAssistControlWidget extends ConsumerWidget {
  const EnhancedAssistControlWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var bikeControl = ref.watch(bikeProvider(bike.id).notifier);
    final bool isActiveAssist = bike.assist > 0;

    return Row(
      children: [
        Expanded(
          child: DiscoverCard(
            colorIndex: bike.color,
            title: "Assist",
            metric: "${bike.assist}/4",
            titleIcon: Icons.autorenew,
            selected: isActiveAssist,
            onTap: () {
              bikeControl.toggleAssist();
            },
          ),
        ),
        EnhancedLockWidget(
          locked: bike.assistLocked,
          onTap: bikeControl.toggleAssistLocked,
          activeColor: Colors.white,
        )
      ],
    );
  }
}
