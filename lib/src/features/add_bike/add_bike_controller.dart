import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/exclusive_bluetooth_operation.dart';
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

final class AddBikeLocationServicesDisabled extends AddBikeState {
  const AddBikeLocationServicesDisabled();
}

final class AddBikeScanning extends AddBikeState {
  const AddBikeScanning({
    required this.results,
    required this.savedDeviceIds,
    required this.isScanning,
  });

  final List<DiscoveredBike> results;
  final Set<String> savedDeviceIds;
  final bool isScanning;
}

final class AddBikeConnecting extends AddBikeState {
  const AddBikeConnecting(this.candidate);

  final DiscoveredBike candidate;
}

final class AddBikeConfirming extends AddBikeState {
  const AddBikeConfirming({
    required this.candidate,
    required this.protocol,
    required this.configuration,
    required this.suggestedName,
    required this.versions,
    required this.odometerMeters,
  });

  final DiscoveredBike candidate;
  final BikeProtocolVersion protocol;
  final BikeConfiguration configuration;
  final String suggestedName;
  final BikeVersionInfo? versions;
  final int? odometerMeters;
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
  late final ExclusiveBluetoothOperation _exclusiveBluetooth =
      ExclusiveBluetoothOperation(
        transport: transport,
        permissions: permissions,
        activeBikeCoordinator: activeBikeCoordinator,
      );
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
  var _operationGeneration = 0;

  ReadonlySignal<AddBikeState> get state => _state.readonly();

  Future<void> start({bool requestPermission = true}) async {
    _ensureNotDisposed();
    final generation = ++_operationGeneration;
    try {
      await _stopCandidateAndScan();
      if (!_isCurrent(generation)) {
        return;
      }
      _state.value = const AddBikeCheckingAccess();
      final access = await _exclusiveBluetooth.acquire(
        requestPermission: requestPermission,
        adapterTimeout: const Duration(seconds: 3),
      );
      if (!_isCurrent(generation)) {
        return;
      }
      if (access.permission != BluetoothPermissionState.granted) {
        _state.value = AddBikePermissionRequired(access.permission);
        return;
      }
      if (access.scanPrerequisite ==
          BluetoothScanPrerequisite.locationServicesDisabled) {
        _state.value = const AddBikeLocationServicesDisabled();
        return;
      }
      if (access.adapter != BikeAdapterState.on) {
        _state.value = AddBikeAdapterUnavailable(access.adapter);
        return;
      }

      _savedIds = (await bikeRepository.getBikes())
          .map((saved) => saved.bike.deviceId)
          .toSet();
      if (!_isCurrent(generation)) {
        return;
      }
      _results = const [];
      _isScanning = true;
      _acceptScanStop = false;
      _state.value = AddBikeScanning(
        results: const [],
        savedDeviceIds: Set.unmodifiable(_savedIds),
        isScanning: true,
      );
      _listenToScan();
      try {
        await transport.startScan(timeout: scanTimeout);
        if (!_isCurrent(generation)) {
          return;
        }
        _acceptScanStop = true;
        _isScanning = true;
        _publishScan();
      } on Object catch (error) {
        if (_isCurrent(generation)) {
          _state.value = AddBikeFailure(error.toString());
        }
      }
    } on ExclusiveBluetoothOperationBusy catch (error) {
      if (_isCurrent(generation)) {
        _state.value = AddBikeFailure(error.toString());
      }
    } on Object {
      if (_isCurrent(generation)) {
        _state.value = const AddBikeFailure(
          'Bluetooth setup could not be started. Try again.',
        );
      }
    }
  }

