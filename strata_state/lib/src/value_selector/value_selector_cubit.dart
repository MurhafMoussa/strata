import 'package:flutter_bloc/flutter_bloc.dart';

import 'value_selector_state.dart';

/// Abstract base class for managing the selection of values.
abstract class ValueSelectorCubit<T> extends Cubit<ValueSelectorState<T>> {
  /// Creates a [ValueSelectorCubit] instance.
  ValueSelectorCubit({
    required List<T> values,
    this.enableUnselect = true,
    List<T>? defaultSelectedValues,
    this.onSelectionChanged,
  })  : _values = List<T>.unmodifiable(values),
        super(
          ValueSelectorState<T>(
            List<T>.unmodifiable(defaultSelectedValues ?? const []),
          ),
        );

  List<T> _values;

  /// The available values to select from.
  List<T> get values => _values;

  /// Whether unselecting an already selected value is enabled.
  final bool enableUnselect;

  /// Optional callback invoked when the selection changes.
  final void Function(List<T> selectedValues)? onSelectionChanged;

  /// Toggles the selection of [value].
  void toggleSelection(T value);

  /// Returns whether [item] is currently selected.
  bool isValueSelected(T item) => state.selectedValues.contains(item);

  /// Returns whether no values are currently selected.
  bool get selectedValuesIsEmpty => state.selectedValues.isEmpty;

  /// Updates the available values and resets the selection.
  ///
  /// Replaces the internal values list reference with a new unmodifiable list
  /// instead of mutating the existing list in place.
  void updateAvailableValues(
    List<T> newValues, {
    List<T> defaultSelectedValues = const [],
  }) {
    _values = List<T>.unmodifiable(newValues);
    final nextSelected = List<T>.unmodifiable(defaultSelectedValues);
    emit(ValueSelectorState<T>(nextSelected));
    onSelectionChanged?.call(nextSelected);
  }
}
