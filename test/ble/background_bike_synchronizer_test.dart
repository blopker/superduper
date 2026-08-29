import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../support/fake_bike_transport.dart';

void main() {
  late AppDatabase database;
  late BikeRepository bikes;
  late SettingsRepository settings;
  late FakeBikeTransport transport;
  late BackgroundBikeSynchronizer synchronizer;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    transport = FakeBikeTransport();
    synchronizer = BackgroundBikeSynchronizer(
      bikeRepository: bikes,
      settingsRepository: settings,
      transport: transport,
    );
    await settings.initialize();
  });

  tearDown(() async {
    await transport.dispose();
    await database.close();
  });

  test('skips a wake when background sync is disabled', () async {
    await bikes.addBike(
      deviceId: 'saved-address',
      moduleSerial: '00112233aabbccdd',
    );

    final result = await synchronizer.synchronize(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: '00112233aabbccdd',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.skippedDisabled);
    expect(transport.connections, isEmpty);
  });

  test('rejects a wake for a different module serial', () async {
    await bikes.addBike(
      deviceId: 'saved-address',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );

    final result = await synchronizer.synchronize(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: 'ffeeddccbbaa9988',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.skippedSerialMismatch);
    expect(transport.connections, isEmpty);
  });

  test('rejects a wake until the current consent is accepted', () async {
    await bikes.addBike(
      deviceId: 'saved-address',
      moduleSerial: '00112233aabbccdd',
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: 0,
      ),
    );

    final result = await synchronizer.synchronize(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: '00112233aabbccdd',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.skippedDisabled);
    expect(transport.connections, isEmpty);
  });

  test('uses the observed address and applies Set on connect', () async {
    await bikes.addBike(
      deviceId: 'saved-address',
      moduleSerial: '00112233aabbccdd',
      setOnConnect: const BikeControlPatch(
        mode: 3,
      ),
      backgroundPreference: const BackgroundPreference(
        requested: true,
        consentVersion: backgroundSyncConsentVersion,
      ),
    );
    transport.readFramesOnOpen['observed-address'] = [
      v1StateFrame(mode: 1, assist: 2),
      v1StateFrame(mode: 3, assist: 2),
    ];

    final result = await synchronizer.synchronize(
      const BackgroundSyncRequest(
        deviceId: 'observed-address',
        moduleSerial: '00112233aabbccdd',
      ),
    );

    expect(result.outcome, BackgroundSyncOutcome.confirmed);
    final connection = transport.connections['observed-address']!;
    final configurationWrites = connection.writes.where(
      (write) => write.characteristicUuid == BikeGatt.stateRegister,
    );
    expect(configurationWrites, hasLength(1));
    expect(
      configurationWrites.single.value,
      [0, 0xd1, 0, 2, 3, 0, 0, 0, 0, 0],
    );
    expect(connection.reads, isNotEmpty);
    expect(connection.isDisposed, isTrue);
  });
}
