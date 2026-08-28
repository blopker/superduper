import 'package:flutter/material.dart';

final class BikeValueSelector extends StatelessWidget {
  const BikeValueSelector({
    required this.values,
    required this.selected,
    required this.enabled,
    required this.semanticLabel,
    required this.label,
    required this.onChanged,
    super.key,
  });

  final List<int> values;
  final int? selected;
  final bool enabled;
  final String semanticLabel;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: [
          for (final value in values)
            ButtonSegment<int>(
              value: value,
              label: Semantics(
                label: '$semanticLabel ${label(value)}',
                excludeSemantics: true,
                child: Text(label(value)),
              ),
            ),
        ],
        selected: selected == null ? const {} : {selected!},
        emptySelectionAllowed: true,
        onSelectionChanged: enabled
            ? (selection) {
                if (selection.isNotEmpty) {
                  onChanged(selection.single);
                }
              }
            : null,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(42, 50)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return states.contains(WidgetState.disabled)
                ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                : scheme.onSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
