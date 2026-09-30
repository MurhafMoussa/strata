import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/network_config_entity.dart';

/// Interceptor that automatically retries transient HTTP request failures with exponential backoff and jitter.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, required this.networkConfigEntity, Random? random})
      : _random = random ?? Random();

  final Dio dio;
  final NetworkConfigEntity networkConfigEntity;
  final Random _random ;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    final int currentRetry = options.extra['retry_count'] as int? ?? 0;
    final enableRetry =
        options.extra['enableRetry'] as bool? ??
        networkConfigEntity.enableRetry;
    final maxRetryAttempts =
        options.extra['maxRetryAttempts'] as int? ??
        networkConfigEntity.maxRetries;
    final retryDelayMs = options.extra['retryDelay'] as int?;
    final baseInterval = retryDelayMs != null
        ? Duration(milliseconds: retryDelayMs)
        : networkConfigEntity.retryInterval;

    final shouldRetry = _shouldRetry(
      err: err,
      currentRetry: currentRetry,
      enableRetry: enableRetry,
      maxRetryAttempts: maxRetryAttempts,
    );

    if (shouldRetry) {
      options.extra['retry_count'] = currentRetry + 1;
      final delay = _calculateDelay(baseInterval, currentRetry);
      await Future<void>.delayed(delay);

      try {
        final response = await dio.fetch<dynamic>(options);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      }
    } else {
      handler.next(err);
    }
  }

  Duration _calculateDelay(Duration baseInterval, int attempt) {
    final factor = 1 << attempt;
    final baseMs = baseInterval.inMilliseconds * factor;
    final jitterMs = (_random.nextDouble() * baseMs * 0.25).round();
    return Duration(milliseconds: baseMs + jitterMs);
  }

  bool _shouldRetry({
    required DioException err,
    required int currentRetry,
    required bool enableRetry,
    required int maxRetryAttempts,
  }) {
    if (!enableRetry || currentRetry >= maxRetryAttempts) {
      return false;
    }

    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    final isSocketError = err.error is SocketException;
    final isRetryableStatus = networkConfigEntity.retryOnStatusCodes.contains(
      err.response?.statusCode,
    );

    return isTimeout || isSocketError || isRetryableStatus;
  }
}
