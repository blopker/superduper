import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/services/bike_service.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';

part 'bike_repository.g.dart';

/// Repository for managing bike data persistence and bike services.
class BikeRepository {
  final Ref _ref;
  final Map<String, BikeService> _bikeServices = {};
  final StreamController<List<BikeModel>> _bikesController =
      StreamController<List<BikeModel>>.broadcast();
  List<BikeModel> _bikes = [];
  bool _initialized = false;

  /// Creates a new bike repository.
  BikeRepository(this._ref) {
    _loadBikes();
  }

  /// Returns a stream of all bikes.
  Stream<List<BikeModel>> get bikesStream => _bikesController.stream;

  /// Returns a list of all bikes.
  List<BikeModel> get bikes => List.unmodifiable(_bikes);

  /// Returns a list of all active bikes.
  List<BikeModel> get activeBikes =>
      _bikes.where((bike) => bike.isActive).toList();

  /// Returns the bike service for the specified bike ID.
  BikeService? getBikeService(String bikeId) => _bikeServices[bikeId];

  /// Returns a bike model by ID directly from the list.
  BikeModel? getBikeForId(String bikeId) =>
      _bikes.firstWhereOrNull((bike) => bike.id == bikeId);

  /// Returns all bike services.
  List<BikeService> get allBikeServices => _bikeServices.values.toList();

  /// Returns all active bike services.
  List<BikeService> get activeBikeServices =>
      _bikeServices.values.where((service) => service.isActive).toList();

  /// Adds a new bike from a scan result.
  Future<BikeModel> addBike(String bikeId, String deviceAddress) async {
    // Ensure we're initialized
    if (!_initialized) await _loadBikes();

    // Check if bike already exists
    final existingIndex = _bikes.indexWhere((bike) => bike.id == bikeId);

    if (existingIndex >= 0) {
      // Bike already exists, return it
      return _bikes[existingIndex];
    }

    // Create new bike
    final newBike = BikeModel.defaultBike(bikeId, deviceAddress);
    _bikes.add(newBike);

    // Create and store bike service
    final bluetoothService = _ref.read(bluetoothServiceProvider);
    final bikeService = BikeService(newBike, bluetoothService);
    log.i(SDLogger.DB, 'Created new bike service for: ${newBike.name}');
    _bikeServices[bikeId] = bikeService;

    // Save bike to storage
    await _saveBikes();

    // Notify listeners
    _bikesController.add(_bikes);

    log.i(SDLogger.DB, 'Added new bike: ${newBike.name} (${newBike.id})');
    return newBike;
  }

  /// Updates an existing bike.
  Future<void> updateBike(BikeModel updatedBike) async {
    final index = _bikes.indexWhere((bike) => bike.id == updatedBike.id);

    if (index < 0) {
      log.w(SDLogger.DB, 'Cannot update non-existent bike: ${updatedBike.id}');
      return;
    }

    _bikes[index] = updatedBike;

    // Update the bike service if it exists
    final service = _bikeServices[updatedBike.id];
    if (service != null && service.bike.isActive != updatedBike.isActive) {
      service.isActive = updatedBike.isActive;
    }

    await _saveBikes();
    _bikesController.add(_bikes);

    log.d(SDLogger.DB, 'Updated bike: ${updatedBike.name} (${updatedBike.id})');
  }

  /// Deletes a bike.
  Future<void> deleteBike(String bikeId) async {
    final service = _bikeServices[bikeId];
    if (service != null) {
      await service.disconnect();
      service.dispose();
      _bikeServices.remove(bikeId);
    }

    _bikes.removeWhere((bike) => bike.id == bikeId);
    await _saveBikes();
    _bikesController.add(_bikes);

    log.i(SDLogger.DB, 'Deleted bike with ID: $bikeId');
  }

  /// Sets whether a bike is active.
  Future<void> setBikeActive(String bikeId, bool isActive) async {
    final index = _bikes.indexWhere((bike) => bike.id == bikeId);

    if (index < 0) {
      log.w(SDLogger.DB,
          'Cannot set active state for non-existent bike: $bikeId');
      return;
    }

    final bike = _bikes[index];
    if (bike.isActive == isActive) return;

    _bikes[index] = bike.copyWith(isActive: isActive);

    // Update the bike service
    final service = _bikeServices[bikeId];
    if (service != null) {
      service.isActive = isActive;
    }

    await _saveBikes();
    _bikesController.add(_bikes);

    log.d(SDLogger.DB, 'Set bike active state: $bikeId -> $isActive');
  }

