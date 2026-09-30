import 'value_selector_cubit.dart';
import 'value_selector_state.dart';

/// A Cubit that manages single-selection of values.
class SingleSelectorCubit<T> extends ValueSelectorCubit<T> {
  /// Creates a [SingleSelectorCubit] instance.
  SingleSelectorCubit({
    required super.values,
    super.enableUnselect = true,
    super.defaultSelectedValues,
    super.onSelectionChanged,
  });

  @override
  void toggleSelection(T value) {
    final currentSelected = List<T>.from(state.selectedValues);
    if (currentSelected.contains(value)) {
      if (enableUnselect) {
        currentSelected.remove(value);
      }
    } else {
      currentSelected
        ..clear()
        ..add(value);
    }
    final nextSelected = List<T>.unmodifiable(currentSelected);
    emit(ValueSelectorState<T>(nextSelected));
    onSelectionChanged?.call(nextSelected);
  }
}
