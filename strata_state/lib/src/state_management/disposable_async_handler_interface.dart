/// Contract for disposable async handlers managed by BLoC/Cubit state hosts.
abstract interface class DisposableAsyncHandlerInterface {
  /// Disposes resources held by the handler (e.g. pending requests).
  void dispose();
}
