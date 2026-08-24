import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/features/home/home_page.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

final class SuperduperApp extends StatefulWidget {
  const SuperduperApp({required this.services, super.key});

  final AppServices services;

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
        unawaited(widget.services.activeBikeCoordinator.setForeground(true));
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(widget.services.activeBikeCoordinator.setForeground(false));
    }
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
        home: const StartupPage(),
      ),
    );
  }
}

final class StartupPage extends SignalWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);

    return switch (services.startup.state.value) {
      StartupLoading() => const _LoadingPage(),
      StartupReady() => const HomePage(),
      StartupMigrationRecovery(:final reason) => _MigrationRecoveryPage(
        reason: reason,
        onRetry: services.startup.retryImport,
        onContinue: services.startup.continueWithoutImport,
      ),
      StartupFailure(:final message) => _StartupFailurePage(
        message: message,
        onRetry: services.startup.initialize,
      ),
    };
  }
}

final class _MigrationRecoveryPage extends StatelessWidget {
  const _MigrationRecoveryPage({
    required this.reason,
    required this.onRetry,
    required this.onContinue,
  });

  final ImportRecoveryReason reason;
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
  const _StartupFailurePage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
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
}
