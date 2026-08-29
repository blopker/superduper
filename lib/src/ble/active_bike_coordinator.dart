import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/bike_identity_resolver.dart';
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
    required this.session,
    required this.sessionState,
    required this.isTemporary,
  });

  final SavedBike bike;
  final BikeSession session;
  final BikeSessionState sessionState;
  final bool isTemporary;
}

final class ActiveBikeCoordinatorFailure extends ActiveBikeState {
  const ActiveBikeCoordinatorFailure(this.error);

  final Object error;
}

typedef BikeSessionBuilder = BikeSession Function(SavedBike bike);

final class ActiveBikeDiscoveryPause {
  ActiveBikeDiscoveryPause._(this._coordinator);

  ActiveBikeCoordinator? _coordinator;

  Future<void> release({SavedBike? temporarilySelect}) async {
    final coordinator = _coordinator;
    if (coordinator == null) {
      return;
    }
    _coordinator = null;
    await coordinator._releaseDiscoveryPause(
      this,
      temporarilySelect: temporarilySelect,
    );
  }

  void _detach() {
    _coordinator = null;
  }
}

final class _CoordinatorInputs {
  const _CoordinatorInputs({this.bikes, this.settings});

  final List<SavedBike>? bikes;
  final AppPreferences? settings;

  bool get isReady => bikes != null && settings != null;
}

final class ActiveBikeCoordinator {
  ActiveBikeCoordinator({
    required this.bikeRepository,
    required this.settingsRepository,
    required this.permissions,
    required this.buildSession,
    this.identityResolver,
  });

  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final BluetoothPermissionGateway permissions;
  final BikeSessionBuilder buildSession;
  final BikeIdentityResolver? identityResolver;
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
  final Completer<void> _disposeSignal = Completer<void>();

  StreamSubscription<List<SavedBike>>? _bikesSubscription;
  StreamSubscription<AppPreferences>? _settingsSubscription;
  EffectCleanup? _sessionStateCleanup;
  Future<BluetoothPermissionState>? _permissionCheck;
  Future<void>? _reconcileFuture;
  _CoordinatorInputs _inputs = const _CoordinatorInputs();
  BikeSession? _session;
  SavedBike? _currentBike;
  String? _temporaryBikeId;
  final Set<String> _forgettingBikeIds = {};
  var _reconcileRequested = false;
  var _reconcileForce = false;
  var _reconcileMayRequestPermission = false;
  var _switchGeneration = 0;
  var _started = false;
  var _disposed = false;
  ActiveBikeDiscoveryPause? _discoveryPause;
  var _foreground = true;
  var _readyRecorded = false;

  bool get _discoveryPaused => _discoveryPause != null;

