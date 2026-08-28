import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/ble/bike_identity_resolver.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/platform/background_sync.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../support/fake_bike_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late BikeRepository bikes;
  late SettingsRepository settings;
  late FakeBikeTransport transport;
  late FakeBluetoothPermissionGateway permissions;
  late ActiveBikeCoordinator activeBike;
  late _FakeBackgroundSyncPlatform platform;
  late BackgroundSyncCoordinator coordinator;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    transport = FakeBikeTransport();
    permissions = FakeBluetoothPermissionGateway();
    activeBike = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: permissions,
      buildSession: (saved) => BikeSession(
        connection: transport.openConnection(saved.bike.deviceId),
        preferredRegion: saved.bike.region,
        preferences: saved.preferences,
        protocol: saved.bike.protocol,
      ),
    );
    platform = _FakeBackgroundSyncPlatform();
    coordinator = BackgroundSyncCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      activeBikeCoordinator: activeBike,
      synchronizer: BackgroundBikeSynchronizer(
        bikeRepository: bikes,
        settingsRepository: settings,
        transport: transport,
      ),
      transport: transport,
      permissions: permissions,
      identityResolver: BikeIdentityResolver(
        bikeRepository: bikes,
        transport: transport,
      ),
      platform: platform,
    );
    await settings.initialize();
  });

  tearDown(() async {
    await coordinator.dispose();
    await activeBike.dispose();
    await transport.dispose();
    await database.close();
  });

  test(
    'registers only the active opted-in bike and cancels on opt-out',
    () async {
      await bikes.addBike(
        deviceId: 'bike',
        moduleSerial: '00112233aabbccdd',
        backgroundPreference: const BackgroundPreference(
          requested: true,
          consentVersion: backgroundSyncConsentVersion,
        ),
      );

      await coordinator.start();

      expect(platform.configurations, [
        const _Configuration(
          deviceId: 'bike',
          moduleSerial: '00112233aabbccdd',
          requestAssociation: false,
        ),
      ]);
      expect(platform.handler, isNotNull);

      await bikes.setBackgroundPreference(
        'bike',
        requested: false,
        consentVersion: backgroundSyncConsentVersion,
      );
      await platform.cancelled.future;

      expect(platform.cancelCount, 1);
    },
  );

  test('cancels stale native work on the first disabled refresh', () async {
    await coordinator.start();

    expect(platform.cancelCount, 1);
    expect(platform.configurations, isEmpty);
  });

  test('does not repeat native teardown when disabled and resumed', () async {
    await coordinator.start();

    await coordinator.reconcileNativeRegistration();

    expect(platform.cancelCount, 1);
  });

  test('does not fail startup when native reconciliation throws', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    platform.configureError = StateError('companion service unavailable');

    await coordinator.start();

    expect(
      (await bikes.getBikes()).single.backgroundPreference.requested,
      isTrue,
    );
  });

  test('turns off consent when the native association is missing', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    platform.configureResult = BackgroundSyncRegistration.needsAssociation;

    await coordinator.start();

    expect(
      (await bikes.getBikes()).single.backgroundPreference.requested,
      isFalse,
    );
    expect(platform.cancelCount, 1);
  });

  test('rechecks the native association after the app resumes', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    await coordinator.start();
    platform.configureResult = BackgroundSyncRegistration.needsAssociation;

    await coordinator.reconcileNativeRegistration();

    expect(
      (await bikes.getBikes()).single.backgroundPreference.requested,
      isFalse,
    );
  });

  test('turns off Background Sync when its bike stops being active', () async {
    await bikes.addBike(
      deviceId: 'first',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    await bikes.addBike(
      deviceId: 'second',
      moduleSerial: 'ffeeddccbbaa2211',
    );
    await coordinator.start();

    await settings.makeBikeActive('second');
    await _waitUntil(
      () async => !(await bikes.getBikes())
          .singleWhere((saved) => saved.bike.deviceId == 'first')
          .backgroundPreference
          .requested,
    );

    expect(platform.cancelCount, 1);
  });

  test('does not opt in when native registration fails', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
    );
    await coordinator.start();
    platform.configureError = StateError('scanner unavailable');

    await expectLater(
      coordinator.setAutomaticSetup('bike', enabled: true),
      throwsStateError,
    );

    final saved = (await bikes.getBikes()).single;
    expect(saved.backgroundPreference.requested, isFalse);
    expect(saved.backgroundPreference.consentVersion, 0);
  });

  test('discovers and saves a missing module serial while enabling', () async {
    await bikes.addBike(deviceId: 'bike');
    await coordinator.start();
    transport.replayedScanResults = const [
      DiscoveredBike(
        deviceId: 'BIKE',
        name: 'SUPER73',
        rssi: -20,
        moduleSerial: '00112233aabbccdd',
      ),
    ];

    await coordinator.setAutomaticSetup('bike', enabled: true);

    final saved = (await bikes.getBikes()).single;
    expect(saved.bike.moduleSerial, '00112233aabbccdd');
    expect(saved.backgroundPreference.requested, isTrue);
    expect(platform.configurations, [
      const _Configuration(
        deviceId: 'bike',
        moduleSerial: '00112233aabbccdd',
        requestAssociation: true,
      ),
    ]);
    expect(transport.scanStarts, 1);
    expect(transport.scanStops, 1);
  });

  test(
    'pauses the foreground connection during companion association',
    () async {
      await bikes.addBike(
        deviceId: 'bike',
        moduleSerial: '00112233aabbccdd',
      );
      await coordinator.start();
      platform.onConfigure = () async {
        expect(await activeBike.acquireDiscoveryPause(), isNull);
      };

      await coordinator.setAutomaticSetup('bike', enabled: true);

      final releasedPause = await activeBike.acquireDiscoveryPause();
      expect(releasedPause, isNotNull);
      await releasedPause!.release();
      expect(platform.configurations.single.requestAssociation, isTrue);
    },
  );

  test('does not steal another Bluetooth operation pause', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
    );
    await coordinator.start();
    final pause = await activeBike.acquireDiscoveryPause();
    expect(pause, isNotNull);
    final cancelCount = platform.cancelCount;

    await expectLater(
      coordinator.setAutomaticSetup('bike', enabled: true),
      throwsA(isA<BackgroundSyncConfigurationFailure>()),
    );

    expect(await activeBike.acquireDiscoveryPause(), isNull);
    expect(platform.configurations, isEmpty);
    expect(platform.cancelCount, cancelCount);
    await pause!.release();
  });

  test('stale scan consent is cancelled instead of restored', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: 1,
      ),
    );

    await coordinator.start();

    expect(platform.cancelCount, 1);
    expect(platform.configurations, isEmpty);
  });

  test('does not release an exclusive operation it did not acquire', () async {
    await bikes.addBike(
      deviceId: 'bike',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    await coordinator.start();
    final pause = await activeBike.acquireDiscoveryPause();
    expect(pause, isNotNull);

    final result = await platform.handler!(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: '00112233aabbccdd',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.skippedBusy);
    expect(await activeBike.acquireDiscoveryPause(), isNull);
    await pause!.release();
  });

  test('preserves the native companion association error', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel(backgroundSyncChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'configure');
          expect(call.arguments, {
            'deviceId': 'AA:BB:CC:DD:EE:FF',
            'moduleSerial': '00112233aabbccdd',
            'requestAssociation': true,
          });
          throw PlatformException(
            code: 'background_sync',
            message: 'Android could not associate this bike',
          );
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      SystemBackgroundSyncPlatformGateway().configure(
        deviceId: 'AA:BB:CC:DD:EE:FF',
        moduleSerial: '00112233aabbccdd',
        requestAssociation: true,
      ),
      throwsA(
        isA<BackgroundSyncConfigurationFailure>().having(
          (error) => error.message,
          'message',
          'Android could not associate this bike',
        ),
      ),
    );
  });

  test('reports a missing native companion association as state', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel(backgroundSyncChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final registration = await SystemBackgroundSyncPlatformGateway().configure(
      deviceId: 'AA:BB:CC:DD:EE:FF',
      moduleSerial: '00112233aabbccdd',
      requestAssociation: false,
    );

    expect(registration, BackgroundSyncRegistration.needsAssociation);
  });

  test(
    'turns a stalled native reconciliation into a visible failure',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel(backgroundSyncChannelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) => Completer<void>().future,
          );
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await expectLater(
        SystemBackgroundSyncPlatformGateway(
          configurationTimeout: Duration.zero,
        ).configure(
          deviceId: 'AA:BB:CC:DD:EE:FF',
          moduleSerial: '00112233aabbccdd',
          requestAssociation: false,
        ),
        throwsA(
          isA<BackgroundSyncConfigurationFailure>().having(
            (error) => error.message,
            'message',
            contains('did not finish associating'),
          ),
        ),
      );
    },
  );

  test(
    'does not time out the interactive Android association chooser',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel(backgroundSyncChannelName);
      final associated = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) => associated.future);
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final configuration =
          SystemBackgroundSyncPlatformGateway(
            configurationTimeout: Duration.zero,
          ).configure(
            deviceId: 'AA:BB:CC:DD:EE:FF',
            moduleSerial: '00112233aabbccdd',
            requestAssociation: true,
          );
      await Future<void>.delayed(Duration.zero);

      associated.complete(true);

      expect(
        await configuration,
        BackgroundSyncRegistration.configured,
      );
    },
  );
}

