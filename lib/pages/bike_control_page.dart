import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'edit_bike_page.dart' as edit;
import '../providers/bluetooth_provider.dart';
import '../widgets/common/discover_card.dart';
import '../widgets/common/connection_status_chip.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/bike_provider.dart';
import '../services/background_bike_service.dart';
import '../database/database.dart';

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
  void initState() {
    super.initState();
    // Schedule a post-frame callback to ensure background service is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bikeNotifier = ref.read(bikeProvider(widget.bikeID).notifier);
      final backgroundService = ref.read(backgroundBikeServiceProvider.notifier);
      
      // Auto-activate bike if it has any locked settings
      if (bikeNotifier.shouldAutoActivate && !bikeNotifier.isBackgroundActive) {
        backgroundService.activateBike(widget.bikeID);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(bikeProvider(widget.bikeID));
    
    // Watch for background service state changes
    ref.watch(backgroundBikeServiceProvider);
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
                                Consumer(
                                  builder: (context, ref, _) {
                                    final connectionStatus = ref.watch(connectionHandlerProvider(bike.id));
                                    final isScanning = ref.watch(isScanningStatusProvider).value == true;
                                    final backgroundService = ref.watch(backgroundBikeServiceProvider.notifier);
                                    
                                    BikeConnectionState state;
                                    VoidCallback? onTap;
                                    
                                    if (connectionStatus == SDBluetoothConnectionState.connected) {
                                      state = BikeConnectionState.connected;
                                      onTap = null;
                                    } else if (!bike.active && !isScanning) {
                                      state = BikeConnectionState.disconnected;
                                      onTap = () => backgroundService.activateBike(bike.id);
                                    } else if (connectionStatus == SDBluetoothConnectionState.disconnected && !isScanning) {
                                      state = BikeConnectionState.disconnected;
                                      onTap = () => ref.read(connectionHandlerProvider(bike.id).notifier).connect();
                                    } else {
                                      state = BikeConnectionState.connecting;
                                      onTap = null;
                                    }
                                    
                                    return ConnectionStatusChip(
                                      connectionState: state,
                                      onTap: onTap,
                                    );
                                  },
                                ),
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
                            final Uri url = Uri.parse(
                                'https://github.com/blopker/superduper/?tab=readme-ov-file#getting-started');
                            launchUrl(url,
                                mode: LaunchMode.externalApplication);
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
