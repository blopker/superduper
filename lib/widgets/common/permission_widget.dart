import 'package:flutter/material.dart';

class PermissionWidget extends StatelessWidget {
  const PermissionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Please enable bluetooth and location permissions.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PermissionWidget(),
      ),
    );
  }
}