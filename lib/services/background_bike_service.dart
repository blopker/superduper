import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/providers/bluetooth_provider.dart';
import '../database/database.dart';
import '../providers/bike_provider.dart';
import '../core/utils/logger.dart';

part 'background_bike_service.g.dart';

@Riverpod(keepAlive: true)
class BackgroundBikeService extends _$BackgroundBikeService {
  @override
  int build() {
    var db = ref.watch(bikesDBProvider);
    final activeBikes = db.where((bike) => bike.active);
    for (final bike in activeBikes) {
      ref.watch(bikeProvider(bike.id));
    }
    log.i(SDLogger.GENERAL,
        'BackgroundBikeService started with: ${activeBikes.length} active bikes');
    return 0;
  }

  void deactivateAndDisconnectAllBikes() async {
    var bikes = ref.read(bikesDBProvider);
    for (final bike in bikes) {
      ref.read(bikeProvider(bike.id).notifier).active = false;
    }
    await Future.delayed(Duration(milliseconds: 100))
        .then((_) => ref.read(bluetoothRepositoryProvider).disconnect());
  }
}
