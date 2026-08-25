import 'package:flutter/material.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/features/hardware_test/bike_hardware_test_page.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

final class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static final Uri faqUri = Uri.parse(
    'https://github.com/blopker/superduper#faq',
  );
  static final Uri gettingStartedUri = Uri.parse(
    'https://github.com/blopker/superduper#getting-started',
  );

  @override
  Widget build(BuildContext context) {
    final links = AppServicesScope.of(context).externalLinks;
    return Scaffold(
      appBar: AppBar(title: const Text('HELP & TIPS')),
      body: AppPageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              'Get back to riding.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Most connection problems are fixed by these three quick checks.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const _HelpTip(
              number: '01',
              icon: Icons.power_settings_new_rounded,
              title: 'Power and proximity',
              detail: 'Power on the bike, keep it nearby, and make sure Bluetooth is on.',
              accent: AppColors.yellow,
            ),
            const SizedBox(height: 12),
            const _HelpTip(
              number: '02',
              icon: Icons.mobile_off_rounded,
              title: 'Close other bike apps',
              detail: 'Disconnect the official app or any other app that may already be using the bike.',
              accent: AppColors.orange,
            ),
            const SizedBox(height: 12),
            const _HelpTip(
              number: '03',
              icon: Icons.sync_rounded,
              title: 'Wait for confirmation',
              detail: 'Superduper reapplies Set on connect values while open and confirms them before showing Ready to ride.',
              accent: AppColors.mint,
            ),
            const SizedBox(height: 30),
            const SectionHeader(
              eyebrow: 'More help',
              title: 'Guides and answers',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _open(context, links.open, gettingStartedUri),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Open Getting Started'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _open(context, links.open, faqUri),
              icon: const Icon(Icons.question_answer_outlined),
              label: const Text('Open FAQ'),
            ),
            const SizedBox(height: 34),
            const SectionHeader(
              eyebrow: 'Diagnostics',
              title: 'Check your bike',
            ),
            const SizedBox(height: 10),
            const Text(
              'Run the complete connection and settings check, then save a report if you need help.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const BikeHardwareTestPage(),
                ),
              ),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Check bike'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    Future<bool> Function(Uri uri) open,
    Uri uri,
  ) async {
    var opened = false;
    try {
      opened = await open(uri);
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }
}

final class _HelpTip extends StatelessWidget {
  const _HelpTip({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
  });

  final String number;
  final IconData icon;
  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number · $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
