import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/token_manager_interface.dart';

/// Interceptor responsible for injecting authentication headers/credentials into requests.
abstract class TokenInjectorInterceptor extends Interceptor {
  TokenInjectorInterceptor(this._tokenManager);

  final TokenManagerInterface _tokenManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.extra['isAuthorized'] == true) {
        await _injectToken(options);
      }
      handler.next(options);
    } on DioException catch (e) {
      handler.reject(e);
    } catch (e) {
      handler.reject(
        DioException.badResponse(
          statusCode: 401,
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {
              'error': {'status': 401, 'message': 'Auth setup failed: $e'},
            },
          ),
        ),
      );
    }
  }

  Future<void> _injectToken(RequestOptions options) async {
    final token = await _tokenManager.accessToken;
    if (token.isNotEmpty) {
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
  }
}

/// Injects Bearer authorization header into authorized requests.
class BearerTokenInjectorInterceptor extends TokenInjectorInterceptor {
  BearerTokenInjectorInterceptor(super.tokenManager);
}

/// Injects Bearer token and enables cookie credentials for requests.
class CookieTokenInjectorInterceptor extends TokenInjectorInterceptor {
  CookieTokenInjectorInterceptor(super.tokenManager);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['withCredentials'] = true;
    return super.onRequest(options, handler);
  }
}
