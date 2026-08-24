import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/bike_names.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';

sealed class AddBikeState {
  const AddBikeState();
}

final class AddBikeIdle extends AddBikeState {
  const AddBikeIdle();
}

final class AddBikeCheckingAccess extends AddBikeState {
  const AddBikeCheckingAccess();
}

final class AddBikePermissionRequired extends AddBikeState {
  const AddBikePermissionRequired(this.permission);

  final BluetoothPermissionState permission;
}

final class AddBikeAdapterUnavailable extends AddBikeState {
  const AddBikeAdapterUnavailable(this.adapterState);

  final BikeAdapterState adapterState;
}

final class AddBikeScanning extends AddBikeState {
  const AddBikeScanning({required this.results, required this.isScanning});

  final List<DiscoveredBike> results;
  final bool isScanning;
}

final class AddBikeConnecting extends AddBikeState {
  const AddBikeConnecting(this.candidate);

  final DiscoveredBike candidate;
}

final class AddBikeConfirming extends AddBikeState {
  const AddBikeConfirming({
    required this.candidate,
    required this.configuration,
    required this.suggestedName,
  });

  final DiscoveredBike candidate;
  final BikeConfiguration configuration;
  final String suggestedName;
}

final class AddBikeSaving extends AddBikeState {
  const AddBikeSaving();
}

final class AddBikeCompleted extends AddBikeState {
  const AddBikeCompleted(this.bike);

  final SavedBike bike;
}

final class AddBikeFailure extends AddBikeState {
  const AddBikeFailure(this.message);

  final String message;
}

final class AddBikeController {
  AddBikeController({
    required this.transport,
    required this.permissions,
    required this.bikeRepository,
    required this.activeBikeCoordinator,
    this.scanTimeout = const Duration(seconds: 15),
  });

  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final BikeRepository bikeRepository;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final Duration scanTimeout;
  final Signal<AddBikeState> _state = signal(
    const AddBikeIdle(),
    options: const SignalOptions(name: 'addBike.state'),
  );

  StreamSubscription<List<DiscoveredBike>>? _resultsSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BikeAdapterState>? _adapterSubscription;
  BikeSession? _candidateSession;
  Set<String> _savedIds = const {};
  List<DiscoveredBike> _results = const [];
  var _isScanning = false;
  var _acceptScanStop = false;
  var _disposed = false;
  var _coordinatorPaused = false;

  ReadonlySignal<AddBikeState> get state => _state.readonly();

