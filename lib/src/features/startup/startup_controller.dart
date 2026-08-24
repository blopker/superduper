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
  const StartupFailure({required this.message});

  final String message;
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
  bool _initializing = false;
  bool _disposed = false;
  Future<void>? _initializationFuture;

  ReadonlySignal<StartupState> get state => _state.readonly();

  Future<void> initialize() => _startInitialization(retryImport: false);

  Future<void> _startInitialization({required bool retryImport}) {
    if (_disposed) {
      return Future.value();
    }
    if (_initializationFuture case final pending?) {
      return pending;
    }
    final pending = _initialize(retryImport: retryImport);
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

  Future<void> _initialize({required bool retryImport}) async {
    _initializing = true;
    _state.value = const StartupLoading();

    try {
      await database.customSelect('SELECT 1').getSingle();
      if (_disposed) {
        return;
      }
      final importResult = retryImport
          ? await importer.retry()
          : await importer.run();
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
        _state.value = StartupFailure(message: error.toString());
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> retryImport() {
    return _startInitialization(retryImport: true);
  }

  Future<void> continueWithoutImport() async {
    if (_initializing || _disposed) {
      return;
    }
    _initializing = true;
    _state.value = const StartupLoading();
    try {
      final importResult = await importer.continueWithoutImport();
      final repositoryInitialization = await settingsRepository.initialize();
      await onReady?.call();
      if (_disposed) {
        return;
      }
      _state.value = StartupReady(
        importResult: importResult,
        repositoryInitialization: repositoryInitialization,
      );
    } on Object catch (error) {
      if (!_disposed) {
        _state.value = StartupFailure(message: error.toString());
      }
    } finally {
      _initializing = false;
    }
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
