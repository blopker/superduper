import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A professional logging service that provides consistent, formatted logs
/// with different log levels and categories.
class SDLogger {
  static final SDLogger _instance = SDLogger._internal();
  factory SDLogger() => _instance;

  late Logger _logger;

  // Tag constants to categorize logs
  static const String BLUETOOTH = 'Bluetooth';
  static const String BIKE = 'Bike';
  static const String UI = 'UI';
  static const String DB = 'Database';
  static const String GENERAL = 'App';

  SDLogger._internal() {
    // Initialize with appropriate settings
    _logger = Logger(
      printer: PrettyPrinter(
          methodCount: 0, // Number of method calls to display
          errorMethodCount:
              5, // Number of method calls if stacktrace is provided
          lineLength: 120, // Width of the output
          colors:
              !Platform.isIOS, // Colors are handled poorly in iOS debug console
          printEmojis: false, // Print emojis
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          noBoxingByDefault: true),
      level: kDebugMode
          ? Level.debug
          : Level.info, // Only show info+ logs in production
    );
  }

  /// Debug level log - only shown in debug mode
  void d(String tag, String message) {
    _logger.d('[$tag] $message');
  }

  /// Info level log - shown in both debug and production
  void i(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  /// Warning level log - shown in both debug and production
  void w(String tag, String message) {
    _logger.w('[$tag] $message');
  }

  /// Error level log with optional error object and stack trace
  void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  /// WTF (What a Terrible Failure) level log - for catastrophic failures
  void wtf(String tag, String message,
      [dynamic error, StackTrace? stackTrace]) {
    _logger.f('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  /// Verbose level log - only shown in debug mode, lowest priority
  void v(String tag, String message) {
    _logger.t('[$tag] $message');
  }
}

/// Global logger instance for easy access
final log = SDLogger();
