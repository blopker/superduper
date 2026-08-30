import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_identity_resolver.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/exclusive_bluetooth_operation.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

const backgroundSyncChannelName = 'io.kbl.superduper/background_sync';

final class BackgroundSyncConfigurationFailure implements Exception {
  const BackgroundSyncConfigurationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class BackgroundSyncPlatformGateway {
  Future<BackgroundSyncRegistration> configure({
    required String deviceId,
    required bool requestAssociation,
  });
  Future<void> setConnectionPaused(bool paused);
  Future<void> cancel();
}

enum BackgroundSyncRegistration { configured, needsAssociation }

final class NoopBackgroundSyncPlatformGateway
    implements BackgroundSyncPlatformGateway {
  const NoopBackgroundSyncPlatformGateway();

  @override
  Future<void> cancel() async {}

  @override
  Future<void> setConnectionPaused(bool paused) async {}

  @override
  Future<BackgroundSyncRegistration> configure({
    required String deviceId,
    required bool requestAssociation,
  }) async => BackgroundSyncRegistration.configured;
}

final class SystemBackgroundSyncPlatformGateway
    implements BackgroundSyncPlatformGateway {
  SystemBackgroundSyncPlatformGateway({
    this.channel = const MethodChannel(backgroundSyncChannelName),
    this.configurationTimeout = const Duration(minutes: 2),
  });

  final MethodChannel channel;
  final Duration configurationTimeout;

  bool get _isSupported => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<BackgroundSyncRegistration> configure({
    required String deviceId,
    required bool requestAssociation,
  }) async {
    if (!_isSupported) {
      return BackgroundSyncRegistration.configured;
    }
    try {
      final pending = channel.invokeMethod<bool>('configure', {
        'deviceId': deviceId,
        'requestAssociation': requestAssociation,
      });
      final associated = requestAssociation
          ? await pending
          : await pending.timeout(configurationTimeout);
      return associated == false
          ? BackgroundSyncRegistration.needsAssociation
          : BackgroundSyncRegistration.configured;
    } on MissingPluginException {
      // Unit tests and non-Android embedders do not install the Android host.
      return BackgroundSyncRegistration.configured;
    } on PlatformException catch (error) {
      throw BackgroundSyncConfigurationFailure(
        error.message ?? 'Android could not associate this bike.',
      );
    } on TimeoutException {
      throw const BackgroundSyncConfigurationFailure(
        'Android did not finish associating this bike. Keep the bike on and try again.',
      );
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
  Future<void> setConnectionPaused(bool paused) async {
    if (_isSupported) {
      try {
        await channel.invokeMethod<void>('setConnectionPaused', {
          'paused': paused,
        });
      } on MissingPluginException {
        // Unit tests and non-Android embedders do not install the Android host.
      } on PlatformException catch (error) {
        throw BackgroundSyncConfigurationFailure(
          error.message ?? 'Android could not update the connection pause.',
        );
      }
    }
  }
}

final class BackgroundSyncCoordinator {
  BackgroundSyncCoordinator({
    required this.bikeRepository,
    required this.settingsRepository,
    required this.activeBikeCoordinator,
    required this.transport,
    required this.permissions,
    required this.identityResolver,
    required this.platform,
    this.moduleSerialDiscoveryTimeout = const Duration(seconds: 15),
  });

  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final BikeIdentityResolver identityResolver;
  final BackgroundSyncPlatformGateway platform;
  final Duration moduleSerialDiscoveryTimeout;
  late final ExclusiveBluetoothOperation _exclusiveBluetooth =
      ExclusiveBluetoothOperation(
        transport: transport,
        permissions: permissions,
        activeBikeCoordinator: activeBikeCoordinator,
      );

  StreamSubscription<List<SavedBike>>? _bikesSubscription;
  StreamSubscription<AppPreferences>? _settingsSubscription;
  final Completer<void> _disposeSignal = Completer<void>();
  List<SavedBike>? _bikes;
  AppPreferences? _settings;
  Future<void>? _refreshFuture;
  ({String deviceId, String moduleSerial})? _configured;
  var _refreshRequested = false;
  var _configurationKnown = false;
  var _started = false;
  var _disposed = false;

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
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
    try {
      await _scheduleRefresh();
    } on Object {
      // Background Sync is optional and must not prevent the app from starting.
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
      if (matches.isEmpty) {
        throw StateError(
          'Turn on Auto connect for this bike before enabling Background Sync.',
        );
      }
      late final ExclusiveBluetoothAccess access;
      try {
        access = await _exclusiveBluetooth.acquire(
          requestPermission: true,
          adapterTimeout: const Duration(seconds: 3),
        );
      } on ExclusiveBluetoothOperationBusy {
        throw const BackgroundSyncConfigurationFailure(
          ExclusiveBluetoothOperationBusy.message,
        );
      } on Object {
        await _exclusiveBluetooth.release(stopScan: false);
        rethrow;
      }
      var preferenceEnabled = false;
      try {
        _requireBluetoothAccess(access);
        final serial = await _moduleSerialFor(matches.single);
        final registration = await platform.configure(
          deviceId: matches.single.bike.deviceId,
          requestAssociation: true,
        );
        if (registration != BackgroundSyncRegistration.configured) {
          throw const BackgroundSyncConfigurationFailure(
            'Android did not save the bike association. Try enabling Background Sync again.',
          );
        }
        await bikeRepository.setBackgroundPreference(
          deviceId,
          requested: true,
          consentVersion: backgroundSyncConsentVersion,
        );
        preferenceEnabled = true;
        final refreshedRegistration = await platform.configure(
          deviceId: matches.single.bike.deviceId,
          requestAssociation: false,
        );
        if (refreshedRegistration != BackgroundSyncRegistration.configured) {
          throw const BackgroundSyncConfigurationFailure(
            'Android did not retain the bike association. Try enabling Background Sync again.',
          );
        }
        _configured = (
          deviceId: matches.single.bike.deviceId,
          moduleSerial: serial,
        );
        _configurationKnown = true;
      } on Object {
        if (preferenceEnabled) {
          await bikeRepository.setBackgroundPreference(
            deviceId,
            requested: false,
            consentVersion: backgroundSyncConsentVersion,
          );
        }
        _configured = null;
        await platform.cancel();
        rethrow;
      } finally {
        await _exclusiveBluetooth.release(stopScan: false);
      }
    } else {
      await bikeRepository.setBackgroundPreference(
        deviceId,
        requested: false,
        consentVersion: backgroundSyncConsentVersion,
      );
      _configured = null;
      _configurationKnown = true;
      await platform.cancel();
    }
    _bikes = await bikeRepository.getBikes();
    _settings = await settingsRepository.get();
  }

  Future<void> reconcileNativeRegistration() {
    if (!_started ||
        _disposed ||
        _exclusiveBluetooth.isAcquired ||
        _configurationKnown && _configured == null) {
      return Future.value();
    }
    _configurationKnown = false;
    return _scheduleRefresh();
  }

  Future<String> _moduleSerialFor(SavedBike saved) async {
    if (saved.bike.moduleSerial case final serial?) {
      return serial;
    }
    try {
      final resolved = await identityResolver.resolve(
        saved,
        timeout: moduleSerialDiscoveryTimeout,
      );
      return resolved.bike.moduleSerial!;
    } on TimeoutException {
      throw const BackgroundSyncConfigurationFailure(
        'Turn on this bike and keep it nearby, then try enabling Background Sync again.',
      );
    } on BackgroundSyncConfigurationFailure {
      rethrow;
    } on Object {
      throw const BackgroundSyncConfigurationFailure(
        'Android could not identify this bike. Turn it on, keep it nearby, and try again.',
      );
    }
  }

  void _requireBluetoothAccess(ExclusiveBluetoothAccess access) {
    if (access.permission != BluetoothPermissionState.granted) {
      throw const BackgroundSyncConfigurationFailure(
        'Bluetooth permission is required to associate this bike for Background Sync.',
      );
    }
    if (access.scanPrerequisite != BluetoothScanPrerequisite.ready) {
      throw const BackgroundSyncConfigurationFailure(
        'Bluetooth scanning is disabled in system settings.',
      );
    }
    if (access.adapter != BikeAdapterState.on) {
      throw const BackgroundSyncConfigurationFailure(
        'Turn Bluetooth on to associate this bike for Background Sync.',
      );
    }
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
    final inactiveRequests = _bikes!.where(
      (saved) =>
          saved.bike.deviceId != activeId &&
          saved.backgroundPreference.requested,
    );
    if (inactiveRequests.isNotEmpty) {
      for (final saved in inactiveRequests.toList(growable: false)) {
        await bikeRepository.setBackgroundPreference(
          saved.bike.deviceId,
          requested: false,
          consentVersion: backgroundSyncConsentVersion,
        );
      }
      _bikes = await bikeRepository.getBikes();
    }
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
    final next = shouldEnable
        ? (deviceId: active.bike.deviceId, moduleSerial: serial)
        : null;
    if (_configurationKnown && _configured == next) {
      return;
    }
    if (next == null) {
      await platform.cancel();
    } else {
      final registration = await platform.configure(
        deviceId: next.deviceId,
        requestAssociation: false,
      );
      if (registration == BackgroundSyncRegistration.needsAssociation) {
        await bikeRepository.setBackgroundPreference(
          next.deviceId,
          requested: false,
          consentVersion: backgroundSyncConsentVersion,
        );
        _bikes = await bikeRepository.getBikes();
        await platform.cancel();
        _configured = null;
        _configurationKnown = true;
        return;
      }
    }
    _configured = next;
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
    await _bikesSubscription?.cancel();
    await _settingsSubscription?.cancel();
  }
}
