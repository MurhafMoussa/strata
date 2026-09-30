/// Abstract contract for managing request cancellation across sub-packages.
///
/// `@example`
/// ```dart
/// class MyCancelManager extends CancelRequestManagerInterface {
///   @override
///   void cancelRequest(String requestId, {String? reason}) {
///     print('Cancelled $requestId: $reason');
///   }
///
///   @override
///   void cancelAll({String? reason}) {
///     print('Cancelled all: $reason');
///   }
/// }
/// ```
abstract class CancelRequestManagerInterface {
  /// Const constructor for [CancelRequestManagerInterface].
  const CancelRequestManagerInterface();

  /// Cancels all active network requests associated with [requestId].
  void cancelRequest(String requestId, {String? reason});

  /// Cancels all active requests across all registered request IDs.
  void cancelAll({String? reason});
}
