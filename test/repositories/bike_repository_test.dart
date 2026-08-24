import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late BikeRepository repository;
  late SettingsRepository settingsRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BikeRepository(
      database: database,
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
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
      final active = await repository.getActiveBike();

      expect(bikes.map((saved) => saved.bike.deviceId), ['first', 'second']);
      expect(bikes.map((saved) => saved.bike.sortOrder), [0, 1]);
      expect(active?.bike.deviceId, 'first');
    },
  );

  test('switching active bike is independent from last viewed bike', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'first');
    await repository.addBike(deviceId: 'second');

    await settingsRepository.setLastViewedBike('second');
    expect((await repository.getActiveBike())?.bike.deviceId, 'first');

    await settingsRepository.makeBikeActive('second');
    final settings = await settingsRepository.get();
    expect(settings.activeBikeId, 'second');
    expect(settings.lastViewedBikeId, 'second');
  });

  test('forgetting the active bike promotes the lowest sorted bike', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'first');
    await repository.addBike(deviceId: 'second');
    await repository.addBike(deviceId: 'third');
    await settingsRepository.makeBikeActive('second');

    await repository.forgetBike('second');

    expect((await repository.getActiveBike())?.bike.deviceId, 'first');
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
    'enabling a lock captures the confirmed bike value atomically',
    () async {
      await settingsRepository.initialize();
      await repository.addBike(
        deviceId: 'bike',
        preferences: const RidePreferences(
          desiredLight: false,
          desiredMode: 0,
          desiredAssist: 0,
          keepLight: false,
          keepMode: false,
          keepAssist: false,
          backgroundRequested: false,
          backgroundConsentVersion: 0,
        ),
      );

      await repository.setModeLock('bike', enabled: true, confirmedValue: 3);

      final saved = (await repository.getBikes()).single;
      expect(saved.preferences.keepMode, isTrue);
      expect(saved.preferences.desiredMode, 3);
    },
  );

  test('invalid desired values never reach SQLite', () async {
    await settingsRepository.initialize();
    await repository.addBike(deviceId: 'bike');

    expect(
      () => repository.saveDesiredSettings('bike', mode: 4),
      throwsRangeError,
    );
    expect(
      () => repository.saveDesiredSettings('bike', assist: -1),
      throwsRangeError,
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
    );

    final saved = (await repository.getBikes()).single;
    expect(saved.bike.displayName, 'Commuter');
    expect(saved.bike.region, BikeRegion.eu);
    expect(saved.bike.color, BikeColor.midnightSky);
  });
}
