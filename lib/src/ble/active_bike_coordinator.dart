import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

sealed class ActiveBikeState {
  const ActiveBikeState();
}

final class ActiveBikeLoading extends ActiveBikeState {
  const ActiveBikeLoading();
}

final class NoActiveBike extends ActiveBikeState {
  const NoActiveBike();
}

final class ActiveBikePermissionRequired extends ActiveBikeState {
  const ActiveBikePermissionRequired({required this.permission});

  final BluetoothPermissionState permission;
}

final class ActiveBikeSessionStatus extends ActiveBikeState {
  const ActiveBikeSessionStatus({
    required this.bike,
    required this.sessionState,
    required this.isTemporary,
  });

  final SavedBike bike;
  final BikeSessionState sessionState;
  final bool isTemporary;
}

final class ActiveBikeCoordinatorFailure extends ActiveBikeState {
  const ActiveBikeCoordinatorFailure(this.message);

  final String message;
}

typedef BikeSessionBuilder = BikeSession Function(SavedBike bike);

final class ActiveBikeCoordinator {
  ActiveBikeCoordinator({
    required this.bikeRepository,
    required this.settingsRepository,
    required this.permissions,
    required this.buildSession,
  });

  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final BluetoothPermissionGateway permissions;
  final BikeSessionBuilder buildSession;
  final Signal<ActiveBikeState> _state = signal(
    const ActiveBikeLoading(),
    options: const SignalOptions(name: 'activeBike.state'),
  );
  final Signal<List<SavedBike>> _bikes = signal(
    const [],
    options: const SignalOptions(name: 'activeBike.bikes'),
  );
  final Signal<String?> _activeBikeId = signal(
    null,
    options: const SignalOptions(name: 'activeBike.activeId'),
  );
  final Signal<bool> _migrationNoticePending = signal(
    false,
    options: const SignalOptions(name: 'activeBike.migrationNoticePending'),
  );
  final Signal<BikeSession?> _session = signal(
    null,
    options: const SignalOptions(name: 'activeBike.session'),
  );
  final Completer<void> _disposeSignal = Completer<void>();

  StreamSubscription<List<SavedBike>>? _bikesSubscription;
  StreamSubscription<AppPreferences>? _settingsSubscription;
  EffectCleanup? _sessionStateCleanup;
  Future<BluetoothPermissionState>? _permissionCheck;
  SavedBike? _currentBike;
  String? _temporaryBikeId;
  var _hasBikes = false;
  var _hasSettings = false;
  var _switchGeneration = 0;
  var _started = false;
  var _disposed = false;
  var _discoveryPaused = false;
  var _foreground = true;
  var _readyRecorded = false;