  ReadonlySignal<ActiveBikeState> get state => _state.readonly();
  ReadonlySignal<List<SavedBike>> get bikes => _bikes.readonly();
  ReadonlySignal<String?> get activeBikeId => _activeBikeId.readonly();
  ReadonlySignal<bool> get migrationNoticePending =>
      _migrationNoticePending.readonly();

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
        _acceptBikes(bikes);
        if (!bikesReady.isCompleted) {
          bikesReady.complete();
        }
        if (initialized) {
          _scheduleReconcile();
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
        _acceptSettings(settings);
        if (!settingsReady.isCompleted) {
          settingsReady.complete();
        }
        if (initialized) {
          _scheduleReconcile();
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
    _scheduleReconcile();
  }

  Future<void> selectTemporarily(String deviceId) async {
    if (!_bikes.peek().any((saved) => saved.bike.deviceId == deviceId)) {
      _acceptBikes(await bikeRepository.getBikes());
      if (_disposed) {
        return;
      }
    }
    _requireSavedBike(deviceId);
    if (_temporaryBikeId == deviceId && _session?.deviceId == deviceId) {
      return;
    }
    _temporaryBikeId = deviceId;
    await _reconcile(force: true);
  }

  Future<void> returnToActiveBike() async {
    if (_temporaryBikeId == null) {
      return;
    }
    _temporaryBikeId = null;
    await _reconcile(force: true);
  }

  Future<void> makeBikeActive(String deviceId) async {
    await settingsRepository.makeBikeActive(deviceId);
    if (_disposed) {
      return;
    }
    _acceptSettings(await settingsRepository.get());
    if (_disposed) {
      return;
    }
    _temporaryBikeId = null;
    await _reconcile(force: _session?.deviceId != deviceId);
  }

  Future<void> forgetBike(String deviceId) async {
    if (_disposed || !_forgettingBikeIds.add(deviceId)) {
      return;
    }
    try {
      _switchGeneration++;
      _acceptBikes(
        _bikes
            .peek()
            .where(
              (saved) => saved.bike.deviceId != deviceId,
            )
            .toList(),
      );
      if (_temporaryBikeId == deviceId) {
        _temporaryBikeId = null;
      }
      if (_session?.deviceId == deviceId) {
        await _clearSession();
      }
      await bikeRepository.forgetBike(deviceId);
      if (_disposed) {
        return;
      }
      _acceptBikes(await bikeRepository.getBikes());
      if (_disposed) {
        return;
      }
      _acceptSettings(await settingsRepository.get());
      if (_disposed) {
        return;
      }
      await _reconcile();
    } finally {
      _forgettingBikeIds.remove(deviceId);
    }
  }

  Future<void> retry() async {
    final current = _session;
    if (current != null) {
      if (current.state.peek() case SessionReady() || SessionSynchronizing()) {
        return;
      }
      await current.retry();
      return;
    }
    await _reconcile(force: true);
  }

  Future<void> disconnectManually() async {
    await _session?.disconnect();
  }

  Future<void> dismissMigrationNotice() {
    return settingsRepository.dismissMigrationNotice();
  }

  Future<ActiveBikeDiscoveryPause?> acquireDiscoveryPause() async {
    if (_disposed || _discoveryPause != null) {
      return null;
    }
    final pause = ActiveBikeDiscoveryPause._(this);
    _discoveryPause = pause;
    _switchGeneration++;
    try {
      await _clearSession();
      return pause;
    } on Object {
      if (identical(_discoveryPause, pause)) {
        _discoveryPause = null;
      }
      pause._detach();
      rethrow;
    }
  }

  Future<void> _releaseDiscoveryPause(
    ActiveBikeDiscoveryPause pause, {
    SavedBike? temporarilySelect,
  }) async {
    if (!identical(_discoveryPause, pause)) {
      return;
    }
    try {
      if (temporarilySelect != null) {
        _acceptBikes(await bikeRepository.getBikes());
        if (_disposed) {
          return;
        }
        _temporaryBikeId = temporarilySelect.bike.deviceId;
      }
    } finally {
      if (identical(_discoveryPause, pause)) {
        _discoveryPause = null;
      }
    }
    if (_foreground) {
      await _reconcile(force: true);
    }
  }

  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    if (_discoveryPaused) {
      return;
    }
    if (foreground) {
      final current = _session;
      if (current == null) {
        await _reconcile(force: true, requestPermission: false);
      } else {
        await current.resumeFromBackground();
      }
    } else {
      await _session?.pauseForBackground();
    }
  }

