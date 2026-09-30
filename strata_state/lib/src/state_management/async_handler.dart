import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';

import 'disposable_async_handler_interface.dart';

/// A delegate class that manages the complete lifecycle of a single async call.
///
/// Encapsulates loading, success, failure, retry, and request tracking
/// for a specific [AsyncState] field within a composite state.
class AsyncHandler<CompositeState, SuccessData>
    implements DisposableAsyncHandlerInterface {
  /// Creates a new [AsyncHandler].
  AsyncHandler({
    required this.emit,
    required this.getState,
    required this.isClosed,
    required this.getAsyncState,
    required this.setAsyncState,
    this.logger,
    this.onCancelRequest,
  });

  /// Function to emit new composite states.
  final void Function(CompositeState) emit;

  /// Function returning the current composite state.
  final CompositeState Function() getState;

  /// Function returning whether the host is closed.
  final bool Function() isClosed;

  /// Selector extracting [AsyncState] from the composite state.
  final AsyncState<SuccessData> Function(CompositeState) getAsyncState;

  /// Reducer updating [AsyncState] within the composite state.
  final CompositeState Function(CompositeState, AsyncState<SuccessData>)
      setAsyncState;

  /// Logger for diagnostic warnings.
  final StrataLoggerInterface? logger;

  /// Cancellation callback invoked when a request is cancelled.
  final void Function(String requestId)? onCancelRequest;

  String? _currentRequestId;

  /// Returns the active request ID if any request is currently tracked.
  String? get currentRequestId => _currentRequestId;

  /// Cancels the ongoing async request if tracked.
  void cancelRequest() {
    if (_currentRequestId != null) {
      onCancelRequest?.call(_currentRequestId!);
      _currentRequestId = null;
    }
  }

  /// Executes the async call and manages its full state lifecycle.
  ///
  /// - When [force] is false (default) and current state is loading, logs a
  ///   diagnostic warning via [StrataLoggerInterface] and skips execution.
  /// - When [force] is true, executes the async call immediately even if loading.
  Future<void> handleAsync<T>({
    required ResultFuture<SuccessData> Function(T params) asyncCall,
    required T params,
    void Function(SuccessData data)? onSuccess,
    void Function(Failure failure)? onFailure,
    String? requestId,
    bool force = false,
  }) async {
    final currentState = getState();
    final currentAsyncState = getAsyncState(currentState);

    if (currentAsyncState.isLoading && !force) {
      _logWarning(
        'AsyncHandler: handleAsync skipped because state is already loading. '
        'Pass force: true to execute during loading state.',
      );
      return;
    }

    emit(setAsyncState(currentState, AsyncState<SuccessData>.loading()));

    if (requestId != null) {
      _currentRequestId = requestId;
    }

    try {
      final result = await asyncCall(params);

      if (!isClosed()) {
        final latestState = getState();

        result.fold(
          (failure) {
            emit(
              setAsyncState(
                latestState,
                AsyncState<SuccessData>.failure(
                  failure,
                  retryFunction: () => handleAsync(
                    asyncCall: asyncCall,
                    params: params,
                    onSuccess: onSuccess,
                    onFailure: onFailure,
                    requestId: requestId,
                    force: force,
                  ),
                ),
              ),
            );
            onFailure?.call(failure);
          },
          (success) {
            emit(
              setAsyncState(
                latestState,
                AsyncState<SuccessData>.success(success),
              ),
            );
            onSuccess?.call(success);
          },
        );
      }
    } finally {
      if (_currentRequestId == requestId) {
        _currentRequestId = null;
      }
    }
  }

  /// Alias for [handleAsync] to manage async calls.
  Future<void> handleAsyncCall<T>({
    required ResultFuture<SuccessData> Function(T params) asyncCall,
    required T params,
    void Function(SuccessData data)? onSuccess,
    void Function(Failure failure)? onFailure,
    String? requestId,
    bool force = false,
  }) =>
      handleAsync(
        asyncCall: asyncCall,
        params: params,
        onSuccess: onSuccess,
        onFailure: onFailure,
        requestId: requestId,
        force: force,
      );

  void _logWarning(String message) {
    if (logger != null) {
      logger!.warning(message);
    } else if (GetIt.I.isRegistered<StrataLoggerInterface>()) {
      GetIt.I<StrataLoggerInterface>().warning(message);
    }
  }

  @override
  void dispose() {
    cancelRequest();
  }
}
