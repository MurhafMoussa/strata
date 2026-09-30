import 'package:equatable/equatable.dart';

/// Represents the state of [ValueSelectorCubit], holding the currently selected values.
class ValueSelectorState<T> extends Equatable {
  /// Creates a [ValueSelectorState] with the given [selectedValues].
  const ValueSelectorState(this.selectedValues);

  /// The currently selected values.
  final List<T> selectedValues;

  @override
  List<Object?> get props => [selectedValues];
}
