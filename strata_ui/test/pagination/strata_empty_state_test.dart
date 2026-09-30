import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataEmptyState', () {
    testWidgets('renders "No items found" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataEmptyState(),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders inbox icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataEmptyState(),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('is centered with padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataEmptyState(),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(StrataEmptyState),
          matching: find.byType(Center),
        ),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.descendant(
          of: find.byType(StrataEmptyState),
          matching: find.byType(Padding),
        ),
        findsOneWidget,
      );
    });
  });
}
