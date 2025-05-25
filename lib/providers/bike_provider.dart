import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../providers/bluetooth_provider.dart';
import '../core/utils/logger.dart';

export '../models/models.dart';

part 'bike_provider.g.dart';

@riverpod
class Bike extends _$Bike {
  Timer? _updateDebounce;
  Timer? _updateTimer;
  bool _writing = false;

  @override
  BikeState build(String id) {
    ref.onDispose(() {
      _updateTimer?.cancel();
      _updateDebounce?.cancel();
    });

    var bike = ref.watch(bikesDBProvider.notifier).getBike(id);
    bike ??= BikeState.defaultState(id);

    _resetReadTimer();

    // Watch connection state and handle auto-connection + immediate settings push
    ref.listen(connectionHandlerProvider(id), (previous, next) {
      _handleConnectionStateChange(previous, next);
    });

    // Auto-connect on first build
    if (bike.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoConnect();
      });
    }
    return bike;
  }

  _resetReadTimer() {
    if (_updateTimer?.isActive ?? false) {
      _updateTimer?.cancel();
    }
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_writing) {
        return;
      }
      updateStateData();
    });
  }

  _resetDebounce() {
    if (_updateDebounce?.isActive ?? false) _updateDebounce?.cancel();
    _resetReadTimer();
  }

  Future<void> updateStateData() async {
    var status = ref.read(connectionHandlerProvider(state.id));
    if (status != SDBluetoothConnectionState.connected) {
      return;
    }
    _resetDebounce();
    _writing = false;
    _updateDebounce = Timer(const Duration(seconds: 2), () async {
      _resetReadTimer();
      await _updateStateDataNow();
    });
  }

  Future<void> _updateStateDataNow({force = false}) async {
    var data =
        await ref.read(connectionHandlerProvider(state.id).notifier).read();
    if (data == null || data.isEmpty) {
      return;
    }
    var newState = state.updateFromData(data);
    if (newState == state && !force) {
      return;
    }
    log.d(SDLogger.BIKE, 'State update from data: $data');
    if (state.lightLocked && state.light != newState.light) {
      newState = newState.copyWith(light: state.light);
    }

    if (state.modeLocked && state.mode != newState.mode) {
      newState = newState.copyWith(mode: state.mode);
    }

    if (state.assistLocked && state.assist != newState.assist) {
      newState = newState.copyWith(assist: state.assist);
    }
    writeStateData(newState);
  }

  void writeStateData(BikeState newState, {saveToBike = true}) async {
    _resetDebounce();
    if (state.id != newState.id) {
      throw Exception('Bike id mismatch');
    }
    var status = ref.read(connectionHandlerProvider(state.id));
    if (saveToBike) {
      if (status != SDBluetoothConnectionState.connected) {
        return;
      }
      _writing = true;
      final repo = ref.read(connectionHandlerProvider(state.id).notifier);
      await repo.write(newState.toWriteData());
      log.d(SDLogger.BIKE, 'Wrote data to bike: ${newState.toWriteData()}');
    }
    ref.read(bikesDBProvider.notifier).saveBike(newState);
    state = newState;
    updateStateData();
  }

  void toggleLight() async {
    log.d(SDLogger.BIKE, 'Toggling light: ${!state.light}');
    writeStateData(state.copyWith(light: !state.light));
  }

  void toggleMode() async {
    log.d(SDLogger.BIKE, 'Toggling mode to: ${state.nextMode}');
    writeStateData(state.copyWith(mode: state.nextMode));
  }

  void toggleAssist() async {
    final newAssist = (state.assist + 1) % 5;
    log.d(SDLogger.BIKE, 'Toggling assist to: $newAssist');
    writeStateData(state.copyWith(assist: newAssist));
  }

  void toggleLightLocked() async {
    log.d(SDLogger.BIKE, 'Toggling light lock: ${!state.lightLocked}');
    writeStateData(state.copyWith(lightLocked: !state.lightLocked),
        saveToBike: false);
  }

  void toggleModeLocked() async {
    log.d(SDLogger.BIKE, 'Toggling mode lock: ${!state.modeLocked}');
    writeStateData(state.copyWith(modeLocked: !state.modeLocked),
        saveToBike: false);
  }

  void toggleAssistLocked() async {
    log.d(SDLogger.BIKE, 'Toggling assist lock: ${!state.assistLocked}');
    writeStateData(state.copyWith(assistLocked: !state.assistLocked),
        saveToBike: false);
  }

  void toggleBackgroundLock() async {
    log.d(SDLogger.BIKE, 'Toggling background lock: ${!state.modeLock}');
    writeStateData(state.copyWith(modeLock: !state.modeLock),
        saveToBike: false);
  }

  set active(bool value) {
    log.i(SDLogger.BIKE, 'Setting active state to: $value');
    state = state.copyWith(active: value);
    writeStateData(state, saveToBike: false);
  }

  void delete(BikeState bike) {
    log.i(SDLogger.BIKE, 'Deleting bike: ${bike.name}');
    ref.read(bikesDBProvider.notifier).deleteBike(bike);
  }

  // Auto-connection logic
  void _autoConnect() async {
    final connectionHandler =
        ref.read(connectionHandlerProvider(state.id).notifier);
    final connectionState = ref.read(connectionHandlerProvider(state.id));

    if (connectionState == SDBluetoothConnectionState.disconnected) {
      log.i(SDLogger.BIKE, 'Auto-connecting to bike: ${state.name}');
      await connectionHandler.connect();
      await Future.delayed(const Duration(seconds: 1), () {
        _updateStateDataNow(force: true);
      });
    }
  }

  // Handle connection state changes
  void _handleConnectionStateChange(
      SDBluetoothConnectionState? previous, SDBluetoothConnectionState next) {
    log.d(SDLogger.BIKE,
        'Connection state change for ${state.name}: $previous -> $next');

    // When we connect, immediately push current settings after 1 second
    if (previous != SDBluetoothConnectionState.connected &&
        next == SDBluetoothConnectionState.connected) {
      log.i(SDLogger.BIKE,
          'Connected to ${state.name} - will push settings in 1 second');

      Future.delayed(const Duration(seconds: 1), () {
        _updateStateDataNow(force: true);
      });
    }
  }
}
