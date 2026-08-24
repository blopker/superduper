import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/features/hardware_test/bike_hardware_test_controller.dart';
import 'package:superduper/src/platform/report_exporter.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/user_facing_error.dart';
import 'package:superduper/src/widgets/app_design.dart';
import 'package:superduper/src/widgets/report_actions.dart';

final class BikeHardwareTestPage extends SignalStatefulWidget {
  const BikeHardwareTestPage({super.key});

  @override
  State<BikeHardwareTestPage> createState() => _BikeHardwareTestPageState();
}

final class _BikeHardwareTestPageState extends State<BikeHardwareTestPage> {
  BikeHardwareTestController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) {
      return;
    }
    final services = AppServicesScope.of(context);
    _controller = BikeHardwareTestController(
      transport: services.transport,
      permissions: services.permissions,
      activeBikeCoordinator: services.activeBikeCoordinator,
    );
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final state = controller.state.value;
    return PopScope(
      canPop: !state.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.isRunning) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stop the bike test before leaving this screen.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('BIKE TEST')),
        body: AppPageBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Text(
                state.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(state.detail),
              if (state.isRunning) ...[
                const SizedBox(height: 22),
                const LinearProgressIndicator(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
              ],
              const SizedBox(height: 28),
              if (state.phase == BikeHardwareTestPhase.idle) ...[
                const SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Requirement(
                        text: 'Bike stationary and rear wheel clear',
                      ),
                      SizedBox(height: 12),
                      _Requirement(
                        text: 'Only the bike being tested is powered on',
                      ),
                      SizedBox(height: 12),
                      _Requirement(text: 'Other bike apps fully closed'),
                      SizedBox(height: 12),
                      _Requirement(
                        text: 'About two minutes available for settings and a power cycle',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (state.log.isNotEmpty) ...[
                const SectionHeader(
                  eyebrow: 'Live results',
                  title: 'Hardware checks',
                ),
                const SizedBox(height: 14),
                SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < state.log.length;
                        index++
                      ) ...[
                        _LogRow(entry: state.log[index]),
                        if (index != state.log.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (!state.isRunning && state.log.isNotEmpty) ...[
                const SectionHeader(
                  eyebrow: 'Report',
                  title: 'Save the results',
                ),
                const SizedBox(height: 10),
                const Text(
                  'The report includes a detailed BLE trace, the bike identifier, and its module serial. Review it before sending it to support.',
                ),
                const SizedBox(height: 16),
                ReportActions(createReport: _createShareableReport),
                const SizedBox(height: 20),
              ],
              if (state.phase == BikeHardwareTestPhase.restoring)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Restoring starting settings…'),
                  ],
                )
              else if (state.isRunning)
                OutlinedButton(
                  onPressed: controller.cancel,
                  child: const Text('Stop and restore'),
                )
              else if (state.phase == BikeHardwareTestPhase.idle)
                FilledButton(
                  onPressed: () => unawaited(controller.start()),
                  child: const Text('Begin bike test'),
                )
              else
                TextButton.icon(
                  onPressed: () => unawaited(controller.start()),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Run again'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ShareableReport> _createShareableReport() async {
    final controller = _controller;
    if (controller == null) {
      throw const BikeHardwareTestFailure(
        'The bike test report is no longer available.',
      );
    }
    final metadata = await ReportMetadata.fromPlatform();
    if (!mounted || !identical(controller, _controller)) {
      throw const BikeHardwareTestFailure(
        'The bike test report is no longer available.',
      );
    }
    return ShareableReport(
      content: controller.createReport(
        appVersion: metadata.appVersion,
        buildNumber: metadata.buildNumber,
        platform: metadata.platform,
        operatingSystemVersion: metadata.operatingSystemVersion,
      ),
      filenamePrefix: 'superduper-bike-test',
      subject: 'Superduper bike test report',
      message: 'Diagnostic report created by Superduper. The attached text file may contain the bike BLE identifier and module serial.',
    );
  }
}

final class _Requirement extends StatelessWidget {
  const _Requirement({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: AppColors.mint, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

final class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final BikeHardwareTestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (entry.status) {
      BikeHardwareTestLogStatus.passed => (
        Icons.check_circle_outline_rounded,
        AppColors.mint,
        'PASS',
      ),
      BikeHardwareTestLogStatus.warning => (
        Icons.warning_amber_rounded,
        AppColors.yellow,
        'NOTE',
      ),
      BikeHardwareTestLogStatus.failed => (
        Icons.error_outline_rounded,
        Theme.of(context).colorScheme.error,
        'FAIL',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · ${entry.label}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(entry.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
