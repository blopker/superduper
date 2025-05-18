import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/connection_state.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';
import 'package:superduper/utils/uuids.dart';

/// Service that manages communication with a single bike.
///
/// Each bike has its own service instance that handles connections,
/// state updates, and commands independent of other bikes or the UI.
class BikeService {
  final Ref _ref;
  final SDBluetoothService _bluetoothService;
  final Function(BikeModel) _onBikeUpdated;

  // Stream controllers
  final _connectionStateController =
      StreamController<BikeConnectionState>.broadcast();
  final _bikeModelController = StreamController<BikeModel>.broadcast();

  // State
  BikeConnectionState _connectionState = BikeConnectionState.disconnected;
  BikeModel _bike;
  BluetoothDevice? _device;

  // Timers
  Timer? _reconnectTimer;
  Timer? _updateTimer;
  Timer? _updateDebounce;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;

  // Flags
  bool _writing = false;
  bool _disposed = false;

  /// Creates a new bike service.
  BikeService(
    this._ref,
    initialBike,
    this._bluetoothService, {
    Function(BikeModel)? onBikeUpdated,
  })  : _bike = initialBike,
        _onBikeUpdated = onBikeUpdated ?? _defaultBikeUpdatedCallback {
    _initialize();
  }

  // Default callback that does nothing when bike is updated
  static void _defaultBikeUpdatedCallback(BikeModel _) {}

  /// Stream of connection state changes.
  Stream<BikeConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of bike model updates.
  Stream<BikeModel> get bikeModelStream => _bikeModelController.stream;

  /// Current connection state.
  BikeConnectionState get connectionState => _connectionState;

  /// Current bike model.
  BikeModel get bike => _bike;

  /// Whether the bike is active (should auto-connect).
  bool get isActive => _bike.isActive;

  /// Changes whether the bike is active.
  set isActive(bool value) {
    if (_bike.isActive == value) return;

    final updatedBike = _bike.copyWith(isActive: value);
    _updateBikeModel(updatedBike);

    if (value) {
      connect();
    } else if (!value && _connectionState == BikeConnectionState.connected) {
      disconnect();
    }
  }

  /// Initializes the service.
  void _initialize() {
    if (_bike.isActive) {
      _startReconnectTimer();
      connect();
    }
  }

  /// Connects to the bike.
  Future<void> connect() async {
    if (_disposed) return;
    if (_connectionState == BikeConnectionState.connecting ||
        _connectionState == BikeConnectionState.connected) {
      return;
    }

    log.i(SDLogger.BIKE, 'Connecting to bike: ${_bike.name} (${_bike.id})');
    _setConnectionState(BikeConnectionState.connecting);

    try {
      _device = BluetoothDevice.fromId(_bike.bluetoothAddress);

      // Listen for device connection state changes
      _deviceConnectionSubscription?.cancel();
      _deviceConnectionSubscription = _device!.connectionState.listen((state) {
        if (_disposed) return;

        if (state == BluetoothConnectionState.connected) {
          log.i(SDLogger.BIKE, 'Device connected: ${_bike.name}');
          _setConnectionState(BikeConnectionState.connected);
          _updateBikeModelProperty(isConnected: true);
          _startUpdateTimer();
          Future.delayed(Duration(seconds: 1), () {
            _pushLockedSettings(); // Push locked settings immediately on connection
          });
          _updateStateDataNow();
        } else if (state == BluetoothConnectionState.disconnected) {
          log.i(SDLogger.BIKE, 'Device disconnected: ${_bike.name}');
          _setConnectionState(BikeConnectionState.disconnected);
          _updateBikeModelProperty(isConnected: false);
        }
      });

      // Connect to the device
      await _device!.connect();
      await _device!.discoverServices();
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error connecting to bike: ${_bike.name}', e);
      _setConnectionState(BikeConnectionState.disconnected);
      _updateBikeModelProperty(isConnected: false);
    }
  }

  /// Disconnects from the bike.
  Future<void> disconnect() async {
    if (_disposed) return;
    if (_connectionState == BikeConnectionState.disconnected ||
        _connectionState == BikeConnectionState.disconnecting) {
      return;
    }

    log.i(SDLogger.BIKE, 'Disconnecting from bike: ${_bike.name}');
    _setConnectionState(BikeConnectionState.disconnecting);

    _stopUpdateTimer();

    try {
      if (_device != null) {
        await _device!.disconnect();
      }
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error disconnecting from bike: ${_bike.name}', e);
    } finally {
      _setConnectionState(BikeConnectionState.disconnected);
      _updateBikeModelProperty(isConnected: false);
    }
  }

