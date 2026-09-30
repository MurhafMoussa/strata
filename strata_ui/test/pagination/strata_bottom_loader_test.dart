import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataBottomLoader', () {
    testWidgets('renders bottom loader with correct key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomLoader(),
          ),
        ),
      );

      expect(
        find.byKey(const Key('strata_pagination_bottom_loader')),
        findsOneWidget,
      );
    });

    testWidgets('renders CircularProgressIndicator.adaptive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataBottomLoader(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
