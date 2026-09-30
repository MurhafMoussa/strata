import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:strata_core/strata_core.dart';

/// A widget builder that reacts to a specific [AsyncState] within a BLoC/Cubit composite state.
class AsyncBuilder<CompositeState, SuccessData> extends StatelessWidget {
  /// Creates a new [AsyncBuilder].
  const AsyncBuilder({
    super.key,
    required this.bloc,
    required this.getAsyncState,
    required this.successBuilder,
    this.initialBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyEntity,
  });

  /// The BLoC/Cubit to observe.
  final BlocBase<CompositeState> bloc;

  /// Selector function to extract [AsyncState] from the composite state.
  final AsyncState<SuccessData> Function(CompositeState) getAsyncState;

  /// Builder for the [AsyncStateSuccess] state.
  final Widget Function(BuildContext context, SuccessData data) successBuilder;

  /// Optional builder for [AsyncStateInitial] state. Defaults to [SizedBox.shrink].
  final Widget Function(BuildContext context)? initialBuilder;

  /// Optional builder for [AsyncStateLoading] state.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Optional builder for [AsyncStateFailure] state.
  final Widget Function(
    BuildContext context,
    Failure failure,
    void Function()? retry,
  )? errorBuilder;

  /// Dummy entity for rendering skeleton loading state when [loadingBuilder] is omitted.
  final SuccessData? emptyEntity;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlocBase<CompositeState>, CompositeState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          getAsyncState(previous) != getAsyncState(current),
      builder: (context, state) {
        final asyncState = getAsyncState(state);

        return switch (asyncState) {
          AsyncStateInitial<SuccessData>() =>
            initialBuilder?.call(context) ?? const SizedBox.shrink(),
          AsyncStateLoading<SuccessData>() =>
            loadingBuilder?.call(context) ??
                (emptyEntity != null
                    ? Skeletonizer(
                        child:
                            successBuilder(context, emptyEntity as SuccessData),
                      )
                    : const Center(child: CircularProgressIndicator())),
          AsyncStateSuccess<SuccessData>(:final value) =>
            successBuilder(context, value),
          AsyncStateFailure<SuccessData>(:final failure, :final retryFunction) =>
            errorBuilder?.call(context, failure, retryFunction) ??
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(failure.message),
                      if (retryFunction != null)
                        TextButton(
                          onPressed: retryFunction,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
        };
      },
    );
  }
}
