/// Abstract contract for pagination request parameter models.
///
/// Implementations expose a unique [requestId] used for request keying
/// and cancellation tracking via `CancelRequestManagerInterface`.
///
/// `@example`
/// ```dart
/// class MyPaginationParams implements PaginationParamsInterface {
///   const MyPaginationParams({required this.page, required this.limit});
///
///   final int page;
///   final int limit;
///
///   @override
///   String get requestId => 'page_${page}_limit_$limit';
/// }
/// ```
abstract interface class PaginationParamsInterface {
  /// Const constructor for [PaginationParamsInterface].
  const PaginationParamsInterface();

  /// Unique request identifier string for request keying and cancellation tracking.
  String get requestId;
}
