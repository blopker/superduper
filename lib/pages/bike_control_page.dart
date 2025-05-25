import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'edit_bike_page.dart' as edit;
import '../models/models.dart';
import '../providers/bluetooth_provider.dart';
import '../core/utils/logger.dart';
import '../widgets/common/discover_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/bike_provider.dart';

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
    return WithForegroundTask(
      child: child,
    );
  }
}

class BikePageState extends ConsumerState<BikePage> {
  @override
  void initState() {
    super.initState();
    // Schedule a post-frame callback to ensure providers are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bikeControl = ref.read(bikeProvider(widget.bikeID).notifier);
      final connectionState =
          ref.read(connectionHandlerProvider(widget.bikeID));

      if (connectionState == SDBluetoothConnectionState.connected) {
        bikeControl.updateStateData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bikeID));
    var bikeControl = ref.watch(bikeProvider(widget.bikeID).notifier);

    return ForegroundNotificationWrapper(
      onWillStart: () async {
        var notificationStatus = await Permission.notification.status;
        log.i(SDLogger.BIKE, 'Notification status: $notificationStatus');
        if (notificationStatus == PermissionStatus.denied) {
          await Permission.notification.request();
        }

        if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          return true;
        } else {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          return FlutterForegroundTask.isIgnoringBatteryOptimizations;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                bike.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                edit.show(context, bike);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                EnhancedConnectionWidget(bike: bike),
                const SizedBox(height: 16),
                EnhancedLightControlWidget(bike: bike),
                const SizedBox(height: 16),
                EnhancedModeControlWidget(bike: bike),
                const SizedBox(height: 16),
                EnhancedAssistControlWidget(bike: bike),
                const SizedBox(height: 16),
                if (Platform.isAndroid)
                  EnhancedBackgroundLockWidget(bike: bike),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: DiscoverCard(
                        colorIndex: bike.color,
                        title: "Support",
                        subtitle: "Discord",
                        titleIcon: Icons.support_agent,
                        onTap: () async {
                          final Uri url =
                              Uri.parse('https://discord.gg/STvgARZYaw');
                          if (!await launchUrl(url)) {
                            throw Exception('Could not launch $url');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DiscoverCard(
                        colorIndex: bike.color,
                        title: "Bugs",
                        subtitle: "GitHub",
                        titleIcon: Icons.bug_report,
                        onTap: () async {
                          final Uri url = Uri.parse(
                              'https://github.com/blopker/superduper/issues');
                          if (!await launchUrl(url)) {
                            throw Exception('Could not launch $url');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DiscoverCard(
                  colorIndex: bike.color,
                  title: "Color",
                  subtitle: "Tap to change",
                  titleIcon: Icons.color_lens,
                  onTap: () {
                    bikeControl.changeColor();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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

    String connectionText = "Disconnected";
    IconData connectionIcon = Icons.bluetooth_disabled;

    switch (connectionStatus) {
      case SDBluetoothConnectionState.connected:
        connectionText = "Connected";
        connectionIcon = Icons.bluetooth_connected;
        break;
      case SDBluetoothConnectionState.connecting:
        connectionText = "Connecting...";
        connectionIcon = Icons.bluetooth_searching;
        break;
      case SDBluetoothConnectionState.disconnecting:
        connectionText = "Disconnecting...";
        connectionIcon = Icons.bluetooth_disabled;
        break;
      case SDBluetoothConnectionState.disconnected:
        connectionText = isScanning ? "Scanning..." : "Disconnected";
        connectionIcon =
            isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled;
        break;
    }

    return DiscoverCard(
      colorIndex: bike.color,
      title: connectionText,
      subtitle: bike.id,
      titleIcon: connectionIcon,
      onTap: () {
        if (connectionStatus == SDBluetoothConnectionState.connected ||
            connectionStatus == SDBluetoothConnectionState.connecting) {
          connectionHandler.disconnect();
        } else {
          connectionHandler.connect();
        }
      },
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: locked ? activeColor : Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          locked ? Icons.lock : Icons.lock_open,
          color: locked ? Colors.black : Colors.white,
          size: 24,
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
            metric: bike.viewMode,
            titleIcon: Icons.directions_bike,
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
          subtitle: bike.modeLock ? "On" : "Off",
          titleIcon: bike.modeLock ? Icons.lock : Icons.lock_open,
          colorIndex: bike.color,
          selected: bike.modeLock,
          onTap: () {
            bikeControl.toggleBackgroundLock();
          },
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