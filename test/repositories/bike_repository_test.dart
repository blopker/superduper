import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late BikeRepository repository;
  late SettingsRepository settingsRepository;
  late DateTime now;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 8, 23, 12);
    repository = BikeRepository(database: database, clock: () => now);
    settingsRepository = SettingsRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'the first bike becomes active and later bikes do not replace it',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(deviceId: 'first');
      await repository.addBike(deviceId: 'second');

      final bikes = await repository.getBikes();
      final settings = await settingsRepository.get();

      expect(bikes.map((saved) => saved.bike.deviceId), ['first', 'second']);
      expect(bikes.map((saved) => saved.bike.sortOrder), [0, 1]);
      expect(settings.activeBikeId, 'first');
    },
  );

  test('switching the active bike persists the new selection', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'first');
    await repository.addBike(deviceId: 'second');

    await settingsRepository.makeBikeActive('second');
    final settings = await settingsRepository.get();
    expect(settings.activeBikeId, 'second');
  });

  test('forgetting the active bike promotes the lowest sorted bike', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'first');
    await repository.addBike(deviceId: 'second');
    await repository.addBike(deviceId: 'third');
    await settingsRepository.makeBikeActive('second');

    await repository.forgetBike('second');

    expect((await settingsRepository.get()).activeBikeId, 'first');
    expect(await database.select(database.bikePreferences).get(), hasLength(2));
  });

  test(
    'initialization repairs a missing active bike deterministically',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(deviceId: 'first');
      await repository.addBike(deviceId: 'second');
      await database
          .update(database.appSettings)
          .write(const AppSettingsCompanion(activeBikeId: Value(null)));

      final result = await settingsRepository.initialize();

      expect(result.activeBikeRepaired, isTrue);
      final settings = await settingsRepository.get();
      expect(settings.activeBikeId, 'first');
      expect(settings.migrationNoticePending, isTrue);
    },
  );

  test(
    'Set on connect values are saved independently of a live bike',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(
        deviceId: 'bike',
      );

      await repository.setOnConnect(
        'bike',
        const BikeControlPatch(
          light: true,
          mode: 3,
          assist: 4,
        ),
      );

      final saved = (await repository.getBikes()).single;
      expect(saved.setOnConnect.light, isTrue);
      expect(saved.setOnConnect.mode, 3);
      expect(saved.setOnConnect.assist, 4);
    },
  );

  test('invalid Set on connect values never reach SQLite', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    expect(
      () => repository.setOnConnect(
        'bike',
        const BikeControlPatch(
          mode: 4,
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => repository.setOnConnect(
        'bike',
        const BikeControlPatch(
          assist: -1,
        ),
      ),
      throwsRangeError,
    );
  });

  test('background sync preference records explicit consent', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    await repository.setBackgroundPreference(
      'bike',
      requested: true,
      consentVersion: 1,
    );

    final saved = (await repository.getBikes()).single;
    expect(saved.backgroundPreference.requested, isTrue);
    expect(saved.backgroundPreference.consentVersion, 1);
  });

  test('materializes a V1 background command with nullable controls', () async {
    await settingsRepository.initialize();
    await repository.addBike(
      deviceId: 'AA:BB:CC:DD:EE:FF',
      moduleSerial: '00112233aabbccdd',
      region: BikeRegion.eu,
      setOnConnect: const BikeControlPatch(light: true, mode: 2),
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );

    final plan = await database
        .select(database.backgroundSyncPlans)
        .getSingle();
    final command = await database
        .select(database.backgroundSyncCommands)
        .getSingle();

    expect(plan.deviceId, 'AA:BB:CC:DD:EE:FF');
    expect(plan.planVersion, 2);
    expect(plan.scanManufacturerId, BikeGatt.manufacturerId);
    expect(plan.scanManufacturerData, [0, 17, 34, 51, 170, 187, 204, 221]);
    expect(plan.scanManufacturerMask, List<int>.filled(8, 0xff));
    expect(plan.authenticationServiceUuid, BikeGatt.authenticationService);
    expect(
      plan.authenticationChallengeUuid,
      BikeGatt.authenticationChallenge,
    );
    expect(plan.authenticationResponseUuid, BikeGatt.authenticationResponse);
    expect(plan.authenticationStateUuid, BikeGatt.authenticationState);
    expect(
      plan.authenticationChallengeLength,
      BikeProtocol.defaultAuthenticationKey.length,
    );
    expect(plan.authenticationDigest, 'SHA-1');
    expect(plan.authenticationKey, BikeProtocol.defaultAuthenticationKey);
    expect(plan.authenticatedState, [1]);
    expect(plan.commandServiceUuid, BikeGatt.metricsService);
    expect(plan.commandCharacteristicUuid, BikeGatt.stateRegister);
    expect(command.sequence, 0);
    expect(command.payload, [0, 0xd1, 1, 0xff, 6, 0, 0, 0, 0, 0]);
  });

  test('rebuilds and removes the native background command plan', () async {
    await settingsRepository.initialize();
    await repository.addBike(
      deviceId: 'first',
      moduleSerial: '00112233aabbccdd',
      setOnConnect: const BikeControlPatch(assist: 4),
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    await repository.addBike(
      deviceId: 'second',
      moduleSerial: 'ffeeddccbbaa2211',
      advertisedName: 'S73 FTEX',
      setOnConnect: const BikeControlPatch(mode: 3),
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );

    expect(
      (await database.select(database.backgroundSyncCommands).getSingle())
          .payload,
      [0, 0xd1, 0xff, 4, 0xff, 0, 0, 0, 0, 0],
    );

    await settingsRepository.makeBikeActive('second');
    expect(
      (await database.select(database.backgroundSyncCommands).getSingle())
          .payload,
      [0, 0xc1, 0xff, 0xff, 3, 0, 0, 0, 0, 0],
    );

    await repository.setOnConnect('second', const BikeControlPatch());
    expect(await database.select(database.backgroundSyncPlans).get(), isEmpty);

    await repository.setBackgroundPreference(
      'second',
      requested: false,
      consentVersion: backgroundSyncConsentVersion,
    );
    expect(await database.select(database.backgroundSyncPlans).get(), isEmpty);
    expect(
      await database.select(database.backgroundSyncCommands).get(),
      isEmpty,
    );
  });

  test('bike details update together with a normalized name', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    await repository.updateBikeDetails(
      'bike',
      displayName: '  Commuter  ',
      region: BikeRegion.eu,
      color: BikeColor.midnightSky,
      protocol: BikeProtocolVersion.v1,
    );

    final saved = (await repository.getBikes()).single;
    expect(saved.bike.displayName, 'Commuter');
    expect(saved.bike.region, BikeRegion.eu);
    expect(saved.bike.color, BikeColor.midnightSky);
  });

  test('V1 bikes default a missing region to US', () async {
    await settingsRepository.initialize();

    var saved = await repository.addBike(deviceId: 'bike', region: null);
    expect(saved.bike.region, BikeRegion.us);

    await repository.updateBikeDetails(
      'bike',
      displayName: 'Bike',
      region: null,
      color: BikeColor.royalHorizon,
      protocol: BikeProtocolVersion.v1,
    );

    saved = (await repository.getBikes()).single;
    expect(saved.bike.region, BikeRegion.us);
  });

  test(
    'bike protocol can be overridden with the other advertised name',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(
        deviceId: 'bike',
        region: BikeRegion.eu,
      );

      await repository.updateBikeDetails(
        'bike',
        displayName: 'Commuter',
        region: BikeRegion.eu,
        color: BikeColor.midnightSky,
        protocol: BikeProtocolVersion.v2,
      );

      var saved = (await repository.getBikes()).single;
      expect(saved.bike.advertisedName, 'SUPER73');
      expect(saved.bike.protocol, BikeProtocolVersion.v2);
      expect(saved.bike.region, equals(null));

      await repository.updateBikeDetails(
        'bike',
        displayName: 'Commuter',
        region: BikeRegion.us,
        color: BikeColor.midnightSky,
        protocol: BikeProtocolVersion.v1,
      );

      saved = (await repository.getBikes()).single;
      expect(saved.bike.advertisedName, 'SUPER73');
      expect(saved.bike.protocol, BikeProtocolVersion.v1);
      expect(saved.bike.region, BikeRegion.us);
    },
  );

  test('version snapshots are inserted with a newly saved bike', () async {
    await settingsRepository.initialize();

    final saved = await repository.addBike(
      deviceId: 'bike',
      versions: _versionInfo,
    );

    expect(saved.versions?.info, _versionInfo);
    expect(saved.versions?.readAt.isAtSameMomentAs(now), isTrue);
  });

  test('odometer readings are cached with a newly saved bike', () async {
    await settingsRepository.initialize();

    final saved = await repository.addBike(
      deviceId: 'bike',
      odometerMeters: 123456,
    );

    expect(saved.odometer?.meters, 123456);
    expect(saved.odometer?.readAt.isAtSameMomentAs(now), isTrue);
  });

  test(
    'odometer reads refresh their timestamp without touching bike edits',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(deviceId: 'bike');
      final originalUpdatedAt =
          (await repository.getBikes()).single.bike.updatedAt;

      expect(await repository.saveOdometer('bike', 123456), isTrue);
      now = now.add(const Duration(hours: 1));
      expect(await repository.saveOdometer('bike', 123456), isFalse);

      final saved = (await repository.getBikes()).single;
      expect(saved.odometer?.meters, 123456);
      expect(saved.odometer?.readAt.isAtSameMomentAs(now), isTrue);
      expect(saved.bike.updatedAt, originalUpdatedAt);
      expect(
        () => repository.saveOdometer('bike', 0x100000000),
        throwsRangeError,
      );
    },
  );

  test('module serials are normalized and only saved when changed', () async {
    await settingsRepository.initialize();
    final saved = await repository.addBike(
      deviceId: 'bike',
      moduleSerial: ' 00112233AABBCCDD ',
    );
    expect(saved.bike.moduleSerial, '00112233aabbccdd');

    expect(
      await repository.saveModuleSerial('bike', '00112233aabbccdd'),
      isFalse,
    );
    expect(
      await repository.saveModuleSerial('bike', 'ffeeddccbbaa9988'),
      isTrue,
    );
    expect(
      (await repository.getBikes()).single.bike.moduleSerial,
      'ffeeddccbbaa9988',
    );
    expect(
      () => repository.saveModuleSerial('bike', 'not-a-chip-id'),
      throwsArgumentError,
    );
  });

  test('duplicate bikes report a domain error', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    await expectLater(
      repository.addBike(deviceId: 'bike'),
      throwsA(isA<BikeAlreadyExistsException>()),
    );
  });

  test('version snapshots are only rewritten when a number changes', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    expect(await repository.saveVersions('bike', _versionInfo), isTrue);
    final firstReadAt = (await repository.getBikes()).single.versions!.readAt;

    now = now.add(const Duration(hours: 1));
    expect(await repository.saveVersions('bike', _versionInfo), isFalse);
    expect((await repository.getBikes()).single.versions!.readAt, firstReadAt);

    const changed = BikeVersionInfo(
      hardwareRevision: 'v3.3.0',
      firmwareRevision: '250426',
      softwareRevision: '250426',
      stmFirmwareVersion: 0x010203,
      controllerVariant: 407,
      bootloaderHandoff: 8,
      motorControllerVersion: 0x12345678,
      bmsVersion: 0xabcdef02,
    );
    expect(await repository.saveVersions('bike', changed), isTrue);
    final saved = (await repository.getBikes()).single;
    expect(saved.versions?.info, changed);
    expect(saved.versions?.readAt.isAtSameMomentAs(now), isTrue);
  });

  test(
    'advertised name alone determines protocol-specific persistence',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(
        deviceId: 'bike',
        advertisedName: 'S73 FTEX',
        region: BikeRegion.eu,
      );

      final v2 = (await repository.getBikes()).single.bike;
      expect(v2.advertisedName, 'S73 FTEX');
      expect(v2.protocol, BikeProtocolVersion.v2);
      expect(v2.region, equals(null));

      await repository.forgetBike('bike');
      await repository.addBike(
        deviceId: 'v1',
        region: BikeRegion.eu,
      );
      final v1 = (await repository.getBikes()).single.bike;
      expect(v1.advertisedName, 'SUPER73');
      expect(v1.protocol, BikeProtocolVersion.v1);
      expect(v1.region, BikeRegion.eu);
    },
  );
}

const _versionInfo = BikeVersionInfo(
  hardwareRevision: 'v3.3.0',
  firmwareRevision: '250426',
  softwareRevision: '250426',
  stmFirmwareVersion: 0x010203,
  controllerVariant: 407,
  bootloaderHandoff: 8,
  motorControllerVersion: 0x12345678,
  bmsVersion: 0xabcdef01,
);