final class _Configuration {
  const _Configuration({
    required this.deviceId,
    required this.moduleSerial,
    required this.requestAssociation,
  });

  final String deviceId;
  final String moduleSerial;
  final bool requestAssociation;

  @override
  bool operator ==(Object other) =>
      other is _Configuration &&
      other.deviceId == deviceId &&
      other.moduleSerial == moduleSerial &&
      other.requestAssociation == requestAssociation;

  @override
  int get hashCode => Object.hash(deviceId, moduleSerial, requestAssociation);
}

final class _FakeBackgroundSyncPlatform
    implements BackgroundSyncPlatformGateway {
  final List<_Configuration> configurations = [];
  final Completer<void> cancelled = Completer<void>();
  int cancelCount = 0;
  BackgroundWakeHandler? handler;
  Error? configureError;
  BackgroundSyncRegistration configureResult =
      BackgroundSyncRegistration.configured;
  FutureOr<void> Function()? onConfigure;

  @override
  Future<void> cancel() async {
    cancelCount++;
    if (!cancelled.isCompleted) {
      cancelled.complete();
    }
  }

  @override
  Future<BackgroundSyncRegistration> configure({
    required String deviceId,
    required String moduleSerial,
    required bool requestAssociation,
  }) async {
    if (configureError case final error?) {
      throw error;
    }
    await onConfigure?.call();
    configurations.add(
      _Configuration(
        deviceId: deviceId,
        moduleSerial: moduleSerial,
        requestAssociation: requestAssociation,
      ),
    );
    return configureResult;
  }

  @override
  void setWakeHandler(BackgroundWakeHandler? handler) {
    this.handler = handler;
  }
}

Future<void> _waitUntil(Future<bool> Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (await condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not reached before the test timeout.');
}
