import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/screens/bike_edit_sheet.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bike_service.dart';

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
        appBar: AppBar(title: const Text('Bike Not Found')),
        body: const Center(
          child: Text('The selected bike could not be found.'),
        ),
      );
    }

    final bikeService = bikeServiceAsync;
    final bike = bikeAsync;

    return Scaffold(
      appBar: AppBar(
        title: Text(bike.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditBikeDialog(context, ref, bike),
          ),
        ],
      ),
      body: StreamBuilder<BikeModel>(
        stream: bikeService.bikeModelStream,
        initialData: bike,
        builder: (context, snapshot) {
          final currentBike = snapshot.data ?? bike;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConnectionStatus(context, bikeService),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLightControl(context, bikeService, currentBike),
                      const SizedBox(height: 24),
                      _buildModeControl(context, bikeService, currentBike),
                      const SizedBox(height: 24),
                      _buildAssistControl(context, bikeService, currentBike),
                      const SizedBox(height: 24),
                      if (Platform.isAndroid)
                        _buildBackgroundLockControl(
                            context, bikeService, currentBike),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, BikeService bikeService) {
    return StreamBuilder<BikeConnectionState>(
      stream: bikeService.connectionStateStream,
      initialData: bikeService.connectionState,
      builder: (context, snapshot) {
        final connectionState =
            snapshot.data ?? BikeConnectionState.disconnected;

        Color statusColor;
        String statusText;

        switch (connectionState) {
          case BikeConnectionState.connected:
            statusColor = Colors.green;
            statusText = 'Connected';
            break;
          case BikeConnectionState.connecting:
            statusColor = Colors.orange;
            statusText = 'Connecting...';
            break;
          case BikeConnectionState.disconnecting:
            statusColor = Colors.orange;
            statusText = 'Disconnecting...';
            break;
          case BikeConnectionState.disconnected:
            statusColor = Colors.red;
            statusText = 'Disconnected';
            break;
        }

        return Container(
          color: statusColor.withAlpha((0.2 * 255).floor()),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 12),
              const SizedBox(width: 8),
              Text(
                statusText,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (connectionState == BikeConnectionState.disconnected)
                TextButton(
                  onPressed: () => bikeService.connect(),
                  child: const Text('CONNECT'),
                )
              else if (connectionState == BikeConnectionState.connected)
                TextButton(
                  onPressed: () => bikeService.disconnect(),
                  child: const Text('DISCONNECT'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLightControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    return _SettingControl(
      title: 'Light',
      subtitle: bike.light ? 'On' : 'Off',
      icon: bike.light ? Icons.lightbulb : Icons.lightbulb_outline,
      isLocked: bike.lightLocked,
      onPressed: () => bikeService.toggleLight(),
      onLongPress: () => bikeService.toggleLightLocked(),
    );
  }

  Widget _buildModeControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    String subtitle;
    switch (bike.mode) {
      case 0:
        subtitle = 'Class 1 (20 mph, PAS only)';
        break;
      case 1:
        subtitle = 'Class 2 (20 mph, PAS & Throttle)';
        break;
      case 2:
        subtitle = 'Class 3 (28 mph, PAS only)';
        break;
      case 3:
        subtitle = 'Off-Road (unlimited)';
        break;
      default:
        subtitle = 'Unknown';
    }

    return _SettingControl(
      title: 'Mode ${bike.viewMode}',
      subtitle: subtitle,
      icon: Icons.electric_bike,
      isLocked: bike.modeLocked,
      onPressed: () => bikeService.toggleMode(),
      onLongPress: () => bikeService.toggleModeLocked(),
    );
  }

  Widget _buildAssistControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    return _SettingControl(
      title: 'Assist Level ${bike.assist}',
      subtitle: 'Level ${bike.assist} of 4',
      icon: Icons.power,
      isLocked: bike.assistLocked,
      onPressed: () => bikeService.toggleAssist(),
      onLongPress: () => bikeService.toggleAssistLocked(),
    );
  }

  Widget _buildBackgroundLockControl(
      BuildContext context, BikeService bikeService, BikeModel bike) {
    return _SettingControl(
      title: 'Background Lock',
      subtitle: bike.backgroundLock ? 'Active (uses more battery)' : 'Inactive',
      icon: bike.backgroundLock ? Icons.lock : Icons.lock_open,
      isLocked: false,
      onPressed: () => bikeService.toggleBackgroundLock(),
      onLongPress: null,
      isToggle: true,
      toggleValue: bike.backgroundLock,
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

class _SettingControl extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLocked;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final bool isToggle;
  final bool toggleValue;

  const _SettingControl({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLocked,
    required this.onPressed,
    required this.onLongPress,
    this.isToggle = false,
    this.toggleValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocked ? Colors.blue : Colors.transparent,
          width: isLocked ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (onLongPress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          isLocked
                              ? 'Long press to unlock'
                              : 'Long press to lock',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isToggle)
                Switch(
                  value: toggleValue,
                  onChanged: (_) => onPressed(),
                )
              else if (isLocked)
                const Icon(Icons.lock, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}


