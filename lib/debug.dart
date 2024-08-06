import 'package:flutter/material.dart';
import 'package:superduper/help.dart';
import 'dart:math';

import 'bike.dart';
import 'edit_bike.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

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
                  backgroundColor: Colors.black,
                  useSafeArea: true,
                  context: context,
                  builder: (BuildContext context) {
                    return const HelpWidget();
                  });
            },
            child: const Text('FAQ'),
          ),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BikeSettingsWidget(
                        bike: BikeState.defaultState(generateRandomMacAddress()));
                  });
            },
            child: const Text('Form'),
          )
        ]),
      ),
    );
  }

  String generateRandomMacAddress() {
    final Random random = Random();
    return '${_randomHex(random)}:${_randomHex(random)}:${_randomHex(random)}:${_randomHex(random)}:${_randomHex(random)}:${_randomHex(random)}';
  }

  String _randomHex(Random random) {
    return random.nextInt(16).toRadixString(16).padLeft(2, '0');
  }

}
