import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

sealed class StartupState {
  const StartupState();
}

final class StartupLoading extends StartupState {
  const StartupLoading();
}

final class StartupReady extends StartupState {
  const StartupReady({
    required this.importResult,
    required this.repositoryInitialization,
  });

  final InstalledDataImportSuccess importResult;
  final SettingsInitialization repositoryInitialization;
}

final class StartupMigrationRecovery extends StartupState {
  const StartupMigrationRecovery({
    required this.reason,
    required this.warnings,
  });

  final ImportRecoveryReason reason;
  final List<ImportWarning> warnings;
}

final class StartupFailure extends StartupState {
  const StartupFailure({required this.error});

  final Object error;
}

final class StartupController {
  StartupController({
    required this.database,
    required this.importer,
    required this.settingsRepository,
    this.onReady,
  });

  final AppDatabase database;
  final InstalledDataImporter importer;
  final SettingsRepository settingsRepository;
  final Future<void> Function()? onReady;
  final Signal<StartupState> _state = signal(
    const StartupLoading(),
    options: const SignalOptions(name: 'startup.state'),
  );
  bool _disposed = false;
  Future<void>? _initializationFuture;

  ReadonlySignal<StartupState> get state => _state.readonly();

  Future<void> initialize() => _startInitialization(importer.run);

  Future<void> _startInitialization(
    Future<InstalledDataImportResult> Function() importData,
  ) {
    if (_disposed) {
      return Future.value();
    }
    if (_initializationFuture case final pending?) {
      return pending;
    }
    final pending = _initialize(importData);
    _initializationFuture = pending;
    unawaited(
      pending.then<void>(
        (_) {
          if (identical(_initializationFuture, pending)) {
            _initializationFuture = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_initializationFuture, pending)) {
            _initializationFuture = null;
          }
        },
      ),
    );
    return pending;
  }

  Future<void> _initialize(
    Future<InstalledDataImportResult> Function() importData,
  ) async {
    _state.value = const StartupLoading();

    try {
      await database.customSelect('SELECT 1').getSingle();
      if (_disposed) {
        return;
      }
      final importResult = await importData();
      if (_disposed) {
        return;
      }
      switch (importResult) {
        case InstalledDataImportRecovery(:final reason, :final warnings):
          _state.value = StartupMigrationRecovery(
            reason: reason,
            warnings: warnings,
          );
          return;
        case InstalledDataImportSuccess():
          final repositoryInitialization = await settingsRepository
              .initialize();
          await onReady?.call();
          if (_disposed) {
            return;
          }
          _state.value = StartupReady(
            importResult: importResult,
            repositoryInitialization: repositoryInitialization,
          );
      }
    } on Object catch (error) {
      if (!_disposed) {
        _state.value = StartupFailure(error: error);
      }
    }
  }

  Future<void> retryImport() => _startInitialization(importer.retry);

  Future<void> continueWithoutImport() =>
      _startInitialization(importer.continueWithoutImport);

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
