import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataErrorView', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataErrorView(message: 'Connection failed'),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataErrorView(
              message: 'Connection failed',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('does not render retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataErrorView(message: 'Connection failed'),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('triggers onRetry when retry button is tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataErrorView(
              message: 'Connection failed',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('message is center-aligned', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataErrorView(message: 'Some error'),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Some error'));
      expect(textWidget.textAlign, TextAlign.center);
    });
  });
}
