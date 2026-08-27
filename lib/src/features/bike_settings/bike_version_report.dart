import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/distance.dart';
import 'package:superduper/src/platform/report_exporter.dart';

String createBikeVersionReport({
  required Bike bike,
  required CachedBikeVersions versions,
  required ReportMetadata metadata,
  CachedBikeOdometer? odometer,
  DateTime? generatedAt,
}) {
  final info = versions.info;
  final generated = (generatedAt ?? DateTime.now()).toUtc();
  return '''SUPERDUPER BIKE INFORMATION REPORT
Report format: 2
Generated: ${generated.toIso8601String()}

APP
Version: ${metadata.appVersion}
Build: ${metadata.buildNumber}
Platform: ${metadata.platform}
OS: ${_singleLine(metadata.operatingSystemVersion)}

PRIVACY
This report contains the bike BLE identifier and module serial. Review it before sharing.

BIKE
Name: ${bike.displayName}
Advertised name: ${bike.advertisedName}
Protocol: ${_protocolLabel(bike)}
BLE identifier: ${bike.deviceId}
Module serial: ${bike.moduleSerial ?? 'Unavailable'}
${_regionLine(bike.region)}Versions cached: ${versions.readAt.toUtc().toIso8601String()}
${_odometerLines(odometer)}

VERSIONS
Hardware revision: ${info.hardwareRevision}
Display firmware: ${info.firmwareRevision}
Software revision: ${info.softwareRevision}
STM firmware: ${_number(info.stmFirmwareVersion, 6)}
Controller variant: ${_number(info.controllerVariant, 4)}
Bootloader handoff: ${_number(info.bootloaderHandoff, 2)}
Motor controller: ${_number(info.motorControllerVersion, 8)}
BMS: ${_number(info.bmsVersion, 8)}
''';
}

String _odometerLines(CachedBikeOdometer? odometer) {
  if (odometer == null) {
    return 'Odometer: Unavailable';
  }
  return '''Odometer: ${formatOdometerDistance(odometer.meters)}
Odometer meters: ${odometer.meters}
Odometer read: ${odometer.readAt.toUtc().toIso8601String()}''';
}

String _protocolLabel(Bike bike) {
  final source = BikeProtocolVersion.fromAdvertisedName(bike.advertisedName);
  final selection = bike.protocol.name.toUpperCase();
  return source == bike.protocol
      ? '$selection (advertised name)'
      : '$selection (manual override)';
}

String _regionLine(BikeRegion? region) {
  return region == null ? '' : 'Region: ${region.label}\n';
}

String _number(int value, int width) {
  final hex = value.toRadixString(16).padLeft(width, '0').toUpperCase();
  return '$value (0x$hex)';
}

String _singleLine(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
