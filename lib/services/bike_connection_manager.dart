import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/utils/logger.dart';

part 'bike_connection_manager.g.dart';

/// Manager for bike connections across the application.
///
/// This class centralizes bike connection management, allowing multiple
/// bikes to be connected simultaneously and monitored regardless of the
/// current UI state.
class BikeConnectionManager {
  final Ref _ref;
  StreamSubscription<List<BikeModel>>? _bikesSubscription;
  final Set<String> _monitoredBikeIds = {};

  /// Creates a new bike connection manager.
  BikeConnectionManager(this._ref) {
    _initialize();
  }

  /// Initializes the manager and starts monitoring active bikes.
  void _initialize() {
    log.i(SDLogger.BIKE, 'Initializing bike connection manager');

    // Listen for bike list changes
    _bikesSubscription =
        _ref.read(bikeRepositoryProvider).bikesStream.listen((bikes) {
      _updateMonitoredBikes(bikes);
    });

    // Connect to all active bikes on startup
    _connectToActiveBikes();
  }

  /// Updates the set of monitored bikes based on the current list of bikes.
  void _updateMonitoredBikes(List<BikeModel> bikes) {
    final repository = _ref.read(bikeRepositoryProvider);
    final currentActiveIds =
        bikes.where((b) => b.isActive).map((b) => b.id).toSet();

    // Find bikes that should be connected but aren't monitored yet
    final newActiveIds = currentActiveIds.difference(_monitoredBikeIds);

    // Find bikes that are monitored but should be disconnected
    final inactiveIds = _monitoredBikeIds.difference(currentActiveIds);

    // Connect to newly active bikes
    for (final bikeId in newActiveIds) {
      final service = repository.getBikeService(bikeId);
      if (service != null) {
        log.d(SDLogger.BIKE, 'Starting to monitor bike: ${service.bike.name}');
        service.connect();
        _monitoredBikeIds.add(bikeId);
      }
    }

    // Update monitored set by removing inactive bikes
    for (final bikeId in inactiveIds) {
      final service = repository.getBikeService(bikeId);
      if (service != null) {
        log.d(
            SDLogger.BIKE, 'Stopping monitoring of bike: ${service.bike.name}');
        service.disconnect();
      }
      _monitoredBikeIds.remove(bikeId);
    }
  }

  /// Connects to all active bikes.
  Future<void> _connectToActiveBikes() async {
    final repository = _ref.read(bikeRepositoryProvider);
    final activeBikes = repository.activeBikes;

    log.i(SDLogger.BIKE, 'Connecting to ${activeBikes.length} active bikes');

    for (final bike in activeBikes) {
      final service = repository.getBikeService(bike.id);
      if (service != null) {
        service.connect();
        _monitoredBikeIds.add(bike.id);
      }
    }
  }

  /// Connects to a specific bike.
  Future<void> connectToBike(String bikeId) async {
    final repository = _ref.read(bikeRepositoryProvider);
    final service = repository.getBikeService(bikeId);

    if (service != null) {
      await service.connect();
      _monitoredBikeIds.add(bikeId);
    }
  }

  /// Disconnects from a specific bike.
  Future<void> disconnectFromBike(String bikeId) async {
    final repository = _ref.read(bikeRepositoryProvider);
    final service = repository.getBikeService(bikeId);

    if (service != null) {
      await service.disconnect();
      _monitoredBikeIds.remove(bikeId);
    }
  }

  /// Disconnects from all bikes.
  Future<void> disconnectFromAllBikes() async {
    final repository = _ref.read(bikeRepositoryProvider);
    await repository.disconnectAllBikes();
    _monitoredBikeIds.clear();
  }

  /// Reconnects to all active bikes.
  Future<void> reconnectAllActiveBikes() async {
    await disconnectFromAllBikes();
    await _connectToActiveBikes();
  }

  /// Disposes the manager.
  void dispose() {
    _bikesSubscription?.cancel();
    _monitoredBikeIds.clear();
  }
}

/// Provider for the bike connection manager.
@Riverpod(keepAlive: true)
BikeConnectionManager bikeConnectionManager(Ref ref) {
  final manager = BikeConnectionManager(ref);
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
}

/// Provider that ensures the bike connection manager is initialized.
///
/// This provider doesn't return any value, but ensures the connection manager
/// is created and starts monitoring bikes as soon as the app starts.
@Riverpod(keepAlive: true)
void ensureBikeConnectionManagerInitialized(Ref ref) {
  // Just watching the provider ensures it gets created
  ref.watch(bikeConnectionManagerProvider);
}
