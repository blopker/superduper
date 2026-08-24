import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/features/home/home_page.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';

typedef AppServicesFactory = AppServices Function();
typedef AppDataReset = Future<void> Function();

final class SuperduperBootstrap extends StatefulWidget {
  const SuperduperBootstrap({
    this.createServices = AppServices.standard,
    this.resetData = AppDatabase.resetAppData,
    super.key,
  });

  final AppServicesFactory createServices;
  final AppDataReset resetData;

  @override
  State<SuperduperBootstrap> createState() => _SuperduperBootstrapState();
}

final class _SuperduperBootstrapState extends State<SuperduperBootstrap> {
  AppServices? _services;
  Object? _creationError;
  var _restarting = false;

  @override
  void initState() {
    super.initState();
    _createInitialServices();
  }

  void _createInitialServices() {
    try {
      final services = widget.createServices();
      _services = services;
      unawaited(services.startup.initialize());
    } on Object catch (error) {
      _creationError = error;
    }
  }

  Future<void> _resetDataAndRestart() async {
    if (_restarting) {
      return;
    }
    final old = _services;
    setState(() {
      _restarting = true;
      _services = null;
    });
    if (old != null) {
      try {
        await old.dispose();
      } on Object {
        // A service graph that failed while opening may also fail while closing.
      }
    }
    if (!mounted) {
      return;
    }
    try {
      await widget.resetData();
      if (!mounted) {
        return;
      }
      final replacement = widget.createServices();
      setState(() {
        _services = replacement;
        _creationError = null;
        _restarting = false;
      });
      await replacement.startup.initialize();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _creationError = error;
          _restarting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    final services = _services;
    if (services != null) {
      unawaited(services.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restarting) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _LoadingPage(),
      );
    }
    final services = _services;
    if (services != null) {
      return SuperduperApp(
        services: services,
        onStartupReset: _resetDataAndRestart,
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _StartupFailurePage(
        message: userFacingError(
          _creationError ?? StateError('Service creation failed.'),
          context: UserErrorContext.startup,
        ),
        onReset: _resetDataAndRestart,
      ),
    );
  }
}

final class SuperduperApp extends StatefulWidget {
  const SuperduperApp({
    required this.services,
    this.onStartupReset,
    super.key,
  });

  final AppServices services;
  final Future<void> Function()? onStartupReset;

  @override
  State<SuperduperApp> createState() => _SuperduperAppState();
}

final class _SuperduperAppState extends State<SuperduperApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setForeground(true);
      case AppLifecycleState.inactive:
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setForeground(false);
    }
  }

  void _setForeground(bool foreground) {
    unawaited(
      widget.services.activeBikeCoordinator
          .setForeground(foreground)
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: widget.services,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Superduper',
        theme: AppTheme.dark,
        home: StartupPage(onStartupReset: widget.onStartupReset),
      ),
    );
  }
}

final class StartupPage extends SignalWidget {
  const StartupPage({this.onStartupReset, super.key});

  final Future<void> Function()? onStartupReset;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);

    return switch (services.startup.state.value) {
      StartupLoading() => const _LoadingPage(),
      StartupReady() => const HomePage(),
      StartupMigrationRecovery(:final reason, :final warnings) =>
        _MigrationRecoveryPage(
          reason: reason,
          warnings: warnings,
          onRetry: services.startup.retryImport,
          onContinue: services.startup.continueWithoutImport,
        ),
      StartupFailure(:final error) => _StartupFailurePage(
        message: userFacingError(
          error,
          context: UserErrorContext.startup,
        ),
        onReset: onStartupReset,
      ),
    };
  }
}

final class _MigrationRecoveryPage extends StatelessWidget {
  const _MigrationRecoveryPage({
    required this.reason,
    required this.warnings,
    required this.onRetry,
    required this.onContinue,
  });

  final ImportRecoveryReason reason;
  final List<ImportWarning> warnings;
  final Future<void> Function() onRetry;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final detail = switch (reason) {
      ImportRecoveryReason.unreadableBikes =>
        'The existing bike file could not be read.',
      ImportRecoveryReason.malformedBikes =>
        'The existing bike file is not valid JSON.',
      ImportRecoveryReason.noValidBikes =>
        'The existing bike file did not contain any usable bikes.',
    };

    return Scaffold(
      body: AppPageBody(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SurfacePanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restore_rounded,
                      size: 44,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Your saved bikes need attention',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$detail Your original files have not been changed.',
                      textAlign: TextAlign.center,
                    ),
                    if (warnings.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      for (final warning in warnings)
                        Text(
                          _importWarningLabel(warning),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onContinue,
                      child: const Text('Continue without saved bikes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _importWarningLabel(ImportWarning warning) {
    final location = [
      if (warning.record case final record?) 'bike ${record + 1}',
      ?warning.field,
    ].join(', ');
    return location.isEmpty
        ? warning.code.replaceAll('_', ' ')
        : '${warning.code.replaceAll('_', ' ')} ($location)';
  }
}

final class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBody(
        maxWidth: double.infinity,
        safeTop: false,
        child: Semantics(
          label: 'Preparing Superduper',
          child: const Stack(
            children: [
              Align(alignment: Alignment.topCenter, child: BrandMasthead()),
              Center(
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StartupFailurePage extends StatelessWidget {
  const _StartupFailurePage({required this.message, required this.onReset});

  final String message;
  final Future<void> Function()? onReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageBody(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SurfacePanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Superduper could not open your saved bikes.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    const Text(
                      'Resetting removes every saved bike, its settings, and cached bike information from this device.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: onReset == null
                          ? null
                          : () => _confirmReset(context),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Reset app data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = onReset;
    if (reset == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RESET APP DATA?'),
        content: const Text(
          'This permanently removes every saved bike and setting from this device. You’ll need to add your bike again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset app data'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await reset();
    }
  }
}