  ReadonlySignal<ActiveBikeState> get state => _state.readonly();
  ReadonlySignal<List<SavedBike>> get bikes => _bikes.readonly();
  ReadonlySignal<String?> get activeBikeId => _activeBikeId.readonly();
  ReadonlySignal<bool> get migrationNoticePending =>
      _migrationNoticePending.readonly();
  ReadonlySignal<BikeSession?> get session => _session.readonly();

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    final bikesReady = Completer<void>();
    final settingsReady = Completer<void>();
    var initialized = false;
    _bikesSubscription = bikeRepository.watchBikes().listen(
      (bikes) {
        if (_disposed) {
          return;
        }
        _hasBikes = true;
        _bikes.value = bikes;
        if (!bikesReady.isCompleted) {
          bikesReady.complete();
        }
        if (initialized) {
          _scheduleRecompute();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _onStreamError(error, stackTrace);
        if (!bikesReady.isCompleted) {
          bikesReady.completeError(error, stackTrace);
        }
      },
    );
    _settingsSubscription = settingsRepository.watch().listen(
      (settings) {
        if (_disposed) {
          return;
        }
        _hasSettings = true;
        _activeBikeId.value = settings.activeBikeId;
        if (_temporaryBikeId == settings.activeBikeId) {
          _temporaryBikeId = null;
        }
        _migrationNoticePending.value = settings.migrationNoticePending;
        if (!settingsReady.isCompleted) {
          settingsReady.complete();
        }
        if (initialized) {
          _scheduleRecompute();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _onStreamError(error, stackTrace);
        if (!settingsReady.isCompleted) {
          settingsReady.completeError(error, stackTrace);
        }
      },
    );
    await Future.any([
      Future.wait([bikesReady.future, settingsReady.future]),
      _disposeSignal.future,
    ]);
    if (_disposed) {
      return;
    }
    initialized = true;
    final targetId = _activeBikeId.peek();
    final hasTarget =
        targetId != null &&
        _bikes.peek().any((saved) => saved.bike.deviceId == targetId);
    if (!hasTarget) {
      _state.value = const NoActiveBike();
    }
    _scheduleRecompute();
  }

  Future<void> selectTemporarily(String deviceId) async {
    _requireSavedBike(deviceId);
    if (_temporaryBikeId == deviceId && _session.peek()?.deviceId == deviceId) {
      return;
    }
    _temporaryBikeId = deviceId;
    await _recompute(force: true);
  }

  Future<void> returnToActiveBike() async {
    if (_temporaryBikeId == null) {
      return;
    }
    _temporaryBikeId = null;
    await _recompute(force: true);
  }

  Future<void> makeBikeActive(String deviceId) async {
    await settingsRepository.makeBikeActive(deviceId);
    _temporaryBikeId = null;
    await _recompute(force: _session.peek()?.deviceId != deviceId);
  }

  Future<void> forgetBike(String deviceId) async {
    _switchGeneration++;
    if (_session.peek()?.deviceId == deviceId) {
      await _clearSession();
    }
    if (_temporaryBikeId == deviceId) {
      _temporaryBikeId = null;
    }
    await bikeRepository.forgetBike(deviceId);
  }

  Future<void> retry() async {
    final current = _session.peek();
    if (current != null) {
      if (current.state.peek() case SessionReady() || SessionSynchronizing()) {
        return;
      }
      await current.retry();
      return;
    }
    await _recompute(force: true);
  }

  Future<void> disconnectManually() async {
    await _session.peek()?.disconnect();
  }

  Future<void> dismissMigrationNotice() {
    return settingsRepository.dismissMigrationNotice();
  }

  Future<void> pauseForDiscovery() async {
    _discoveryPaused = true;
    _switchGeneration++;
    await _clearSession();
  }

  Future<void> resumeAfterDiscovery({SavedBike? temporarilySelect}) async {
    if (!_discoveryPaused) {
      return;
    }
    if (temporarilySelect != null) {
      final updated = [..._bikes.peek()];
      final existingIndex = updated.indexWhere(
        (bike) => bike.bike.deviceId == temporarilySelect.bike.deviceId,
      );
      if (existingIndex == -1) {
        updated.add(temporarilySelect);
      } else {
        updated[existingIndex] = temporarilySelect;
      }
      _bikes.value = List.unmodifiable(updated);
      _temporaryBikeId = temporarilySelect.bike.deviceId;
    }
    _discoveryPaused = false;
    if (_foreground) {
      await _recompute(force: true);
    }
  }

  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    if (_discoveryPaused) {
      return;
    }
    if (foreground) {
      final current = _session.peek();
      if (current == null) {
        await _recompute(force: true, requestPermission: false);
      } else {
        await current.resumeFromBackground();
      }
    } else {
      await _session.peek()?.pauseForBackground();
    }
  }

