import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

const backgroundSyncChannelName = 'io.kbl.superduper/background_sync';
const backgroundSyncWorkerChannelName =
    'io.kbl.superduper/background_sync_worker';

typedef BackgroundWakeHandler = Future<BackgroundSyncResult> Function(
  BackgroundSyncRequest request,
);

abstract interface class BackgroundSyncPlatformGateway {
  Future<void> configure({required String moduleSerial});
  Future<void> cancel();
  void setWakeHandler(BackgroundWakeHandler? handler);
}

final class NoopBackgroundSyncPlatformGateway
    implements BackgroundSyncPlatformGateway {
  const NoopBackgroundSyncPlatformGateway();

  @override
  Future<void> cancel() async {}

  @override
  Future<void> configure({required String moduleSerial}) async {}

  @override
  void setWakeHandler(BackgroundWakeHandler? handler) {}
}

final class SystemBackgroundSyncPlatformGateway
    implements BackgroundSyncPlatformGateway {
  SystemBackgroundSyncPlatformGateway({
    this.channel = const MethodChannel(backgroundSyncChannelName),
  });

  final MethodChannel channel;
  BackgroundWakeHandler? _handler;

  bool get _isSupported => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> configure({required String moduleSerial}) async {
    if (!_isSupported) {
      return;
    }
    try {
      await channel.invokeMethod<void>('configure', {
        'moduleSerial': moduleSerial,
      });
    } on MissingPluginException {
      // Unit tests and non-Android embedders do not install the Android host.
    }
  }

  @override
  Future<void> cancel() async {
    if (_isSupported) {
      try {
        await channel.invokeMethod<void>('cancel');
      } on MissingPluginException {
        // Unit tests and non-Android embedders do not install the Android host.
      }
    }
  }

  @override
  void setWakeHandler(BackgroundWakeHandler? handler) {
    _handler = handler;
    channel.setMethodCallHandler(handler == null ? null : _handleMethod);
  }

  Future<Object?> _handleMethod(MethodCall call) async {
    if (call.method != 'run') {
      throw MissingPluginException('Unknown method ${call.method}.');
    }
    final arguments = Map<Object?, Object?>.from(call.arguments as Map);
    final request = BackgroundSyncRequest(
      deviceId: arguments['deviceId']! as String,
      moduleSerial: arguments['moduleSerial']! as String,
    );
    final handler = _handler;
    if (handler == null) {
      return const BackgroundSyncResult(
        outcome: BackgroundSyncOutcome.failed,
        detail: 'The background synchronization handler is unavailable.',
      ).toJson();
    }
    return (await handler(request)).toJson();
  }
}

final class BackgroundSyncCoordinator {
  BackgroundSyncCoordinator({
    required this.bikeRepository,
    required this.settingsRepository,
    required this.activeBikeCoordinator,
    required this.synchronizer,
    required this.platform,
  });

  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final BackgroundBikeSynchronizer synchronizer;
  final BackgroundSyncPlatformGateway platform;

