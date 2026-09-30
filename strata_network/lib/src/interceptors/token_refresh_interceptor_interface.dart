import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';

import '../auth/token_manager_interface.dart';
import '../config/network_config_entity.dart';

/// Abstract interceptor responsible for handling token refresh on 401 errors.
abstract class TokenRefreshInterceptorInterface extends Interceptor {
  TokenRefreshInterceptorInterface({
    required this.dio,
    required this.tokenManager,
    required this.networkConfigEntity,
  });

  final Dio dio;
  final TokenManagerInterface tokenManager;
  final NetworkConfigEntity networkConfigEntity;

  final Mutex _refreshMutex = Mutex();
  final Queue<MapEntry<RequestOptions, ErrorInterceptorHandler>> _pending =
      Queue();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldHandle401(err)) {
      await _queueAndRefresh(err, handler);
    } else {
      handler.reject(err);
    }
  }

  bool _shouldHandle401(DioException err) {
    if (!networkConfigEntity.enableRefreshTokenBehavior) {
      return false;
    }
    final requestOptions = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final requiresAuthorization = requestOptions.extra['isAuthorized'] == true;
    final isNotRetryAttempt = requestOptions.extra['isRetry'] != true;
    final isNotRefreshTokenPath = !requestOptions.path.contains(
      networkConfigEntity.refreshTokenApiEndpoint,
    );
    final isNotExcludedPath = !networkConfigEntity.excludedPaths.any(
      (path) => requestOptions.path.contains(path),
    );
    return isUnauthorized &&
        requiresAuthorization &&
        isNotRetryAttempt &&
        isNotRefreshTokenPath &&
        isNotExcludedPath;
  }

  Future<void> _queueAndRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _pending.add(MapEntry(err.requestOptions, handler));

    if (!_refreshMutex.isLocked) {
      await _refreshMutex.protect(() async {
        bool success = false;
        try {
          success = await handleRefresh(err);
        } catch (_) {
          success = false;
        }

        if (!success) {
          try {
            await tokenManager.clearTokens();
          } catch (_) {
            // Continue rejecting the queued requests even if cleanup fails.
          }

          tokenManager.notifyUnauthenticated();
        }

        while (_pending.isNotEmpty) {
          final entry = _pending.removeFirst();
          if (success) {
            await _retry(entry.key, entry.value);
          } else {
            entry.value.reject(_makeRefreshFailure(entry.key, err));
          }
        }
      });
    }
  }

  Future<void> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    requestOptions.extra['isRetry'] = true;
    try {
      final resp = await dio.fetch<dynamic>(requestOptions);
      handler.resolve(resp);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  DioException _makeRefreshFailure(RequestOptions opts, DioException err) {
    final statusCode = err.response?.statusCode ?? 401;
    return DioException.badResponse(
      statusCode: statusCode,
      requestOptions: opts,
      response: Response(
        requestOptions: opts,
        statusCode: statusCode,
        data:
            err.response?.data ??
            {
              'error': {
                'status': statusCode,
                'message': 'Token refresh failed',
              },
            },
      ),
    );
  }

  /// Implemented by subclasses to execute the refresh request.
  Future<bool> handleRefresh(DioException err);

  /// Helper to extract nested JSON values via dot notation (e.g. `data.token`).
  dynamic getNestedValue(Map<String, dynamic>? data, String path) {
    if (data == null || path.isEmpty) return null;
    dynamic currentValue = data;
    for (final key in path.split('.')) {
      if (currentValue is! Map || !currentValue.containsKey(key)) {
        return null;
      }
      currentValue = currentValue[key];
    }
    return currentValue;
  }

  String? getNestedString(Map<String, dynamic>? data, String path) {
    final value = getNestedValue(data, path);
    return value is String && value.isNotEmpty ? value : null;
  }
}

/// Token refresh interceptor for Bearer token authorization headers.
class BearerTokenRefreshInterceptor extends TokenRefreshInterceptorInterface {
  BearerTokenRefreshInterceptor({
    required super.dio,
    required super.tokenManager,
    required super.networkConfigEntity,
   
  });

  @override
  Future<bool> handleRefresh(DioException err) async {
    final rt = await tokenManager.refreshToken;
    if (rt.isEmpty) return false;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        networkConfigEntity.refreshTokenApiEndpoint,
        data: {networkConfigEntity.refreshTokenKey: rt},
        options: Options(extra: {'isAuthorized': false}),
      );
      final data = response.data;
      if (data == null) return false;

      final accessToken = getNestedString(
        data,
        networkConfigEntity.accessTokenKey,
      );
      if (accessToken == null) return false;
      final refreshToken = getNestedString(
        data,
        networkConfigEntity.refreshTokenKey,
      );
      await tokenManager.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Token refresh interceptor for cookie-based authorization.
class CookieTokenRefreshInterceptor extends TokenRefreshInterceptorInterface {
  CookieTokenRefreshInterceptor({
    required super.dio,
    required super.tokenManager,
    required super.networkConfigEntity,

  });

  @override
  Future<bool> handleRefresh(DioException err) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        networkConfigEntity.refreshTokenApiEndpoint,
        options: Options(extra: {'isAuthorized': false}),
      );
      final data = response.data;
      if (data == null) return false;

      final refreshToken = getNestedString(
        data,
        networkConfigEntity.refreshTokenKey,
      );
      final accessToken = getNestedString(
        data,
        networkConfigEntity.accessTokenKey,
      );
      if (accessToken == null && refreshToken == null) return false;
      await tokenManager.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
