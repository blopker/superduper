import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/platform/background_sync.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../support/fake_bike_transport.dart';

void main() {
  late AppDatabase database;
  late BikeRepository bikes;
  late SettingsRepository settings;
  late FakeBikeTransport transport;
  late ActiveBikeCoordinator activeBike;
  late _FakeBackgroundSyncPlatform platform;
  late BackgroundSyncCoordinator coordinator;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    transport = FakeBikeTransport();
    activeBike = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: FakeBluetoothPermissionGateway(),
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

      expect(platform.configuredSerials, ['00112233aabbccdd']);
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
    expect(platform.configuredSerials, isEmpty);
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
    await activeBike.pauseForDiscovery();

    final result = await platform.handler!(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: '00112233aabbccdd',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.skippedBusy);
    expect(activeBike.isDiscoveryPaused, isTrue);
  });
}

final class _FakeBackgroundSyncPlatform
    implements BackgroundSyncPlatformGateway {
  final List<String> configuredSerials = [];
  final Completer<void> cancelled = Completer<void>();
  int cancelCount = 0;
  BackgroundWakeHandler? handler;
  Error? configureError;

  @override
  Future<void> cancel() async {
    cancelCount++;
    if (!cancelled.isCompleted) {
      cancelled.complete();
    }
  }

  @override
  Future<void> configure({required String moduleSerial}) async {
    if (configureError case final error?) {
      throw error;
    }
    configuredSerials.add(moduleSerial);
  }

  @override
  void setWakeHandler(BackgroundWakeHandler? handler) {
    this.handler = handler;
  }
}