  /// Sets a new connection state and notifies listeners.
  void _setConnectionState(BikeConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Updates the bike model, notifies listeners, and optionally triggers the update callback.
  /// 
  /// If skipCallback is true, the update callback will not be called. This is used
  /// to prevent infinite loops when the repository updates the bike model.
  void _updateBikeModel(BikeModel updatedBike, {bool skipCallback = false}) {
    _bike = updatedBike;
    _bikeModelController.add(_bike);
    if (!skipCallback) {
      _onBikeUpdated(updatedBike);
    }
  }

  /// Updates specific properties of the bike model.
  void _updateBikeModelProperty({
    bool? light,
    bool? lightLocked,
    int? mode,
    bool? modeLocked,
    int? assist,
    bool? assistLocked,
    bool? backgroundLock,
    bool? isConnected,
    bool? isActive,
  }) {
    final updatedBike = _bike.copyWith(
      light: light ?? _bike.light,
      lightLocked: lightLocked ?? _bike.lightLocked,
      mode: mode ?? _bike.mode,
      modeLocked: modeLocked ?? _bike.modeLocked,
      assist: assist ?? _bike.assist,
      assistLocked: assistLocked ?? _bike.assistLocked,
      backgroundLock: backgroundLock ?? _bike.backgroundLock,
      isConnected: isConnected ?? _bike.isConnected,
      isActive: isActive ?? _bike.isActive,
    );

    _updateBikeModel(updatedBike);
  }

  /// Starts the reconnect timer.
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (_connectionState == BikeConnectionState.disconnected &&
          _bike.isActive) {
        connect();
      }
    });
  }

  /// Starts the update timer.
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (!_writing) {
        _updateStateData();
      }
    });
  }

  /// Stops the update timer.
  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Updates the bike state from the device.
  Future<void> _updateStateData() async {
    if (_disposed) return;
    if (_connectionState != BikeConnectionState.connected) return;

    _resetUpdateDebounce();
    _writing = false;

    _updateDebounce = Timer(const Duration(seconds: 2), () async {
      await _updateStateDataNow();
    });
  }

  /// Forces an immediate state update from the device.
  Future<void> _updateStateDataNow() async {
    if (_disposed) return;
    if (_connectionState != BikeConnectionState.connected || _device == null) {
      return;
    }

    try {
      final data = await _readFromBike();
      if (data == null || data.isEmpty) return;

      log.d(SDLogger.BIKE, 'Received data from bike: $data');

      var updatedBike = _bike.updateFromData(data);

      // Apply locked settings
      if (_bike.lightLocked && _bike.light != updatedBike.light) {
        updatedBike = updatedBike.copyWith(light: _bike.light);
      }

      if (_bike.modeLocked && _bike.mode != updatedBike.mode) {
        updatedBike = updatedBike.copyWith(mode: _bike.mode);
      }

      if (_bike.assistLocked && _bike.assist != updatedBike.assist) {
        updatedBike = updatedBike.copyWith(assist: _bike.assist);
      }

      // Also check if any settings are locked, even if they haven't changed
      bool hasLockedSettings =
          _bike.lightLocked || _bike.modeLocked || _bike.assistLocked;

      if (updatedBike != _bike) {
        _updateBikeModel(updatedBike);
        await _writeToBike(updatedBike.toWriteData());
      } else if (hasLockedSettings) {
        await _writeToBike(_bike.toWriteData());
      }
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error updating state from bike: ${_bike.name}', e);
    }
  }

  /// Immediately pushes locked settings to the bike.
  /// This ensures the bike receives the locked settings as soon as it connects.
  Future<void> _pushLockedSettings() async {
    if (_disposed) return;
    if (_connectionState != BikeConnectionState.connected || _device == null) {
      return;
    }

    try {
      // Only push settings if at least one setting is locked
      if (_bike.lightLocked || _bike.modeLocked || _bike.assistLocked) {
        log.i(SDLogger.BIKE, 'Pushing locked settings to bike: ${_bike.name}');
        await _writeToBike(_bike.toWriteData());
      }
    } catch (e) {
      log.e(SDLogger.BIKE,
          'Error pushing locked settings to bike: ${_bike.name}', e);
    }
  }

  /// Resets the update debounce timer.
  void _resetUpdateDebounce() {
    _updateDebounce?.cancel();
  }

  /// Reads data from the bike.
  Future<List<int>?> _readFromBike() async {
    if (_device == null) return null;

    try {
      // Request the current state
      await _bluetoothService.write(
        device: _device!,
        data: [3, 0],
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER_ID,
      );

      // Read the response
      return await _bluetoothService.read(
        device: _device!,
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER,
      );
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error reading from bike: ${_bike.name}', e);
      return null;
    }
  }

  /// Writes data to the bike.
  Future<void> _writeToBike(List<int> data) async {
    if (_device == null) return;

    _writing = true;
    try {
      await _bluetoothService.write(
        device: _device!,
        data: data,
      );
      log.d(SDLogger.BIKE, 'Wrote data to bike: $data');
    } catch (e) {
      log.e(SDLogger.BIKE, 'Error writing to bike: ${_bike.name}', e);
    } finally {
      _writing = false;
    }
  }

  /// Updates the bike's light state.
  Future<void> toggleLight() async {
    final newLightState = !_bike.light;
    log.d(SDLogger.BIKE, 'Toggling light to: $newLightState');

    final updatedBike = _bike.copyWith(light: newLightState);
    _updateBikeModel(updatedBike);

    if (_connectionState == BikeConnectionState.connected) {
      await _writeToBike(updatedBike.toWriteData());
    }
  }

  /// Updates the bike's mode.
  Future<void> toggleMode() async {
    log.d(SDLogger.BIKE, 'Toggling mode to: ${_bike.nextMode}');

    final updatedBike = _bike.copyWith(mode: _bike.nextMode);
    _updateBikeModel(updatedBike);

    if (_connectionState == BikeConnectionState.connected) {
      await _writeToBike(updatedBike.toWriteData());
    }
  }

  /// Updates the bike's assist level.
  Future<void> toggleAssist() async {
    final newAssist = (_bike.assist + 1) % 5;
    log.d(SDLogger.BIKE, 'Toggling assist to: $newAssist');

    final updatedBike = _bike.copyWith(assist: newAssist);
    _updateBikeModel(updatedBike);

    if (_connectionState == BikeConnectionState.connected) {
      await _writeToBike(updatedBike.toWriteData());
    }
  }

  /// Toggles whether light setting is locked.
  void toggleLightLocked() {
    log.d(SDLogger.BIKE, 'Toggling light lock: ${!_bike.lightLocked}');
    final updatedBike = _bike.copyWith(lightLocked: !_bike.lightLocked);
    _updateBikeModel(updatedBike);
  }

  /// Toggles whether mode setting is locked.
  void toggleModeLocked() {
    log.d(SDLogger.BIKE, 'Toggling mode lock: ${!_bike.modeLocked}');
    final updatedBike = _bike.copyWith(modeLocked: !_bike.modeLocked);
    _updateBikeModel(updatedBike);
  }

  /// Toggles whether assist setting is locked.
  void toggleAssistLocked() {
    log.d(SDLogger.BIKE, 'Toggling assist lock: ${!_bike.assistLocked}');
    final updatedBike = _bike.copyWith(assistLocked: !_bike.assistLocked);
    _updateBikeModel(updatedBike);
  }

  /// Toggles background lock.
  void toggleBackgroundLock() {
    log.d(SDLogger.BIKE, 'Toggling background lock: ${!_bike.backgroundLock}');
    final updatedBike = _bike.copyWith(backgroundLock: !_bike.backgroundLock);
    _updateBikeModel(updatedBike);
  }

  /// Updates the bike model with a new instance.
  /// This method is public and can be called from outside the service.
  /// 
  /// The skipCallback parameter controls whether the update callback is called.
  /// Set to true when updating from the repository to avoid infinite loops.
  void updateBikeModel(BikeModel updatedBike, {bool skipCallback = true}) {
    if (_disposed) return;
    if (updatedBike.id != _bike.id) {
      log.e(SDLogger.BIKE, 'Cannot update bike with different ID', null);
      return;
    }
    _updateBikeModel(updatedBike, skipCallback: skipCallback);
  }

  /// Disposes resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    log.d(SDLogger.BIKE, 'Disposing bike service: ${_bike.name}');

    _reconnectTimer?.cancel();
    _updateTimer?.cancel();
    _updateDebounce?.cancel();
    _deviceConnectionSubscription?.cancel();

    _connectionStateController.close();
    _bikeModelController.close();

    if (_connectionState == BikeConnectionState.connected) {
      disconnect();
    }
  }
}
