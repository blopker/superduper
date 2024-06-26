import 'package:flutter/material.dart';
import 'package:superduper/help.dart';

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
                        bike: BikeState.defaultState('1'));
                  });
            },
            child: const Text('Form'),
          )
        ]),
      ),
    );
  }
}
