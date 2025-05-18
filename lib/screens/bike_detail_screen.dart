import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/screens/bike_edit_sheet.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bike_service.dart';
import 'package:superduper/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for controlling and viewing details of a specific bike.
class BikeDetailScreen extends ConsumerWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeServiceAsync = ref.watch(bikeServiceProvider(bikeId));
    final bikeAsync = ref.watch(bikeProvider(bikeId));

    if (bikeServiceAsync == null || bikeAsync == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Bike Not Found'),
        ),
        body: const Center(
          child: Text(
            'The selected bike could not be found.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final bikeService = bikeServiceAsync;
    final bike = bikeAsync;

    return StreamBuilder<BikeModel>(
      stream: bikeService.bikeModelStream,
      initialData: bike,
      builder: (context, snapshot) {
        final currentBike = snapshot.data ?? bike;

        return Scaffold(
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
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                    onPressed: () => _showEditBikeDialog(context, ref, currentBike),
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
                              currentBike.name,
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
                                _buildConnectionChip(context, bikeService),
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
                    _buildLightControl(context, bikeService, currentBike),
                    const SizedBox(height: 16),

                    // Mode Control
                    _buildModeControl(context, bikeService, currentBike),
                    const SizedBox(height: 16),

                    // Assist Control
                    _buildAssistControl(context, bikeService, currentBike),

                    // Background Lock (Android only)
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      _buildBackgroundLockControl(context, bikeService, currentBike),
                    ],

                    // Help Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final Uri url = Uri.parse(
                                'https://github.com/blopker/superduper/?tab=readme-ov-file#getting-started');
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: Text(
                            "HELP & TIPS",
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4A80F0).withOpacity(0.2),
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
          ),
        );
      },
    );
  }

  Widget _buildConnectionChip(BuildContext context, BikeService bikeService) {
    return StreamBuilder<BikeConnectionState>(
      stream: bikeService.connectionStateStream,
      initialData: bikeService.connectionState,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? BikeConnectionState.disconnected;

        String text = 'Connecting...';
        IconData icon = Icons.sync;
        Color textColor = Colors.grey;
        bool disabled = true;
        Color bgColor = Colors.grey.withOpacity(0.2);

        if (connectionState == BikeConnectionState.connected) {
          text = 'Connected';
          icon = Icons.bluetooth_connected;
          textColor = Colors.green;
          bgColor = Colors.green.withOpacity(0.15);
          disabled = true;
        } else if (connectionState == BikeConnectionState.disconnected) {
          text = 'Connect';
          icon = Icons.bluetooth;
          textColor = const Color(0xff4A80F0);
          bgColor = const Color(0xff4A80F0).withOpacity(0.15);
          disabled = false;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled
              ? null
              : () {
                  bikeService.connect();
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
      },
    );
  }

  Widget _buildLockWidget({
    required bool locked,
    required VoidCallback onTap,
    Color activeColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: locked ? Colors.grey.withOpacity(0.15) : Colors.transparent,
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

  Widget _buildLightControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
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
            onTap: () => bikeService.toggleLight(),
          ),
        ),
        _buildLockWidget(
          locked: bike.lightLocked,
          onTap: () => bikeService.toggleLightLocked(),
          activeColor: Colors.white,
        )
      ],
    );
  }

  Widget _buildModeControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    final bool isActiveMode = bike.mode != 0;

    return Row(
      children: [
        Expanded(
          child: DiscoverCard(
            colorIndex: bike.color,
            title: "Mode",
            metric: "${bike.viewMode}/4",
            titleIcon: Icons.electric_bike,
            selected: isActiveMode,
            onTap: () => bikeService.toggleMode(),
          ),
        ),
        _buildLockWidget(
          locked: bike.modeLocked,
          onTap: () => bikeService.toggleModeLocked(),
          activeColor: Colors.white,
        )
      ],
    );
  }

  Widget _buildAssistControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
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
            onTap: () => bikeService.toggleAssist(),
          ),
        ),
        _buildLockWidget(
          locked: bike.assistLocked,
          onTap: () => bikeService.toggleAssistLocked(),
          activeColor: Colors.white,
        )
      ],
    );
  }

  Widget _buildBackgroundLockControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    return Column(
      children: [
        DiscoverCard(
          title: "Background Lock",
          metric: bike.backgroundLock ? "On" : "Off",
          titleIcon: Icons.phonelink_lock,
          selected: bike.backgroundLock,
          colorIndex: bike.color,
          onTap: () => bikeService.toggleBackgroundLock(),
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

  void _showEditBikeDialog(
      BuildContext context, WidgetRef ref, BikeModel bike) {
    BikeEditBottomSheet.show(context, bike).then((updatedBike) {
      if (updatedBike != null) {
        ref.read(bikeRepositoryProvider).updateBike(updatedBike);
      }
    });
  }
}


