import 'package:flutter/material.dart';
import 'dart:math';

import '../providers/bike_provider.dart';
import 'edit_bike_page.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  // Function to generate a random MAC address
  String _generateRandomMac() {
    final random = Random();
    final parts = List.generate(6, (_) => random.nextInt(256));
    return parts
        .map((part) => part.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BikeSettingsWidget(
                        bike: BikeState.defaultState(_generateRandomMac()));
                  });
            },
            child: const Text('Form'),
          )
        ]),
      ),
    );
  }
}
