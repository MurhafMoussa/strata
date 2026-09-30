import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata_core/strata_core.dart';

import 'async_handler.dart';
import 'disposable_async_handler_interface.dart';

/// A mixin for [BlocBase] (Cubit or BLoC) that acts as a factory and manager
/// for [AsyncHandler] instances.
mixin AsyncHostMixin<CompositeState> on BlocBase<CompositeState> {
  final List<DisposableAsyncHandlerInterface> _asyncHandlers = [];

  /// Creates, registers, and returns a new [AsyncHandler].
  AsyncHandler<CompositeState, SuccessData> createAsyncHandler<SuccessData>({
    required AsyncState<SuccessData> Function(CompositeState) getAsyncState,
    required CompositeState Function(
      CompositeState,
      AsyncState<SuccessData>,
    ) setAsyncState,
    CancelRequestManagerInterface? cancelRequestManager,
    String? defaultRequestId,
  }) {
    final handler = AsyncHandler<CompositeState, SuccessData>(
      emit: emit,
      getState: () => state,
      isClosed: () => isClosed,
      getAsyncState: getAsyncState,
      setAsyncState: setAsyncState,
      cancelRequestManager: cancelRequestManager,
      defaultRequestId: defaultRequestId,
    );

    _asyncHandlers.add(handler);
    return handler;
  }

  @override
  Future<void> close() {
    for (final handler in _asyncHandlers) {
      handler.dispose();
    }
    _asyncHandlers.clear();
    return super.close();
  }
}
