import 'package:flutter/widgets.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/flutter_blue_bike_transport.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/platform/external_links.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

final class AppServices {
  factory AppServices({
    required AppDatabase database,
    InstalledDataImporter? importer,
    BikeRepository? bikeRepository,
    SettingsRepository? settingsRepository,
    BikeTransport? transport,
    BluetoothPermissionGateway? permissions,
    ExternalLinkLauncher? externalLinks,
    ActiveBikeCoordinator? activeBikeCoordinator,
  }) {
    final resolvedImporter =
        importer ?? InstalledDataImporter(database: database);
    final resolvedBikeRepository =
        bikeRepository ?? BikeRepository(database: database);
    final resolvedSettingsRepository =
        settingsRepository ?? SettingsRepository(database: database);
    final resolvedTransport = transport ?? FlutterBlueBikeTransport();
    final resolvedPermissions =
        permissions ?? SystemBluetoothPermissionGateway();
    final resolvedExternalLinks =
        externalLinks ?? const SystemExternalLinkLauncher();
    final resolvedActiveBikeCoordinator =
        activeBikeCoordinator ??
        ActiveBikeCoordinator(
          bikeRepository: resolvedBikeRepository,
          settingsRepository: resolvedSettingsRepository,
          permissions: resolvedPermissions,
          buildSession: (bike) => BikeSession(
            connection: resolvedTransport.openConnection(bike.bike.deviceId),
            preferredRegion: bike.bike.region,
            preferences: bike.preferences,
            onConfigurationConfirmed: (configuration) {
              return resolvedBikeRepository.saveDesiredSettings(
                bike.bike.deviceId,
                light: configuration.light,
                mode: configuration.mode,
                assist: configuration.assist,
              );
            },
          ),
        );
    return AppServices._(
      database: database,
      importer: resolvedImporter,
      bikeRepository: resolvedBikeRepository,
      settingsRepository: resolvedSettingsRepository,
      transport: resolvedTransport,
      permissions: resolvedPermissions,
      externalLinks: resolvedExternalLinks,
      activeBikeCoordinator: resolvedActiveBikeCoordinator,
      startup: StartupController(
        database: database,
        importer: resolvedImporter,
        settingsRepository: resolvedSettingsRepository,
        onReady: resolvedActiveBikeCoordinator.start,
      ),
    );
  }

  const AppServices._({
    required this.database,
    required this.importer,
    required this.bikeRepository,
    required this.settingsRepository,
    required this.transport,
    required this.permissions,
    required this.externalLinks,
    required this.activeBikeCoordinator,
    required this.startup,
  });

  factory AppServices.standard() {
    return AppServices(database: AppDatabase.open());
  }

  final AppDatabase database;
  final InstalledDataImporter importer;
  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final ExternalLinkLauncher externalLinks;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final StartupController startup;

  Future<void> dispose() async {
    startup.dispose();
    await activeBikeCoordinator.dispose();
    await transport.dispose();
    await database.close();
  }
}

final class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    required this.services,
    required super.child,
    super.key,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'AppServicesScope is missing above this context.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) {
    return services != oldWidget.services;
  }
}