  /// Connects to all active bikes.
  Future<void> connectToActiveBikes() async {
    for (final service in _bikeServices.values) {
      if (service.isActive) {
        await service.connect();
      }
    }
  }

  /// Disconnects from all bikes.
  Future<void> disconnectAllBikes() async {
    for (final service in _bikeServices.values) {
      await service.disconnect();
    }
  }

  /// Loads bikes from storage or starts fresh if loading fails.
  Future<void> _loadBikes() async {
    if (_initialized) return;

    try {
      // Get file reference
      final file = await _getBikesFile();

      if (await file.exists()) {
        try {
          // Try to load existing bikes file
          final contents = await file.readAsString();
          if (contents.isNotEmpty) {
            final bikesList = jsonDecode(contents) as List;
            _bikes = bikesList
                .map((json) {
                  try {
                    return BikeModel.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    log.e(SDLogger.DB, 'Error parsing bike data', e);
                    return null;
                  }
                })
                .whereNotNull()
                .toList();

            log.i(SDLogger.DB,
                'Loaded ${_bikes.length} bikes from existing file');

            // Create services for each bike
            final bluetoothService = _ref.read(bluetoothServiceProvider);
            for (final bike in _bikes) {
              final bikeService = BikeService(bike, bluetoothService);
              _bikeServices[bike.id] = bikeService;
              log.d(SDLogger.DB, 'Loaded bike service for: ${bike.name}');
            }

            _bikesController.add(_bikes);
            _initialized = true;
            return;
          }
        } catch (loadError) {
          // Failed to load or parse existing file, delete it and start fresh
          log.e(
              SDLogger.DB,
              'Failed to load bikes from existing file, starting fresh',
              loadError);
          await file.delete();
        }
      }

      // Initialize with empty list if we couldn't load from file
      _bikes = [];
      _bikesController.add(_bikes);
      log.i(SDLogger.DB, 'Starting with fresh bike data');
    } catch (e) {
      log.e(SDLogger.DB, 'Error initializing bikes repository', e);
      // Still initialize with empty list on error
      _bikes = [];
      _bikesController.add(_bikes);
    } finally {
      _initialized = true;
    }
  }

  /// Saves bikes to storage.
  Future<void> _saveBikes() async {
    if (!_initialized) await _loadBikes();

    try {
      final file = await _getBikesFile();
      // Use explicit toJson to ensure proper serialization
      final jsonData = jsonEncode(_bikes.map((b) => b.toJson()).toList());
      await file.writeAsString(jsonData);

      log.d(SDLogger.DB, 'Saved ${_bikes.length} bikes to disk');
    } catch (e) {
      log.e(SDLogger.DB, 'Error saving bikes', e);
    }
  }

  /// Gets the bikes file.
  Future<File> _getBikesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/bikes.json');
  }

  /// Disposes resources.
  void dispose() {
    // Save bikes one last time before disposing
    _saveBikes().then((_) {
      for (final service in _bikeServices.values) {
        service.dispose();
      }
      _bikeServices.clear();
      _bikesController.close();
    });
  }
}

/// Provider for the bike repository.
@Riverpod(keepAlive: true)
BikeRepository bikeRepository(Ref ref) {
  log.i(SDLogger.DB, 'Initializing bike repository');
  final repository = BikeRepository(ref);
  ref.onDispose(() {
    log.i(SDLogger.DB, 'Disposing bike repository');
    repository.dispose();
  });
  return repository;
}

/// Provider for all bikes.
@riverpod
Stream<List<BikeModel>> bikes(Ref ref) {
  return ref.watch(bikeRepositoryProvider).bikesStream;
}

/// Provider for active bikes.
@riverpod
List<BikeModel> activeBikes(Ref ref) {
  return ref.watch(bikeRepositoryProvider).activeBikes;
}

/// Provider for a specific bike by ID.
@riverpod
BikeModel? bike(Ref ref, String bikeId) {
  final allBikes = ref.watch(bikesProvider).valueOrNull ?? [];
  for (final bike in allBikes) {
    if (bike.id == bikeId) {
      return bike;
    }
  }
  return null;
}

/// Provider for a bike service by bike ID.
@riverpod
BikeService? bikeService(Ref ref, String bikeId) {
  return ref.watch(bikeRepositoryProvider).getBikeService(bikeId);
}
