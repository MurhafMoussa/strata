import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  testWidgets('StrataContextExtensions provides correct BuildContext properties', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const Text('Test');
            },
          ),
        ),
      ),
    );

    expect(capturedContext.width, greaterThan(0));
    expect(capturedContext.height, greaterThan(0));
    expect(capturedContext.theme, isA<ThemeData>());
    expect(capturedContext.colorScheme, isA<ColorScheme>());
    expect(capturedContext.textTheme, isA<TextTheme>());
    expect(capturedContext.isDarkMode, isFalse);
  });
}
