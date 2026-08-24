import 'package:flutter/material.dart';
import 'package:superduper/src/app_services.dart';

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
      appBar: AppBar(title: const Text('Help & tips')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text('Bike not found'),
            subtitle: Text(
              'Power on the bike, keep it nearby, and make sure Bluetooth is on.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.mobile_off),
            title: Text('Connection refused'),
            subtitle: Text(
              'Disconnect the official app or any other app that may already be using the bike.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.sync),
            title: Text('Kept settings'),
            subtitle: Text(
              'Superduper reapplies kept settings while the app is open and confirms them before showing Ready to ride.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _open(context, links.open, gettingStartedUri),
            child: const Text('Open Getting Started'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _open(context, links.open, faqUri),
            child: const Text('Open FAQ'),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    Future<bool> Function(Uri uri) open,
    Uri uri,
  ) async {
    final opened = await open(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }
}
