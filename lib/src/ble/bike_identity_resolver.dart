import 'dart:async';

import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/repositories/bike_repository.dart';

final class BikeIdentityResolver {
  const BikeIdentityResolver({
    required this.bikeRepository,
    required this.transport,
  });

  final BikeRepository bikeRepository;
  final BikeTransport transport;

  Future<SavedBike> resolve(
    SavedBike saved, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (saved.bike.moduleSerial != null) {
      return saved;
    }
    final discovered = Completer<DiscoveredBike>();
    final expectedId = saved.bike.deviceId.toLowerCase();
    final subscription = transport.scanResults.listen(
      (results) {
        for (final result in results) {
          if (!discovered.isCompleted &&
              result.deviceId.toLowerCase() == expectedId &&
              result.moduleSerial != null) {
            discovered.complete(result);
            break;
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!discovered.isCompleted) {
          discovered.completeError(error, stackTrace);
        }
      },
    );
    try {
      await transport.startScan(timeout: timeout);
      final result = await discovered.future.timeout(timeout);
      await bikeRepository.saveModuleSerial(
        saved.bike.deviceId,
        result.moduleSerial!,
      );
      return (await bikeRepository.getBikes()).singleWhere(
        (candidate) => candidate.bike.deviceId == saved.bike.deviceId,
      );
    } finally {
      await subscription.cancel();
      try {
        await transport.stopScan();
      } on Object {
        // Identity enrichment is complete or already failed; scan cleanup is
        // best effort so it cannot replace the useful result.
      }
    }
  }
}
