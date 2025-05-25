import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../providers/bike_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../core/utils/logger.dart';

part 'background_bike_service.g.dart';

@Riverpod(keepAlive: true)
class BackgroundBikeService extends _$BackgroundBikeService {
  final Map<String, Timer> _keepAliveTimers = {};
  Timer? _maintenanceTimer;
  bool _isRunning = false;

  @override
  int build() {
    ref.onDispose(_dispose);
    _startService();
    return 0;
  }

  void _dispose() {
    log.i(SDLogger.BLUETOOTH, 'Disposing BackgroundBikeService');
    _stopService();
  }

  void _startService() {
    if (_isRunning) return;

    _isRunning = true;
    log.i(SDLogger.BLUETOOTH, 'Starting BackgroundBikeService');

    // Start maintenance timer
    _maintenanceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performMaintenance();
    });

    // Initial maintenance
    _performMaintenance();

    // Connect all active bikes after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      connectAllActiveBikes();
    });
  }

  void _stopService() {
    _isRunning = false;
    _maintenanceTimer?.cancel();

    // Stop all keep-alive timers
    for (final timer in _keepAliveTimers.values) {
      timer.cancel();
    }
    _keepAliveTimers.clear();
  }

  void _performMaintenance() {
    if (!_isRunning) return;

    final allBikes = ref.read(bikesDBProvider);
    final activeBikes = allBikes.where((bike) => bike.active).toList();

    log.d(
        SDLogger.BLUETOOTH, 'Maintenance: ${activeBikes.length} active bikes');

    // Ensure active bikes have providers running
    for (final bike in activeBikes) {
      _ensureBikeProviderActive(bike.id);
    }

    // Clean up inactive bikes
    final activeIds = activeBikes.map((b) => b.id).toSet();
    final timersToRemove = <String>[];

    for (final bikeId in _keepAliveTimers.keys) {
      if (!activeIds.contains(bikeId)) {
        timersToRemove.add(bikeId);
      }
    }

    for (final bikeId in timersToRemove) {
      _stopKeepingBikeAlive(bikeId);
    }

    state = activeBikes.length;
  }

  void _ensureBikeProviderActive(String bikeId) {
    if (_keepAliveTimers.containsKey(bikeId)) return;

    log.d(
        SDLogger.BLUETOOTH, 'Starting background management for bike: $bikeId');

    // Keep the bike provider alive by reading it periodically
    _keepAliveTimers[bikeId] =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isRunning) {
        // This ensures the bike provider stays active and continues its work
        ref.read(bikeProvider(bikeId));
      } else {
        timer.cancel();
      }
    });

    // Initial read to start the provider
    ref.read(bikeProvider(bikeId));

    // Auto-connect the bike if it's not already connected
    _autoConnectBike(bikeId);
  }

  void _stopKeepingBikeAlive(String bikeId) {
    final timer = _keepAliveTimers.remove(bikeId);
    timer?.cancel();
    log.d(
        SDLogger.BLUETOOTH, 'Stopped background management for bike: $bikeId');
  }

  // Public interface
  void activateBike(String bikeId) {
    final bike = ref.read(bikesDBProvider.notifier).getBike(bikeId);
    if (bike != null && !bike.active) {
      final activeBike = bike.copyWith(active: true);
      ref.read(bikesDBProvider.notifier).saveBike(activeBike);
      _performMaintenance(); // Immediate maintenance to start the bike
      log.i(SDLogger.BLUETOOTH, 'Activated bike for background: $bikeId');
    }
  }

  void deactivateBike(String bikeId) {
    final bike = ref.read(bikesDBProvider.notifier).getBike(bikeId);
    if (bike != null && bike.active) {
      final inactiveBike = bike.copyWith(active: false);
      ref.read(bikesDBProvider.notifier).saveBike(inactiveBike);
      _stopKeepingBikeAlive(bikeId);
      log.i(SDLogger.BLUETOOTH, 'Deactivated bike from background: $bikeId');
    }
  }

  void deactivateAllBikes() {
    final allBikes = ref.read(bikesDBProvider);
    for (final bike in allBikes) {
      if (bike.active) {
        deactivateBike(bike.id);
      }
    }
  }

  List<String> getActiveBikeIds() {
    final allBikes = ref.read(bikesDBProvider);
    return allBikes
        .where((bike) => bike.active)
        .map((bike) => bike.id)
        .toList();
  }

  bool isBikeActive(String bikeId) {
    final bike = ref.read(bikesDBProvider.notifier).getBike(bikeId);
    return bike?.active ?? false;
  }

  int get activeBikeCount => state;

  // Auto-connect a bike if it's not connected
  void _autoConnectBike(String bikeId) {
    final connectionState = ref.read(connectionHandlerProvider(bikeId));

    if (connectionState == SDBluetoothConnectionState.disconnected) {
      log.i(SDLogger.BLUETOOTH, 'Auto-connecting active bike: $bikeId');

      // Small delay to ensure provider is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        final connectionHandler =
            ref.read(connectionHandlerProvider(bikeId).notifier);
        connectionHandler.connect();
      });
    }
  }

  // Connect all active bikes (useful for service startup)
  void connectAllActiveBikes() {
    final activeBikeIds = getActiveBikeIds();
    log.i(SDLogger.BLUETOOTH,
        'Connecting all ${activeBikeIds.length} active bikes');

    for (final bikeId in activeBikeIds) {
      _autoConnectBike(bikeId);
    }
  }
}
