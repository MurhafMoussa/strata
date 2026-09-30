import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataImage Widget Tests', () {
    testWidgets('renders file image constructor without throwing error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataImage.file(
              'non_existent_path.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(StrataImage), findsOneWidget);
    });

    testWidgets('renders network image placeholder on initial load', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrataImage.network(
              'https://example.com/image.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(StrataImage), findsOneWidget);
    });
  });
}
