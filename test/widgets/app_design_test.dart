import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

void main() {
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
