import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataOfflineBadge', () {
    testWidgets('renders offline badge with correct key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataOfflineBadge(),
          ),
        ),
      );

      expect(
        find.byKey(const Key('strata_pagination_offline_badge')),
        findsOneWidget,
      );
    });

    testWidgets('renders "Viewing offline cached data" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataOfflineBadge(),
          ),
        ),
      );

      expect(find.text('Viewing offline cached data'), findsOneWidget);
    });

    testWidgets('renders wifi_off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataOfflineBadge(),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });
}
