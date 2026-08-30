import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/bike_settings/bike_version_report.dart';
import 'package:superduper/src/platform/report_exporter.dart';

void main() {
  test('version report includes bike, app, cache, and version details', () {
    final bike = Bike(
      deviceId: 'E15225C1-76CE-3CA1-BB6A-BD3CC506ADB2',
      displayName: 'Commuter',
      protocol: BikeProtocolVersion.v1,
      region: BikeRegion.us,
      color: BikeColor.deepSpace,
      sortOrder: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      lastConnectedAt: DateTime.utc(2026, 8, 24, 17),
      moduleSerial: '00112233aabbccdd',
    );
    final versions = CachedBikeVersions(
      info: const BikeVersionInfo(
        hardwareRevision: '221122',
        firmwareRevision: 'v3.2.0',
        softwareRevision: 'display-17',
        stmFirmwareVersion: 0x010203,
        controllerVariant: 0x0196,
        bootloaderHandoff: 0x08,
        motorControllerVersion: 0x12345678,
        bmsVersion: 0xABCDEF01,
      ),
      readAt: DateTime.utc(2026, 8, 24, 16, 30),
    );
    final odometer = CachedBikeOdometer(
      meters: 1609344,
      readAt: DateTime.utc(2026, 8, 24, 16, 45),
    );
    const metadata = ReportMetadata(
      appVersion: '2.0.0',
      buildNumber: '42',
      platform: 'macos',
      operatingSystemVersion: 'macOS 15.6\nBuild 24G84',
    );

    final report = createBikeVersionReport(
      bike: bike,
      versions: versions,
      odometer: odometer,
      metadata: metadata,
      generatedAt: DateTime.utc(2026, 8, 24, 17, 45),
    );

    expect(report, contains('Generated: 2026-08-24T17:45:00.000Z'));
    expect(report, contains('Version: 2.0.0'));
    expect(report, contains('Build: 42'));
    expect(report, contains('OS: macOS 15.6 Build 24G84'));
    expect(report, contains('Name: Commuter'));
    expect(
      report,
      contains('Advertised name: ${BikeProtocolVersion.v1.advertisedName}'),
    );
    expect(report, contains('Protocol: V1 (advertised name)'));
    expect(report, contains('BLE identifier: ${bike.deviceId}'));
    expect(report, contains('Module serial: 00112233aabbccdd'));
    expect(report, contains('Region: US'));
    expect(report, contains('Versions cached: 2026-08-24T16:30:00.000Z'));
    expect(report, contains('Odometer: 1609.3 km · 1000.0 mi'));
    expect(report, contains('Odometer meters: 1609344'));
    expect(report, contains('Odometer read: 2026-08-24T16:45:00.000Z'));
    expect(report, contains('Hardware revision: 221122'));
    expect(report, contains('Display firmware: v3.2.0'));
    expect(report, contains('Software revision: display-17'));
    expect(report, contains('STM firmware: 66051 (0x010203)'));
    expect(report, contains('Controller variant: 406 (0x0196)'));
    expect(report, contains('Bootloader handoff: 8 (0x08)'));
    expect(report, contains('Motor controller: 305419896 (0x12345678)'));
    expect(report, contains('BMS: 2882400001 (0xABCDEF01)'));
    expect(report, contains('Review it before sharing'));
  });

  test('version report omits region when it does not apply', () {
    final bike = Bike(
      deviceId: 'v2-bike',
      displayName: 'V2 Bike',
      advertisedName: BikeProtocolVersion.v2.advertisedName,
      protocol: BikeProtocolVersion.v2,
      region: null,
      color: BikeColor.deepSpace,
      sortOrder: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      lastConnectedAt: null,
    );
    final versions = CachedBikeVersions(
      info: const BikeVersionInfo(
        hardwareRevision: 'v3.3.0',
        firmwareRevision: '250426',
        softwareRevision: '250426',
        stmFirmwareVersion: 0x010203,
        controllerVariant: 407,
        bootloaderHandoff: 8,
        motorControllerVersion: 0x12345678,
        bmsVersion: 0xabcdef01,
      ),
      readAt: DateTime.utc(2026, 8, 24),
    );

    final report = createBikeVersionReport(
      bike: bike,
      versions: versions,
      metadata: const ReportMetadata(
        appVersion: '2.0.0',
        buildNumber: '42',
        platform: 'macos',
        operatingSystemVersion: 'macOS',
      ),
      generatedAt: DateTime.utc(2026, 8, 24),
    );

    expect(report, isNot(contains('Region:')));
    expect(
      report,
      contains('Advertised name: ${BikeProtocolVersion.v2.advertisedName}'),
    );
    expect(report, contains('Protocol: V2 (advertised name)'));
  });

  test('version report identifies a manually overridden protocol', () {
    final bike = Bike(
      deviceId: 'override-bike',
      displayName: 'Override Bike',
      protocol: BikeProtocolVersion.v2,
      region: null,
      color: BikeColor.deepSpace,
      sortOrder: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      lastConnectedAt: null,
    );
    final versions = CachedBikeVersions(
      info: const BikeVersionInfo(
        hardwareRevision: 'hardware',
        firmwareRevision: 'firmware',
        softwareRevision: 'software',
        stmFirmwareVersion: 1,
        controllerVariant: 2,
        bootloaderHandoff: 3,
        motorControllerVersion: 4,
        bmsVersion: 5,
      ),
      readAt: DateTime.utc(2026),
    );

    final report = createBikeVersionReport(
      bike: bike,
      versions: versions,
      metadata: const ReportMetadata(
        appVersion: '2.0.0',
        buildNumber: '42',
        platform: 'macos',
        operatingSystemVersion: 'macOS',
      ),
    );

    expect(
      report,
      contains('Advertised name: ${BikeProtocolVersion.v1.advertisedName}'),
    );
    expect(report, contains('Protocol: V2 (manual override)'));
  });
}
