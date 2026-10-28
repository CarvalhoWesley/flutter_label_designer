import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter_label_designer/flutter_label_designer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_studio/src/print/print_dialog.dart';

void main() {
  final document = LabelDocument.blank(name: 'Teste').copyWith(
    variables: const [
      LabelVariable(name: 'produto', defaultValue: 'Parafuso'),
    ],
  );

  Future<void> pumpDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font is much wider than the real one, so the fixed-width
    // dialog overflows here in ways it doesn't on screen.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PrintDialog(document: document))),
    );
    await tester.pump();
  }

  testWidgets('sample data fields accept typing', (tester) async {
    await pumpDialog(tester);

    final field = find.widgetWithText(TextField, 'produto');
    await tester.enterText(field, 'Porca M8');
    await tester.pump();

    expect(find.text('Porca M8'), findsOneWidget);
  });

  testWidgets('offset fields accept typing', (tester) async {
    await pumpDialog(tester);

    final field = find.widgetWithText(TextFormField, 'Deslocamento X');
    await tester.enterText(field, '1.5');
    await tester.pump();

    expect(find.text('1.5'), findsOneWidget);
  });
}