  Future<bool> openPermissionSettings() => permissions.openSettings();

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _discoveryPause?._detach();
    _discoveryPause = null;
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
  }

  Future<void> _reconcile({
    bool force = false,
    bool requestPermission = true,
  }) {
    if (_disposed) {
      return Future.value();
    }
    _reconcileRequested = true;
    _reconcileForce = _reconcileForce || force;
    _reconcileMayRequestPermission =
        _reconcileMayRequestPermission || requestPermission;
    if (_reconcileFuture case final pending?) {
      return pending;
    }

    late final Future<void> pending;
    pending = _drainReconciliation();
    _reconcileFuture = pending;
    unawaited(
      pending.whenComplete(() {
        if (identical(_reconcileFuture, pending)) {
          _reconcileFuture = null;
        }
      }),
    );
    return pending;
  }

  Future<void> _drainReconciliation() async {
    while (_reconcileRequested && !_disposed) {
      final force = _reconcileForce;
      final requestPermission = _reconcileMayRequestPermission;
      _reconcileRequested = false;
      _reconcileForce = false;
      _reconcileMayRequestPermission = false;
      await _recomputeOnce(
        force: force,
        requestPermission: requestPermission,
      );
    }
  }

  Future<void> _recomputeOnce({
    bool force = false,
    bool requestPermission = true,
  }) async {
    final inputs = _inputs;
    if (_disposed || !inputs.isReady || _discoveryPaused || !_foreground) {
      return;
    }
    try {
      final targetId = _temporaryBikeId ?? inputs.settings!.activeBikeId;
      if (targetId == null) {
        await _clearSession();
        if (!_disposed) {
          _state.value = const NoActiveBike();
        }
        return;
      }
      final target = inputs.bikes!.where(
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
      final current = _session;
      if (!force &&
          current?.deviceId == targetId &&
          current?.protocolVersion == bike.bike.protocol) {
        _currentBike = bike;
        current!.updatePreferredRegion(bike.bike.region);
        current.updateSetOnConnect(bike.setOnConnect);
        if (!_disposed &&
            !_discoveryPaused &&
            _session == current &&
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
      _state.value = const ActiveBikeLoading();

      var preparedBike = bike;
      if (bike.bike.moduleSerial == null && identityResolver != null) {
        try {
          preparedBike = await identityResolver!.resolve(bike);
        } on Object {
          // Advertisement metadata improves background behavior but must not
          // prevent the normal foreground connection.
        }
      }
      if (_disposed ||
          _discoveryPaused ||
          !_foreground ||
          generation != _switchGeneration) {
        return;
      }
      final next = buildSession(preparedBike);
      if (_disposed ||
          _discoveryPaused ||
          !_foreground ||
          generation != _switchGeneration) {
        await next.dispose();
        return;
      }
      _readyRecorded = false;
      _currentBike = preparedBike;
      _session = next;
      _sessionStateCleanup = next.state.subscribe((sessionState) {
        if (!_disposed && _session == next) {
          _publishSessionState(sessionState);
        }
      });
      unawaited(
        next.connect().catchError((Object error) {
          if (!_disposed && _session == next) {
            _state.value = ActiveBikeCoordinatorFailure(error);
          }
        }),
      );
    } on Object catch (error) {
      if (!_disposed && !_discoveryPaused && _foreground) {
        _state.value = ActiveBikeCoordinatorFailure(error);
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
    final old = _session;
    _session = null;
    _currentBike = null;
    _readyRecorded = false;
    if (!_disposed) {
      _state.value = const ActiveBikeLoading();
    }
    if (old != null) {
      await old.dispose();
    }
  }

  void _publishSessionState(BikeSessionState sessionState) {
    final bike = _currentBike;
    final session = _session;
    if (bike == null || session == null) {
      return;
    }
    _state.value = ActiveBikeSessionStatus(
      bike: bike,
      session: session,
      sessionState: sessionState,
      isTemporary: _temporaryBikeId != null,
    );
    if (sessionState is SessionReady && !_readyRecorded) {
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
      _state.value = ActiveBikeCoordinatorFailure(error);
    }
  }

  void _acceptBikes(List<SavedBike> bikes) {
    final immutable = List<SavedBike>.unmodifiable(
      bikes.where(
        (saved) => !_forgettingBikeIds.contains(saved.bike.deviceId),
      ),
    );
    _inputs = _CoordinatorInputs(
      bikes: immutable,
      settings: _inputs.settings,
    );
    _bikes.value = immutable;
  }

  void _acceptSettings(AppPreferences settings) {
    _inputs = _CoordinatorInputs(bikes: _inputs.bikes, settings: settings);
    _activeBikeId.value = settings.activeBikeId;
    if (_temporaryBikeId == settings.activeBikeId) {
      _temporaryBikeId = null;
    }
    _migrationNoticePending.value = settings.migrationNoticePending;
  }

  void _scheduleReconcile() {
    unawaited(_reconcile().catchError((Object _, StackTrace _) {}));
  }
}
