import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/platform/report_exporter.dart';
import 'package:superduper/src/widgets/report_actions.dart';

void main() {
  testWidgets('report failures do not expose platform exception text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportActions(
            createReport: () => Future<ShareableReport>.error(
              StateError('private platform implementation detail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save or send report'));
    await tester.pump();

    expect(
      find.text('Couldn’t prepare the report. Try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private platform'), findsNothing);
  });
}
