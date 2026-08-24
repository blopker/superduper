import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

void main() {
  test('bike color display order is alphabetical and complete', () {
    final names = BikeColor.displayOrder
        .map((color) => color.displayName)
        .toList();
    final sortedNames = names.toList()..sort();

    expect(names, sortedNames);
    expect(BikeColor.displayOrder.toSet(), BikeColor.values.toSet());
  });

  test('bike device IDs map to stable default colors', () {
    expect(
      BikeColor.defaultForDeviceId('E15225C1-76CE-3CA1-BB6A-BD3CC506ADB2'),
      BikeColor.neonCyber,
    );
    expect(
      BikeColor.defaultForDeviceId('  e15225c1-76ce-3ca1-bb6a-bd3cc506adb2 '),
      BikeColor.neonCyber,
    );
    expect(
      BikeColor.defaultForDeviceId('AA:BB:CC:DD:EE:FF'),
      BikeColor.frostedMint,
    );
    expect(
      () => BikeColor.defaultForDeviceId('  '),
      throwsArgumentError,
    );
  });

  test('every bike avatar chooses an accessible foreground color', () {
    for (final color in BikeColor.values) {
      final background = color.gradientColors.last;
      final contrast = _contrastRatio(background, color.iconColor);
      final palette = BikeColorPalette.from(color);

      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: '${color.displayName} has only $contrast:1 contrast.',
      );
      expect(
        _contrastRatio(palette.accent, palette.onAccent),
        greaterThanOrEqualTo(4.5),
        reason: '${color.displayName} has an inaccessible primary color.',
      );
      expect(
        _contrastRatio(palette.accent, palette.surfaceHighest),
        greaterThanOrEqualTo(4.5),
        reason: '${color.displayName} has an invisible accent on its panel.',
      );
      expect(
        _contrastRatio(palette.secondary, palette.onSecondary),
        greaterThanOrEqualTo(4.5),
        reason: '${color.displayName} has an inaccessible secondary color.',
      );
      expect(
        _contrastRatio(palette.secondary, palette.surfaceHighest),
        greaterThanOrEqualTo(4.5),
        reason: '${color.displayName} has an invisible secondary color.',
      );
    }
    expect(BikeColor.frostedMint.iconColor, AppColors.ink);
  });

  testWidgets('bike color theme changes only its subtree', (tester) async {
    late ThemeData baseTheme;
    late ThemeData bikeTheme;
    late BikeColorPalette palette;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            baseTheme = Theme.of(context);
            return BikeColorTheme(
              color: BikeColor.frostedMint,
              child: Builder(
                builder: (context) {
                  bikeTheme = Theme.of(context);
                  palette = BikeColorTheme.maybeOf(context)!;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(baseTheme.colorScheme.primary, AppColors.magenta);
    expect(baseTheme.colorScheme.surface, AppColors.surface);
    expect(
      bikeTheme.colorScheme.primary,
      BikeColor.frostedMint.gradientColors.last,
    );
    expect(bikeTheme.colorScheme.onPrimary, AppColors.ink);
    expect(bikeTheme.colorScheme.surface, BikeColor.frostedMint.panelTint);
    expect(palette.accent, BikeColor.frostedMint.gradientColors.last);
  });

  testWidgets('bike color label paints a full-size gradient preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: BikeColorLabel(color: BikeColor.royalHorizon)),
        ),
      ),
    );

    final swatch = find.byKey(const ValueKey('bike-color-swatch'));
    expect(swatch, findsOneWidget);
    expect(tester.getSize(swatch), const Size(24, 18));

    final decoration = tester.widget<DecoratedBox>(swatch).decoration;
    expect(
      decoration,
      isA<BoxDecoration>().having(
        (value) => (value.gradient! as LinearGradient).colors,
        'gradient colors',
        BikeColor.royalHorizon.gradientColors,
      ),
    );
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
