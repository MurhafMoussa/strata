import 'package:flutter_test/flutter_test.dart';
import 'package:strata_state/strata_state.dart';

void main() {
  group('ValueSelectorState', () {
    test('supports value equality', () {
      expect(
        const ValueSelectorState<String>(['A', 'B']),
        equals(const ValueSelectorState<String>(['A', 'B'])),
      );
      expect(
        const ValueSelectorState<String>(['A']).props,
        equals([['A']]),
      );
    });
  });

  group('SingleSelectorCubit', () {
    test('selects single item and toggles unselect if allowed', () {
      final cubit = SingleSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        enableUnselect: true,
      );

      expect(cubit.selectedValuesIsEmpty, isTrue);

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);
      expect(cubit.selectedValuesIsEmpty, isFalse);

      cubit.toggleSelection('B');
      expect(cubit.isValueSelected('B'), isTrue);
      expect(cubit.isValueSelected('A'), isFalse);

      cubit.toggleSelection('B');
      expect(cubit.selectedValuesIsEmpty, isTrue);
    });

    test('does not unselect when enableUnselect is false', () {
      final cubit = SingleSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        enableUnselect: false,
      );

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);
    });

    test('initializes with defaultSelectedValues', () {
      final cubit = SingleSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        defaultSelectedValues: ['B'],
      );

      expect(cubit.isValueSelected('B'), isTrue);
      expect(cubit.state.selectedValues, equals(['B']));
    });

    test('invokes onSelectionChanged callback when selection changes', () {
      List<String>? reported;
      final cubit = SingleSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        onSelectionChanged: (values) => reported = values,
      );

      cubit.toggleSelection('A');
      expect(reported, equals(['A']));

      cubit.toggleSelection('B');
      expect(reported, equals(['B']));

      cubit.toggleSelection('B');
      expect(reported, isEmpty);
    });

    test('updateAvailableValues replaces list without mutating original', () {
      final originalValues = ['A', 'B', 'C'];
      final newValues = ['X', 'Y', 'Z'];
      List<String>? reported;
      final cubit = SingleSelectorCubit<String>(
        values: originalValues,
        enableUnselect: true,
        onSelectionChanged: (values) => reported = values,
      );

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);

      cubit.updateAvailableValues(newValues, defaultSelectedValues: ['X']);

      expect(cubit.values, equals(['X', 'Y', 'Z']));
      expect(originalValues, equals(['A', 'B', 'C']));
      expect(cubit.isValueSelected('X'), isTrue);
      expect(cubit.isValueSelected('A'), isFalse);
      expect(reported, equals(['X']));

      // Modifying caller input list does not affect cubit
      newValues.add('W');
      expect(cubit.values, equals(['X', 'Y', 'Z']));

      // Cubit values is unmodifiable
      expect(() => cubit.values.add('FAIL'), throwsUnsupportedError);
    });
  });

  group('MultiSelectorCubit', () {
    test('selects multiple items and allows toggling', () {
      final cubit = MultiSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        enableUnselect: true,
      );

      cubit.toggleSelection('A');
      cubit.toggleSelection('B');

      expect(cubit.isValueSelected('A'), isTrue);
      expect(cubit.isValueSelected('B'), isTrue);
      expect(cubit.state.selectedValues, equals(['A', 'B']));

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isFalse);
      expect(cubit.isValueSelected('B'), isTrue);
      expect(cubit.state.selectedValues, equals(['B']));
    });

    test('does not unselect when enableUnselect is false', () {
      final cubit = MultiSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        enableUnselect: false,
      );

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);

      cubit.toggleSelection('A');
      expect(cubit.isValueSelected('A'), isTrue);
    });

    test('initializes with defaultSelectedValues', () {
      final cubit = MultiSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        defaultSelectedValues: ['A', 'C'],
      );

      expect(cubit.isValueSelected('A'), isTrue);
      expect(cubit.isValueSelected('C'), isTrue);
      expect(cubit.state.selectedValues, equals(['A', 'C']));
    });

    test('invokes onSelectionChanged callback when selection changes', () {
      List<String>? reported;
      final cubit = MultiSelectorCubit<String>(
        values: ['A', 'B', 'C'],
        onSelectionChanged: (values) => reported = values,
      );

      cubit.toggleSelection('A');
      expect(reported, equals(['A']));

      cubit.toggleSelection('B');
      expect(reported, equals(['A', 'B']));

      cubit.toggleSelection('A');
      expect(reported, equals(['B']));
    });

    test('updateAvailableValues replaces list without mutating original', () {
      final originalValues = ['A', 'B', 'C'];
      final newValues = ['X', 'Y', 'Z'];
      List<String>? reported;
      final cubit = MultiSelectorCubit<String>(
        values: originalValues,
        enableUnselect: true,
        onSelectionChanged: (values) => reported = values,
      );

      cubit.toggleSelection('A');
      cubit.updateAvailableValues(newValues, defaultSelectedValues: ['X', 'Y']);

      expect(cubit.values, equals(['X', 'Y', 'Z']));
      expect(originalValues, equals(['A', 'B', 'C']));
      expect(cubit.isValueSelected('X'), isTrue);
      expect(cubit.isValueSelected('Y'), isTrue);
      expect(reported, equals(['X', 'Y']));

      // Modifying caller input list does not affect cubit
      newValues.add('W');
      expect(cubit.values, equals(['X', 'Y', 'Z']));

      // Cubit values is unmodifiable
      expect(() => cubit.values.add('FAIL'), throwsUnsupportedError);
    });
  });
}