  Future<bool> openPermissionSettings() => permissions.openSettings();

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (!_disposeSignal.isCompleted) {
      _disposeSignal.complete();
    }
    _switchGeneration++;
    await _bikesSubscription?.cancel();
    await _settingsSubscription?.cancel();
    await _clearSession();
    _state.dispose();
    _bikes.dispose();
    _activeBikeId.dispose();
    _migrationNoticePending.dispose();
    _session.dispose();
  }

  Future<void> _recompute({
    bool force = false,
    bool requestPermission = true,
  }) async {
    if (_disposed ||
        !_hasBikes ||
        !_hasSettings ||
        _discoveryPaused ||
        !_foreground) {
      return;
    }
    try {
      final targetId = _temporaryBikeId ?? _activeBikeId.peek();
      if (targetId == null) {
        await _clearSession();
        if (!_disposed) {
          _state.value = const NoActiveBike();
        }
        return;
      }
      final target = _bikes.peek().where(
        (saved) => saved.bike.deviceId == targetId,
      );
      if (target.isEmpty) {
        await _clearSession();
        if (!_disposed) {
          _state.value = const NoActiveBike();
        }
        return;
      }
      final bike = target.single;
      final current = _session.peek();
      if (!force &&
          current?.deviceId == targetId &&
          current?.protocolVersion == bike.bike.protocol) {
        _currentBike = bike;
        current!.updatePreferredRegion(bike.bike.region);
        try {
          await current.updatePreferences(bike.preferences);
        } on BikeSessionFailure {
          // The session publishes its own retry/degraded state. A settings
          // enforcement failure must not hide a live bike behind a global
          // repository-style error.
        }
        if (!_disposed &&
            !_discoveryPaused &&
            _session.peek() == current &&
            _currentBike?.bike.deviceId == bike.bike.deviceId) {
          _publishSessionState(current.state.peek());
        }
        return;
      }

      final generation = ++_switchGeneration;
      await _clearSession();
      if (_disposed ||
          _discoveryPaused ||
          !_foreground ||
          generation != _switchGeneration) {
        return;
      }
      _state.value = const ActiveBikeLoading();
      final permission = await _ensurePermission(
        request: requestPermission,
      );
      if (_disposed ||
          _discoveryPaused ||
          !_foreground ||
          generation != _switchGeneration) {
        return;
      }
      if (permission != BluetoothPermissionState.granted) {
        _state.value = ActiveBikePermissionRequired(permission: permission);
        return;
      }

      final next = buildSession(bike);
      if (_disposed ||
          _discoveryPaused ||
          !_foreground ||
          generation != _switchGeneration) {
        await next.dispose();
        return;
      }
      _readyRecorded = false;
      _currentBike = bike;
      _session.value = next;
      _sessionStateCleanup = next.state.subscribe((sessionState) {
        if (!_disposed && _session.peek() == next) {
          _publishSessionState(sessionState);
        }
      });
      _publishSessionState(next.state.peek());
      unawaited(
        next.connect().catchError((Object error) {
          if (!_disposed && _session.peek() == next) {
            _state.value = ActiveBikeCoordinatorFailure(error.toString());
          }
        }),
      );
    } on Object catch (error) {
      if (!_disposed && !_discoveryPaused && _foreground) {
        _state.value = ActiveBikeCoordinatorFailure(error.toString());
      }
    }
  }

  Future<BluetoothPermissionState> _ensurePermission({
    required bool request,
  }) async {
    final existing = _permissionCheck;
    if (existing != null) {
      return existing;
    }
    late final Future<BluetoothPermissionState> pending;
    pending = permissions.ensureAccess(request: request);
    _permissionCheck = pending;
    try {
      return await pending;
    } finally {
      if (identical(_permissionCheck, pending)) {
        _permissionCheck = null;
      }
    }
  }

  Future<void> _clearSession() async {
    _sessionStateCleanup?.call();
    _sessionStateCleanup = null;
    final old = _session.peek();
    _session.value = null;
    _currentBike = null;
    _readyRecorded = false;
    if (old != null) {
      await old.dispose();
    }
  }

  void _publishSessionState(BikeSessionState sessionState) {
    final bike = _currentBike;
    if (bike == null) {
      return;
    }
    _state.value = ActiveBikeSessionStatus(
      bike: bike,
      sessionState: sessionState,
      isTemporary: _temporaryBikeId != null,
    );
    if ((sessionState is SessionReady || sessionState is SessionDegraded) &&
        !_readyRecorded) {
      _readyRecorded = true;
      unawaited(
        bikeRepository
            .markConnected(bike.bike.deviceId)
            .catchError((Object _) {}),
      );
    }
  }

  SavedBike _requireSavedBike(String deviceId) {
    final bike = _bikes.peek().where(
      (saved) => saved.bike.deviceId == deviceId,
    );
    if (bike.isEmpty) {
      throw BikeNotFoundException(deviceId);
    }
    return bike.single;
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      _state.value = ActiveBikeCoordinatorFailure(error.toString());
    }
  }

  void _scheduleRecompute() {
    unawaited(_recompute().catchError((Object _, StackTrace _) {}));
  }
}
