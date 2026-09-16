import 'package:flutter_test/flutter_test.dart';

import 'package:lab_compilation_app/main.dart';

void main() {
  testWidgets('shows the laboratory activities dashboard', (tester) async {
    await tester.pumpWidget(const LabCompilationApp());

    expect(find.text('Lab Compilation'), findsOneWidget);
    expect(find.text('Mobile Computing'), findsOneWidget);
    expect(find.text('Device Sensors'), findsOneWidget);
  });

  testWidgets('opens Activity 1 and updates its counter', (tester) async {
    await tester.pumpWidget(const LabCompilationApp());

    await tester.tap(find.text('Open Activity').first);
    await tester.pumpAndSettle();

    expect(find.text('Interaction Counter'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Increase'));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
