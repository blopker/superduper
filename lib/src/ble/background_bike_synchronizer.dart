import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

enum BackgroundSyncOutcome {
  confirmed,
  skippedDisabled,
  skippedInactiveBike,
  skippedSerialMismatch,
  skippedBusy,
  failed,
}

final class BackgroundSyncRequest {
  const BackgroundSyncRequest({
    required this.deviceId,
    required this.moduleSerial,
  });

  final String deviceId;
  final String moduleSerial;
}

final class BackgroundSyncResult {
  const BackgroundSyncResult({required this.outcome, this.detail});

  final BackgroundSyncOutcome outcome;
  final String? detail;

  Map<String, Object?> toJson() => {
    'outcome': outcome.name,
    'detail': detail,
  };
}

final class BackgroundBikeSynchronizer {
  const BackgroundBikeSynchronizer({
    required this.bikeRepository,
    required this.settingsRepository,
    required this.transport,
    this.timeout = const Duration(seconds: 75),
  });

  final BikeRepository bikeRepository;
  final SettingsRepository settingsRepository;
  final BikeTransport transport;
  final Duration timeout;

  Future<BackgroundSyncResult> synchronize(
    BackgroundSyncRequest request,
  ) async {
    BikeSession? session;
    try {
      final settings = await settingsRepository.get();
      final activeBikeId = settings.activeBikeId;
      if (activeBikeId == null) {
        return const BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.skippedInactiveBike,
        );
      }
      final matches = (await bikeRepository.getBikes()).where(
        (saved) => saved.bike.deviceId == activeBikeId,
      );
      if (matches.isEmpty) {
        return const BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.skippedInactiveBike,
        );
      }
      final saved = matches.single;
      if (!saved.backgroundPreference.requested ||
          saved.backgroundPreference.consentVersion <
              backgroundSyncConsentVersion) {
        return const BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.skippedDisabled,
        );
      }
      if (saved.bike.moduleSerial?.toLowerCase() !=
          request.moduleSerial.toLowerCase()) {
        return const BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.skippedSerialMismatch,
        );
      }

      session = BikeSession(
        connection: transport.openConnection(request.deviceId),
        preferredRegion: saved.bike.region,
        setOnConnect: saved.setOnConnect,
        protocol: saved.bike.protocol,
        pollInterval: null,
        reconnectDelays: const [],
        readDiagnosticsOnConnect: false,
      );
      await session.connect().timeout(timeout);
      return switch (session.state.peek()) {
        SessionReady() => const BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.confirmed,
        ),
        SessionFailed(:final failure) => BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.failed,
          detail: failure.message,
        ),
        final state => BackgroundSyncResult(
          outcome: BackgroundSyncOutcome.failed,
          detail: 'Synchronization ended in ${state.runtimeType}.',
        ),
      };
    } on Object catch (error) {
      return BackgroundSyncResult(
        outcome: BackgroundSyncOutcome.failed,
        detail: error.toString(),
      );
    } finally {
      await session?.dispose();
    }
  }
}
