import 'package:flutter/material.dart';

/// Displays the current firmware versions for the selected bike.
///
/// Intended for the main/settings page.
class BikeFirmwareVersionsSection extends StatelessWidget {
  const BikeFirmwareVersionsSection({super.key, required this.versions});

  final Map<String, String> versions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Firmware Versions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        if (versions.isEmpty)
          const ListTile(
            title: Text('No firmware information available'),
          )
        else
          ...versions.entries
              .map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                ),
              ),
      ],
    );
  }
}
