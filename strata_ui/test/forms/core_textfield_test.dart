import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';
import 'package:typed_form_fields/typed_form_fields.dart';

void main() {
  group('StrataTextField Widget Tests', () {
    testWidgets('renders input field and accepts user text input', (
      tester,
    ) async {
      String? updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: TypedFormProvider(
            fields: const [
              FormFieldDefinition<String>(
                name: 'username',
                validators: [],
                initialValue: '',
              ),
            ],
            child: (context) => Scaffold(
              body: StrataTextField(
                name: 'username',
                labelText: 'Username',
                onChanged: (val) => updatedValue = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'JohnDoe');
      expect(updatedValue, equals('JohnDoe'));
    });

    testWidgets('shows required star indicator when showRequiredStar is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TypedFormProvider(
            fields: const [
              FormFieldDefinition<String>(
                name: 'email',
                validators: [],
                initialValue: '',
              ),
            ],
            child: (context) => const Scaffold(
              body: StrataTextField(
                name: 'email',
                labelText: 'Email',
                showRequiredStar: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('*'), findsOneWidget);
    });
  });
}