  StreamSubscription<List<SavedBike>>? _bikesSubscription;
  StreamSubscription<AppPreferences>? _settingsSubscription;
  final Completer<void> _disposeSignal = Completer<void>();
  List<SavedBike>? _bikes;
  AppPreferences? _settings;
  Future<void>? _refreshFuture;
  String? _configuredSerial;
  var _refreshRequested = false;
  var _configurationKnown = false;
  var _started = false;
  var _disposed = false;

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    platform.setWakeHandler(_handleWake);
    final bikesReady = Completer<void>();
    final settingsReady = Completer<void>();
    _bikesSubscription = bikeRepository.watchBikes().listen((bikes) {
      _bikes = bikes;
      if (!bikesReady.isCompleted) {
        bikesReady.complete();
      }
      unawaited(_scheduleRefresh().catchError((Object _) {}));
    });
    _settingsSubscription = settingsRepository.watch().listen((settings) {
      _settings = settings;
      if (!settingsReady.isCompleted) {
        settingsReady.complete();
      }
      unawaited(_scheduleRefresh().catchError((Object _) {}));
    });
    await Future.any([
      Future.wait([bikesReady.future, settingsReady.future]),
      _disposeSignal.future,
    ]);
    if (_disposed) {
      return;
    }
    await _scheduleRefresh();
  }

  Future<BackgroundSyncResult> _handleWake(
    BackgroundSyncRequest request,
  ) async {
    final acquired = await activeBikeCoordinator
        .pauseForBackgroundSynchronization();
    if (!acquired) {
      return const BackgroundSyncResult(
        outcome: BackgroundSyncOutcome.skippedBusy,
      );
    }
    try {
      return await synchronizer.synchronize(request);
    } finally {
      await activeBikeCoordinator.resumeAfterBackgroundSynchronization();
    }
  }

  Future<void> setAutomaticSetup(
    String deviceId, {
    required bool enabled,
  }) async {
    if (enabled) {
      final settings = await settingsRepository.get();
      final matches = (await bikeRepository.getBikes()).where(
        (saved) =>
            saved.bike.deviceId == deviceId &&
            settings.activeBikeId == deviceId,
      );
      if (matches.isEmpty || matches.single.bike.moduleSerial == null) {
        throw StateError(
          'Background Sync requires an active bike with a module serial.',
        );
      }
      final serial = matches.single.bike.moduleSerial!;
      await platform.configure(moduleSerial: serial);
      _configuredSerial = serial;
      _configurationKnown = true;
      try {
        await bikeRepository.setBackgroundPreference(
          deviceId,
          requested: true,
          consentVersion: backgroundSyncConsentVersion,
        );
      } on Object {
        _configuredSerial = null;
        await platform.cancel();
        rethrow;
      }
    } else {
      await bikeRepository.setBackgroundPreference(
        deviceId,
        requested: false,
        consentVersion: backgroundSyncConsentVersion,
      );
      _configuredSerial = null;
      _configurationKnown = true;
      await platform.cancel();
    }
    _bikes = await bikeRepository.getBikes();
    _settings = await settingsRepository.get();
  }

  Future<void> _scheduleRefresh() {
    _refreshRequested = true;
    if (_refreshFuture case final pending?) {
      return pending;
    }
    late final Future<void> pending;
    pending = _drainRefreshes();
    _refreshFuture = pending;
    unawaited(
      pending.then<void>(
        (_) {
          if (identical(_refreshFuture, pending)) {
            _refreshFuture = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_refreshFuture, pending)) {
            _refreshFuture = null;
          }
        },
      ),
    );
    return pending;
  }

  Future<void> _drainRefreshes() async {
    while (_refreshRequested && !_disposed) {
      _refreshRequested = false;
      await _refreshOnce();
    }
  }

  Future<void> _refreshOnce() async {
    if (_disposed || _bikes == null || _settings == null) {
      return;
    }
    final activeId = _settings!.activeBikeId;
    final candidates = _bikes!.where(
      (saved) => saved.bike.deviceId == activeId,
    );
    final active = candidates.isEmpty ? null : candidates.single;
    final serial = active?.bike.moduleSerial;
    final shouldEnable =
        active != null &&
        active.backgroundPreference.requested &&
        active.backgroundPreference.consentVersion >=
            backgroundSyncConsentVersion &&
        serial != null;
    final nextSerial = shouldEnable ? serial : null;
    if (_configurationKnown && _configuredSerial == nextSerial) {
      return;
    }
    if (nextSerial == null) {
      await platform.cancel();
    } else {
      await platform.configure(moduleSerial: nextSerial);
    }
    _configuredSerial = nextSerial;
    _configurationKnown = true;
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (!_disposeSignal.isCompleted) {
      _disposeSignal.complete();
    }
    platform.setWakeHandler(null);
    await _bikesSubscription?.cancel();
    await _settingsSubscription?.cancel();
  }
}
