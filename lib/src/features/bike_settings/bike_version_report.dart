import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/platform/report_exporter.dart';

String createBikeVersionReport({
  required Bike bike,
  required CachedBikeVersions versions,
  required ReportMetadata metadata,
  DateTime? generatedAt,
}) {
  final info = versions.info;
  final generated = (generatedAt ?? DateTime.now()).toUtc();
  return '''SUPERDUPER BIKE VERSION REPORT
Report format: 1
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
BLE identifier: ${bike.deviceId}
Module serial: ${bike.moduleSerial ?? 'Unavailable'}
${_regionLine(bike.region)}
Versions cached: ${versions.readAt.toUtc().toIso8601String()}

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

String _regionLine(BikeRegion? region) {
  return region == null ? '' : 'Region: ${region.label}';
}

String _number(int value, int width) {
  final hex = value.toRadixString(16).padLeft(width, '0').toUpperCase();
  return '$value (0x$hex)';
}

String _singleLine(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
