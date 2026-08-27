import 'package:flutter/widgets.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/background_bike_synchronizer.dart';
import 'package:superduper/src/ble/bike_identity_resolver.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/flutter_blue_bike_transport.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/platform/background_sync.dart';
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
    BackgroundSyncPlatformGateway? backgroundSyncPlatform,
    BackgroundSyncCoordinator? backgroundSyncCoordinator,
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
    final resolvedIdentityResolver = BikeIdentityResolver(
      bikeRepository: resolvedBikeRepository,
      transport: resolvedTransport,
    );
    final resolvedActiveBikeCoordinator =
        activeBikeCoordinator ??
        ActiveBikeCoordinator(
          bikeRepository: resolvedBikeRepository,
          settingsRepository: resolvedSettingsRepository,
          permissions: resolvedPermissions,
          identityResolver: resolvedIdentityResolver,
          buildSession: (bike) => BikeSession(
            connection: resolvedTransport.openConnection(bike.bike.deviceId),
            preferredRegion: bike.bike.region,
            preferences: bike.preferences,
            protocol: bike.bike.protocol,
            onConfigurationConfirmed: (configuration) {
              return resolvedBikeRepository.saveDesiredSettings(
                bike.bike.deviceId,
                light: configuration.light,
                mode: configuration.mode,
                assist: configuration.assist,
              );
            },
            onVersionsRead: (versions) async {
              await resolvedBikeRepository.saveVersions(
                bike.bike.deviceId,
                versions,
              );
            },
            onOdometerRead: (meters) async {
              await resolvedBikeRepository.saveOdometer(
                bike.bike.deviceId,
                meters,
              );
            },
          ),
        );
    final resolvedBackgroundSyncPlatform =
        backgroundSyncPlatform ?? const NoopBackgroundSyncPlatformGateway();
    final resolvedBackgroundSyncCoordinator =
        backgroundSyncCoordinator ??
        BackgroundSyncCoordinator(
          bikeRepository: resolvedBikeRepository,
          settingsRepository: resolvedSettingsRepository,
          activeBikeCoordinator: resolvedActiveBikeCoordinator,
          synchronizer: BackgroundBikeSynchronizer(
            bikeRepository: resolvedBikeRepository,
            settingsRepository: resolvedSettingsRepository,
            transport: resolvedTransport,
          ),
          transport: resolvedTransport,
          permissions: resolvedPermissions,
          identityResolver: resolvedIdentityResolver,
          platform: resolvedBackgroundSyncPlatform,
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
      backgroundSyncCoordinator: resolvedBackgroundSyncCoordinator,
      startup: StartupController(
        database: database,
        importer: resolvedImporter,
        settingsRepository: resolvedSettingsRepository,
        onReady: () async {
          await resolvedActiveBikeCoordinator.start();
          await resolvedBackgroundSyncCoordinator.start();
        },
      ),
    );
  }

  AppServices._({
    required this.database,
    required this.importer,
    required this.bikeRepository,
    required this.settingsRepository,
    required this.transport,
    required this.permissions,
    required this.externalLinks,
    required this.activeBikeCoordinator,
    required this.backgroundSyncCoordinator,
    required this.startup,
  });

  factory AppServices.standard() {
    return AppServices(
      database: AppDatabase.open(),
      backgroundSyncPlatform: SystemBackgroundSyncPlatformGateway(),
    );
  }

  final AppDatabase database;
  final InstalledDataImporter importer;
  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final ExternalLinkLauncher externalLinks;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final BackgroundSyncCoordinator backgroundSyncCoordinator;
  final StartupController startup;
  Future<void>? _disposeFuture;

  Future<void> dispose() {
    final existing = _disposeFuture;
    if (existing != null) {
      return existing;
    }
    final pending = _performDispose();
    _disposeFuture = pending;
    return pending;
  }

  Future<void> _performDispose() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    void capture(Object error, StackTrace stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    try {
      startup.dispose();
    } on Object catch (error, stackTrace) {
      capture(error, stackTrace);
    }
    for (final cleanup in <Future<void> Function()>[
      backgroundSyncCoordinator.dispose,
      activeBikeCoordinator.dispose,
      transport.dispose,
      database.close,
    ]) {
      try {
        await cleanup();
      } on Object catch (error, stackTrace) {
        capture(error, stackTrace);
      }
    }
    if (firstError case final error?) {
      Error.throwWithStackTrace(error, firstStackTrace!);
    }
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
