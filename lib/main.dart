import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/app_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    unawaited(FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false));
  }

  final services = AppServices.standard();
  unawaited(services.startup.initialize());
  runApp(SuperduperApp(services: services));
}