  Future<void> start() async {
    _ensureNotDisposed();
    try {
      await _stopCandidateAndScan();
      _state.value = const AddBikeCheckingAccess();
      if (!_coordinatorPaused) {
        _coordinatorPaused = true;
        await activeBikeCoordinator.pauseForDiscovery();
      }

      final permission = await permissions.ensureAccess(request: true);
      if (_disposed) {
        return;
      }
      if (permission != BluetoothPermissionState.granted) {
        _state.value = AddBikePermissionRequired(permission);
        return;
      }

      final adapter = await transport.adapterStates
          .where((state) => state != BikeAdapterState.unknown)
          .first
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => BikeAdapterState.unknown,
          );
      if (_disposed) {
        return;
      }
      if (adapter != BikeAdapterState.on) {
        _state.value = AddBikeAdapterUnavailable(adapter);
        return;
      }

      _savedIds = (await bikeRepository.getBikes())
          .map((saved) => saved.bike.deviceId)
          .toSet();
      _results = const [];
      _isScanning = true;
      _acceptScanStop = false;
      _state.value = const AddBikeScanning(results: [], isScanning: true);
      _listenToScan();
      try {
        await transport.startScan(timeout: scanTimeout);
        _acceptScanStop = true;
        _isScanning = true;
        _publishScan();
      } on Object catch (error) {
        _state.value = AddBikeFailure(error.toString());
      }
    } on Object {
      if (!_disposed) {
        _state.value = const AddBikeFailure(
          'Bluetooth setup could not be started. Try again.',
        );
      }
    }
  }

  Future<void> selectCandidate(DiscoveredBike candidate) async {
    _ensureNotDisposed();
    _state.value = AddBikeConnecting(candidate);
    await transport.stopScan();
    _isScanning = false;

    final session = BikeSession(
      connection: transport.openConnection(candidate.deviceId),
      preferredRegion: null,
      preferences: const RidePreferences.defaults(),
      protocolHint: BikeProtocolVersion.fromAdvertisedName(candidate.name),
      pollInterval: null,
      reconnectDelays: const [],
    );
    _candidateSession = session;
    await session.connect();
    if (_disposed || _candidateSession != session) {
      return;
    }
    final configuration = session.observed.peek();
    if (session.state.peek() is! SessionReady || configuration == null) {
      final sessionState = session.state.peek();
      final message = sessionState is SessionFailed
          ? sessionState.failure.message
          : 'The bike could not be prepared for setup.';
      _state.value = AddBikeFailure(message);
      return;
    }

    final advertisedName = candidate.name.trim();
    _state.value = AddBikeConfirming(
      candidate: candidate,
      configuration: configuration,
      suggestedName: advertisedName.isEmpty
          ? defaultBikeName(candidate.deviceId)
          : advertisedName,
    );
  }

  Future<SavedBike> confirm({
    required String displayName,
    required BikeRegion region,
    required BikeColor color,
  }) async {
    _ensureNotDisposed();
    final current = _state.peek();
    if (current is! AddBikeConfirming) {
      throw StateError('No bike is waiting for confirmation.');
    }
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty.',
      );
    }

    _state.value = const AddBikeSaving();
    await _candidateSession?.dispose();
    _candidateSession = null;
    final configuration = current.configuration;
    final saved = await bikeRepository.addBike(
      deviceId: current.candidate.deviceId,
      displayName: normalizedName,
      region: region,
      color: color,
      preferences: RidePreferences(
        desiredLight: configuration.light,
        desiredMode: configuration.mode,
        desiredAssist: configuration.assist,
        keepLight: false,
        keepMode: false,
        keepAssist: false,
        backgroundRequested: false,
        backgroundConsentVersion: 0,
      ),
    );
    await _resumeCoordinator();
    _state.value = AddBikeCompleted(saved);
    return saved;
  }

  Future<void> retry() => start();

  Future<bool> openPermissionSettings() => permissions.openSettings();

  Future<void> cancel() async {
    if (_disposed) {
      return;
    }
    await _stopCandidateAndScan();
    await _resumeCoordinator();
    _state.value = const AddBikeIdle();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await _stopCandidateAndScan();
    await _resumeCoordinator();
    _disposed = true;
    _state.dispose();
  }

  void _listenToScan() {
    unawaited(_resultsSubscription?.cancel());
    unawaited(_scanningSubscription?.cancel());
    unawaited(_adapterSubscription?.cancel());
    _resultsSubscription = transport.scanResults.listen((results) {
      _results = List.unmodifiable(
        results.where((result) => !_savedIds.contains(result.deviceId)),
      );
      _publishScan();
    }, onError: _onScanError);
    _scanningSubscription = transport.scanning.listen((isScanning) {
      if (!isScanning && !_acceptScanStop) {
        return;
      }
      _isScanning = isScanning;
      _publishScan();
    }, onError: _onScanError);
    _adapterSubscription = transport.adapterStates.listen((adapter) {
      if (adapter != BikeAdapterState.on &&
          adapter != BikeAdapterState.unknown &&
          _state.peek() is AddBikeScanning) {
        _state.value = AddBikeAdapterUnavailable(adapter);
      }
    }, onError: _onScanError);
  }

  void _publishScan() {
    if (!_disposed && _state.peek() is AddBikeScanning) {
      _state.value = AddBikeScanning(
        results: _results,
        isScanning: _isScanning,
      );
    }
  }

  void _onScanError(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      _state.value = AddBikeFailure(error.toString());
    }
  }

  Future<void> _stopCandidateAndScan() async {
    await _resultsSubscription?.cancel();
    _resultsSubscription = null;
    await _scanningSubscription?.cancel();
    _scanningSubscription = null;
    await _adapterSubscription?.cancel();
    _adapterSubscription = null;
    if (_isScanning) {
      await transport.stopScan();
    }
    _isScanning = false;
    _acceptScanStop = false;
    await _candidateSession?.dispose();
    _candidateSession = null;
  }

  Future<void> _resumeCoordinator() async {
    if (!_coordinatorPaused) {
      return;
    }
    _coordinatorPaused = false;
    await activeBikeCoordinator.resumeAfterDiscovery();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('The Add Bike workflow is disposed.');
    }
  }
}