  Future<void> selectCandidate(DiscoveredBike candidate) async {
    _ensureNotDisposed();
    if (_state.peek() is! AddBikeScanning) {
      return;
    }
    if (_savedIds.contains(candidate.deviceId)) {
      _state.value = const AddBikeFailure('This bike is already saved.');
      return;
    }
    final protocol = BikeProtocolVersion.fromAdvertisedName(candidate.name);
    if (protocol == null) {
      _state.value = const AddBikeFailure(
        'This device does not advertise a supported bike protocol.',
      );
      return;
    }
    final generation = ++_operationGeneration;
    _state.value = AddBikeConnecting(candidate);
    try {
      await transport.stopScan();
      _isScanning = false;
      if (!_isCurrent(generation)) {
        return;
      }

      final session = BikeSession(
        connection: transport.openConnection(candidate.deviceId),
        preferredRegion: null,
        setOnConnect: const SetOnConnectSettings.defaults(),
        protocol: protocol,
        pollInterval: null,
        reconnectDelays: const [],
      );
      _candidateSession = session;
      await session.connect();
      if (!_isCurrent(generation) || _candidateSession != session) {
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

      _state.value = AddBikeConfirming(
        candidate: candidate,
        protocol: session.protocolVersion,
        configuration: configuration,
        suggestedName: defaultBikeName(candidate.deviceId),
        versions: session.versions.peek(),
        odometerMeters: session.odometerMeters.peek(),
      );
    } on Object catch (error) {
      if (_isCurrent(generation)) {
        _state.value = AddBikeFailure(error.toString());
      }
    }
  }

  Future<SavedBike> confirm({
    required String displayName,
    required BikeRegion? region,
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

    final persistedRegion = switch (current.protocol) {
      BikeProtocolVersion.v1 =>
        region ??
            (throw ArgumentError.value(
              region,
              'region',
              'A V1 bike requires a region.',
            )),
      BikeProtocolVersion.v2 => null,
    };

    _state.value = const AddBikeSaving();
    try {
      await _candidateSession?.dispose();
      _candidateSession = null;
      final configuration = current.configuration;
      final saved = await bikeRepository.addBike(
        deviceId: current.candidate.deviceId,
        advertisedName: current.protocol.advertisedName,
        displayName: normalizedName,
        region: persistedRegion,
        color: color,
        moduleSerial: current.candidate.moduleSerial,
        setOnConnect: SetOnConnectSettings(
          lightEnabled: false,
          mode: configuration.mode,
          modeEnabled: false,
          assist: configuration.assist,
          assistEnabled: false,
        ),
        versions: current.versions,
        odometerMeters: current.odometerMeters,
      );
      await _resumeCoordinator(temporarilySelect: saved);
      if (!_disposed) {
        _state.value = AddBikeCompleted(saved);
      }
      return saved;
    } on Object catch (error) {
      if (!_disposed) {
        _state.value = AddBikeFailure(error.toString());
      }
      rethrow;
    }
  }

  Future<void> retry({bool requestPermission = true}) {
    return start(requestPermission: requestPermission);
  }

  Future<bool> openPermissionSettings() => permissions.openSettings();

  Future<void> cancel() async {
    if (_disposed) {
      return;
    }
    _operationGeneration++;
    try {
      await _stopCandidateAndScan();
    } finally {
      await _resumeCoordinator();
      if (!_disposed) {
        _state.value = const AddBikeIdle();
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _operationGeneration++;
    try {
      await _stopCandidateAndScan();
    } on Object {
      // Leaving setup must still restore normal bike ownership.
    } finally {
      try {
        await _resumeCoordinator();
      } on Object {
        // The app may be shutting down with the coordinator already disposed.
      }
      _state.dispose();
    }
  }

  void _listenToScan() {
    unawaited(_resultsSubscription?.cancel());
    unawaited(_scanningSubscription?.cancel());
    unawaited(_adapterSubscription?.cancel());
    _resultsSubscription = transport.scanResults.listen((results) {
      for (final result in results) {
        if (_savedIds.contains(result.deviceId) &&
            result.moduleSerial != null) {
          unawaited(_saveSeenModuleSerial(result));
        }
      }
      _results = List.unmodifiable(
        results.where(
          (result) =>
              BikeProtocolVersion.fromAdvertisedName(result.name) != null,
        ),
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

  Future<void> _saveSeenModuleSerial(DiscoveredBike bike) async {
    try {
      await bikeRepository.saveModuleSerial(bike.deviceId, bike.moduleSerial!);
    } on Object {
      // Discovery remains usable if optional identity metadata cannot be saved.
    }
  }

  void _publishScan() {
    if (!_disposed && _state.peek() is AddBikeScanning) {
      _state.value = AddBikeScanning(
        results: _results,
        savedDeviceIds: Set.unmodifiable(_savedIds),
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
    final candidateSession = _candidateSession;
    _candidateSession = null;
    try {
      if (_isScanning) {
        await transport.stopScan();
      }
    } finally {
      await candidateSession?.dispose();
    }
    _isScanning = false;
    _acceptScanStop = false;
  }

  Future<void> _resumeCoordinator({SavedBike? temporarilySelect}) async {
    await _exclusiveBluetooth.release(
      temporarilySelect: temporarilySelect,
      stopScan: false,
    );
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('The Add Bike workflow is disposed.');
    }
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _operationGeneration;
  }
}
