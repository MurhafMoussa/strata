import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';

import 'disposable_async_handler_interface.dart';

/// A delegate class that manages the complete lifecycle of a single async call.
///
/// Encapsulates loading, success, failure, retry, and automated request cancellation
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
    this.cancelRequestManager,
    this.defaultRequestId,
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

  /// Manager handling network request cancellation.
  final CancelRequestManagerInterface? cancelRequestManager;

  /// Optional default request identifier string used for cancellation tracking.
  final String? defaultRequestId;

  String? _currentRequestId;

  /// Returns the active request ID if any request is currently tracked.
  String? get currentRequestId => _currentRequestId;

  CancelRequestManagerInterface? _resolveCancelRequestManager() {
    if (cancelRequestManager != null) return cancelRequestManager;
    if (GetIt.I.isRegistered<CancelRequestManagerInterface>()) {
      return GetIt.I<CancelRequestManagerInterface>();
    }
    return null;
  }

  String? _resolveRequestId<T>(String? requestId, T params) {
    if (requestId != null) return requestId;
    if (params is PaginationParamsInterface) {
      return params.requestId;
    }
    return defaultRequestId;
  }

  /// Cancels the ongoing async request if tracked.
  void cancelRequest({String? reason}) {
    final id = _currentRequestId;
    if (id != null) {
      _resolveCancelRequestManager()?.cancelRequest(
        id,
        reason: reason ?? 'Request cancelled by AsyncHandler',
      );
      _currentRequestId = null;
    }
  }

  /// Executes the async call and manages its full state lifecycle.
  ///
  /// - When [force] is false (default) and current state is loading, skips execution.
  /// - When [force] is true, executes the async call immediately even if loading,
  ///   automatically cancelling any previous in-flight request.
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
      return;
    }

    if (_currentRequestId != null) {
      cancelRequest(reason: 'Superseded by new async call');
    }

    final effectiveRequestId = _resolveRequestId(requestId, params);

    emit(setAsyncState(currentState, AsyncState<SuccessData>.loading()));

    if (effectiveRequestId != null) {
      _currentRequestId = effectiveRequestId;
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
      if (_currentRequestId == effectiveRequestId) {
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

  /// Convenience executor for parameterless calls or closures: `execute(() => useCase(params))`
  Future<void> execute({
    required ResultFuture<SuccessData> Function() asyncCall,
    void Function(SuccessData data)? onSuccess,
    void Function(Failure failure)? onFailure,
    String? requestId,
    bool force = false,
  }) =>
      handleAsync<void>(
        asyncCall: (_) => asyncCall(),
        params: null,
        onSuccess: onSuccess,
        onFailure: onFailure,
        requestId: requestId,
        force: force,
      );

  @override
  void dispose() {
    cancelRequest(reason: 'AsyncHandler disposed');
  }
}
