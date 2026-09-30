import 'package:equatable/equatable.dart';

/// Callback for tracking request send or receive progress.
typedef ProgressTrackerCallback = void Function(double progress);

/// Immutable configuration options for individual network requests.
class ApiRequestOptions extends Equatable {
  /// Creates a new [ApiRequestOptions] instance.
  const ApiRequestOptions({
    this.isAuthorized = false,
    this.shouldCache = false,
    this.enableRetry = true,
    this.maxRetryAttempts,
    this.retryDelay,
    this.requestId,
    this.headers,
    this.onSendProgress,
    this.onReceiveProgress,
    this.extra,
  });

  /// Whether the request requires authorization tokens.
  final bool isAuthorized;

  /// Whether the request should attempt to cache responses.
  final bool shouldCache;

  /// Whether automatic retries are enabled for transient failures.
  final bool enableRetry;

  /// Maximum number of retry attempts.
  final int? maxRetryAttempts;

  /// Base delay between retries.
  final Duration? retryDelay;

  /// Unique identifier for tracking and canceling this request.
  final String? requestId;

  /// Custom per-request headers.
  final Map<String, String>? headers;

  /// Callback for monitoring upload progress.
  final ProgressTrackerCallback? onSendProgress;

  /// Callback for monitoring download/receive progress.
  final ProgressTrackerCallback? onReceiveProgress;

  /// Additional custom metadata passed to interceptors.
  final Map<String, dynamic>? extra;

  @override
  List<Object?> get props => [
        isAuthorized,
        shouldCache,
        enableRetry,
        maxRetryAttempts,
        retryDelay,
        requestId,
        headers,
        onSendProgress,
        onReceiveProgress,
        extra,
      ];
}
