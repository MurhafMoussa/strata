import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataBottomRetryBar', () {
    testWidgets('renders failure message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: ServerFailure(
                message: 'Failed to load page 2',
                statusCode: 500,
              ),
              onRetryMore: null,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load page 2'), findsOneWidget);
    });

    testWidgets('renders default message when failure is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: null,
              onRetryMore: null,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load next page'), findsOneWidget);
    });

    testWidgets('renders retry button with correct key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: ServerFailure(message: 'Error', statusCode: 500),
              onRetryMore: null,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('strata_pagination_retry_button')),
        findsOneWidget,
      );
    });

    testWidgets('renders retry bar with correct key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: ServerFailure(message: 'Error', statusCode: 500),
              onRetryMore: null,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('strata_pagination_retry_bar')),
        findsOneWidget,
      );
    });

    testWidgets('triggers onRetryMore when retry button is tapped', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: const ServerFailure(
                message: 'Failed to load page 2',
                statusCode: 500,
              ),
              onRetryMore: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('strata_pagination_retry_button')));
      expect(retryCalled, isTrue);
    });

    testWidgets('renders "Retry" label on button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomRetryBar(
              failure: ServerFailure(message: 'Error', statusCode: 500),
              onRetryMore: null,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
