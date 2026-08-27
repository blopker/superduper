import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/ble/flutter_blue_bike_transport.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/platform/background_sync.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    unawaited(FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false));
  }

  runApp(const SuperduperBootstrap());
}

@pragma('vm:entry-point')
Future<void> backgroundSyncMain(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  const completion = MethodChannel(backgroundSyncWorkerChannelName);
  BackgroundSyncResult result;
  AppDatabase? database;
  FlutterBlueBikeTransport? transport;
  try {
    if (arguments.length != 2) {
      throw ArgumentError('Expected a device ID and module serial.');
    }
    database = AppDatabase.open();
    transport = FlutterBlueBikeTransport();
    result =
        await BackgroundBikeSynchronizer(
          bikeRepository: BikeRepository(database: database),
          settingsRepository: SettingsRepository(database: database),
          transport: transport,
        ).synchronize(
          BackgroundSyncRequest(
            deviceId: arguments[0],
            moduleSerial: arguments[1],
          ),
        );
  } on Object catch (error) {
    result = BackgroundSyncResult(
      outcome: BackgroundSyncOutcome.failed,
      detail: error.toString(),
    );
  } finally {
    await transport?.dispose();
    await database?.close();
  }
  await completion.invokeMethod<void>('complete', result.toJson());
}
