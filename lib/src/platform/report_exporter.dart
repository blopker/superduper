import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

final class ReportMetadata {
  const ReportMetadata({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.operatingSystemVersion,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String operatingSystemVersion;

  static Future<ReportMetadata> fromPlatform() async {
    final package = await PackageInfo.fromPlatform();
    return ReportMetadata(
      appVersion: package.version,
      buildNumber: package.buildNumber,
      platform: Platform.operatingSystem,
      operatingSystemVersion: Platform.operatingSystemVersion,
    );
  }
}

final class ShareableReport {
  const ShareableReport({
    required this.content,
    required this.filenamePrefix,
    required this.subject,
    required this.message,
  });

  final String content;
  final String filenamePrefix;
  final String subject;
  final String message;

  String filename([DateTime? createdAt]) {
    final timestamp = (createdAt ?? DateTime.now())
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll('.', '-');
    return '$filenamePrefix-$timestamp.txt';
  }
}

abstract final class ReportExporter {
  static Future<ShareResult> share(
    ShareableReport report, {
    Rect? sharePositionOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        subject: report.subject,
        text: report.message,
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(report.content)),
            mimeType: 'text/plain',
          ),
        ],
        fileNameOverrides: [report.filename()],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static Future<void> copy(ShareableReport report) {
    return Clipboard.setData(ClipboardData(text: report.content));
  }
}
