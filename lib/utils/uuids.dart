// Constants from services.dart - MUST be 'final' not 'const' because Guid is not a const constructor
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final UUID_METRICS_SERVICE =
    Guid.fromString("00001554-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER =
    Guid.fromString("0000155f-1212-efde-1523-785feabcd123");
final UUID_CHARACTERISTIC_REGISTER_ID =
    Guid.fromString("00001564-1212-efde-1523-785feabcd123");
